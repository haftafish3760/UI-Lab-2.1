import '../../data/work/estimate_service_price.dart';
import '../../data/work/models/work_models.dart';
import '../../data/work/company_document_branding.dart';
import '../../data/work/estimate_draft_controller.dart';
import '../../data/work/models/work_contact_models.dart';
import 'documents/customer_document.dart';

/// Design browsing never confirms a record or changes a recovered draft.
/// Incomplete raw fields stay in the editor; the preview is explicitly a draft.
CustomerDocument estimateTemplateDocument(
  EstimateDraftInput input,
  WorkCompanyProfile company,
) {
  int cents(String raw) {
    final value = double.tryParse(raw);
    return value != null && value.isFinite && value >= 0
        ? (value * 100).round()
        : 0;
  }

  final pricedItems = estimatePricedItems(input);
  final items = [
    for (final item in pricedItems)
      CustomerDocumentItem(
        name: item.name,
        description: item.description,
        quantity: item.quantity,
        unit: item.unit,
        unitPriceCents: (item.customerPrice * 100).round(),
        totalCents: (item.total * 100).round(),
      ),
  ];
  final discount = cents(input.discount), tax = cents(input.tax);
  return CustomerDocument(
    kind: 'Estimate',
    number: input.number,
    draft: true,
    title: input.title.isEmpty ? 'Estimate preview' : input.title,
    description:
        'Template preview — unfinished entries are not included.\n${input.scope}',
    company: company.companyName,
    companyDetails: company.address,
    branding: companyDocumentBranding(company),
    customer: input.client ?? 'Customer',
    customerDetails: input.customerSnapshot?.billingAddress ?? '',
    date: input.createdOn,
    validUntil: input.expiresOn,
    proposedServiceOn: input.proposedServiceOn,
    proposedServiceDates: input.proposedServiceDates,
    reference: input.purchaseOrderNumber,
    templateId: input.template,
    currency:
        RegExp(r'^[A-Z]{3}').firstMatch(company.defaultCurrency)?.group(0) ??
        'USD',
    summarySubtotalCents:
        input.documentPresentation == WorkDocumentPresentation.summary
        ? items.fold<int>(0, (sum, item) => sum + item.totalCents)
        : null,
    items: input.documentPresentation == WorkDocumentPresentation.summary
        ? const []
        : items,
    discountCents: discount,
    taxCents: tax,
    totalCents:
        (items.fold<int>(0, (sum, item) => sum + item.totalCents) -
                discount +
                tax)
            .clamp(0, 1 << 53),
    terms: [
      if (input.validityDays case final days?)
        'Price guaranteed for $days days from the date sent to the customer.',
      input.terms,
      if (input.requiresDeposit && cents(input.depositAmount) > 0)
        'Required deposit: \$${(cents(input.depositAmount) / 100).toStringAsFixed(2)}',
    ].where((text) => text.isNotEmpty).join('\n\n'),
  );
}
