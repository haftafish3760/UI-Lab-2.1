import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_entry_setup_input.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_entry_setup_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_entry_setup.dart';
import 'receipt_evidence_draft_workflow_test.dart'
    show openEvidenceSession, seedEvidence;

void main() {
  test(
    'returning receipt setup preserves evidence and text with atomic rollback',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'receipt-setup-return-',
      );
      final persistence = await LocalPersistence.open(directory: root);
      try {
        final session = await openEvidenceSession(persistence);
        final original = await seedEvidence(session, root);
        final edited = (await session.receipts.update(
          draftId: original.draftId,
          title: original.title,
          expenseDate: original.expenseDate,
          retainedEvidenceIds: original.activeEvidence.map((e) => e.evidenceId),
          addedEvidence: const [],
          occurredAtUtc: DateTime.now().toUtc(),
          expectedRevision: original.lifecycle.revision,
          entrySetup: const ReceiptEntrySetup(pastedText: 'unfinished 12.'),
        ))!;
        final setupInput = ExpenseEntrySetupInput(
          date: edited.expenseDate,
          category: ExpenseCategory.fuel,
          receiptType: ExpenseReceiptType.detailed,
          continuation: ExpenseSetupContinuation(
            destination: ExpenseSetupDestination.receipt,
            id: edited.draftId,
            revision: edited.lifecycle.revision,
          ),
        );
        final setup = await session.expenses.openEntrySetup(
          initial: setupInput,
        );
        final stale = await session.expenses.openEntrySetup(
          initial: setupInput,
        );
        await setup.session.flush();
        await stale.session.flush();
        await persistence.database.customStatement(
          "CREATE TRIGGER fail_receipt_return BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        await expectLater(
          session.continueExpenseSetup(setup),
          throwsA(anything),
        );
        expect(
          (await session.receipts.findById(
            draftId: edited.draftId,
          )).record!.toJson(),
          edited.toJson(),
        );
        await persistence.database.customStatement(
          'DROP TRIGGER fail_receipt_return',
        );
        final result = await session.continueExpenseSetup(setup);
        expect(result.draftId, edited.draftId);
        expect(
          result.evidence.map((e) => e.toJson()).toList(),
          edited.evidence.map((e) => e.toJson()).toList(),
        );
        expect(result.entrySetup!.pastedText, 'unfinished 12.');
        expect(result.entrySetup!.category, ExpenseCategory.fuel);
        expect(result.lifecycle.revision, edited.lifecycle.revision + 1);
        await expectLater(
          session.continueExpenseSetup(stale),
          throwsA(anything),
        );
        expect(session.receipts.records, hasLength(1));
        expect(session.expenses.records, isEmpty);
        await setup.session.close();
        await stale.session.close();
      } finally {
        await persistence.close();
        await root.delete(recursive: true);
      }
    },
  );
  test(
    'receipt continuation rolls back setup consumption and retries once across reopen',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'expense-setup-receipt-',
      );
      var persistence = await LocalPersistence.open(directory: root);
      try {
        final session = await openEvidenceSession(persistence);
        final setup = await session.expenses.openEntrySetup(
          initial: ExpenseEntrySetupInput(
            date: DateTime(2030, 2, 3),
            category: ExpenseCategory.fuel,
            receiptType: ExpenseReceiptType.detailed,
          ),
        );
        await setup.session.flush();
        await persistence.database.customStatement(
          "CREATE TRIGGER fail_setup_transfer BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        await expectLater(
          session.continueExpenseSetup(setup),
          throwsA(anything),
        );
        expect(
          await persistence.database
              .select(persistence.database.localDrafts)
              .get(),
          hasLength(1),
        );
        expect(session.receipts.records, isEmpty);
        expect(
          await persistence.database
              .select(persistence.database.localRecords)
              .get(),
          isEmpty,
        );
        await persistence.database.customStatement(
          'DROP TRIGGER fail_setup_transfer',
        );
        final receipt = await session.continueExpenseSetup(setup);
        expect(receipt.entrySetup!.category, ExpenseCategory.fuel);
        expect(receipt.entrySetup!.type, ExpenseReceiptType.detailed);
        expect(receipt.activeEvidence, isEmpty);
        await expectLater(
          session.continueExpenseSetup(setup),
          throwsStateError,
        );
        await setup.session.close();
        await persistence.close();
        persistence = await LocalPersistence.open(directory: root);
        final reopened = await openEvidenceSession(persistence);
        expect(reopened.receipts.records, hasLength(1));
        expect(reopened.receipts.records.single.draftId, receipt.draftId);
        expect(
          reopened.receipts.records.single.entrySetup!.category,
          ExpenseCategory.fuel,
        );
        expect(reopened.expenses.records, isEmpty);
        expect(
          await persistence.database
              .select(persistence.database.localDrafts)
              .get(),
          isEmpty,
        );
      } finally {
        await persistence.close();
        await root.delete(recursive: true);
      }
    },
  );
}
