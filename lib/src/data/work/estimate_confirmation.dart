import 'estimate_service_price.dart';
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
  if (input.documentKind != WorkRecordKind.estimate &&
      input.documentKind != WorkRecordKind.quote) {
    throw const EstimateInputValidation('Choose an estimate or quote.');
  }
  if (input.baseRecord != null &&
      input.baseRecord!.kind != input.documentKind) {
    throw const EstimateInputValidation('The document type cannot be changed.');
  }
  if (input.documentKind == WorkRecordKind.quote &&
      input.pricing != WorkPricingModel.flatRate) {
    throw const EstimateInputValidation('A quote requires a fixed price.');
  }
  final label = input.documentKind == WorkRecordKind.quote
      ? 'quote'
      : 'estimate';
  if (input.validityDays != null && input.validityDays! <= 0) {
    throw const EstimateInputValidation(
      'Enter a validity period greater than zero days.',
    );
  }
  if (input.number.trim().isEmpty) {
    throw EstimateInputValidation('Enter a $label number.');
  }
  if (input.pendingLineItems.isNotEmpty) {
    throw EstimateInputValidation(
      'Review and save the unfinished $label items first.',
    );
  }
  if (input.pendingPhotos != null) {
    throw EstimateInputValidation(
      'Review and save the unfinished $label photos and notes first.',
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

  final List<WorkLineItem> items;
  try {
    items = estimatePricedItems(input);
  } on FormatException catch (error) {
    throw EstimateInputValidation(error.message);
  }
  final discount = money(input.discount);
  final tax = money(input.tax);
  final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
  final total = (subtotal - discount + tax).clamp(0.0, double.infinity);
  if (input.requiresDeposit &&
      !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(input.depositAmount.trim())) {
    throw const EstimateInputValidation(
      'Enter a deposit amount with no more than two decimal places.',
    );
  }
  final deposit = input.requiresDeposit ? money(input.depositAmount) : 0.0;
  if (input.requiresDeposit && (deposit <= 0 || deposit > total)) {
    throw EstimateInputValidation(
      'Enter a deposit greater than zero and no more than the $label total.',
    );
  }
  final requiredDepositCents = (deposit * 100).round();
  final existing = input.baseRecord;
  final missingCustomerDetails =
      (input.client?.trim().isEmpty ?? true) ||
      input.title.trim().isEmpty ||
      input.scope.trim().isEmpty;
  if (existing != null &&
      existing.resolvedEstimateStage != EstimateStage.draft &&
      missingCustomerDetails) {
    throw EstimateInputValidation(
      'Add the customer, $label title, and proposed work before saving changes to a customer-ready $label.',
    );
  }
  final client = input.client?.trim().isNotEmpty == true
      ? input.client!.trim()
      : 'Client not selected';
  final title = input.title.trim().isEmpty
      ? 'Untitled $label'
      : input.title.trim();
  final scope = input.scope.trim().isEmpty
      ? 'Proposed work not entered yet.'
      : input.scope.trim();
  final dates = EstimateDates(
    createdOn: input.createdOn,
    lastEditedOn: now,
    sentOn: input.sentOn ?? existing?.estimateDates?.sentOn,
    viewedOn: existing?.estimateDates?.viewedOn,
    followUpOn: input.followUpOn,
    expiresOn: input.expiresOn,
    validityDays: input.validityDays,
    finishedOn: input.finishedOn,
    proposedServiceOn: input.proposedServiceOn,
    proposedServiceDates: List.unmodifiable(input.proposedServiceDates),
    decidedOn: existing?.estimateDates?.decidedOn,
    convertedOn: existing?.estimateDates?.convertedOn,
  );
  if (existing != null) {
    final revised = existing.reviseEstimate(
      title: title,
      purchaseOrderNumber: input.purchaseOrderNumber.trim(),
      client: client,
      customerSnapshot: input.customerSnapshot,
      scope: scope,
      pricing: input.pricing,
      documentPresentation: input.documentPresentation,
      items: items,
      sitePhotos: input.sitePhotos,
      template: input.template,
      terms: input.terms.trim(),
      requiredDepositCents: requiredDepositCents,
      discount: discount,
      tax: tax,
      dates: dates,
      changedOn: now,
    );
    return !missingCustomerDetails &&
            items.isNotEmpty &&
            revised.resolvedEstimateStage == EstimateStage.draft
        ? revised.withEstimateStage(EstimateStage.readyToSend, now)
        : revised;
  }
  return WorkRecord(
    id: input.estimateId,
    kind: input.documentKind,
    number: input.number.trim(),
    purchaseOrderNumber: input.purchaseOrderNumber.trim(),
    title: title,
    client: client,
    customerSnapshot: input.customerSnapshot,
    detail: scope,
    pricing: input.pricing,
    documentPresentation: input.documentPresentation,
    createdOn: input.createdOn,
    createdByEmployeeId: input.creatorId,
    status: !missingCustomerDetails && items.isNotEmpty
        ? WorkRecordStatus.ready
        : WorkRecordStatus.draft,
    items: List.unmodifiable(items),
    template: input.template,
    terms: input.terms.trim(),
    requiredDepositCents: requiredDepositCents,
    discount: discount,
    tax: tax,
    total: total,
    estimateStage: !missingCustomerDetails && items.isNotEmpty
        ? EstimateStage.readyToSend
        : EstimateStage.draft,
    estimateDates: dates,
    sitePhotos: List.unmodifiable(input.sitePhotos),
  );
}
