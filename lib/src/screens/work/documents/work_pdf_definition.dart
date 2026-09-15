import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import '../../../shared/documents/pdf/pdf_document_definition.dart';
import '../../../shared/documents/pdf/pdf_primitives.dart';
import 'customer_document.dart';

/// Work owns customer document composition and validation. The shared engine
/// has no invoice/estimate/expense branches and never looks up business records.
class WorkPdfDefinition extends PdfDocumentDefinition {
  WorkPdfDefinition(this.data, {this.artwork});
  final CustomerDocument data;
  final Uint8List? artwork;
  @override
  String get title => '${data.kind} ${data.number}';
  @override
  String get reference => '${data.number} · Revision ${data.revision}';
  @override
  DateTime get createdAt => data.date;
  @override
  void validate() {
    if (data.number.trim().isEmpty ||
        data.company.trim().isEmpty ||
        (!data.draft &&
            (data.customer.trim().isEmpty ||
                data.title.trim().isEmpty ||
                data.items.isEmpty))) {
      throw const FormatException(
        'Company, document number, customer, title and items are required for a final customer document.',
      );
    }
    if (data.items.length > 2000 ||
        data.items.any(
          (i) =>
              !i.quantity.isFinite ||
              i.quantity <= 0 ||
              i.totalCents < 0 ||
              i.unitPriceCents < 0,
        ) ||
        data.discountCents < 0 ||
        data.taxCents < 0 ||
        data.totalCents < 0 ||
        (data.subtotalCents - data.discountCents + data.taxCents).clamp(
              0,
              1 << 53,
            ) !=
            data.totalCents) {
      throw const FormatException(
        'Review document quantities, prices, discounts, tax and total.',
      );
    }
  }

  String money(int cents) =>
      '${data.currency} ${(cents / 100).toStringAsFixed(2)}';
  String day(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  @override
  List<pw.Widget> compose(PdfLayoutContext c) => [
    PdfPrimitives.branding(c),
    if (artwork != null && !c.theme.printerFriendly)
      pw.Image(
        pw.MemoryImage(artwork!),
        width: c.page.contentWidth,
        height: 72,
        fit: pw.BoxFit.contain,
      ),
    pw.Text(
      '${data.draft ? 'DRAFT ' : ''}${data.kind.toUpperCase()}',
      style: c.theme.heading,
    ),
    pw.Divider(color: c.theme.ink),
    ...PdfPrimitives.paragraph(
      'Prepared for: ${data.customer}\n${data.customerDetails}',
    ),
    ...PdfPrimitives.paragraph(
      'Date: ${day(data.date)}${data.validUntil == null ? '' : '\nValid until: ${day(data.validUntil!)}'}${data.dueOn == null ? '' : '\nPayment due: ${day(data.dueOn!)}'}${data.reference.isEmpty ? '' : '\nPurchase order: ${data.reference}'}',
    ),
    pw.SizedBox(height: 12),
    pw.Text(data.title, style: c.theme.heading),
    if (data.proposedServiceOn case final proposed?)
      ...PdfPrimitives.paragraph(
        'Proposed service: ${day(proposed)}${proposed.hour == 0 && proposed.minute == 0 ? '' : ' at ${proposed.hour.toString().padLeft(2, '0')}:${proposed.minute.toString().padLeft(2, '0')}'} (subject to scheduling confirmation)',
      ),
    ...PdfPrimitives.paragraph(data.description),
    pw.SizedBox(height: 12),
    PdfPrimitives.table(
      c,
      headers: const ['Items', 'Quantity', 'Unit price', 'Amount'],
      rows: [
        for (final item in data.items)
          [
            '${item.name}${item.description.isEmpty ? '' : '\n${item.description}'}',
            '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
            money(item.unitPriceCents),
            money(item.totalCents),
          ],
      ],
      widths: const [3.5, 1.2, 1.5, 1.5],
    ),
    pw.SizedBox(height: 12),
    PdfPrimitives.totals([
      ('Subtotal', money(data.subtotalCents)),
      if (data.discountCents != 0) ('Discount', money(-data.discountCents)),
      if (data.taxCents != 0) ('Tax', money(data.taxCents)),
      ('Total', money(data.totalCents)),
    ]),
    if (data.paymentMethod.isNotEmpty && data.paymentMethod != 'Not selected')
      ...PdfPrimitives.paragraph('Payment method: ${data.paymentMethod}'),
    pw.SizedBox(height: 16),
    pw.Text(
      'Terms and conditions',
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    ),
    ...PdfPrimitives.paragraph(data.terms),
    if (data.signatureSvg != null)
      pw.SvgImage(svg: data.signatureSvg!, width: 200, height: 55),
    if (data.signedBy != null)
      ...PdfPrimitives.paragraph(
        'Approved by ${data.signedBy}${data.signedOn == null ? '' : ' on ${day(data.signedOn!)}'}',
      ),
  ];
}
