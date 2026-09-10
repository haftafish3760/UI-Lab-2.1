import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/job_notes_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';

import 'support/storage/database_harness.dart';

const job = WorkRecord(
  id: 'notes-workflow-job',
  kind: WorkRecordKind.job,
  number: 'JOB-NOTES',
  title: 'Service',
  client: 'Maya Thompson',
  detail: 'Repair',
  pricing: WorkPricingModel.flatRate,
  jobNotes: 'Confirmed note',
);

void main() {
  test(
    'notes survive failed commit and reopen; retry consumes exactly once',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      expect(await work.create(job), isTrue);
      var controller = await work.openJobNotesDraft(job.id);
      controller.updateNotes('  Check shutoff\nStill typing ');
      await db.customStatement(
        "CREATE TRIGGER fail_notes BEFORE UPDATE ON local_records WHEN NEW.record_id = 'notes-workflow-job' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await controller.confirm(), isNull);
      expect(work.storageRevisionFor(job.id), 1);
      expect(
        work.records.singleWhere((r) => r.id == job.id).jobNotes,
        job.jobNotes,
      );
      await controller.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      controller = await work.openJobNotesDraft(job.id);
      expect(controller.input.notes, '  Check shutoff\nStill typing ');
      expect(controller.input.baseRevision, 1);
      await db.customStatement('DROP TRIGGER fail_notes');
      expect(
        (await controller.confirm())!.jobNotes,
        'Check shutoff\nStill typing',
      );
      await expectLater(controller.confirm(), throwsStateError);
      expect(work.storageRevisionFor(job.id), 2);
      expect(
        await work.drafts.find(
          organizationId: work.permissions.organizationId,
          domain: controller.session.domain,
          draftId: controller.session.draftId,
          ownerId: work.permissions.actorEmployeeId,
        ),
        isNull,
      );
      await controller.session.close();
    },
  );

  test(
    'legacy notes retain stale revisions and reject mismatched recovery identities',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      expect(await work.create(job), isTrue);
      final actor = work.permissions.actorEmployeeId;
      final id = 'edit-$actor-${job.id}';
      final payload = {
        'base': encodeWorkRecord(job),
        'baseRevision': 1,
        'notes': ' unfinished ',
      };
      await work.drafts.save(
        organizationId: work.permissions.organizationId,
        domain: 'work/job-notes',
        draftId: id,
        ownerId: actor,
        expectedRevision: 0,
        payload: payload,
        occurredAt: DateTime.utc(2026, 9, 10),
      );
      expect(
        await work.update(job.copyWith(jobNotes: 'Concurrent change')),
        isTrue,
      );
      final controller = await work.openJobNotesDraft(job.id);
      expect(controller.input.toPayload(), payload);
      expect(await controller.confirm(), isNull);
      expect(
        work.records.singleWhere((r) => r.id == job.id).jobNotes,
        'Concurrent change',
      );
      expect(controller.input.notes, ' unfinished ');
      await controller.session.close();
      await work.drafts.save(
        organizationId: work.permissions.organizationId,
        domain: 'work/job-notes',
        draftId: id,
        ownerId: actor,
        expectedRevision: 1,
        payload: {
          ...payload,
          'base': {...encodeWorkRecord(job), 'id': 'another-job'},
        },
        occurredAt: DateTime.utc(2026, 9, 10),
      );
      await expectLater(work.openJobNotesDraft(job.id), throwsStateError);
      final retained = await work.drafts.find(
        organizationId: work.permissions.organizationId,
        domain: 'work/job-notes',
        draftId: id,
        ownerId: actor,
      );
      expect(retained, isNotNull);
      await expectLater(work.openJobNotesDraft('missing'), throwsStateError);
    },
  );
}
