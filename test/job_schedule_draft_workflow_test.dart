import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/job_schedule_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';

import 'support/storage/database_harness.dart';

WorkRecord job() => WorkRecord(
  id: 'schedule-workflow',
  kind: WorkRecordKind.job,
  number: 'JOB-SCHEDULE',
  title: 'Service',
  client: 'Customer',
  detail: 'Repair',
  pricing: WorkPricingModel.flatRate,
  status: WorkRecordStatus.needsReturnVisit,
  scheduledStart: DateTime(2026, 9, 9, 9),
  scheduledEnd: DateTime(2026, 9, 9, 10, 30),
);

void main() {
  test(
    'partial schedule survives reopen and failed save; confirmation preserves duration and updates status once',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      final record = job();
      expect(await work.create(record), isTrue);
      var workflow = await work.openJobScheduleDraft(record.id);
      workflow.update(
        day: DateTime(2026, 9, 10),
        hour: '1x',
        minute: '0',
        period: 'AM',
      );
      await expectLater(workflow.confirm(), throwsStateError);
      final raw = workflow.session.input;
      expect(work.storageRevisionFor(record.id), 1);
      await workflow.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      workflow = await work.openJobScheduleDraft(record.id);
      expect(workflow.session.input, raw);
      workflow.update(
        day: workflow.input.day,
        hour: '12',
        minute: '03',
        period: 'AM',
      );
      await db.customStatement(
        "CREATE TRIGGER reject_schedule BEFORE UPDATE ON local_records WHEN NEW.record_id = 'schedule-workflow' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isNull);
      final unchanged = work.records.singleWhere((r) => r.id == record.id);
      expect(unchanged.scheduledStart, record.scheduledStart);
      expect(unchanged.status, WorkRecordStatus.needsReturnVisit);
      expect(workflow.input.minute, '03');
      await db.customStatement('DROP TRIGGER reject_schedule');
      final saved = (await workflow.confirm())!;
      expect(saved.scheduledStart, DateTime(2026, 9, 10, 0, 3));
      expect(saved.scheduledEnd, DateTime(2026, 9, 10, 1, 33));
      expect(saved.status, WorkRecordStatus.scheduled);
      expect(work.storageRevisionFor(record.id), 2);
      await expectLater(workflow.confirm(), throwsStateError);
      expect(
        await work.drafts.find(
          organizationId: work.permissions.organizationId,
          domain: workflow.session.domain,
          draftId: workflow.session.draftId,
          ownerId: work.permissions.actorEmployeeId,
        ),
        isNull,
      );
      await workflow.session.close();
    },
  );

  test(
    'stale rescheduling does not overwrite concurrent job changes or consume its raw input',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final record = job();
      expect(await work.create(record), isTrue);
      final workflow = await work.openJobScheduleDraft(record.id);
      workflow.update(
        day: DateTime(2026, 9, 11),
        hour: '12',
        minute: '30',
        period: 'PM',
      );
      await workflow.session.flush();
      final raw = workflow.session.input;
      expect(
        await work.update(record.copyWith(jobNotes: 'Concurrent notes')),
        isTrue,
      );
      expect(await workflow.confirm(), isNull);
      expect(workflow.session.input, raw);
      expect(workflow.input.baseRevision, 1);
      final latest = work.records.singleWhere((r) => r.id == record.id);
      expect(latest.jobNotes, 'Concurrent notes');
      expect(latest.scheduledStart, record.scheduledStart);
      expect(
        workflow.input.confirmedRecord().scheduledStart,
        DateTime(2026, 9, 11, 12, 30),
      );
      await workflow.session.close();
    },
  );

  test(
    'schedule confirmation rejects invalid time ranges and missing duration outside widgets',
    () {
      for (final time in [
        ('0', '00', 'AM'),
        ('13', '00', 'PM'),
        ('1', '60', 'AM'),
        ('1', '-1', 'AM'),
        ('1', '00', 'unknown'),
      ]) {
        final input = JobScheduleInput(
          base: job(),
          baseRevision: 1,
          day: DateTime(2026, 9, 10),
          hour: time.$1,
          minute: time.$2,
          period: time.$3,
        );
        expect(input.confirmedRecord, throwsStateError);
      }
      const unscheduled = WorkRecord(
        id: 'unscheduled',
        kind: WorkRecordKind.job,
        number: 'JOB',
        title: 'Service',
        client: 'Customer',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
      );
      expect(
        JobScheduleInput(
          base: unscheduled,
          baseRevision: 1,
          day: DateTime(2026, 9, 10),
          hour: '1',
          minute: '00',
          period: 'PM',
        ).confirmedRecord,
        throwsStateError,
      );
    },
  );
}
