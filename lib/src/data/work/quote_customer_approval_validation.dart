part of 'work_persistence_session.dart';

extension _QuoteCustomerApprovalValidation on WorkPersistenceSession {
  void _validateQuoteCustomerApproval(WorkRecord next, WorkRecord? previous) {
    final stage = next.estimateStage ?? next.resolvedEstimateStage;
    if (previous?.resolvedEstimateStage == EstimateStage.converted &&
        (stage != EstimateStage.converted ||
            quoteApprovalFingerprint(next) !=
                quoteApprovalFingerprint(previous!))) {
      throw StateError(
        'This quote has already been used. Open its linked job or invoice.',
      );
    }
    if (!{
      EstimateStage.draft,
      EstimateStage.readyToSend,
      EstimateStage.approved,
      EstimateStage.converted,
    }.contains(stage)) {
      throw StateError('This quote action is not connected yet.');
    }
    if ((stage == EstimateStage.approved || stage == EstimateStage.converted) &&
        (previous == null ||
            !next.hasCurrentCustomerApproval ||
            !next.companyReviewAllowsCustomerApproval ||
            next.items.isEmpty ||
            next.client.trim().isEmpty ||
            next.client == 'Client not selected' ||
            next.detail.trim().isEmpty ||
            next.title.trim().isEmpty)) {
      throw StateError(
        'A saved, complete quote and customer approval are required.',
      );
    }
    final signature = next.customerSignature;
    final addedApproval =
        next.customerApprovals.length >
        (previous?.customerApprovals.length ?? 0);
    if (addedApproval &&
        (previous == null ||
            quoteApprovalFingerprint(next) !=
                quoteApprovalFingerprint(previous))) {
      throw StateError(
        'Save the quote changes before recording customer approval.',
      );
    }
    final newSignature =
        signature != null &&
        signature.isCurrentFor(next.revision) &&
        canonicalJson(encodeWorkCustomerSignature(signature)) !=
            canonicalJson(
              previous?.customerSignature == null
                  ? null
                  : encodeWorkCustomerSignature(previous!.customerSignature!),
            );
    if (newSignature &&
        (previous == null ||
            quoteApprovalFingerprint(next) !=
                quoteApprovalFingerprint(previous) ||
            signature.signedBy.trim().isEmpty ||
            signature.ink?.hasInk != true ||
            stage != EstimateStage.approved)) {
      throw StateError(
        'Review the saved quote and collect a signature for this exact revision.',
      );
    }
    final oldDeliveries =
        previous?.estimateDeliveries ?? const <EstimateDeliveryRecord>[];
    if (next.estimateDeliveries.length < oldDeliveries.length ||
        canonicalJson(
              next.estimateDeliveries
                  .take(oldDeliveries.length)
                  .map(encodeEstimateDeliveryRecord)
                  .toList(),
            ) !=
            canonicalJson(
              oldDeliveries.map(encodeEstimateDeliveryRecord).toList(),
            )) {
      throw StateError(
        'Quote approval evidence cannot be removed or rewritten.',
      );
    }
    final added = next.estimateDeliveries.skip(oldDeliveries.length).toList();
    final prepared =
        previous != null &&
        permissions.canShareDocuments &&
        (!(permissions.requiresQuoteApproval || next.requiresCompanyReview) ||
            quoteHasCurrentCompanyApproval(next)) &&
        next.companyReviewAllowsCustomerApproval &&
        next.items.isNotEmpty &&
        next.client.trim().isNotEmpty &&
        next.client != 'Client not selected' &&
        next.title.trim().isNotEmpty &&
        next.detail.trim().isNotEmpty &&
        stage != EstimateStage.draft &&
        quoteApprovalFingerprint(next) == quoteApprovalFingerprint(previous) &&
        added.length == 1 &&
        added.single.method != EstimateDeliveryMethod.inPerson &&
        added.single.revision == next.revision &&
        added.single.recipient.trim().isNotEmpty &&
        added.single.occurredOn.isUtc &&
        added.single.description ==
            'Revision ${next.revision} prepared for ${added.single.method.label}; delivery not confirmed.';
    if (added.isNotEmpty &&
        !prepared &&
        !(newSignature &&
            added.length == 1 &&
            added.single.method == EstimateDeliveryMethod.inPerson &&
            added.single.revision == next.revision &&
            added.single.recipient == signature.signedBy &&
            added.single.occurredOn == signature.signedOn)) {
      throw StateError(
        'Quote delivery must preserve the saved document and record preparation only.',
      );
    }
  }
}
