import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/job_assignment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';

import 'support/storage/database_harness.dart';

const job = WorkRecord(
  id: 'assignment-workflow-job',
  kind: WorkRecordKind.job,
  number: 'JOB-ASSIGN',
  title: 'Service',
  client: 'Maya Thompson',
  detail: 'Repair',
  pricing: WorkPricingModel.flatRate,
  assignee: 'Alex Morgan',
  vehicle: 'Transit 12',
);

void main() {
  test(
    'assignment pair survives rollback and reopen before atomic confirmation',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      expect(await work.create(job), isTrue);
      var controller = await work.openJobAssignmentDraft(job.id);
      controller.updateAssignment(
        assignee: 'Jordan Lee',
        vehicle: 'Service Van 4',
      );
      await db.customStatement(
        "CREATE TRIGGER fail_assignment BEFORE UPDATE ON local_records WHEN NEW.record_id = 'assignment-workflow-job' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await controller.confirm(), isNull);
      final unchanged = work.records.singleWhere((r) => r.id == job.id);
      expect(unchanged.assignee, job.assignee);
      expect(unchanged.vehicle, job.vehicle);
      expect(work.storageRevisionFor(job.id), 1);
      await controller.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      controller = await work.openJobAssignmentDraft(job.id);
      expect(controller.input.assignee, 'Jordan Lee');
      expect(controller.input.vehicle, 'Service Van 4');
      expect(controller.input.baseRevision, 1);
      await db.customStatement('DROP TRIGGER fail_assignment');
      final saved = (await controller.confirm())!;
      expect(saved.assignee, 'Jordan Lee');
      expect(saved.vehicle, 'Service Van 4');
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
    'legacy assignment preserves selections and stale revision; wrong parent is retained',
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
        'assignee': 'Unassigned',
        'vehicle': 'No vehicle assigned',
      };
      await work.drafts.save(
        organizationId: work.permissions.organizationId,
        domain: 'work/job-assignment',
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
      final controller = await work.openJobAssignmentDraft(job.id);
      expect(controller.input.toPayload(), payload);
      expect(await controller.confirm(), isNull);
      final latest = work.records.singleWhere((r) => r.id == job.id);
      expect(latest.jobNotes, 'Concurrent change');
      expect(latest.assignee, 'Alex Morgan');
      await controller.session.close();
      await work.drafts.save(
        organizationId: work.permissions.organizationId,
        domain: 'work/job-assignment',
        draftId: id,
        ownerId: actor,
        expectedRevision: 1,
        payload: {
          ...payload,
          'base': {...encodeWorkRecord(job), 'id': 'another-job'},
        },
        occurredAt: DateTime.utc(2026, 9, 10),
      );
      await expectLater(work.openJobAssignmentDraft(job.id), throwsStateError);
      expect(
        await work.drafts.find(
          organizationId: work.permissions.organizationId,
          domain: 'work/job-assignment',
          draftId: id,
          ownerId: actor,
        ),
        isNotNull,
      );
      await expectLater(
        work.openJobAssignmentDraft('missing'),
        throwsStateError,
      );
    },
  );
}
