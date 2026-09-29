part of 'work_persistence_session.dart';

extension _QuoteApprovalValidation on WorkPersistenceSession {
  void _validateQuoteApproval(WorkRecord next, WorkRecord? previous) {
    if (next.kind != WorkRecordKind.quote) return;
    final expectedTotal =
        (next.items.fold<double>(0, (sum, item) => sum + item.total) -
                next.discount +
                next.tax)
            .clamp(0, double.infinity);
    if (!expectedTotal.isFinite ||
        !next.discount.isFinite ||
        !next.tax.isFinite ||
        next.discount < 0 ||
        next.tax < 0 ||
        (expectedTotal * 100).round() != (next.total * 100).round()) {
      throw StateError('The quote total must match its saved work and prices.');
    }
    if ((permissions.requiresQuoteApproval ||
            previous?.requiresCompanyReview == true) &&
        !next.requiresCompanyReview) {
      throw StateError('Required quote approval cannot be bypassed.');
    }
    final before =
        previous?.estimateCompanyReviewHistory ??
        const <EstimateCompanyReviewEvent>[];
    final after = next.estimateCompanyReviewHistory;
    if (after.length < before.length ||
        after.length > before.length + 1 ||
        canonicalJson(before.map(encodeEstimateCompanyReviewEvent).toList()) !=
            canonicalJson(
              after
                  .take(before.length)
                  .map(encodeEstimateCompanyReviewEvent)
                  .toList(),
            )) {
      throw StateError(
        'Quote approval history cannot be removed or rewritten.',
      );
    }
    final changed =
        previous != null &&
        quoteApprovalFingerprint(previous) != quoteApprovalFingerprint(next);
    if (changed && next.revision != previous.revision + 1) {
      throw StateError('Changed quote contents require a new revision.');
    }
    if (after.length == before.length) {
      final status = next.estimateCompanyReviewStatus;
      if (previous == null) {
        if (status !=
            (next.requiresCompanyReview
                ? EstimateCompanyReviewStatus.pending
                : EstimateCompanyReviewStatus.notRequired)) {
          throw StateError('A new quote cannot already have approval.');
        }
      } else if (status != previous.estimateCompanyReviewStatus &&
          !(changed &&
              next.requiresCompanyReview &&
              status == EstimateCompanyReviewStatus.changesRequested)) {
        throw StateError('Use the quote approval action to record a decision.');
      }
      if (status == EstimateCompanyReviewStatus.approved &&
          !quoteHasCurrentCompanyApproval(next)) {
        throw StateError('This quote revision needs fresh approval.');
      }
      return;
    }
    final event = after.last;
    if (previous == null ||
        changed ||
        !next.requiresCompanyReview ||
        event.actor != permissions.actorEmployeeId ||
        event.revision != next.revision ||
        event.contentFingerprint != quoteApprovalFingerprint(next) ||
        event.occurredOn.isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 1)),
        ) ||
        (before.isNotEmpty &&
            event.occurredOn.isBefore(before.last.occurredOn)) ||
        previous.resolvedEstimateStage != EstimateStage.readyToSend ||
        next.resolvedEstimateStage != EstimateStage.readyToSend ||
        previous.items.isEmpty ||
        previous.title.trim().isEmpty ||
        previous.client.trim().isEmpty ||
        previous.detail.trim().isEmpty) {
      throw StateError(
        'Submit or approve the current saved quote without changing its contents.',
      );
    }
    final submitted = before.lastOrNull;
    if (event.decision != EstimateCompanyReviewDecision.submitted &&
        (!permissions.canApproveQuotes ||
            submitted?.decision != EstimateCompanyReviewDecision.submitted ||
            submitted?.contentFingerprint != event.contentFingerprint)) {
      throw StateError(
        'Only an authorized supervisor or admin can decide a submitted quote.',
      );
    }
    final requiredStatus = switch (event.decision) {
      EstimateCompanyReviewDecision.submitted =>
        EstimateCompanyReviewStatus.pending,
      EstimateCompanyReviewDecision.approved =>
        EstimateCompanyReviewStatus.approved,
      EstimateCompanyReviewDecision.changesRequested =>
        EstimateCompanyReviewStatus.changesRequested,
      EstimateCompanyReviewDecision.rejected =>
        EstimateCompanyReviewStatus.rejected,
    };
    if (next.estimateCompanyReviewStatus != requiredStatus ||
        next.estimateCompanyReviewNote != event.note ||
        ((event.decision == EstimateCompanyReviewDecision.changesRequested ||
                event.decision == EstimateCompanyReviewDecision.rejected) &&
            event.note.trim().isEmpty)) {
      throw StateError(
        'Record the decision and explain any requested changes or rejection.',
      );
    }
  }
}

extension QuoteApprovalCommands on WorkPersistenceSession {
  Future<bool> recordQuoteApproval(
    WorkRecord record,
    EstimateCompanyReviewDecision decision, {
    String note = '',
  }) {
    final status = switch (decision) {
      EstimateCompanyReviewDecision.submitted =>
        EstimateCompanyReviewStatus.pending,
      EstimateCompanyReviewDecision.approved =>
        EstimateCompanyReviewStatus.approved,
      EstimateCompanyReviewDecision.changesRequested =>
        EstimateCompanyReviewStatus.changesRequested,
      EstimateCompanyReviewDecision.rejected =>
        EstimateCompanyReviewStatus.rejected,
    };
    return save(
      records: [
        record.copyWith(
          requiresCompanyReview: true,
          estimateCompanyReviewStatus: status,
          estimateCompanyReviewNote: note.trim(),
          estimateCompanyReviewHistory: [
            ...record.estimateCompanyReviewHistory,
            EstimateCompanyReviewEvent(
              decision: decision,
              actor: permissions.actorEmployeeId,
              occurredOn: DateTime.now().toUtc(),
              revision: record.revision,
              note: note.trim(),
              contentFingerprint: quoteApprovalFingerprint(record),
            ),
          ],
        ),
      ],
    );
  }
}
