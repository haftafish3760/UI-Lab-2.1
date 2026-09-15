import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:ui_lab_2_1/src/shared/documents/pdf/pdf_document_definition.dart';
import 'package:ui_lab_2_1/src/shared/documents/pdf/pdf_primitives.dart';

Uint8List fixtureLogo(
  int width,
  int height, {
  bool jpeg = false,
  bool transparent = false,
}) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(24, 80, 120, transparent ? 100 : 255));
  return jpeg ? img.encodeJpg(image) : img.encodePng(image);
}

class SharedPdfFixture extends PdfDocumentDefinition {
  SharedPdfFixture({this.rows = 90, this.longNotes = true});
  final int rows;
  final bool longNotes;
  @override
  String get title => 'Document infrastructure verification';
  @override
  String get reference => 'Verification document 001';
  @override
  void validate() {
    if (rows < 0) throw const FormatException('Invalid row count.');
  }

  @override
  List<pw.Widget> compose(PdfLayoutContext c) => [
    PdfPrimitives.branding(c),
    pw.Text(title, style: c.theme.heading),
    ...PdfPrimitives.paragraph(
      'CUSTOMER-BEGIN ${'Long customer information and service address. ' * 18} CUSTOMER-END',
    ),
    PdfPrimitives.table(
      c,
      headers: const ['Description', 'Quantity', 'Amount'],
      rows: [
        for (var i = 0; i < rows; i++)
          [
            'ROW-${i.toString().padLeft(3, '0')} ${i == 4 ? 'Very long service description with all details preserved. ' * 60 : 'Service completed with retained detail.'} END-${i.toString().padLeft(3, '0')}',
            '1 hour',
            'USD 12.50',
          ],
      ],
      widths: const [5, 1, 1.5],
    ),
    pw.SizedBox(height: 10),
    PdfPrimitives.totals([
      ('FINAL TOTAL', 'USD ${(rows * 12.5).toStringAsFixed(2)}'),
    ]),
    if (longNotes)
      ...PdfPrimitives.paragraph(
        'NOTES-BEGIN ${'Complete warranty and service information. ' * 160} NOTES-END',
      ),
  ];
}
