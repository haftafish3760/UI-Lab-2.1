import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/directory_draft_workflows.dart';
import 'package:ui_lab_2_1/src/data/work/directory_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'support/storage/seeded_directory_fixture.dart';
import 'package:ui_lab_2_1/src/data/work/employee_draft_controller.dart';

import 'support/storage/database_harness.dart';

EmployeeDraftInput employeeInput({String role = 'Technician'}) =>
    EmployeeDraftInput(
      employeeId: 'unfinished-employee',
      baseRevision: 0,
      role: role,
      active: true,
      canSeeEstimates: true,
      canCreateEstimates: false,
      canApproveEstimates: false,
      canRecordExpenses: true,
      canViewCompanyReports: false,
      name: 'Unfinished name',
      phone: '+1 (',
      emergency: '',
      pay: '12.',
    );

void main() {
  test(
    'controller confirmation consumes input atomically and rejects stale submit',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      final directory = await openSeededTestDirectory(database);
      final other = await openSeededTestDirectory(database);
      final controller = await directory.openEmployeeDraft();
      controller.updateInput(employeeInput());
      await controller.session.flush();
      final stale = await other.openEmployeeDraft();
      final profile = employeeInput().confirmedProfile();
      expect((await controller.confirm())!.toJson(), profile.toJson());
      await expectLater(controller.confirm(), throwsStateError);
      expect(await stale.confirm(), isNull);
      expect(stale.recoveredInput!.pay, '12.');
      await controller.session.close();
      await stale.session.close();
      directory.dispose();
      other.dispose();
      await harness.close(database);
      database = await harness.open();
      final reopened = await openSeededTestDirectory(database);
      addTearDown(reopened.dispose);
      expect(
        reopened.employees.singleWhere((e) => e.id == profile.id).name,
        profile.name,
      );
      expect(reopened.employeeRevision(profile.id), 1);
      final recovery = await reopened.openEmployeeDraft();
      expect(recovery.recoveredInput, isNull);
      await recovery.session.close();
    },
  );

  test(
    'directory opens legacy identities without routes and isolates actors',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var directory = await openSeededTestDirectory(database);
      final actor = directory.permissions.actorEmployeeId;
      final organization = directory.permissions.organizationId;
      // This literal identity predates the service; layout-independent opening
      // must locate it without a widget supplying the persisted key.
      await directory.drafts.save(
        organizationId: organization,
        domain: 'directory/employee-editor',
        draftId: 'new-$actor',
        ownerId: actor,
        expectedRevision: 0,
        payload: employeeInput().toPayload(),
        occurredAt: DateTime.utc(2026, 9, 9),
      );
      directory.dispose();
      await harness.close(database);
      database = await harness.open();
      directory = await openSeededTestDirectory(database);
      addTearDown(directory.dispose);
      final recovered = await directory.openEmployeeDraft();
      expect(recovered.recoveredInput!.phone, '+1 (');
      expect(recovered.recoveredInput!.pay, '12.');
      expect(recovered.session.savedRevision, 1);
      await recovered.session.close();

      final other = await DirectoryPersistenceSession.open(
        database,
        DirectoryPermissions(
          organizationId: organization,
          actorEmployeeId: 'other-actor',
          permissionRevision: 'test-only',
          canViewEmployees: true,
          canManageEmployees: true,
        ),
      );
      addTearDown(other.dispose);
      final isolated = await other.openEmployeeDraft();
      expect(isolated.recoveredInput, isNull);
      expect(isolated.session.draftId, 'new-other-actor');
      await isolated.session.close();
      final retained = await directory.drafts.find(
        organizationId: organization,
        domain: 'directory/employee-editor',
        draftId: 'new-$actor',
        ownerId: actor,
      );
      expect(retained!.revision, 1);
      expect(directory.drafts.decode(retained), employeeInput().toPayload());
    },
  );

  test(
    'profile opening enforces access without relying on route guards',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final database = await harness.open();
      final denied = await DirectoryPersistenceSession.open(
        database,
        const DirectoryPermissions(
          organizationId: 'business',
          actorEmployeeId: 'restricted',
          permissionRevision: 'synthetic-denial',
        ),
      );
      addTearDown(denied.dispose);
      expect(denied.openCompanyDraft, throwsStateError);
      expect(denied.openEmployeeDraft, throwsStateError);
      expect(denied.openVehicleDraft, throwsStateError);
      expect(await database.select(database.localDrafts).get(), isEmpty);
    },
  );

  test('company and vehicle opening retain existing stable keys', () async {
    final harness = await DatabaseHarness.create();
    addTearDown(harness.dispose);
    final directory = await openSeededTestDirectory(await harness.open());
    addTearDown(directory.dispose);
    final actor = directory.permissions.actorEmployeeId;
    final company = await directory.openCompanyDraft();
    expect(company.session.domain, 'directory/company-editor');
    expect(company.session.draftId, 'company-$actor');
    await company.session.close();
    final fresh = await directory.openVehicleDraft();
    expect(fresh.session.domain, 'directory/vehicle-editor');
    expect(fresh.session.draftId, 'new-$actor');
    await fresh.session.close();
    final vehicle = directory.vehicles.first;
    final edit = await directory.openVehicleDraft(vehicleId: vehicle.id);
    expect(edit.session.draftId, 'edit-$actor-${vehicle.id}');
    expect(edit.expectedRecordId, vehicle.id);
    await edit.session.close();
    expect(
      () => directory.openVehicleDraft(vehicleId: 'missing'),
      throwsStateError,
    );
    expect(
      () => directory.openEmployeeDraft(employeeId: 'missing'),
      throwsStateError,
    );
  });

  test('failed recovery opening retains the row and can be retried', () async {
    final harness = await DatabaseHarness.create();
    addTearDown(harness.dispose);
    final directory = await openSeededTestDirectory(await harness.open());
    addTearDown(directory.dispose);
    final permissions = directory.permissions;
    final payload = employeeInput(role: 'unsupported').toPayload();
    await directory.drafts.save(
      organizationId: permissions.organizationId,
      domain: 'directory/employee-editor',
      draftId: 'new-${permissions.actorEmployeeId}',
      ownerId: permissions.actorEmployeeId,
      expectedRevision: 0,
      payload: payload,
      occurredAt: DateTime.utc(2026, 9, 9),
    );
    for (var attempt = 0; attempt < 2; attempt++) {
      await expectLater(directory.openEmployeeDraft(), throwsFormatException);
    }
    final retained = await directory.drafts.find(
      organizationId: permissions.organizationId,
      domain: 'directory/employee-editor',
      draftId: 'new-${permissions.actorEmployeeId}',
      ownerId: permissions.actorEmployeeId,
    );
    expect(retained!.revision, 1);
    expect(directory.drafts.decode(retained), payload);
  });
}
