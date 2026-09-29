import 'dart:io';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_delivery_draft_workflow.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_pdf_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legacy ink remains readable and invalid thickness is rejected', () {
    final legacy = SignatureInk([
      [(0.1, 0.2), (0.8, 0.7)],
    ]);
    expect(SignatureInk.fromJson(legacy.toJson()).toJson(), legacy.toJson());
    for (final invalid in [double.nan, double.infinity, -1.0, 0.0, 9.0]) {
      expect(
        () => SignatureInk([], strokeWidth: invalid),
        throwsFormatException,
      );
    }
  });
  for (final thickness in [2.0, 3.0, 4.0]) {
    test(
      'signed PDF and delivery preserve $thickness thickness and approval',
      () async {
        final base = prototypeDemoWorkRecords().firstWhere(
          (r) => r.kind == WorkRecordKind.estimate,
        );
        final ink = SignatureInk([
          [(0.1, 0.6), (0.3, 0.2), (0.5, 0.8), (0.85, 0.4)],
        ], strokeWidth: thickness);
        final signed = base.recordEstimateSignature(
          'Test signer',
          DateTime.utc(2026, 9, 27),
          ink: SignatureInk.fromJson(ink.toJson()),
        );
        for (final method in [
          EstimateDeliveryMethod.email,
          EstimateDeliveryMethod.textMessage,
        ]) {
          final input =
              EstimateDeliveryInput.initial(
                    signed,
                    baseRevision: 0,
                    customers: const [],
                  )
                  .withMethod(method, '')
                  .withRecipient(
                    method == EstimateDeliveryMethod.email
                        ? 'test@example.invalid'
                        : '2025550123',
                  );
          final prepared = input.withReviewed(true).prepare().confirmedRecord();
          expect(prepared.hasCurrentCustomerSignature, isTrue);
          expect(prepared.customerSignature!.ink!.strokeWidth, thickness);
          expect(
            prepared.customerSignature!.signedOn,
            signed.customerSignature!.signedOn,
          );
        }
        final document = workCustomerDocument(signed, demoWorkCompany, null);
        expect(
          document.signatureSvg,
          contains('stroke-width="${thickness * 72 / 210}"'),
        );
        final bytes = await generateCustomerPdf(document);
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        await File(
          '/tmp/estimate-signed-${thickness.toInt()}.pdf',
        ).writeAsBytes(bytes);
      },
    );
  }
}
