import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_payment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'payment raw input and identity survive reopen and rollback; retry posts exactly once',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      final invoice = work.records.firstWhere(
        (r) =>
            r.kind == WorkRecordKind.invoice &&
            r.status == WorkRecordStatus.due,
      );
      var workflow = await work.openInvoicePaymentDraft(
        invoiceId: invoice.id,
        initialDay: DateTime(2026, 9, 10),
      );
      final originalBalance = workflow.balanceCents;
      final originalRevision = work.storageRevisionFor(invoice.id);
      final ledgerCount = work.financialEntries.length;
      final paymentId = workflow.input.paymentId;
      workflow.updateInput(
        workflow.input.withValues(
          amount: '12.',
          note: '  Reference  ',
          method: 'Check',
          receivedOn: DateTime(2026, 9, 8),
        ),
      );
      await expectLater(
        workflow.confirm(),
        throwsA(isA<InvoicePaymentInputValidation>()),
      );
      final raw = workflow.session.input;
      await workflow.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      workflow = await work.openInvoicePaymentDraft(
        invoiceId: invoice.id,
        initialDay: DateTime(2026, 10, 1),
      );
      expect(workflow.session.input, raw);
      workflow.updateInput(
        workflow.input.withValues(
          amount: '12.00',
          note: workflow.input.note,
          method: workflow.input.method,
          receivedOn: workflow.input.receivedOn,
        ),
      );
      await db.customStatement(
        "CREATE TRIGGER reject_payment BEFORE INSERT ON local_records WHEN NEW.domain = 'work/ledger' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isNull);
      expect(workflow.balanceCents, originalBalance);
      expect(work.storageRevisionFor(invoice.id), originalRevision);
      expect(work.financialEntries.length, ledgerCount);
      expect(workflow.input.paymentId, paymentId);
      await db.customStatement('DROP TRIGGER reject_payment');
      final payment = (await workflow.confirm())!;
      expect(payment.id, paymentId);
      expect(payment.amountCents, 1200);
      expect(payment.note, 'Reference');
      expect(payment.paymentMethod, 'Check');
      expect(payment.occurredOn, DateTime(2026, 9, 8));
      expect(payment.sourceId, invoice.number);
      expect(workflow.balanceCents, originalBalance - 1200);
      expect(work.storageRevisionFor(invoice.id), originalRevision + 1);
      expect(work.financialEntries.length, ledgerCount + 1);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );

  test(
    'payment confirmation rechecks changed balance and preserves oversized input until corrected',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final invoice = work.records.firstWhere(
        (r) =>
            r.kind == WorkRecordKind.invoice &&
            r.status == WorkRecordStatus.due,
      );
      final workflow = await work.openInvoicePaymentDraft(
        invoiceId: invoice.id,
        initialDay: DateTime(2026, 9, 10),
      );
      await workflow.session.flush();
      final raw = workflow.session.input;
      final balance = workflow.balanceCents;
      expect(
        await work.save(
          financialEntries: [
            PrototypeFinancialEntry(
              id: 'concurrent-payment',
              kind: PrototypeFinancialKind.paymentReceived,
              occurredOn: DateTime(2026, 9, 10),
              amountCents: 100,
              sourceId: invoice.number,
            ),
          ],
        ),
        isTrue,
      );
      expect(workflow.balanceCents, balance - 100);
      await expectLater(
        workflow.confirm(),
        throwsA(isA<InvoicePaymentInputValidation>()),
      );
      expect(workflow.session.input, raw);
      workflow.updateInput(
        workflow.input.withValues(
          amount: ((balance - 100) / 100).toStringAsFixed(2),
          note: '',
          method: 'Card',
          receivedOn: workflow.input.receivedOn,
        ),
      );
      expect(await workflow.confirm(), isNotNull);
      expect(workflow.balanceCents, 0);
      expect(
        work.records.singleWhere((r) => r.id == invoice.id).status,
        WorkRecordStatus.paid,
      );
      await workflow.session.close();
      await expectLater(
        work.openInvoicePaymentDraft(
          invoiceId: 'missing',
          initialDay: DateTime(2026, 9, 10),
        ),
        throwsA(isA<InvoicePaymentInputValidation>()),
      );
    },
  );
}
