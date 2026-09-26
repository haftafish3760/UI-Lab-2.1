import 'invoice_draft_controller.dart';
import 'models/work_models.dart';
import 'models/estimate_models.dart';

class InvoiceInputValidation implements Exception {
  const InvoiceInputValidation(this.message);
  final String message;
}

/// Confirmed document construction and validation, independent of presentation.
WorkRecord buildConfirmedInvoice(
  InvoiceDraftInput input, {
  WorkRecord? existing,
  bool previewIncomplete = false,
}) {
  if (input.number.trim().isEmpty) {
    throw const InvoiceInputValidation('Enter an invoice number.');
  }
  if (input.pendingLineItem != null) {
    throw const InvoiceInputValidation(
      'Review and save the unfinished invoice items first.',
    );
  }
  if (!previewIncomplete &&
      (input.client == null ||
          input.title.trim().isEmpty ||
          input.summary.trim().isEmpty ||
          input.items.isEmpty)) {
    throw const InvoiceInputValidation(
      'Choose a customer and enter the work completed with at least one invoice item.',
    );
  }
  if (input.dueOn.isBefore(input.issuedOn)) {
    throw const InvoiceInputValidation(
      'The payment due date cannot be before the invoice date.',
    );
  }
  double money(String value) {
    final amount = value.trim().isEmpty ? 0.0 : double.tryParse(value.trim());
    if (amount == null || !amount.isFinite || amount < 0) {
      throw const InvoiceInputValidation(
        'Enter a valid non-negative discount and tax amount.',
      );
    }
    return amount;
  }

  final discount = money(input.discount);
  final tax = money(input.tax);
  final subtotal = input.items.fold(0.0, (sum, item) => sum + item.total);
  final total = (subtotal - discount + tax).clamp(0.0, double.infinity);
  return WorkRecord(
    id: input.recordId,
    kind: WorkRecordKind.invoice,
    number: input.number.trim(),
    purchaseOrderNumber: input.purchaseOrderNumber.trim(),
    title: input.title.trim(),
    client: input.client ?? 'Client not selected',
    customerSnapshot:
        input.customerSnapshot ??
        (input.client == existing?.client ? existing?.customerSnapshot : null),
    detail: input.summary.trim(),
    pricing: input.pricing,
    sourceId: input.sourceJobId,
    serviceLocation: input.location ?? '',
    createdOn: input.createdOn,
    issuedOn: input.issuedOn,
    dueOn: input.dueOn,
    createdByEmployeeId: input.creatorId,
    status: existing?.status ?? WorkRecordStatus.draft,
    items: List.unmodifiable(input.items),
    template: input.template,
    terms: input.terms.trim(),
    paymentMethod: input.paymentMethod,
    discount: discount,
    tax: tax,
    total: total,
    revision: existing?.revision ?? 1,
    assignee: existing?.assignee,
    vehicle: existing?.vehicle,
    jobNotes: existing?.jobNotes ?? '',
    scheduledStart: existing?.scheduledStart,
    scheduledEnd: existing?.scheduledEnd,
    completedOn: existing?.completedOn,
    customerSignature: existing?.customerSignature,
    estimateStage: existing?.estimateStage,
    estimateDates: existing?.estimateDates,
    estimateDeliveries: existing?.estimateDeliveries ?? const [],
    estimateRevisionHistory: existing?.estimateRevisionHistory ?? const [],
    requiresCompanyReview: existing?.requiresCompanyReview ?? false,
    estimateCompanyReviewStatus:
        existing?.estimateCompanyReviewStatus ??
        EstimateCompanyReviewStatus.notRequired,
    estimateCompanyReviewNote: existing?.estimateCompanyReviewNote ?? '',
    estimateCompanyReviewHistory:
        existing?.estimateCompanyReviewHistory ?? const [],
    sitePhotos: existing?.sitePhotos ?? const [],
    linkedExpenseIds: existing?.linkedExpenseIds ?? const [],
  );
}
