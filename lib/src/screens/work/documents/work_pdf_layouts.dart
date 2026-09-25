import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../shared/documents/pdf/pdf_document_definition.dart';
import '../../../shared/documents/pdf/pdf_primitives.dart';
import 'customer_document.dart';
import 'document_template.dart';

/// Distinct compositions share the same customer-safe data and arithmetic.
class WorkPdfLayouts {
  static List<pw.Widget> header(
    PdfLayoutContext c,
    CustomerDocument d,
    DocumentLayout layout,
    String Function(DateTime) day,
    String Function(int) money,
  ) {
    final label = '${d.draft ? 'DRAFT ' : ''}${d.kind.toUpperCase()}';
    final dates = [
      'Date: ${day(d.date)}',
      if (d.validUntil != null) 'Valid until: ${day(d.validUntil!)}',
      if (d.dueOn != null) 'Payment due: ${day(d.dueOn!)}',
      if (d.reference.isNotEmpty) 'Purchase order: ${d.reference}',
    ].join('\n');
    if (layout == DocumentLayout.project || layout == DocumentLayout.garden) {
      return [
        PdfPrimitives.branding(c),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border(
              left: pw.BorderSide(color: c.theme.ink, width: 6),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Text(d.title, style: c.theme.heading.copyWith(fontSize: 24)),
              pw.SizedBox(height: 12),
              pw.Text(
                'Proposed total  ${money(d.totalCents)}',
                style: c.theme.heading,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        ...PdfPrimitives.paragraph(
          'Prepared for: ${d.customer}\n${d.customerDetails}',
        ),
        pw.SizedBox(height: 8),
        ...PdfPrimitives.paragraph(dates),
      ];
    }
    if (layout == DocumentLayout.service || layout == DocumentLayout.plumbing) {
      return [
        pw.Text(label, style: c.theme.heading.copyWith(fontSize: 28)),
        pw.Divider(color: c.theme.ink, thickness: 3),
        PdfPrimitives.branding(c),
        pw.Text(
          'CUSTOMER & SERVICE DETAILS',
          style: c.theme.heading.copyWith(fontSize: 11),
        ),
        ...PdfPrimitives.paragraph('${d.customer}\n${d.customerDetails}'),
        pw.SizedBox(height: 8),
        ...PdfPrimitives.paragraph(dates),
      ];
    }
    return [
      if (layout == DocumentLayout.masonry ||
          layout == DocumentLayout.carpentry)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          color: PdfColors.grey200,
          child: pw.Text(label, style: c.theme.heading.copyWith(fontSize: 26)),
        ),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 3, child: PdfPrimitives.branding(c)),
          pw.SizedBox(width: 24),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(label, style: c.theme.heading.copyWith(fontSize: 24)),
                pw.SizedBox(height: 8),
                ...PdfPrimitives.paragraph(dates),
              ],
            ),
          ),
        ],
      ),
      pw.Divider(color: c.theme.ink, thickness: 2),
      pw.SizedBox(height: 8),
      ...PdfPrimitives.paragraph(
        'Prepared for: ${d.customer}\n${d.customerDetails}',
      ),
    ];
  }

  static List<pw.Widget> serviceItems(
    PdfLayoutContext c,
    CustomerDocument d,
    String Function(int) money,
  ) => [
    for (var index = 0; index < d.items.length; index++) ...[
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
        ),
        child: pw.Row(
          children: [
            pw.Text('${index + 1}'.padLeft(2, '0'), style: c.theme.heading),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Text(
                '${d.items[index].quantity} ${d.items[index].unit} × ${money(d.items[index].unitPriceCents)}',
              ),
            ),
            pw.Text(money(d.items[index].totalCents), style: c.theme.heading),
          ],
        ),
      ),
      ...PdfPrimitives.paragraph(d.items[index].name, size: 12),
      ...PdfPrimitives.paragraph(d.items[index].description),
      pw.SizedBox(height: 12),
    ],
  ];
}
