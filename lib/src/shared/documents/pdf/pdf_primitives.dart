import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_document_definition.dart';

class PdfPrimitives {
  static pw.Widget branding(PdfLayoutContext c) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (c.logo != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Image(
            pw.MemoryImage(c.logo!.bytes),
            width: c.logo!.fit(160, 64).width,
            height: c.logo!.fit(160, 64).height,
            fit: pw.BoxFit.contain,
          ),
        ),
      pw.Text(c.branding.companyName, style: c.theme.heading),
      ...paragraph(c.branding.contactLines.join('\n'), size: 9),
      pw.SizedBox(height: 12),
    ],
  );

  static List<pw.Widget> paragraph(String text, {double size = 10}) {
    // Separate bounded text blocks permit page breaks even for very long notes.
    final lines = [for (final line in text.split('\n')) ..._chunks(line, 300)];
    return [
      for (final line in lines)
        pw.Text(line, style: pw.TextStyle(fontSize: size)),
    ];
  }

  static pw.Widget table(
    PdfLayoutContext c, {
    required List<String> headers,
    required List<List<String>> rows,
    required List<double> widths,
  }) {
    final expanded = <List<String>>[];
    for (final row in rows) {
      if (row.length != headers.length) {
        throw const FormatException('Table cells do not match the headers.');
      }
      final chunks = [for (final cell in row) _chunks(cell, 220)];
      final count = chunks.fold<int>(
        0,
        (n, cells) => n > cells.length ? n : cells.length,
      );
      for (var index = 0; index < count; index++) {
        expanded.add([
          for (final cells in chunks) index < cells.length ? cells[index] : '',
        ]);
      }
    }
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: expanded,
      columnWidths: {
        for (var i = 0; i < widths.length; i++)
          i: pw.FlexColumnWidth(widths[i]),
      },
      border: null,
      headerCount: 1,
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellStyle: pw.TextStyle(fontSize: c.theme.bodySize),
      cellPadding: const pw.EdgeInsets.all(6),
      cellAlignments: {
        for (var i = 0; i < widths.length; i++)
          i: i == 0 ? pw.Alignment.topLeft : pw.Alignment.topRight,
      },
    );
  }

  static List<String> _chunks(String text, int limit) {
    if (text.isEmpty) return [''];
    final result = <String>[];
    var remaining = text;
    while (remaining.length > limit) {
      var end = remaining.lastIndexOf(' ', limit);
      if (end <= 0) end = limit;
      if (remaining.codeUnitAt(end - 1) >= 0xd800 &&
          remaining.codeUnitAt(end - 1) <= 0xdbff) {
        end--;
      }
      result.add(remaining.substring(0, end));
      remaining = remaining.substring(end);
    }
    result.add(remaining);
    return result;
  }

  static pw.Widget totals(List<(String, String)> values) => pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.SizedBox(
      width: 260,
      child: pw.Column(
        children: [
          for (final value in values)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(value.$1)),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Text(value.$2, textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
