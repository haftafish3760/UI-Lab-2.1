part of 'work_persistence_session.dart';

extension _WorkCustomerApprovalValidation on WorkPersistenceSession {
  Future<void> _validateApprovalEvidence(
    WorkRecord next,
    WorkRecord? previous,
  ) async {
    final added = next.customerApprovals
        .skip(previous?.customerApprovals.length ?? 0)
        .toList();
    for (final item in next.items) {
      final approval = item.changeApproval;
      final old = previous?.items
          .where((value) => value.id == item.id)
          .firstOrNull
          ?.changeApproval;
      if (approval != null &&
          canonicalJson(approval.toJson()) != canonicalJson(old?.toJson())) {
        added.add(approval);
      }
    }
    for (final approval in added) {
      final ids = approval.evidence.map((item) => item.attachmentId).toSet();
      if (ids.length != approval.evidence.length) {
        throw StateError('The same approval attachment cannot be added twice.');
      }
      if (ids.isEmpty) continue;
      await LocalAttachmentStore(repository.database).verifiedFiles(
        organizationId: permissions.organizationId,
        ownerIds: {permissions.actorEmployeeId},
        attachmentIds: ids,
      );
    }
  }

  void _validateCustomerApprovalChanges(
    WorkRecord record,
    WorkRecord? current,
  ) {
    final signature = record.customerSignature;
    if (signature != null &&
        signature.isCurrentFor(record.revision) &&
        canonicalJson(encodeWorkCustomerSignature(signature)) !=
            canonicalJson(
              current?.customerSignature == null
                  ? null
                  : encodeWorkCustomerSignature(current!.customerSignature!),
            ) &&
        !permissions.canCollectSignature) {
      throw StateError(
        'You do not have permission to collect customer signatures.',
      );
    }
    final previousApprovals =
        current?.customerApprovals ?? const <WorkCustomerApproval>[];
    if (record.customerApprovals.length < previousApprovals.length ||
        canonicalJson(
              record.customerApprovals
                  .take(previousApprovals.length)
                  .map((approval) => approval.toJson())
                  .toList(),
            ) !=
            canonicalJson(
              previousApprovals.map((approval) => approval.toJson()).toList(),
            )) {
      throw StateError(
        'Recorded customer approval history cannot be removed or rewritten.',
      );
    }
    for (final approval in record.customerApprovals.skip(
      previousApprovals.length,
    )) {
      if (!permissions.canRecordCustomerApproval) {
        throw StateError(
          'You do not have permission to record customer approval.',
        );
      }
      if (approval.recordedByEmployeeId != permissions.actorEmployeeId ||
          approval.revision != record.revision ||
          approval.customerName.trim().isEmpty ||
          (approval.method == CustomerApprovalMethod.other &&
              approval.note.trim().isEmpty) ||
          !record.companyReviewAllowsCustomerApproval ||
          !record.isProposal ||
          record.items.isEmpty ||
          record.resolvedEstimateStage != EstimateStage.approved) {
        throw StateError(
          'Customer approval must identify the current user and document revision.',
        );
      }
    }

    if (record.kind == WorkRecordKind.job) {
      for (final item in record.items.where(
        (item) =>
            item.isJobAddition &&
            item.resolvedJobMaterialBillingTreatment ==
                JobMaterialBillingTreatment.invoiceCandidate,
      )) {
        final previous = current?.items
            .where((entry) => entry.id == item.id)
            .firstOrNull;
        final unchanged =
            previous != null &&
            canonicalJson(encodeWorkLineItem(previous)) ==
                canonicalJson(encodeWorkLineItem(item));
        if (!unchanged && !permissions.canRecordCustomerApproval) {
          throw StateError(
            'You do not have permission to record approval for additional work.',
          );
        }
        if (!unchanged &&
            (item.changeApproval == null ||
                item.changeApproval!.recordedByEmployeeId !=
                    permissions.actorEmployeeId ||
                item.changeApproval!.revision != record.revision ||
                item.changeApproval!.customerName.trim().isEmpty ||
                (item.changeApproval!.method == CustomerApprovalMethod.other &&
                    item.changeApproval!.note.trim().isEmpty))) {
          throw StateError(
            'Billable job additions require documented customer approval for these changes.',
          );
        }
      }
    }
  }
}
