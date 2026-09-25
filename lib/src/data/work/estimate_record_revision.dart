import 'models/work_contact_models.dart';
import 'work_contact_codec.dart';
import 'models/estimate_models.dart';
import 'models/work_models.dart';

extension EstimateRecordEditing on WorkRecord {
  WorkRecord reviseEstimate({
    required String title,
    String? purchaseOrderNumber,
    required String client,
    WorkCustomerProfile? customerSnapshot,
    required String scope,
    required WorkPricingModel pricing,
    required List<WorkLineItem> items,
    List<WorkSitePhoto>? sitePhotos,
    required String template,
    required String terms,
    required double discount,
    required double tax,
    required EstimateDates dates,
    required DateTime changedOn,
  }) {
    assert(kind == WorkRecordKind.estimate);
    final customerVisibleChange =
        (purchaseOrderNumber != null &&
            purchaseOrderNumber != this.purchaseOrderNumber) ||
        title != this.title ||
        client != this.client ||
        (customerSnapshot != null &&
            encodeWorkCustomerProfile(customerSnapshot).toString() !=
                (this.customerSnapshot == null
                    ? ''
                    : encodeWorkCustomerProfile(
                        this.customerSnapshot!,
                      ).toString())) ||
        scope != detail ||
        pricing != this.pricing ||
        !_sameLineItems(items, this.items) ||
        template != this.template ||
        terms != this.terms ||
        discount != this.discount ||
        tax != this.tax ||
        !_sameDate(dates.expiresOn, estimateDates?.expiresOn) ||
        !_sameDate(dates.proposedServiceOn, estimateDates?.proposedServiceOn);
    final internalDateChange = !_sameDate(
      dates.followUpOn,
      estimateDates?.followUpOn,
    );
    final resolvedSitePhotos = sitePhotos ?? this.sitePhotos;
    final internalPhotoChange = !_sameSitePhotos(
      resolvedSitePhotos,
      this.sitePhotos,
    );
    if (!customerVisibleChange && !internalDateChange && !internalPhotoChange) {
      return this;
    }

    final nextRevision = customerVisibleChange ? revision + 1 : revision;
    final signatureWasCurrent =
        customerVisibleChange &&
        (customerSignature?.isCurrentFor(revision) ?? false);
    final requiresResend =
        customerVisibleChange && resolvedEstimateStage != EstimateStage.draft;
    final invalidatesCompanyReview =
        customerVisibleChange && requiresCompanyReview;
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    return WorkRecord(
      id: id,
      kind: kind,
      number: number,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      title: title,
      client: client,
      customerSnapshot:
          customerSnapshot ??
          (client == this.client ? this.customerSnapshot : null),
      detail: scope,
      pricing: pricing,
      sourceId: sourceId,
      assignee: assignee,
      vehicle: vehicle,
      serviceLocation: serviceLocation,
      jobNotes: jobNotes,
      issuedOn: issuedOn,
      dueOn: dueOn,
      completedOn: completedOn,
      linkedExpenseIds: linkedExpenseIds,
      createdOn: createdOn,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      createdByEmployeeId: createdByEmployeeId,
      status: requiresResend ? WorkRecordStatus.ready : status,
      items: List.unmodifiable(items),
      sitePhotos: List.unmodifiable(resolvedSitePhotos),
      template: template,
      terms: terms,
      paymentMethod: paymentMethod,
      discount: discount,
      tax: tax,
      total: (subtotal - discount + tax).clamp(0, double.infinity),
      revision: nextRevision,
      customerApprovals: customerApprovals,
      businessSignature: businessSignature,
      customerSignature: signatureWasCurrent
          ? customerSignature!.invalidate(
              changedOn,
              'Customer-visible estimate details changed after approval.',
            )
          : customerSignature,
      estimateStage: requiresResend ? EstimateStage.readyToSend : estimateStage,
      estimateDates: dates.copyWith(lastEditedOn: changedOn),
      estimateDeliveries: estimateDeliveries,
      estimateRevisionHistory: customerVisibleChange
          ? List.unmodifiable([
              ...estimateRevisionHistory,
              EstimateRevisionRecord(
                revision: revision,
                changedOn: changedOn,
                total: total,
                description: hasCurrentCustomerApproval
                    ? 'Customer-approved revision replaced by updated estimate details.'
                    : 'Customer-visible estimate details updated.',
                customerApproved: hasCurrentCustomerApproval,
              ),
            ])
          : estimateRevisionHistory,
      requiresCompanyReview: requiresCompanyReview,
      estimateCompanyReviewStatus: invalidatesCompanyReview
          ? EstimateCompanyReviewStatus.changesRequested
          : estimateCompanyReviewStatus,
      estimateCompanyReviewNote: invalidatesCompanyReview
          ? 'Estimate changed. Review the revision and submit it again.'
          : estimateCompanyReviewNote,
      estimateCompanyReviewHistory: estimateCompanyReviewHistory,
    );
  }
}

bool _sameLineItems(List<WorkLineItem> left, List<WorkLineItem> right) {
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
        a.jobMaterialBillingTreatment != b.jobMaterialBillingTreatment) {
      return false;
    }
  }
  return true;
}

bool _sameDate(DateTime? left, DateTime? right) {
  if (left == null || right == null) return left == right;
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _sameSitePhotos(List<WorkSitePhoto> left, List<WorkSitePhoto> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.id != b.id ||
        a.path != b.path ||
        a.name != b.name ||
        a.source != b.source ||
        a.addedOn != b.addedOn ||
        a.note != b.note) {
      return false;
    }
  }
  return true;
}
