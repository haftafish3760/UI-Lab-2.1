import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../../shared/documents/pdf/pdf_document_definition.dart';
import '../../../shared/documents/pdf/pdf_primitives.dart';
import 'customer_document.dart';
import 'document_template.dart';
import 'work_pdf_layouts.dart';
import 'work_pdf_trade_art.dart';
import 'masonry_pdf_layout.dart';

/// Work owns customer document composition and validation. The shared engine
/// has no invoice/estimate/expense branches and never looks up business records.
class WorkPdfDefinition extends PdfDocumentDefinition {
  WorkPdfDefinition(
    this.data, {
    this.artwork,
    this.panelArtwork,
    this.pageArtwork,
    this.layout = DocumentLayout.standard,
  });
  final DocumentLayout layout;
  final CustomerDocument data;
  final Uint8List? artwork, panelArtwork, pageArtwork;
  @override
  pw.Widget? background(PdfLayoutContext context) => pageArtwork == null
      ? WorkPdfTradeArt.background(context, layout)
      : pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(
            pw.MemoryImage(pageArtwork!),
            width: context.page.format.width,
            height: context.page.format.height,
            fit: pw.BoxFit.fill,
          ),
        );
  @override
  pw.Widget decoratePageLabel(pw.Widget label) => pageArtwork == null
      ? label
      : pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.all(3),
          child: label,
        );
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
                (data.isSummary
                    ? data.description.trim().isEmpty
                    : data.items.isEmpty)))) {
      throw const FormatException(
        'Company, document number, customer, title and items are required for a final customer document.',
      );
    }
    if ((data.isSummary && (data.items.isNotEmpty || data.subtotalCents < 0)) ||
        data.items.length > 2000 ||
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
        (data.paidCents != null &&
            (data.kind != 'Invoice' ||
                data.paidCents! < 0 ||
                data.paidCents! > data.totalCents)) ||
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
  List<pw.Widget> compose(PdfLayoutContext c) =>
      layout == DocumentLayout.masonry && panelArtwork != null
      ? MasonryPdfLayout(data, panelArtwork!).compose(c)
      : [
          if (layout == DocumentLayout.standard) ...[
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
          ] else
            ...WorkPdfLayouts.header(c, data, layout, day, money),
          pw.SizedBox(height: 12),
          if (layout != DocumentLayout.project &&
              layout != DocumentLayout.garden)
            pw.Text(data.title, style: c.theme.heading),
          if (data.proposedServiceOn case final proposed?)
            ...PdfPrimitives.paragraph(
              'Proposed service: ${day(proposed)}${proposed.hour == 0 && proposed.minute == 0 ? '' : ' at ${proposed.hour.toString().padLeft(2, '0')}:${proposed.minute.toString().padLeft(2, '0')}'} (subject to scheduling confirmation)',
            ),
          ...PdfPrimitives.paragraph(data.description),
          pw.SizedBox(height: 12),
          if (data.isSummary)
            pw.SizedBox(height: 0)
          else if (layout == DocumentLayout.service ||
              layout == DocumentLayout.plumbing)
            ...WorkPdfLayouts.serviceItems(c, data, money)
          else
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
            if (data.discountCents != 0)
              ('Discount', money(-data.discountCents)),
            if (data.taxCents != 0) ('Tax', money(data.taxCents)),
            ('Total', money(data.totalCents)),
            if (data.paidCents != null) ...[
              ('Paid', money(-data.paidCents!)),
              ('Amount due', money(data.balanceCents!)),
            ],
          ]),
          if (data.paymentMethod.isNotEmpty &&
              data.paymentMethod != 'Not selected')
            ...PdfPrimitives.paragraph('Payment method: ${data.paymentMethod}'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Terms and conditions',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          ...PdfPrimitives.paragraph(data.terms),
          if (data.businessSignatureSvg != null) ...[
            pw.SizedBox(height: 12),
            pw.Text('Business signature'),
            pw.SvgImage(
              svg: data.businessSignatureSvg!,
              width: 200,
              height: 55,
            ),
            ...PdfPrimitives.paragraph(
              '${data.businessSignedBy ?? ''}${data.businessSignedOn == null ? '' : ' · ${day(data.businessSignedOn!)}'}',
            ),
          ],
          if (data.signatureSvg != null)
            pw.SvgImage(svg: data.signatureSvg!, width: 200, height: 55),
          if (data.signedBy != null)
            ...PdfPrimitives.paragraph(
              'Approved by ${data.signedBy}${data.signedOn == null ? '' : ' on ${day(data.signedOn!)}'}',
            ),
        ];
}
