import 'package:flutter/services.dart';
import '../../../shared/documents/document_image_scope.dart';
import '../../../shared/documents/pdf/pdf_font_assets.dart';
import '../../../shared/documents/pdf/pdf_image_resolver.dart';
import 'customer_document.dart';
import 'customer_pdf_generator.dart';
import 'document_template.dart';

Future<Uint8List> generateCustomerPdf(
  CustomerDocument document, {
  String? templateId,
  DocumentImageLoader? logoLoader,
}) async {
  final template = DocumentTemplate.resolve(templateId ?? document.templateId);
  final fonts = await PdfFontAssets.load();
  final art = template.artAsset == null
      ? null
      : await rootBundle.load(template.artAsset!);
  final reference = document.branding?.logoReference;
  final logo = reference == null
      ? null
      : await const PdfImageResolver().resolve(
          () async => logoLoader == null ? null : await logoLoader(reference),
        );
  return const CustomerPdfGenerator().generate(
    document,
    regularFont: fonts.regular,
    boldFont: fonts.bold,
    logo: logo,
    artwork: art?.buffer.asUint8List(art.offsetInBytes, art.lengthInBytes),
    templateId: template.id,
  );
}
