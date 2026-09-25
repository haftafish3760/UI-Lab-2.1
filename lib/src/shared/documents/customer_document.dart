import 'pdf/pdf_branding.dart';

/// Public customer copy only. Domain adapters must omit private costs and notes.
class CustomerDocument {
  const CustomerDocument({
    required this.kind,
    required this.number,
    required this.title,
    required this.company,
    required this.companyDetails,
    required this.customer,
    required this.customerDetails,
    required this.date,
    required this.items,
    required this.totalCents,
    required this.terms,
    this.branding,
    this.dueOn,
    this.paymentMethod = '',
    this.description = '',
    this.validUntil,
    this.proposedServiceOn,
    this.reference = '',
    this.currency = 'USD',
    this.discountCents = 0,
    this.taxCents = 0,
    this.templateId = 'Service standard',
    this.revision = 1,
    this.draft = false,
    this.signatureSvg,
    this.businessSignatureSvg,
    this.businessSignedBy,
    this.businessSignedOn,
    this.signedBy,
    this.signedOn,
  });
  final PdfBranding? branding;
  final String kind, number, title, company, companyDetails, customer;
  final String description;
  final DateTime? validUntil, dueOn;
  final DateTime? proposedServiceOn;
  final String paymentMethod;
  final String customerDetails, reference, currency, terms, templateId;
  final DateTime date;
  final List<CustomerDocumentItem> items;
  final int totalCents, discountCents, taxCents, revision;
  final bool draft;
  final String? signatureSvg, signedBy;
  final String? businessSignatureSvg, businessSignedBy;
  final DateTime? businessSignedOn;
  final DateTime? signedOn;
  Map<String, Object?> toPortalJson() => {
    'kind': kind,
    'number': number,
    'title': title,
    'description': description,
    'company': company,
    'companyDetails': companyDetails,
    'customer': customer,
    'customerDetails': customerDetails,
    'date': date.toIso8601String(),
    'validUntil': validUntil?.toIso8601String(),
    'proposedServiceOn': proposedServiceOn?.toIso8601String(),
    'dueOn': dueOn?.toIso8601String(),
    'paymentMethod': paymentMethod,
    'reference': reference,
    'currency': currency,
    'terms': terms,
    'templateId': templateId,
    'revision': revision,
    'totalCents': totalCents,
    'discountCents': discountCents,
    'taxCents': taxCents,
    'items': [
      for (final item in items)
        {
          'name': item.name,
          'description': item.description,
          'quantity': item.quantity,
          'unit': item.unit,
          'unitPriceCents': item.unitPriceCents,
          'totalCents': item.totalCents,
        },
    ],
  };
  int get subtotalCents => items.fold(0, (sum, item) => sum + item.totalCents);
}

class CustomerDocumentItem {
  const CustomerDocumentItem({
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPriceCents,
    required this.totalCents,
  });
  final String name, description, unit;
  final double quantity;
  final int unitPriceCents, totalCents;
}
