import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_branding.dart';
import 'pdf_configuration.dart';
import 'pdf_document_definition.dart';
import 'pdf_image_resolver.dart';

class PdfRenderFailure implements Exception {
  const PdfRenderFailure(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}

class PdfRenderedDocument {
  PdfRenderedDocument(Uint8List bytes, this.pageCount, this.warnings)
    : _bytes = Uint8List.fromList(bytes);
  final Uint8List _bytes;
  Uint8List get bytes => Uint8List.fromList(_bytes);
  final int pageCount;
  final List<String> warnings;
}

/// Pure rendering boundary: no repositories, app state, feature switches or I/O.
class PdfEngine {
  const PdfEngine();
  Future<PdfRenderedDocument> render(
    PdfDocumentDefinition definition, {
    required PdfBranding branding,
    required ByteData regularFont,
    required ByteData boldFont,
    PdfPageConfig page = const PdfPageConfig(),
    PdfDocumentTheme theme = const PdfDocumentTheme(),
    PdfImageResult? logo,
  }) async {
    page.validate();
    definition.validate();
    try {
      final regular = pw.Font.ttf(regularFont), bold = pw.Font.ttf(boldFont);
      final context = PdfLayoutContext(
        branding: branding,
        page: page,
        theme: theme,
        logo: logo?.image,
        regularFont: regular,
      );
      final document = pw.Document(
        title: definition.title,
        author: branding.companyName,
        creator: 'Tame Your Biz',
      );
      document.addPage(
        pw.MultiPage(
          pageFormat: page.format,
          margin: pw.EdgeInsets.all(page.margin),
          maxPages: page.maxPages,
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
          header: (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              definition.reference,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          footer: (ctx) => pw.Column(
            children: [
              if (branding.footerText.isNotEmpty)
                pw.Text(
                  branding.footerText,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      definition.reference,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Text(
                    'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
          build: (_) => definition.compose(context),
        ),
      );
      final count = document.document.pdfPageList.pages.length;
      if (count > page.maxPages) {
        throw const PdfRenderFailure(
          'The document exceeds the supported page count.',
        );
      }
      final bytes = await document.save();
      return PdfRenderedDocument(
        bytes,
        count,
        List.unmodifiable([
          if (logo?.issue != null)
            'Company logo unavailable (${logo!.issue!.name}); company text was used.',
        ]),
      );
    } on PdfRenderFailure {
      rethrow;
    } on Object catch (error) {
      throw PdfRenderFailure(
        'The PDF could not be rendered completely.',
        cause: error,
      );
    }
  }
}
