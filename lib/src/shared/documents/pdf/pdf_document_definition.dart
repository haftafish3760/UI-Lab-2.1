import 'package:pdf/widgets.dart' as pw;
import 'pdf_branding.dart';
import 'pdf_configuration.dart';
import 'pdf_image_resolver.dart';

/// Composition uses the PDF package's widgets, not a new document language.
/// Feature builders own validation, labels, calculations and section ordering.
abstract class PdfDocumentDefinition {
  String get title;
  String get reference;
  DateTime? get createdAt => null;
  void validate();
  List<pw.Widget> compose(PdfLayoutContext context);
}

class PdfLayoutContext {
  const PdfLayoutContext({
    required this.branding,
    required this.page,
    required this.theme,
    required this.regularFont,
    this.logo,
  });
  final PdfBranding branding;
  final PdfPageConfig page;
  final PdfDocumentTheme theme;
  final pw.Font regularFont;
  final PdfResolvedImage? logo;
}
