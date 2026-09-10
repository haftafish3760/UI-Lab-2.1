import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_payment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_payment_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'payment catalog reopens partial amount and identity with current balance without posting',
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
      final original = await work.openInvoicePaymentDraft(
        invoiceId: invoice.id,
        initialDay: DateTime(2026, 9, 10),
      );
      final balance = original.balanceCents;
      original.updateInput(
        original.input.withValues(
          amount: '12.',
          note: '  Still typing  ',
          method: 'Check',
          receivedOn: DateTime(2026, 9, 8),
        ),
      );
      await original.session.close();
      final raw = original.session.input;
      expect(
        await work.save(
          financialEntries: [
            PrototypeFinancialEntry(
              id: 'other-payment',
              kind: PrototypeFinancialKind.paymentReceived,
              occurredOn: DateTime(2026, 9, 10),
              amountCents: 100,
              sourceId: invoice.number,
            ),
          ],
        ),
        isTrue,
      );
      final count = work.financialEntries.length;
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      final recovery = InvoicePaymentDraftRecovery(work);
      final entry = (await recovery.list()).single;
      expect(entry.preview.availability, DraftRecoveryAvailability.recoverable);
      final resumed = await recovery.resume(entry);
      expect(resumed.session.input, raw);
      expect(resumed.session.savedRevision, entry.revision);
      expect(resumed.balanceCents, balance - 100);
      await expectLater(
        resumed.confirm(),
        throwsA(isA<InvoicePaymentInputValidation>()),
      );
      expect(work.financialEntries, hasLength(count));
      await resumed.session.close();
    },
  );
  test(
    'payment selected revisions and discard cannot recreate consumed input',
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
      final original = await work.openInvoicePaymentDraft(
        invoiceId: invoice.id,
        initialDay: DateTime(2026, 9, 10),
      );
      await original.session.close();
      final recovery = InvoicePaymentDraftRecovery(work);
      final entry = (await recovery.list()).single;
      Future<Object> open(int revision) => work.openInvoicePaymentDraft(
        invoiceId: invoice.id,
        initialDay: DateTime(2026, 9, 10),
        recoverySelection: DraftRecoverySelection(
          domain: entry.domain,
          draftId: entry.draftId,
          revision: revision,
        ),
      );
      await expectLater(
        open(entry.revision + 1),
        throwsA(isA<LocalRecordConflict>()),
      );
      await recovery.discard(entry);
      await expectLater(
        open(entry.revision),
        throwsA(isA<LocalRecordConflict>()),
      );
      expect(await recovery.list(), isEmpty);
    },
  );
  test(
    'already recorded payment identity stays a conflict rather than posting it again',
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
      final original = await work.openInvoicePaymentDraft(
        invoiceId: invoice.id,
        initialDay: DateTime(2026, 9, 10),
      );
      await original.session.close();
      expect(
        await work.save(
          financialEntries: [
            PrototypeFinancialEntry(
              id: original.input.paymentId,
              kind: PrototypeFinancialKind.paymentReceived,
              occurredOn: original.input.receivedOn,
              amountCents: 100,
              sourceId: invoice.number,
            ),
          ],
        ),
        isTrue,
      );
      final recovery = InvoicePaymentDraftRecovery(work);
      final entry = (await recovery.list()).single;
      expect(entry.preview.availability, DraftRecoveryAvailability.conflict);
      await expectLater(recovery.resume(entry), throwsStateError);
      expect(await recovery.list(), hasLength(1));
    },
  );
}
