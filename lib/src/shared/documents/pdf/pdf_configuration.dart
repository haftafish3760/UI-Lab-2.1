import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfPageConfig {
  const PdfPageConfig({
    this.size = PdfPageFormat.a4,
    this.landscape = false,
    this.margin = 32,
    this.maxPages = 200,
  });
  final PdfPageFormat size;
  final bool landscape;
  final double margin;
  final int maxPages;
  PdfPageFormat get format => landscape ? size.landscape : size.portrait;
  double get contentWidth => format.width - 2 * margin;
  void validate() {
    if (!margin.isFinite ||
        margin < 0 ||
        !format.width.isFinite ||
        !format.height.isFinite ||
        contentWidth < 160 ||
        format.height - margin * 2 < 200 ||
        maxPages < 1 ||
        maxPages > 500) {
      throw const FormatException(
        'The document page configuration is invalid.',
      );
    }
  }
}

class PdfDocumentTheme {
  const PdfDocumentTheme({
    this.accent = 0x183c55,
    this.printerFriendly = false,
    this.bodySize = 10,
    this.spacing = 8,
  });
  final int accent;
  final bool printerFriendly;
  final double bodySize, spacing;
  PdfColor get ink =>
      printerFriendly ? PdfColors.black : PdfColor.fromInt(0xff000000 | accent);
  pw.TextStyle get heading =>
      pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: ink);
}
