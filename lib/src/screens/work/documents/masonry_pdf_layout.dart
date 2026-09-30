import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../shared/documents/pdf/pdf_document_definition.dart';
import '../../../shared/documents/pdf/pdf_primitives.dart';
import 'customer_document.dart';

/// Every content block is an independent stone, not text baked into artwork.
/// Tables and bounded continuation slabs flow across any number of pages.
class MasonryPdfLayout {
  MasonryPdfLayout(this.data, Uint8List slab) : stone = pw.MemoryImage(slab);
  final CustomerDocument data;
  final pw.MemoryImage stone;
  static const ink = PdfColor.fromInt(0xff392820);
  static const headingInk = PdfColor.fromInt(0xff62352a);

  String money(int cents) =>
      '${data.currency == 'USD' ? '\$' : '${data.currency} '}${(cents / 100).toStringAsFixed(2)}';
  String date(DateTime d) => '${d.month}/${d.day}/${d.year}';
  pw.Widget text(String value, {double size = 10, bool bold = false}) =>
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: size,
          color: ink,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      );
  pw.Widget heading(String value) => pw.Text(
    value,
    style: pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: headingInk,
    ),
  );
  pw.Widget slab(pw.Widget child, {double inset = 12}) => pw.Container(
    margin: const pw.EdgeInsets.all(2),
    padding: pw.EdgeInsets.all(inset),
    decoration: pw.BoxDecoration(
      image: pw.DecorationImage(image: stone, fit: pw.BoxFit.fill),
    ),
    child: child,
  );
  pw.Widget block(String label, String value) => slab(
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        heading(label),
        pw.SizedBox(height: 6),
        ...PdfPrimitives.paragraph(value),
      ],
    ),
  );
  List<String> chunks(String value, [int length = 220]) {
    if (value.isEmpty) {
      return [''];
    }
    final result = <String>[];
    var remaining = value;
    while (remaining.length > length) {
      var end = remaining.lastIndexOf(' ', length);
      if (end < 1) end = length;
      if (remaining.codeUnitAt(end - 1) >= 0xd800 &&
          remaining.codeUnitAt(end - 1) <= 0xdbff) {
        end--;
      }
      result.add(remaining.substring(0, end));
      remaining = remaining.substring(end);
    }
    return [...result, remaining];
  }

  List<pw.Widget> compose(PdfLayoutContext c) {
    final customer = chunks('${data.customer}\n${data.customerDetails}', 450);
    final details = [
      '${data.kind} #: ${data.number}',
      'Date: ${date(data.date)}',
      if (data.validUntil != null) 'Valid until: ${date(data.validUntil!)}',
      if (data.dueOn != null) 'Payment due: ${date(data.dueOn!)}',
      if (data.reference.isNotEmpty) 'P.O.: ${data.reference}',
    ].join('\n');
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        children: [
          for (final label in ['QTY', 'DESCRIPTION', 'UNIT PRICE', 'AMOUNT'])
            slab(heading(label), inset: 7),
        ],
      ),
      for (final item in data.items) ..._itemRows(item),
    ];
    return [
      slab(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (c.logo != null) ...[
              pw.Image(
                pw.MemoryImage(c.logo!.bytes),
                width: 45,
                height: 45,
                fit: pw.BoxFit.contain,
              ),
              pw.SizedBox(width: 10),
            ],
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  text(c.branding.companyName, size: 21, bold: true),
                  pw.SizedBox(height: 6),
                  ...PdfPrimitives.paragraph(
                    c.branding.contactLines.join('\n'),
                    size: 8,
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                children: [
                  text(
                    '${data.draft ? 'DRAFT\n' : ''}${data.kind.toUpperCase()}',
                    size: 22,
                    bold: true,
                  ),
                  pw.SizedBox(height: 6),
                  heading('Revision ${data.revision}'),
                ],
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 7),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: block(
              data.kind == 'Invoice' ? 'BILL TO' : 'PREPARED FOR',
              customer.first,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: block('${data.kind.toUpperCase()} DETAILS', details),
          ),
        ],
      ),
      for (final part in customer.skip(1))
        block('CUSTOMER DETAILS — CONTINUED', part),
      for (final part in chunks('${data.title}\n${data.description}', 600))
        block('PROPOSED WORK', part),
      for (final proposed in data.serviceOptions)
        block(
          'PROPOSED SCHEDULE',
          '${date(proposed)} at ${proposed.hour.toString().padLeft(2, '0')}:${proposed.minute.toString().padLeft(2, '0')} — subject to scheduling confirmation',
        ),
      pw.SizedBox(height: 7),
      if (!data.isSummary)
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(0.8),
            1: pw.FlexColumnWidth(3.6),
            2: pw.FlexColumnWidth(1.35),
            3: pw.FlexColumnWidth(1.35),
          },
          children: rows,
        ),
      pw.SizedBox(height: 7),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: block('NOTES / TERMS', chunks(data.terms, 450).first),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Column(
              children: [
                _total('Subtotal', data.subtotalCents),
                if (data.discountCents != 0)
                  _total('Discount', -data.discountCents),
                if (data.taxCents != 0) _total('Tax', data.taxCents),
                _total(
                  data.kind == 'Estimate' ? 'ESTIMATED TOTAL' : 'TOTAL',
                  data.totalCents,
                  bold: true,
                ),
                if (data.paidCents != null) ...[
                  _total('Paid', -data.paidCents!),
                  _total('AMOUNT DUE', data.balanceCents!, bold: true),
                ],
              ],
            ),
          ),
        ],
      ),
      for (final part in chunks(data.terms, 450).skip(1))
        block('TERMS — CONTINUED', part),
      if (data.paymentMethod.isNotEmpty && data.paymentMethod != 'Not selected')
        block('PAYMENT METHOD', data.paymentMethod),
      pw.SizedBox(height: 7),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _signature(
              'BUSINESS SIGNATURE',
              data.businessSignatureSvg,
              data.businessSignedBy,
              data.businessSignedOn,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: _signature(
              'CUSTOMER SIGNATURE',
              data.signatureSvg,
              data.signedBy,
              data.signedOn,
            ),
          ),
        ],
      ),
    ];
  }

  List<pw.TableRow> _itemRows(CustomerDocumentItem item) {
    final parts = chunks('${item.name}\n${item.description}');
    return [
      for (var index = 0; index < parts.length; index++)
        pw.TableRow(
          children: [
            slab(
              text(
                index == 0
                    ? '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity}\n${item.unit}'
                    : '',
              ),
              inset: 7,
            ),
            slab(text(parts[index]), inset: 8),
            slab(text(index == 0 ? money(item.unitPriceCents) : ''), inset: 7),
            slab(text(index == 0 ? money(item.totalCents) : ''), inset: 7),
          ],
        ),
    ];
  }

  pw.Widget _total(String label, int amount, {bool bold = false}) => slab(
    pw.Row(
      children: [
        pw.Expanded(
          child: text(label, bold: bold, size: bold ? 11 : 10),
        ),
        pw.SizedBox(width: 6),
        text(money(amount), bold: bold, size: bold ? 13 : 10),
      ],
    ),
    inset: 9,
  );
  pw.Widget _signature(
    String label,
    String? svg,
    String? name,
    DateTime? signedOn,
  ) => slab(
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        heading(label),
        if (svg != null)
          pw.SvgImage(svg: svg, width: 180, height: 40)
        else
          pw.SizedBox(height: 28),
        pw.Divider(color: ink),
        text(name ?? '', size: 9),
        text(
          signedOn == null
              ? 'Date: __________________'
              : 'Date: ${date(signedOn)}',
          size: 8,
        ),
      ],
    ),
  );
}
