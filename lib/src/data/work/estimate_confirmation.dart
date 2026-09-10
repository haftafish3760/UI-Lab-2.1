import 'estimate_record_revision.dart';
import 'estimate_draft_controller.dart';
import 'models/work_models.dart';
import 'models/estimate_models.dart';

class EstimateInputValidation implements Exception {
  const EstimateInputValidation(this.message);
  final String message;
}

/// Existing estimate readiness and revision rules, shared by every presentation.
WorkRecord buildConfirmedEstimate(
  EstimateDraftInput input, {
  required DateTime now,
}) {
  if (input.pendingLineItems.isNotEmpty) {
    throw const EstimateInputValidation(
      'Review and save the unfinished estimate items first.',
    );
  }
  if (input.pendingPhotos != null) {
    throw const EstimateInputValidation(
      'Review and save the unfinished estimate photos and notes first.',
    );
  }
  double money(String value) {
    final amount = value.trim().isEmpty ? 0.0 : double.tryParse(value.trim());
    if (amount == null || !amount.isFinite || amount < 0) {
      throw const EstimateInputValidation(
        'Enter a valid non-negative discount and tax amount.',
      );
    }
    return amount;
  }

  final discount = money(input.discount);
  final tax = money(input.tax);
  final subtotal = input.items.fold(0.0, (sum, item) => sum + item.total);
  final total = (subtotal - discount + tax).clamp(0.0, double.infinity);
  final existing = input.baseRecord;
  final missingCustomerDetails =
      (input.client?.trim().isEmpty ?? true) ||
      input.title.trim().isEmpty ||
      input.scope.trim().isEmpty;
  if (existing != null &&
      existing.resolvedEstimateStage != EstimateStage.draft &&
      missingCustomerDetails) {
    throw const EstimateInputValidation(
      'Add the customer, estimate title, and proposed work before saving changes to a customer-ready estimate.',
    );
  }
  final client = input.client?.trim().isNotEmpty == true
      ? input.client!.trim()
      : 'Client not selected';
  final title = input.title.trim().isEmpty
      ? 'Untitled estimate'
      : input.title.trim();
  final scope = input.scope.trim().isEmpty
      ? 'Proposed work not entered yet.'
      : input.scope.trim();
  final dates = EstimateDates(
    createdOn: input.createdOn,
    lastEditedOn: now,
    sentOn: existing?.estimateDates?.sentOn,
    viewedOn: existing?.estimateDates?.viewedOn,
    followUpOn: input.followUpOn,
    expiresOn: input.expiresOn,
    proposedServiceOn: input.proposedServiceOn,
    decidedOn: existing?.estimateDates?.decidedOn,
    convertedOn: existing?.estimateDates?.convertedOn,
  );
  if (existing != null) {
    return existing.reviseEstimate(
      title: title,
      client: client,
      scope: scope,
      pricing: input.pricing,
      items: input.items,
      sitePhotos: input.sitePhotos,
      template: input.template,
      terms: input.terms.trim(),
      discount: discount,
      tax: tax,
      dates: dates,
      changedOn: now,
    );
  }
  return WorkRecord(
    id: input.estimateId,
    kind: WorkRecordKind.estimate,
    number: input.number,
    title: title,
    client: client,
    detail: scope,
    pricing: input.pricing,
    createdOn: input.createdOn,
    createdByEmployeeId: input.creatorId,
    status: WorkRecordStatus.draft,
    items: List.unmodifiable(input.items),
    template: input.template,
    terms: input.terms.trim(),
    discount: discount,
    tax: tax,
    total: total,
    estimateStage: EstimateStage.draft,
    estimateDates: dates,
    sitePhotos: List.unmodifiable(input.sitePhotos),
  );
}
