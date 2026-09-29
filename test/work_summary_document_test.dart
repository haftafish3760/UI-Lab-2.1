import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_template_document.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_pdf_assets.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_template.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'work_document_presentation_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'summary excludes item detail from public projection and keeps total',
    () {
      final record = buildConfirmedEstimate(
        fixtures.input(WorkDocumentPresentation.summary),
        now: DateTime(2026, 9, 28),
      );
      final document = workCustomerDocument(record, demoWorkCompany, null);
      expect(document.isSummary, isTrue);
      expect(document.items, isEmpty);
      expect(document.subtotalCents, 4000);
      expect(document.totalCents, 4000);
      final publicPayload = document.toPortalJson().toString();
      expect(publicPayload, isNot(contains('2 x 4 lumber')));
      expect(publicPayload, isNot(contains('Framing timber')));
      expect(publicPayload, isNot(contains('internalUnitCost')));
      expect(record.items.single.name, '2 x 4 lumber');
      final preview = estimateTemplateDocument(
        fixtures.input(WorkDocumentPresentation.summary),
        demoWorkCompany,
      );
      expect(preview.items, isEmpty);
      expect(preview.subtotalCents, document.subtotalCents);
    },
  );
  test(
    'every existing template generates a summary PDF without item rows',
    () async {
      final record = buildConfirmedEstimate(
        fixtures.input(WorkDocumentPresentation.summary),
        now: DateTime(2026, 9, 28),
      );
      final document = workCustomerDocument(record, demoWorkCompany, null);
      for (final template in DocumentTemplate.catalog) {
        final bytes = await generateCustomerPdf(
          document,
          templateId: template.id,
        );
        expect(
          String.fromCharCodes(bytes.take(5)),
          '%PDF-',
          reason: template.id,
        );
        expect(bytes.length, greaterThan(1000), reason: template.id);
      }
    },
  );
  test(
    'detailed customer documents retain descriptions and quantities but no costs',
    () {
      final record = buildConfirmedEstimate(
        fixtures.input(WorkDocumentPresentation.detailed),
        now: DateTime(2026, 9, 28),
      );
      final document = workCustomerDocument(record, demoWorkCompany, null);
      expect(document.isSummary, isFalse);
      expect(document.items.single.name, '2 x 4 lumber');
      expect(document.items.single.quantity, 4);
      expect(
        document.toPortalJson().toString(),
        isNot(contains('internalUnitCost')),
      );
    },
  );
}
