import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/payment_receipt_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'standalone saved payment produces a customer receipt without an invoice',
    () async {
      final payment = PrototypeFinancialEntry(
        id: 'private-payment-id',
        kind: PrototypeFinancialKind.paymentReceived,
        occurredOn: DateTime(2026, 9, 26),
        amountCents: 2750,
        sourceId: '',
        paymentLinkKind: PaymentLinkKind.none,
        payerName: 'Casey Green',
        description: 'Lawn mowing',
        paymentMethod: 'Cash',
        note: 'Internal note only',
      );
      final document = paymentReceiptData(
        organizationId: 'test-business',
        payment: payment,
        company: demoWorkCompany,
      );
      expect(
        document.reference,
        paymentReceiptReference('test-business', payment.id),
      );
      expect(document.reference, isNot(contains(payment.id)));
      expect(document.amountCents, 2750);
      expect(document.payer, 'Casey Green');
      expect(document.linkedWork, isNull);
      final bytes = await generatePaymentReceiptPdf(document);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    },
  );

  test('a ledger application cannot be printed as new money received', () {
    final application = PrototypeFinancialEntry(
      id: 'application',
      kind: PrototypeFinancialKind.paymentApplied,
      occurredOn: DateTime(2026, 9, 26),
      amountCents: 2750,
      sourceId: 'invoice-1',
      sourcePaymentId: 'original-payment',
      paymentMethod: 'Cash',
    );
    expect(
      () => paymentReceiptData(
        organizationId: 'test-business',
        payment: application,
        company: demoWorkCompany,
      ),
      throwsArgumentError,
    );
  });

  test('a linked customer is not falsely named as the payer', () {
    final payment = PrototypeFinancialEntry(
      id: 'job-payment',
      kind: PrototypeFinancialKind.paymentReceived,
      occurredOn: DateTime(2026, 9, 26),
      amountCents: 5000,
      sourceId: 'job-1',
      paymentLinkKind: PaymentLinkKind.job,
      paymentMethod: 'Cash',
    );
    const job = WorkRecord(
      id: 'job-1',
      kind: WorkRecordKind.job,
      number: 'Job 1',
      title: 'Lawn mowing',
      client: 'Property owner',
      detail: '',
      pricing: WorkPricingModel.flatRate,
    );
    final document = paymentReceiptData(
      organizationId: 'test-business',
      payment: payment,
      company: demoWorkCompany,
      linkedWork: job,
    );
    expect(document.payer, isEmpty);
    expect(document.linkedWork, contains('Job 1'));
  });
}
