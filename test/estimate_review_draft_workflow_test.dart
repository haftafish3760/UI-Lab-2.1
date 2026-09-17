import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_review_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'support/storage/database_harness.dart';

void main() {
  for (final decision in [
    EstimateCompanyReviewDecision.changesRequested,
    EstimateCompanyReviewDecision.rejected,
  ]) {
    test(
      '${decision.name} preserves raw reason and first attempt through rollback and reopen',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        var db = await harness.open();
        var work = await openSeededTestWorkSession(db);
        final pending = work.records
            .singleWhere((r) => r.id == 'est-1040')
            .submitForCompanyReview(
              submittedBy: 'alex',
              submittedOn: DateTime.utc(2026, 9, 10),
            );
        expect(await work.update(pending), isTrue);
        final revision = work.storageRevisionFor(pending.id);
        var workflow = await work.openEstimateReviewDraft(
          pending,
          decision: decision,
          reviewPermissions: const EstimatePermissions.development(),
        );
        await expectLater(workflow.confirm(), throwsStateError);
        const reason = '  Clarify access\nand labor.  ';
        workflow.updateReason(reason);
        await db.customStatement(
          "CREATE TRIGGER fail_review BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/estimate-review' BEGIN SELECT RAISE(ABORT, 'failure'); END",
        );
        expect(await workflow.confirm(), isNull);
        final raw = workflow.session.input;
        final at = workflow.input.confirmedAt!;
        expect(work.storageRevisionFor(pending.id), revision);
        expect(
          work.records
              .singleWhere((r) => r.id == pending.id)
              .estimateCompanyReviewStatus,
          EstimateCompanyReviewStatus.pending,
        );
        await workflow.session.close();
        work.dispose();
        await harness.close(db);
        db = await harness.open();
        work = await openSeededTestWorkSession(db);
        addTearDown(work.dispose);
        workflow = await work.openEstimateReviewDraft(
          work.records.singleWhere((r) => r.id == pending.id),
          decision: decision,
          reviewPermissions: const EstimatePermissions.development(),
        );
        expect(workflow.session.input, raw);
        await db.customStatement('DROP TRIGGER fail_review');
        final saved = (await workflow.confirm())!;
        expect(saved.estimateCompanyReviewNote, reason);
        expect(
          saved.estimateCompanyReviewHistory.length,
          pending.estimateCompanyReviewHistory.length + 1,
        );
        expect(saved.estimateCompanyReviewHistory.last.occurredOn, at);
        expect(
          saved.estimateCompanyReviewHistory.last.actor,
          work.permissions.actorEmployeeId,
        );
        expect(
          saved.resolvedEstimateStage,
          decision == EstimateCompanyReviewDecision.rejected
              ? EstimateStage.archived
              : EstimateStage.draft,
        );
        expect(work.storageRevisionFor(pending.id), revision + 1);
        await expectLater(workflow.confirm(), throwsStateError);
        await workflow.session.close();
      },
    );
  }
  test(
    'review gate and stale revision are enforced outside the dialog',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openSeededTestWorkSession(await harness.open());
      addTearDown(work.dispose);
      final pending = work.records
          .singleWhere((r) => r.id == 'est-1040')
          .submitForCompanyReview(
            submittedBy: 'alex',
            submittedOn: DateTime.utc(2026, 9, 10),
          );
      expect(await work.update(pending), isTrue);
      await expectLater(
        work.openEstimateReviewDraft(
          pending,
          decision: EstimateCompanyReviewDecision.rejected,
          reviewPermissions: const EstimatePermissions.technicianDevelopment(),
        ),
        throwsStateError,
      );
      await expectLater(
        work.openEstimateReviewDraft(
          pending,
          decision: EstimateCompanyReviewDecision.approved,
          reviewPermissions: const EstimatePermissions.development(),
        ),
        throwsStateError,
      );
      final workflow = await work.openEstimateReviewDraft(
        pending,
        decision: EstimateCompanyReviewDecision.rejected,
        reviewPermissions: const EstimatePermissions.development(),
      );
      workflow.updateReason('Original reason');
      expect(
        await work.update(pending.copyWith(jobNotes: 'Concurrent edit')),
        isTrue,
      );
      expect(await workflow.confirm(), isNull);
      expect(workflow.input.reason, 'Original reason');
      expect(workflow.input.confirmedAt, isNotNull);
      workflow.updateReason('Revised reason');
      expect(workflow.input.confirmedAt, isNull);
      expect(
        work.records.singleWhere((r) => r.id == pending.id).jobNotes,
        'Concurrent edit',
      );
      await workflow.session.close();
      await expectLater(
        work.openEstimateReviewDraft(
          pending,
          decision: EstimateCompanyReviewDecision.rejected,
          reviewPermissions: const EstimatePermissions.development(),
        ),
        throwsStateError,
      );
    },
  );
}
