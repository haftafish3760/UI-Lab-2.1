import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/prototype_financial_models.dart';
import '../../../data/work/company_document_branding.dart';
import '../../../data/work/models/work_contact_models.dart';
import '../../../data/work/models/work_models.dart';
import '../../../shared/documents/document_image_scope.dart';
import '../../../shared/documents/pdf/pdf_branding.dart';
import '../../../shared/documents/pdf/pdf_document_definition.dart';
import '../../../shared/documents/pdf/pdf_engine.dart';
import '../../../shared/documents/pdf/pdf_font_assets.dart';
import '../../../shared/documents/pdf/pdf_image_resolver.dart';
import '../../../shared/documents/pdf/pdf_primitives.dart';

/// A stable public reference; the private payment record ID stays out of PDFs.
String paymentReceiptReference(String organizationId, String paymentId) {
  final digest = sha256.convert(utf8.encode('$organizationId/$paymentId'));
  return 'R-${digest.toString().substring(0, 24).toUpperCase()}';
}

class PaymentReceiptData {
  const PaymentReceiptData({
    required this.reference,
    required this.branding,
    required this.receivedOn,
    required this.amountCents,
    required this.currency,
    required this.method,
    required this.payer,
    required this.description,
    this.linkedWork,
  });

  final String reference;
  final PdfBranding branding;
  final DateTime receivedOn;
  final int amountCents;
  final String currency, method, payer, description;
  final String? linkedWork;
}

PaymentReceiptData paymentReceiptData({
  required String organizationId,
  required PrototypeFinancialEntry payment,
  required WorkCompanyProfile company,
  WorkRecord? linkedWork,
}) {
  if (payment.kind != PrototypeFinancialKind.paymentReceived) {
    throw ArgumentError('Only money received can have a payment receipt.');
  }
  return PaymentReceiptData(
    reference: paymentReceiptReference(organizationId, payment.id),
    branding: companyDocumentBranding(company),
    receivedOn: payment.occurredOn,
    amountCents: payment.amountCents,
    currency:
        RegExp(r'^[A-Z]{3}').firstMatch(company.defaultCurrency)?.group(0) ??
        'USD',
    method: payment.paymentMethod,
    payer: payment.payerName,
    description: payment.description,
    linkedWork: linkedWork == null
        ? null
        : '${linkedWork.kind.name} ${linkedWork.number} · ${linkedWork.title}',
  );
}

class PaymentReceiptPdfDefinition extends PdfDocumentDefinition {
  PaymentReceiptPdfDefinition(this.data);

  final PaymentReceiptData data;

  @override
  String get title => 'Payment receipt ${data.reference}';

  @override
  String get reference => data.reference;

  @override
  DateTime get createdAt => data.receivedOn;

  @override
  void validate() {
    if (data.reference.isEmpty ||
        data.branding.companyName.trim().isEmpty ||
        data.amountCents <= 0 ||
        data.method.trim().isEmpty) {
      throw const FormatException('This payment is missing receipt details.');
    }
  }

  @override
  List<pw.Widget> compose(PdfLayoutContext context) {
    final date = data.receivedOn.toLocal();
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return [
      PdfPrimitives.branding(context),
      pw.Text('PAYMENT RECEIPT', style: context.theme.heading),
      pw.Divider(),
      pw.SizedBox(height: 12),
      PdfPrimitives.totals([
        (
          'Amount received',
          '${data.currency} ${(data.amountCents / 100).toStringAsFixed(2)}',
        ),
      ]),
      pw.SizedBox(height: 16),
      ...PdfPrimitives.paragraph('Received on: $dateLabel'),
      ...PdfPrimitives.paragraph('Payment method: ${data.method}'),
      if (data.payer.isNotEmpty)
        ...PdfPrimitives.paragraph('Received from: ${data.payer}'),
      if (data.description.isNotEmpty)
        ...PdfPrimitives.paragraph('For: ${data.description}'),
      if (data.linkedWork case final work?)
        ...PdfPrimitives.paragraph('Related work: $work'),
      pw.SizedBox(height: 16),
      ...PdfPrimitives.paragraph('Receipt reference: ${data.reference}'),
    ];
  }
}

Future<Uint8List> generatePaymentReceiptPdf(
  PaymentReceiptData data, {
  DocumentImageLoader? logoLoader,
}) async {
  final fonts = await PdfFontAssets.load();
  final logoReference = data.branding.logoReference;
  final logo = logoReference == null
      ? null
      : await const PdfImageResolver().resolve(
          () async => logoLoader == null ? null : logoLoader(logoReference),
        );
  final rendered = await const PdfEngine().render(
    PaymentReceiptPdfDefinition(data),
    branding: data.branding,
    regularFont: fonts.regular,
    boldFont: fonts.bold,
    logo: logo,
  );
  return rendered.bytes;
}
