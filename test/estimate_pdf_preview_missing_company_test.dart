import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_pdf_assets.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_template.dart';
import 'estimate_service_price_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'missing company permits every preview but blocks outgoing PDF with clear reason',
    () async {
      final data = workCustomerDocument(
        buildConfirmedEstimate(
          fixtures.priceInput('250'),
          now: DateTime(2026, 9, 29),
        ),
        emptyCompanyProfile,
        null,
      );
      expect(data.company, isEmpty);
      for (final template in DocumentTemplate.catalog) {
        final bytes = await generateCustomerPdf(
          data,
          templateId: template.id,
          previewOnly: true,
        );
        expect(
          String.fromCharCodes(bytes.take(5)),
          '%PDF-',
          reason: template.id,
        );
      }
      await expectLater(
        generateCustomerPdf(data),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'reason',
            contains('business name'),
          ),
        ),
      );
    },
  );
}
