import '../../data/work/company_document_branding.dart';
import '../../data/work/models/work_models.dart';
import '../../data/work/models/estimate_models.dart';
import '../../data/work/models/work_contact_models.dart';
import 'documents/customer_document.dart';

CustomerDocument workCustomerDocument(
  WorkRecord record,
  WorkCompanyProfile company,
  WorkCustomerProfile? customer,
) {
  customer = record.customerSnapshot ?? customer;
  final signature = record.hasCurrentCustomerSignature
      ? record.customerSignature
      : null;
  String? renderSignature(WorkCustomerSignature? value) {
    final ink = value?.ink;
    String point((double, double) p) =>
        '${(p.$1 * 280).toStringAsFixed(2)} ${(p.$2 * 72).toStringAsFixed(2)}';
    return ink?.hasInk == true
        ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 280 72"><g fill="none" stroke="#172c3d" stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round">${ink!.strokes.where((s) => s.length > 1).map((s) => '<path d="M ${point(s.first)} ${s.skip(1).map((p) => 'L ${point(p)}').join(' ')}"/>').join()}</g></svg>'
        : null;
  }

  final svg = renderSignature(signature);
  final businessSignature =
      record.businessSignature?.isCurrentFor(record.revision) == true
      ? record.businessSignature
      : null;
  return CustomerDocument(
    kind: switch (record.kind) {
      WorkRecordKind.estimate => 'Estimate',
      WorkRecordKind.invoice => 'Invoice',
      WorkRecordKind.job => 'Job',
    },
    number: record.number
        .replaceFirst(RegExp(r'^EST-'), 'Estimate ')
        .replaceFirst(RegExp(r'^INV-'), 'Invoice ')
        .replaceFirst(RegExp(r'^JOB-'), 'Job '),
    branding: companyDocumentBranding(company),
    title: record.title,
    description: record.detail,
    validUntil: record.estimateDates?.expiresOn,
    dueOn: record.dueOn,
    paymentMethod: record.paymentMethod,
    proposedServiceOn: record.estimateDates?.proposedServiceOn,
    company: company.companyName,
    companyDetails: [
      company.address,
      company.phone,
      company.email,
      company.website,
    ].where((s) => s.trim().isNotEmpty).join('\n'),
    customer: record.client,
    customerDetails: [
      customer?.billingAddress ?? '',
      record.serviceLocation,
    ].where((s) => s.trim().isNotEmpty).toSet().join('\n'),
    date:
        record.issuedOn ??
        record.createdOn ??
        record.estimateDates?.createdOn ??
        DateTime.now(),
    reference: record.purchaseOrderNumber,
    currency:
        RegExp(r'^[A-Z]{3}').firstMatch(company.defaultCurrency)?.group(0) ??
        'USD',
    templateId: record.template,
    revision: record.revision,
    draft: record.kind == WorkRecordKind.estimate
        ? record.resolvedEstimateStage == EstimateStage.draft
        : record.status == WorkRecordStatus.draft,
    terms: record.terms,
    discountCents: (record.discount * 100).round(),
    taxCents: (record.tax * 100).round(),
    totalCents: (record.total * 100).round(),
    items: [
      for (final item in record.items)
        CustomerDocumentItem(
          name: item.name,
          description: item.description,
          quantity: item.quantity,
          unit: item.unit,
          unitPriceCents: (item.customerPrice * 100).round(),
          totalCents: (item.total * 100).round(),
        ),
    ],
    signatureSvg: svg,
    businessSignatureSvg: renderSignature(businessSignature),
    businessSignedBy: businessSignature?.signedBy,
    businessSignedOn: businessSignature?.signedOn,
    signedBy: signature?.signedBy,
    signedOn: signature?.signedOn,
  );
}
