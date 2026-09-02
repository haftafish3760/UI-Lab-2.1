import 'estimate_models.dart';
import 'work_models.dart';

extension EstimateCompanyReviewActions on WorkRecord {
  WorkRecord submitForCompanyReview({
    required String submittedBy,
    required DateTime submittedOn,
  }) {
    assert(kind == WorkRecordKind.estimate);
    final event = EstimateCompanyReviewEvent(
      decision: EstimateCompanyReviewDecision.submitted,
      actor: submittedBy,
      occurredOn: submittedOn,
      revision: revision,
      note: 'Submitted revision $revision for company approval.',
    );
    return withEstimateStage(EstimateStage.readyToSend, submittedOn).copyWith(
      requiresCompanyReview: true,
      estimateCompanyReviewStatus: EstimateCompanyReviewStatus.pending,
      estimateCompanyReviewNote: event.note,
      estimateCompanyReviewHistory: [...estimateCompanyReviewHistory, event],
    );
  }

  WorkRecord recordCompanyReview({
    required EstimateCompanyReviewDecision decision,
    required String reviewedBy,
    required String note,
    required DateTime reviewedOn,
  }) {
    assert(kind == WorkRecordKind.estimate);
    assert(decision != EstimateCompanyReviewDecision.submitted);
    final status = switch (decision) {
      EstimateCompanyReviewDecision.approved =>
        EstimateCompanyReviewStatus.approved,
      EstimateCompanyReviewDecision.changesRequested =>
        EstimateCompanyReviewStatus.changesRequested,
      EstimateCompanyReviewDecision.rejected =>
        EstimateCompanyReviewStatus.rejected,
      EstimateCompanyReviewDecision.submitted => throw StateError(
        'Use submitForCompanyReview to submit an estimate.',
      ),
    };
    final stage = switch (status) {
      EstimateCompanyReviewStatus.approved => EstimateStage.readyToSend,
      EstimateCompanyReviewStatus.changesRequested => EstimateStage.draft,
      EstimateCompanyReviewStatus.rejected => EstimateStage.archived,
      _ => resolvedEstimateStage,
    };
    final event = EstimateCompanyReviewEvent(
      decision: decision,
      actor: reviewedBy,
      occurredOn: reviewedOn,
      revision: revision,
      note: note,
    );
    return withEstimateStage(stage, reviewedOn).copyWith(
      requiresCompanyReview: true,
      estimateCompanyReviewStatus: status,
      estimateCompanyReviewNote: note,
      estimateCompanyReviewHistory: [...estimateCompanyReviewHistory, event],
    );
  }
}
