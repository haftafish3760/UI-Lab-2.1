part of 'work_persistence_session.dart';

extension _WorkCustomerApprovalValidation on WorkPersistenceSession {
  void _validateCustomerApprovalChanges(
    WorkRecord record,
    WorkRecord? current,
  ) {
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
      if (approval.recordedByEmployeeId != permissions.actorEmployeeId ||
          approval.revision != record.revision ||
          approval.customerName.trim().isEmpty ||
          (approval.method == CustomerApprovalMethod.other &&
              approval.note.trim().isEmpty) ||
          !record.companyReviewAllowsCustomerApproval ||
          record.kind != WorkRecordKind.estimate ||
          record.items.isEmpty ||
          record.resolvedEstimateStage != EstimateStage.approved) {
        throw StateError(
          'Customer approval must identify the current user and estimate revision.',
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
