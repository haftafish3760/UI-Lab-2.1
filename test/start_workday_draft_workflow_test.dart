import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/workday/start_workday_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'start recovery keeps raw reading, authority and timestamp through atomic retry',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openUiLabWorkdaySession(database);
      var workflow = await work.openStartDraft(
        employeeId: 'alex',
        vehicleId: 'transit-12',
        initialOdometer: '0.0',
      );
      workflow.update(
        employeeId: 'alex',
        vehicleId: 'transit-12',
        odometer: '12,345.',
        gpsAssistance: true,
      );
      final id = workflow.input.workdayId;
      final draftId = workflow.session.draftId;
      await database.customStatement(
        "CREATE TRIGGER reject_start BEFORE INSERT ON local_records WHEN NEW.domain = 'workday/records' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect((await workflow.confirm()).committed, isFalse);
      final firstAttempt = workflow.input.confirmedAt;
      expect(firstAttempt!.isUtc, isTrue);
      expect(work.activeFor('alex'), isNull);
      expect(work.odometerFor('transit-12')!.revision, 0);
      await workflow.session.close();
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkdaySession(database);
      addTearDown(work.dispose);
      // The saved workflow wins over a different initial presentation selection.
      workflow = await work.openStartDraft(
        employeeId: 'jordan',
        vehicleId: 'pickup-2',
        initialOdometer: '0.0',
      );
      expect(workflow.input.workdayId, id);
      expect(workflow.session.draftId, draftId);
      expect(workflow.input.employeeId, 'alex');
      expect(workflow.input.vehicleId, 'transit-12');
      expect(workflow.input.odometer, '12,345.');
      expect(workflow.input.confirmedAt, firstAttempt);
      await database.customStatement('DROP TRIGGER reject_start');
      expect((await workflow.confirm()).committed, isTrue);
      expect(work.records.single.record.id, id);
      expect(work.records.single.record.gpsAssistanceRequested, isTrue);
      expect(work.odometerFor('transit-12')!.readingTenths, 123450);
      expect(work.odometerFor('pickup-2')!.revision, 0);
      await expectLater(workflow.confirm(), throwsStateError);
      expect(
        await work.drafts.find(
          organizationId: work.access.organizationId,
          ownerId: work.access.actorEmployeeId,
          domain: 'workday/start',
          draftId: draftId,
        ),
        isNull,
      );
      await workflow.session.close();
    },
  );

  test(
    'unfinished employee selection and invalid odometer remain raw without starting',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkdaySession(await harness.open());
      addTearDown(work.dispose);
      var workflow = await work.openStartDraft(
        employeeId: null,
        vehicleId: 'transit-12',
        initialOdometer: '12..',
      );
      final id = workflow.input.workdayId;
      await expectLater(
        workflow.confirm(),
        throwsA(isA<StartWorkdayInputValidation>()),
      );
      await workflow.session.close();
      workflow = await work.openStartDraft(
        employeeId: 'alex',
        vehicleId: 'transit-12',
        initialOdometer: '0',
      );
      expect(workflow.input.employeeId, isNull);
      expect(workflow.input.workdayId, id);
      expect(workflow.input.odometer, '12..');
      workflow.update(
        employeeId: 'alex',
        vehicleId: 'transit-12',
        odometer: '12..',
        gpsAssistance: false,
      );
      await expectLater(
        workflow.confirm(),
        throwsA(isA<StartWorkdayInputValidation>()),
      );
      expect(work.records, isEmpty);
      workflow.update(
        employeeId: 'alex',
        vehicleId: 'transit-12',
        odometer: '12.',
        gpsAssistance: false,
      );
      expect((await workflow.confirm()).committed, isTrue);
      await workflow.session.close();
      await expectLater(
        work.openStartDraft(
          employeeId: 'unauthorized',
          vehicleId: 'transit-12',
          initialOdometer: '0',
        ),
        throwsStateError,
      );
    },
  );
}
