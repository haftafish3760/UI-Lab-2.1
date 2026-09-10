import 'package:ui_lab_2_1/src/data/work/work_items_draft_input.dart';
import 'work_draft_controller_compatibility_test.dart'
    show legacyItemsWorkspace;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/job_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/job_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/job_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';

import 'support/storage/database_harness.dart';

JobDraftInput inputFor(
  WorkRecord? source,
  int revision, {
  bool pending = false,
}) => JobDraftInput(
  jobId: 'workflow-job',
  number: 'JOB-WORKFLOW',
  sourceEstimate: source,
  sourceStorageRevision: revision,
  scheduledStart: DateTime(2026, 9, 9, 23, 30),
  scheduledEnd: DateTime(2026, 9, 10, 1, 30),
  client: 'Customer',
  location: 'Site',
  assignee: null,
  vehicle: null,
  pricing: source?.pricing ?? WorkPricingModel.timeAndMaterials,
  items: source?.items ?? const [],
  pendingLineItem: pending
      ? WorkItemsDraftInput.fromPayload(legacyItemsWorkspace())
      : null,
  title: ' Overnight job ',
  scope: ' Scope ',
  notes: ' Notes ',
);

void main() {
  test('job discovery and opening both enforce creator visibility', () async {
    final harness = await DatabaseHarness.create();
    addTearDown(harness.dispose);
    final owner = await openUiLabWorkSession(await harness.open());
    addTearDown(owner.dispose);
    final denied = await WorkPersistenceSession.open(
      owner.repository,
      WorkSessionPermissions(
        organizationId: owner.permissions.organizationId,
        actorEmployeeId: owner.permissions.actorEmployeeId,
        permissionRevision: 'test-denied-visibility',
        visibleCreatorIds: {},
        editableKinds: {WorkRecordKind.job},
      ),
    );
    addTearDown(denied.dispose);
    expect(() => denied.jobDraftRecovery, throwsStateError);
    await expectLater(denied.openJobDraft(), throwsStateError);
  });

  for (final linked in [false, true]) {
    test(
      '${linked ? 'linked' : 'standalone'} job confirms after recovery and failed-write retry',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        var database = await harness.open();
        var work = await openUiLabWorkSession(database);
        WorkRecord? source;
        var sourceRevision = 0;
        if (linked) {
          source = WorkRecord(
            id: 'approved-source',
            kind: WorkRecordKind.estimate,
            number: 'EST-TEST',
            title: 'Repair',
            client: 'Customer',
            detail: 'Scope',
            pricing: WorkPricingModel.flatRate,
            total: 50,
            estimateStage: EstimateStage.approved,
            customerSignature: WorkCustomerSignature(
              signedBy: 'Customer',
              signedOn: DateTime(2026, 9, 9),
              signedRevision: 1,
            ),
          );
          expect(await work.create(source), isTrue);
          sourceRevision = work.storageRevisionFor(source.id);
        }
        var controller = await work.openJobDraft(sourceEstimateId: source?.id);
        final draftId = controller.session.draftId;
        controller.updateInput(inputFor(source, sourceRevision, pending: true));
        await expectLater(
          controller.confirm(),
          throwsA(isA<JobInputValidation>()),
        );
        expect(
          controller.recoveredInput!.pendingLineItem!.pendingItem!.quantity,
          '1.',
        );
        await controller.session.close();
        work.dispose();
        await harness.close(database);
        database = await harness.open();
        work = await openUiLabWorkSession(database);
        addTearDown(work.dispose);
        controller = await work.openJobDraft(
          sourceEstimateId: source?.id,
          recoveryDraftId: linked ? null : draftId,
        );
        expect(controller.session.draftId, draftId);
        expect(controller.recoveredInput!.scheduledStart.hour, 23);
        expect(controller.recoveredInput!.scheduledEnd.day, 10);
        controller.updateInput(inputFor(source, sourceRevision));
        await database.customStatement(
          "CREATE TRIGGER reject_job BEFORE INSERT ON local_records WHEN NEW.record_id = 'workflow-job' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
        );
        expect(await controller.confirm(), isNull);
        expect(work.records.where((r) => r.id == 'workflow-job'), isEmpty);
        expect(controller.recoveredInput!.notes, ' Notes ');
        if (linked) {
          expect(
            work.records
                .singleWhere((r) => r.id == source!.id)
                .resolvedEstimateStage,
            EstimateStage.approved,
          );
        }
        await database.customStatement('DROP TRIGGER reject_job');
        final job = await controller.confirm();
        expect(job!.title, 'Overnight job');
        expect(job.jobNotes, 'Notes');
        expect(job.createdByEmployeeId, work.permissions.actorEmployeeId);
        expect(job.total, linked ? 50 : 0);
        expect(job.scheduledEnd!.isAfter(job.scheduledStart!), isTrue);
        await expectLater(controller.confirm(), throwsStateError);
        expect(work.records.where((r) => r.id == 'workflow-job'), hasLength(1));
        if (linked) {
          expect(
            work.records
                .singleWhere((r) => r.id == source!.id)
                .resolvedEstimateStage,
            EstimateStage.converted,
          );
        }
        expect(
          await work.drafts.find(
            organizationId: work.permissions.organizationId,
            ownerId: work.permissions.actorEmployeeId,
            domain: 'work/job-editor',
            draftId: draftId,
          ),
          isNull,
        );
        await controller.session.close();
      },
    );
  }

  test(
    'missing selected recovery does not silently create blank input',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      await expectLater(
        work.openJobDraft(recoveryDraftId: 'missing'),
        throwsStateError,
      );
      await expectLater(
        work.openJobDraft(sourceEstimateId: 'missing'),
        throwsStateError,
      );
    },
  );
}
