import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/work/directory_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'support/storage/seeded_directory_fixture.dart';
import 'package:ui_lab_2_1/src/data/work/employee_directory_profile.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'employee confirmation, private fields and configured access survive reopen without reseeding',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var session = await openSeededTestDirectory(db);
      final profile = EmployeeDirectoryProfile.fromJson({
        ...session.employees.first.toJson(),
        'name': 'Retained employee',
        'phone': '555 0000',
        'pay': 'Salary arrangement',
        'emergencyContact': 'Private contact',
        'active': false,
        'status': 'Former employee',
        'canSeeEstimates': false,
        'canCreateEstimates': false,
        'canApproveEstimates': false,
        'canRecordExpenses': false,
        'canViewCompanyReports': true,
      });
      expect(await session.saveEmployee(profile, expectedRevision: 1), isTrue);
      session.dispose();
      await harness.close(db);
      db = await harness.open();
      session = await openSeededTestDirectory(db);
      addTearDown(session.dispose);
      expect(session.employees, hasLength(3));
      expect(
        session.employees.singleWhere((e) => e.id == profile.id).toJson(),
        profile.toJson(),
      );
      expect(session.employeeRevision(profile.id), 2);
    },
  );

  test(
    'denied reads and writes, view-only, and other organizations cannot change private employee records',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final owner = await openSeededTestDirectory(db);
      addTearDown(owner.dispose);
      for (final permissions in [
        DirectoryPermissions(
          organizationId: owner.permissions.organizationId,
          actorEmployeeId: 'denied',
          permissionRevision: '1',
          canManageEmployees: true,
        ),
        DirectoryPermissions(
          organizationId: owner.permissions.organizationId,
          actorEmployeeId: 'viewer',
          permissionRevision: '1',
          canViewEmployees: true,
        ),
        const DirectoryPermissions(
          organizationId: 'other',
          actorEmployeeId: 'owner',
          permissionRevision: '1',
          canViewEmployees: true,
        ),
      ]) {
        final session = await DirectoryPersistenceSession.open(db, permissions);
        addTearDown(session.dispose);
        expect(
          session.employees,
          hasLength(permissions.actorEmployeeId == 'viewer' ? 3 : 0),
        );
        expect(
          await session.saveEmployee(
            owner.employees.first,
            expectedRevision: 1,
          ),
          isFalse,
        );
      }
      expect(owner.employeeRevision(owner.employees.first.id), 1);
    },
  );

  test(
    'SQL failure and stale cross-connection confirmation preserve draft and cache atomically',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final owner = await openSeededTestDirectory(db);
      addTearDown(owner.dispose);
      final otherDb = await harness.open();
      final stale = await DirectoryPersistenceSession.open(
        otherDb,
        owner.permissions,
      );
      addTearDown(stale.dispose);
      final original = owner.employees.first;
      final changed = EmployeeDirectoryProfile.fromJson({
        ...original.toJson(),
        'name': 'First confirmed',
      });
      final drafts = LocalDraftStore(db);
      final p = owner.permissions;
      await drafts.save(
        organizationId: p.organizationId,
        domain: 'directory/employee-editor',
        draftId: 'recovery',
        ownerId: p.actorEmployeeId,
        expectedRevision: 0,
        payload: {'name': 'Unfinished'},
        occurredAt: DateTime.now(),
      );
      const checkpoint = LocalDraftCheckpoint(
        domain: 'directory/employee-editor',
        draftId: 'recovery',
        revision: 1,
      );
      Future<int> draftCount() async => (await drafts.list(
        organizationId: p.organizationId,
        domain: checkpoint.domain,
        ownerId: p.actorEmployeeId,
      )).length;
      await db.customStatement("""
      CREATE TRIGGER fail_employee BEFORE UPDATE ON local_records
      WHEN NEW.domain = 'directory/employees'
      BEGIN SELECT RAISE(ABORT, 'injected write failure'); END
    """);
      expect(
        await owner.saveEmployee(
          changed,
          expectedRevision: 1,
          draftCheckpoint: checkpoint,
        ),
        isFalse,
      );
      expect(owner.employees.first.toJson(), original.toJson());
      expect(await draftCount(), 1);
      await db.customStatement('DROP TRIGGER fail_employee');
      expect(await owner.saveEmployee(changed, expectedRevision: 1), isTrue);
      // Even an unchanged stale form must execute SQL CAS, not silently consume input.
      expect(
        await stale.saveEmployee(
          original,
          expectedRevision: 1,
          draftCheckpoint: checkpoint,
        ),
        isFalse,
      );
      expect(await draftCount(), 1);
      expect(stale.employees.first.toJson(), original.toJson());
      expect(
        await owner.saveEmployee(
          changed,
          expectedRevision: 2,
          draftCheckpoint: checkpoint,
        ),
        isTrue,
      );
      expect(await draftCount(), 0);
      await db.verifyIntegrity();
    },
  );
}
