import 'dart:typed_data';
import '../../../shared/documents/pdf/pdf_engine.dart';
import '../../../shared/documents/pdf/pdf_branding.dart';
import '../../../shared/documents/pdf/pdf_configuration.dart';
import '../../../shared/documents/pdf/pdf_image_resolver.dart';
import 'work_pdf_definition.dart';
import 'customer_document.dart';
import 'document_template.dart';

/// Work compatibility adapter; the only rendering engine is the shared PdfEngine.
class CustomerPdfGenerator {
  const CustomerPdfGenerator();
  Future<Uint8List> generate(
    CustomerDocument data, {
    required ByteData regularFont,
    required ByteData boldFont,
    Uint8List? artwork,
    Uint8List? panelArtwork,
    Uint8List? pageArtwork,
    String? templateId,
    bool previewOnly = false,
    PdfImageResult? logo,
  }) async {
    final template = DocumentTemplate.resolve(templateId ?? data.templateId);
    return (await const PdfEngine().render(
      WorkPdfDefinition(
        data,
        previewOnly: previewOnly,
        artwork: artwork,
        layout: template.layout,
        panelArtwork: panelArtwork,
        pageArtwork: pageArtwork,
      ),
      branding:
          data.branding ??
          PdfBranding(companyName: data.company, address: data.companyDetails),
      regularFont: regularFont,
      boldFont: boldFont,
      logo: logo,
      page: PdfPageConfig(
        landscape: template.landscape,
        margin: template.layout.index >= DocumentLayout.masonry.index ? 52 : 32,
      ),
      theme: PdfDocumentTheme(
        accent: data.branding?.accentColor ?? template.accent,
        printerFriendly: template.printerFriendly,
      ),
    )).bytes;
  }
}
