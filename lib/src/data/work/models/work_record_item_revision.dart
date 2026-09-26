import 'estimate_models.dart';
import 'work_models.dart';

extension WorkRecordItemRevision on WorkRecord {
  WorkRecord reviseItems(
    List<WorkLineItem> revisedItems, {
    required DateTime changedOn,
  }) {
    if (_sameWorkItems(items, revisedItems)) return this;
    final revisedSubtotal = revisedItems.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );
    final signatureWasCurrent = hasCurrentCustomerSignature;
    final history = kind == WorkRecordKind.estimate
        ? [
            ...estimateRevisionHistory,
            EstimateRevisionRecord(
              revision: revision,
              changedOn: changedOn,
              total: total,
              description: hasCurrentCustomerApproval
                  ? 'Customer-approved revision replaced by updated items or pricing.'
                  : 'Items or pricing updated.',
              customerApproved: hasCurrentCustomerApproval,
            ),
          ]
        : estimateRevisionHistory;
    final reviewStatus =
        kind == WorkRecordKind.estimate && requiresCompanyReview
        ? EstimateCompanyReviewStatus.changesRequested
        : estimateCompanyReviewStatus;
    return WorkRecord(
      id: id,
      kind: kind,
      number: number,
      purchaseOrderNumber: purchaseOrderNumber,
      title: title,
      client: client,
      customerSnapshot: customerSnapshot,
      detail: detail,
      pricing: pricing,
      sourceId: sourceId,
      assignee: assignee,
      assignedEmployeeIds: assignedEmployeeIds,
      vehicle: vehicle,
      serviceLocation: serviceLocation,
      jobNotes: jobNotes,
      createdOn: createdOn,
      issuedOn: issuedOn,
      dueOn: dueOn,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      scheduleBufferMinutes: scheduleBufferMinutes,
      completedOn: completedOn,
      createdByEmployeeId: createdByEmployeeId,
      status: hasCurrentCustomerApproval && kind == WorkRecordKind.estimate
          ? WorkRecordStatus.ready
          : status,
      items: List.unmodifiable(revisedItems),
      template: template,
      terms: terms,
      paymentMethod: paymentMethod,
      discount: discount,
      tax: tax,
      total: (revisedSubtotal - discount + tax).clamp(0, double.infinity),
      revision: revision + 1,
      customerApprovals: customerApprovals,
      businessSignature: businessSignature,
      customerSignature: signatureWasCurrent
          ? customerSignature!.invalidate(
              changedOn,
              'Estimate items or pricing changed after customer approval.',
            )
          : customerSignature,
      estimateStage: kind == WorkRecordKind.estimate
          ? EstimateStage.readyToSend
          : estimateStage,
      estimateDates: kind == WorkRecordKind.estimate
          ? (estimateDates ?? _itemRevisionDates(changedOn)).copyWith(
              lastEditedOn: changedOn,
            )
          : estimateDates,
      estimateDeliveries: estimateDeliveries,
      estimateRevisionHistory: List.unmodifiable(history),
      requiresCompanyReview: requiresCompanyReview,
      estimateCompanyReviewStatus: reviewStatus,
      estimateCompanyReviewNote: requiresCompanyReview
          ? 'Estimate changed. Review the revision and submit it again.'
          : estimateCompanyReviewNote,
      estimateCompanyReviewHistory: estimateCompanyReviewHistory,
      sitePhotos: sitePhotos,
      linkedExpenseIds: linkedExpenseIds,
    );
  }
}

EstimateDates _itemRevisionDates(DateTime date) => EstimateDates(
  createdOn: date,
  lastEditedOn: date,
  expiresOn: date.add(const Duration(days: 30)),
);

bool _sameWorkItems(List<WorkLineItem> left, List<WorkLineItem> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.id != b.id ||
        a.type != b.type ||
        a.name != b.name ||
        a.description != b.description ||
        a.quantity != b.quantity ||
        a.workerCount != b.workerCount ||
        a.unit != b.unit ||
        a.customerPrice != b.customerPrice ||
        a.internalUnitCost != b.internalUnitCost ||
        a.sourceExpenseId != b.sourceExpenseId ||
        a.sourceExpenseLineId != b.sourceExpenseLineId ||
        a.sourceReceiptId != b.sourceReceiptId ||
        a.sourceStockId != b.sourceStockId ||
        a.isJobAddition != b.isJobAddition ||
        a.jobMaterialBillingTreatment != b.jobMaterialBillingTreatment) {
      return false;
    }
  }
  return true;
}
