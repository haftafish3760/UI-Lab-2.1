import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/company_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/employee_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/vehicle_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_contact_codec.dart';

import 'support/storage/database_harness.dart';

Map<String, Object?> legacyInput(String kind) => switch (kind) {
  'company' => {
    'baseProfile': encodeWorkCompanyProfile(emptyCompanyProfile),
    'baseRevision': 2,
    'logoLabel': 'Pending logo',
    'name': 'Partial company',
    'category': '',
    'phone': '+1 (555',
    'email': 'pending@',
    'website': 'https://',
    'address': '',
    'terms': 'Partial terms',
  },
  'employee' => {
    'employeeId': 'employee-1',
    'baseRevision': 2,
    'role': 'Technician',
    'active': true,
    'canSeeEstimates': true,
    'canCreateEstimates': false,
    'canApproveEstimates': false,
    'canRecordExpenses': true,
    'canViewCompanyReports': false,
    'name': 'Partial employee',
    'phone': '+1 (555',
    'emergency': '',
    'pay': '12.',
  },
  'vehicle' => {
    'vehicleId': 'vehicle-1',
    'baseRevision': 2,
    'odometerRevision': 4,
    'active': true,
    'name': 'Partial vehicle',
    'model': '2020',
    'odometer': '12345.',
    'assignment': 'Unassigned',
  },
  _ => throw ArgumentError.value(kind),
};

void main() {
  for (final kind in ['company', 'employee', 'vehicle']) {
    test(
      '$kind draft restores without widgets and retains version-one bytes',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        var database = await harness.open();
        var repository = LocalDraftStore(database);
        final input = legacyInput(kind);
        final domain = 'directory/$kind-editor';
        await repository.save(
          organizationId: 'business',
          domain: domain,
          draftId: 'saved-input',
          ownerId: 'owner',
          expectedRevision: 0,
          payload: input,
          occurredAt: DateTime.utc(2026, 9, 9),
        );
        final before = await repository.find(
          organizationId: 'business',
          domain: domain,
          draftId: 'saved-input',
          ownerId: 'owner',
        );
        await harness.close(database);
        database = await harness.open();
        repository = LocalDraftStore(database);
        final session = DraftAutosaveSession(
          store: repository,
          organizationId: 'business',
          domain: domain,
          draftId: 'saved-input',
          ownerId: 'owner',
        );
        await session.initialize();
        switch (kind) {
          case 'company':
            final controller = CompanyDraftController(session);
            final restored = controller.recoveredInput!;
            expect(restored.email, 'pending@');
            expect(restored.toPayload(), input);
            controller.updateInput(restored);
          case 'employee':
            final controller = EmployeeDraftController(
              session,
              expectedRecordId: 'employee-1',
            );
            final restored = controller.recoveredInput!;
            expect(restored.pay, '12.');
            expect(restored.toPayload(), input);
            controller.updateInput(restored);
            expect(
              () => EmployeeDraftController(
                session,
                expectedRecordId: 'other',
              ).recoveredInput,
              throwsFormatException,
            );
          case 'vehicle':
            final controller = VehicleDraftController(
              session,
              expectedRecordId: 'vehicle-1',
            );
            final restored = controller.recoveredInput!;
            expect(restored.odometer, '12345.');
            expect(restored.odometerRevision, 4);
            expect(restored.toPayload(), input);
            controller.updateInput(restored);
            expect(
              () => VehicleDraftController(
                session,
                expectedRecordId: 'other',
              ).recoveredInput,
              throwsFormatException,
            );
        }
        await session.close();
        final after = await repository.find(
          organizationId: 'business',
          domain: domain,
          draftId: 'saved-input',
          ownerId: 'owner',
        );
        expect(after!.payload, before!.payload);
        expect(after.payloadVersion, before.payloadVersion);
        expect(after.revision, before.revision);
        expect(await database.select(database.localRecords).get(), isEmpty);
      },
    );
  }

  for (final (kind, field, value) in [
    ('employee', 'employeeId', ''),
    ('employee', 'baseRevision', -1),
    ('employee', 'role', 'Unsupported'),
    ('vehicle', 'vehicleId', ''),
    ('vehicle', 'baseRevision', -1),
    ('vehicle', 'odometerRevision', -1),
  ]) {
    test('$kind rejects malformed $field without deleting the draft', () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final database = await harness.open();
      final repository = LocalDraftStore(database);
      final domain = 'directory/$kind-editor';
      await repository.save(
        organizationId: 'business',
        domain: domain,
        draftId: 'malformed',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: {...legacyInput(kind), field: value},
        occurredAt: DateTime.utc(2026),
      );
      final session = DraftAutosaveSession(
        store: repository,
        organizationId: 'business',
        domain: domain,
        draftId: 'malformed',
        ownerId: 'owner',
      );
      await session.initialize();
      final before = session.input;
      expect(
        () => kind == 'employee'
            ? EmployeeDraftController(session).recoveredInput
            : VehicleDraftController(session).recoveredInput,
        throwsFormatException,
      );
      await session.close();
      final stored = await repository.find(
        organizationId: 'business',
        domain: domain,
        draftId: 'malformed',
        ownerId: 'owner',
      );
      expect(repository.decode(stored!), before);
      expect(stored.revision, 1);
    });
  }
}
