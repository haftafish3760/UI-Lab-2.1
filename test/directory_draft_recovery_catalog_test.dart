import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/work/directory_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/directory_draft_workflows.dart';
import 'package:ui_lab_2_1/src/data/work/customer_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/company_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/vehicle_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/directory_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/workday/sqlite_workday_repository.dart';
import 'package:ui_lab_2_1/src/data/work/directory_recovery_revision.dart';
import 'support/storage/database_harness.dart';
import 'directory_draft_workflows_test.dart' show employeeInput;
import 'directory_draft_confirmation_input_test.dart' show vehicleInput;
import 'customer_draft_workflow_test.dart' as customer;
import 'vehicle_directory_persistence_test.dart' as fleet;

DraftAutosaveSession sessionOf(ResumedDirectoryDraft value) => switch (value) {
  ResumedCompanyDraft(:final controller) => controller.session,
  ResumedCustomerDraft(:final controller) => controller.session,
  ResumedEmployeeDraft(:final controller) => controller.session,
  ResumedVehicleDraft(:final controller) => controller.session,
};
Future<void> seedDrafts(DirectoryPersistenceSession directory) async {
  final company = await directory.openCompanyDraft();
  company.updateInput(
    CompanyDraftInput(
      baseProfile: directory.company,
      baseRevision: directory.companyRevision,
      logoLabel: 'Logo',
      name: '  Pending company ',
      category: '',
      phone: '+1 (',
      email: 'pending@',
      website: '',
      address: '',
      terms: '  Terms  ',
    ),
  );
  await company.session.close();
  final employee = await directory.openEmployeeDraft();
  employee.updateInput(employeeInput());
  await employee.session.close();
  final vehicle = await directory.openVehicleDraft();
  vehicle.updateInput(vehicleInput('12.'));
  await vehicle.session.close();
  final client = await directory.openCustomerDraft();
  client.updateInput(customer.inputFor(existing: false));
  await client.session.close();
}

void main() {
  test(
    'directory catalog reopens all four typed workflows and preserves exact raw input',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var directory = await openUiLabDirectory(db);
      await seedDrafts(directory);
      final raw = <String, Map<String, Object?>>{};
      for (final entry in await DirectoryDraftRecovery(directory).list()) {
        final row = (await directory.drafts.find(
          organizationId: directory.permissions.organizationId,
          ownerId: directory.permissions.actorEmployeeId,
          domain: entry.domain,
          draftId: entry.draftId,
        ))!;
        raw[entry.domain] = directory.drafts.decode(row);
      }
      directory.dispose();
      await harness.close(db);
      db = await harness.open();
      directory = await openUiLabDirectory(db);
      addTearDown(directory.dispose);
      final recovery = DirectoryDraftRecovery(directory);
      final entries = await recovery.list();
      expect(entries, hasLength(4));
      for (final entry in entries) {
        expect(
          entry.preview.availability,
          DraftRecoveryAvailability.recoverable,
        );
        final session = sessionOf(await recovery.resume(entry));
        expect(session.input, raw[entry.domain]);
        expect(session.savedRevision, entry.revision);
        await session.close();
      }
      expect(directory.customerRevision(customer.original.id), 0);
      expect(directory.employeeRevision(employeeInput().employeeId), 0);
      expect(directory.vehicleRevision(vehicleInput('').vehicleId), 0);
    },
  );
  test(
    'all directory factories reject changed or consumed selection without reseeding',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final directory = await openUiLabDirectory(await harness.open());
      addTearDown(directory.dispose);
      await seedDrafts(directory);
      final recovery = DirectoryDraftRecovery(directory);
      for (final entry in await recovery.list()) {
        Future<Object> open(int revision) {
          final selected = DraftRecoverySelection(
            domain: entry.domain,
            draftId: entry.draftId,
            revision: revision,
          );
          return switch (entry.domain) {
            'directory/company-editor' => directory.openCompanyDraft(
              recoverySelection: selected,
            ),
            'directory/customer-editor' => directory.openCustomerDraft(
              recoverySelection: selected,
            ),
            'directory/employee-editor' => directory.openEmployeeDraft(
              recoverySelection: selected,
            ),
            _ => directory.openVehicleDraft(recoverySelection: selected),
          };
        }

        await expectLater(
          open(entry.revision + 1),
          throwsA(isA<LocalRecordConflict>()),
        );
        await recovery.discard(entry);
        await expectLater(
          open(entry.revision),
          throwsA(isA<LocalRecordConflict>()),
        );
      }
      expect(await recovery.list(), isEmpty);
    },
  );
  test(
    'fresh directory reads detect another session creating the draft identity; missing and unreadable input remain retained',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final directory = await openUiLabDirectory(db);
      addTearDown(directory.dispose);
      await seedDrafts(directory);
      final recovery = DirectoryDraftRecovery(directory);
      final selected = (await recovery.list()).singleWhere(
        (e) => e.domain == 'directory/customer-editor',
      );
      final other = await openUiLabDirectory(await harness.open());
      addTearDown(other.dispose);
      expect(
        await other.saveCustomer(customer.original, expectedRevision: 0),
        isTrue,
      );
      expect(directory.customerRevision(customer.original.id), 0);
      expect(
        (await recovery.list())
            .singleWhere((e) => e.domain == selected.domain)
            .preview
            .availability,
        DraftRecoveryAvailability.conflict,
      );
      await expectLater(recovery.resume(selected), throwsStateError);
      for (final payload in [
        (
          'orphan',
          <String, Object?>{...employeeInput().toPayload(), 'baseRevision': 1},
        ),
        ('malformed', <String, Object?>{'name': 'Private malformed name'}),
      ]) {
        await directory.drafts.save(
          organizationId: directory.permissions.organizationId,
          ownerId: directory.permissions.actorEmployeeId,
          domain: 'directory/employee-editor',
          draftId: payload.$1,
          expectedRevision: 0,
          payload: payload.$2,
          occurredAt: DateTime.now(),
        );
      }
      final entries = await recovery.list();
      expect(entries, hasLength(6));
      final orphan = entries.singleWhere((e) => e.draftId == 'orphan');
      expect(
        orphan.preview.availability,
        DraftRecoveryAvailability.parentUnavailable,
      );
      await expectLater(recovery.resume(orphan), throwsStateError);
      final malformed = entries.singleWhere((e) => e.draftId == 'malformed');
      expect(
        malformed.preview.availability,
        DraftRecoveryAvailability.unreadable,
      );
      expect(malformed.preview.title, isNot(contains('Private')));
      final denied = await DirectoryPersistenceSession.open(
        db,
        DirectoryPermissions(
          organizationId: directory.permissions.organizationId,
          actorEmployeeId: directory.permissions.actorEmployeeId,
          permissionRevision: 'synthetic-denial',
        ),
      );
      addTearDown(denied.dispose);
      expect(await DirectoryDraftRecovery(denied).list(), isEmpty);
      for (final kind in DirectoryProfileKind.values) {
        await expectLater(
          denied.recoveryRevisionFor(kind, 'company'),
          throwsStateError,
        );
      }
      expect(await recovery.list(), hasLength(6));
    },
  );
  test(
    'independent workday mileage revision blocks vehicle recovery without rebasing saved reading',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final directory = await DirectoryPersistenceSession.open(
        db,
        fleet.access,
      );
      addTearDown(directory.dispose);
      expect(
        await directory.saveVehicle(
          fleet.vehicle,
          expectedRevision: 0,
          odometerTenths: 1000,
          expectedOdometerRevision: 0,
        ),
        isTrue,
      );
      final workflow = await directory.openVehicleDraft(
        vehicleId: fleet.vehicle.id,
      );
      workflow.updateInput(
        const VehicleDraftInput(
          vehicleId: 'van',
          baseRevision: 1,
          odometerRevision: 1,
          active: true,
          name: 'Pending van',
          model: '',
          odometer: '100.',
          assignment: '',
        ),
      );
      await workflow.session.close();
      final recovery = DirectoryDraftRecovery(directory);
      final selected = (await recovery.list()).single;
      expect(
        selected.preview.availability,
        DraftRecoveryAvailability.recoverable,
      );
      expect(
        (await directory.recoveryRevisionFor(
          DirectoryProfileKind.vehicle,
          'van',
        )).odometerRevision,
        1,
      );
      final resumed = await recovery.resume(selected) as ResumedVehicleDraft;
      expect(resumed.controller.recoveredInput!.odometer, '100.');
      await resumed.controller.session.close();
      await SqliteWorkdayRepository(await harness.open()).start(
        id: 'day',
        employeeId: 'driver',
        vehicleId: 'van',
        odometerTenths: 1100,
        expectedOdometerRevision: 1,
        at: DateTime.utc(2026, 9, 10),
        access: fleet.workdayAccess(),
      );
      expect(directory.vehicleRevision('van'), 1);
      expect(directory.vehicleOdometer('van')!.revision, 1);
      expect(
        (await directory.recoveryRevisionFor(
          DirectoryProfileKind.vehicle,
          'van',
        )).odometerRevision,
        2,
      );
      expect(
        (await recovery.list()).single.preview.availability,
        DraftRecoveryAvailability.conflict,
      );
      await expectLater(recovery.resume(selected), throwsStateError);
      final row = (await directory.drafts.find(
        organizationId: fleet.access.organizationId,
        ownerId: fleet.access.actorEmployeeId,
        domain: selected.domain,
        draftId: selected.draftId,
      ))!;
      expect(directory.drafts.decode(row)['odometer'], '100.');
    },
  );
}
