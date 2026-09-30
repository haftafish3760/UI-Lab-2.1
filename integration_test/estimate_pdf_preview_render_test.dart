import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';
import 'package:ui_lab_2_1/src/shared/documents/customer_document.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_pdf_assets.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_template.dart';

/// Isolated native rendering only: no company storage, sending, or screenshots.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native renderer opens all template previews without a company profile',
    () async {
      if (!const bool.fromEnvironment('STORAGE_QA'))
        throw StateError('Use isolated STORAGE_QA app');
      final document = CustomerDocument(
        kind: 'Estimate',
        number: 'QA-PREVIEW',
        title: 'Preview verification',
        company: '',
        companyDetails: '',
        customer: 'Test customer',
        customerDetails: '',
        date: DateTime(2026, 9, 29),
        items: const [],
        summarySubtotalCents: 25000,
        totalCents: 25000,
        terms: 'Test terms',
        description: 'Synthetic rendering check only.',
      );
      for (final template in DocumentTemplate.catalog) {
        final bytes = await generateCustomerPdf(
          document,
          templateId: template.id,
          previewOnly: true,
        );
        final pdf = await PdfDocument.openData(bytes);
        expect(pdf.pagesCount, greaterThan(0));
        final page = await pdf.getPage(1);
        final image = await page.render(
          width: 400,
          height: 400 * page.height / page.width,
        );
        expect(image?.bytes.length, greaterThan(100));
        await page.close();
        await pdf.close();
        final thumbnail = await Printing.raster(
          bytes,
          pages: [0],
          dpi: 40,
        ).first;
        expect((await thumbnail.toPng()).length, greaterThan(100));
        debugPrint('NATIVE_PDF_RENDER_PASS ${template.id}');
      }
    },
  );
}
