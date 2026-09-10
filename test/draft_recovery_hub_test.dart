import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_hub.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_review_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_workflow_draft_recovery.dart';
import 'receipt_evidence_draft_workflow_test.dart'
    show openEvidenceSession, seedEvidence;
import 'expense_draft_workflow_test.dart' show initialExpense, change;

void main() {
  test(
    'hub preserves native catalog ownership and recovery despite provider failure',
    () async {
      final dir = await Directory.systemTemp.createTemp('recovery-hub-');
      var p = await LocalPersistence.open(directory: dir);
      addTearDown(() async {
        await p.close();
        await dir.delete(recursive: true);
      });
      var app = await openEvidenceSession(p);
      await seedEvidence(app, dir);
      final expense = await app.expenses.openExpenseDraft(
        initial: initialExpense(),
      );
      expense.updateInput(
        change(expense.input, {'vendor': 'Manual unfinished', 'amount': '-'}),
      );
      await expense.session.close();
      final receipt = await app.openReviewDraft(
        receiptId: 'receipt',
        initial: initialExpense(),
      );
      receipt.updateInput(
        change(receipt.input, {
          'vendor': 'Receipt unfinished',
          'amount': '12.',
        }),
      );
      await receipt.session.close();
      await p.close();
      p = await LocalPersistence.open(directory: dir);
      app = await openEvidenceSession(p);
      final expenses = ExpenseDraftRecovery(app.expenses);
      final receipts = ReceiptWorkflowDraftRecovery(app);
      final providers = [
        DraftRecoveryProvider<Object>(
          id: 'expenses',
          label: 'Expenses',
          list: expenses.list,
          resume: expenses.resume,
          discard: expenses.discard,
        ),
        DraftRecoveryProvider<Object>(
          id: 'receipts',
          label: 'Receipts',
          list: receipts.list,
          resume: receipts.resume,
          discard: receipts.discard,
        ),
        DraftRecoveryProvider<Object>(
          id: 'offline',
          label: 'Unavailable workflow',
          list: () async => throw StateError('private storage path'),
          resume: (_) async => throw StateError('unused'),
          discard: (_) async => throw StateError('unused'),
        ),
      ];
      final hub = DraftRecoveryHub(providers);
      final listing = await hub.list();
      expect(listing.isComplete, isFalse);
      expect(listing.entries, hasLength(2));
      expect(listing.unavailableProviders.single.providerId, 'offline');
      expect(() => listing.entries.clear(), throwsUnsupportedError);
      final otherHub = DraftRecoveryHub(providers);
      for (final entry in listing.entries) {
        await expectLater(otherHub.resume(entry), throwsStateError);
        await expectLater(otherHub.discard(entry), throwsStateError);
        final resumed = await hub.resume(entry);
        if (resumed is ExpenseDraftController) {
          expect(resumed.input.amount, '-');
          await resumed.session.close();
        } else {
          final review = resumed as ResumedReceiptReview;
          expect(review.controller.input.amount, '12.');
          await review.controller.session.close();
        }
      }
      expect(app.expenses.records, isEmpty);
      expect(app.receipts.records.single.activeEvidence, hasLength(2));
      final selected = listing.entries.singleWhere(
        (e) => e.providerId == 'expenses',
      );
      final concurrent = await hub.resume(selected) as ExpenseDraftController;
      concurrent.updateInput(
        change(concurrent.input, {'vendor': 'Newer input'}),
      );
      await concurrent.session.close();
      await expectLater(hub.discard(selected), throwsA(anything));
      final refreshed = (await hub.list()).entries.singleWhere(
        (e) => e.providerId == 'expenses',
      );
      expect(refreshed.title, 'Newer input');
      await hub.discard(refreshed);
      await expectLater(hub.resume(refreshed), throwsA(anything));
      expect((await hub.list()).entries.single.providerId, 'receipts');
      expect(
        () => DraftRecoveryHub([providers.first, providers.first]),
        throwsArgumentError,
      );
    },
  );
}
