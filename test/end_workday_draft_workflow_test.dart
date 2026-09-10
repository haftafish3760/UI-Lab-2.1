import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/workday/end_workday_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/workday/stored_workday_record.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'ending input and confirmation time survive rollback and reopen; retry is atomic',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openUiLabWorkdaySession(database);
      expect(
        (await work.start(
          id: 'workflow-day',
          employeeId: 'alex',
          vehicleId: 'transit-12',
          odometerTenths: 1000,
          expectedOdometerRevision: 0,
          at: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        )).committed,
        isTrue,
      );
      var workflow = await work.openEndDraft(
        workdayId: 'workflow-day',
        initialOdometer: '100.',
      );
      workflow.update('101.');
      final draftId = workflow.session.draftId;
      await database.customStatement(
        "CREATE TRIGGER reject_end BEFORE UPDATE ON local_records WHEN NEW.record_id = 'workflow-day' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect((await workflow.confirm()).committed, isFalse);
      final timestamp = workflow.input.confirmedAt;
      expect(timestamp!.isUtc, isTrue);
      expect(work.odometerFor('transit-12')!.readingTenths, 1000);
      expect(work.activeFor('alex'), isNotNull);
      await workflow.session.close();
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkdaySession(database);
      addTearDown(work.dispose);
      workflow = await work.openEndDraft(
        workdayId: 'workflow-day',
        initialOdometer: '100.0',
      );
      expect(workflow.session.draftId, draftId);
      expect(workflow.input.odometer, '101.');
      expect(workflow.input.confirmedAt, timestamp);
      final stale = await work.openEndDraft(
        workdayId: 'workflow-day',
        initialOdometer: '100.0',
      );
      await database.customStatement('DROP TRIGGER reject_end');
      expect((await workflow.confirm()).committed, isTrue);
      expect(work.activeFor('alex'), isNull);
      expect(work.records.single.record.status, StoredWorkdayStatus.ended);
      expect(work.odometerFor('transit-12')!.readingTenths, 1010);
      // Exact replay keeps the original command acknowledgement, with no
      // second state change or odometer revision.
      final revision = work.records.single.revision;
      final odometerRevision = work.odometerFor('transit-12')!.revision;
      expect((await stale.confirm()).committed, isTrue);
      expect(work.records.single.revision, revision);
      expect(work.odometerFor('transit-12')!.revision, odometerRevision);
      await expectLater(workflow.confirm(), throwsStateError);
      expect(
        await work.drafts.find(
          organizationId: work.access.organizationId,
          ownerId: work.access.actorEmployeeId,
          domain: 'workday/end',
          draftId: draftId,
        ),
        isNull,
      );
      await workflow.session.close();
      await stale.session.close();
    },
  );

  test(
    'invalid or decreasing odometers stay recoverable without ending the workday',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkdaySession(await harness.open());
      addTearDown(work.dispose);
      expect(
        (await work.start(
          id: 'validation-day',
          employeeId: 'alex',
          vehicleId: 'transit-12',
          odometerTenths: 1000,
          expectedOdometerRevision: 0,
          at: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        )).committed,
        isTrue,
      );
      final workflow = await work.openEndDraft(
        workdayId: 'validation-day',
        initialOdometer: '100.0',
      );
      for (final raw in ['12..', '99.', 'NaN']) {
        workflow.update(raw);
        await expectLater(
          workflow.confirm(),
          throwsA(isA<EndWorkdayInputValidation>()),
        );
        expect(workflow.input.odometer, raw);
        expect(work.activeFor('alex'), isNotNull);
        expect(work.odometerFor('transit-12')!.readingTenths, 1000);
      }
      workflow.update('101.');
      expect((await workflow.confirm()).committed, isTrue);
      await workflow.session.close();
      await expectLater(
        work.openEndDraft(workdayId: 'missing', initialOdometer: '0'),
        throwsStateError,
      );
    },
  );
}
