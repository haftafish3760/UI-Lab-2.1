import 'dart:io';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_submission_session.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_entry_flow.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_intake_screen.dart';
import 'receipt_evidence_draft_workflow_test.dart' show openEvidenceSession;
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final withReceipt in [true, false]) {
    testWidgets(
      'Back returns to setup and reuses saved work, receipt: $withReceipt',
      (tester) async {
        final root = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('expense-back-'),
        ))!;
        final persistence = (await tester.runAsync(
          () => LocalPersistence.open(directory: root),
        ))!;
        final session = (await tester.runAsync(
          () => openEvidenceSession(persistence),
        ))!;
        final operations = OperationalScopeController();
        addTearDown(operations.dispose);
        try {
          await tester.pumpWidget(
            ExpenseUiScope(
              controller: session.expenses,
              child: ReceiptSubmissionScope(
                session: session,
                child: MaterialApp(
                  builder: (context, child) => OperationalScope(
                    controller: operations,
                    child: ReceiptDraftUiScope(
                      controller: session.receipts,
                      child: child!,
                    ),
                  ),
                  home: Builder(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () => openExpenseEntryFlow(
                          context,
                          expenseDate: DateTime(2030),
                          permissions: ExpensePermissions(
                            canView: true,
                            canViewAmounts: true,
                            canCreate: true,
                            canAttachReceipt: withReceipt,
                            canEditOwn: true,
                            canEditTeam: true,
                            canReviewCompanyExpenses: true,
                            canManageScheduledExpenses: true,
                            canConfigureDisplay: true,
                          ),
                          onConfirm: (r) async => r,
                        ),
                        child: const Text('Start'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Start'));
          final next = find.byKey(const ValueKey('continue-expense-setup'));
          await waitForNativeSave(tester, () => next.evaluate().isNotEmpty);
          await tester.ensureVisible(next);
          await tester.tap(next);
          await waitForNativeSave(
            tester,
            () => find
                .byType(withReceipt ? ReceiptIntakeScreen : ExpenseEditorScreen)
                .evaluate()
                .isNotEmpty,
          );
          final id = withReceipt
              ? session.receipts.records.single.draftId
              : tester
                    .widget<ExpenseEditorScreen>(
                      find.byType(ExpenseEditorScreen),
                    )
                    .recoveredExpenseWorkflow!
                    .session
                    .draftId;
          if (!withReceipt) {
            final vendor = find.byKey(const ValueKey('expense-vendor-field'));
            await tester.ensureVisible(vendor);
            await tester.enterText(vendor, 'Unfinished vendor');
            final amount = find.byKey(const ValueKey('expense-amount-field'));
            await tester.ensureVisible(amount);
            await tester.enterText(amount, '12.');
            await finishNativeOperation(
              tester,
              tester
                  .widget<ExpenseEditorScreen>(find.byType(ExpenseEditorScreen))
                  .recoveredExpenseWorkflow!
                  .session
                  .flush,
            );
          }
          await tester.runAsync(
            () => persistence.database.customStatement(
              "CREATE TRIGGER fail_setup_return BEFORE INSERT ON local_drafts WHEN NEW.domain = 'expenses/entry-setup' BEGIN SELECT RAISE(ABORT, 'injected'); END",
            ),
          );
          await tester.binding.handlePopRoute();
          await waitForNativeSave(
            tester,
            () => find.byType(SnackBar).evaluate().isNotEmpty,
          );
          await tester.runAsync(
            () => persistence.database.customStatement(
              'DROP TRIGGER fail_setup_return',
            ),
          );
          ScaffoldMessenger.of(tester.element(next)).removeCurrentSnackBar();
          await tester.pumpAndSettle();
          // First retry recovers setup from the already committed destination.
          await tester.ensureVisible(next);
          await tester.tap(next);
          await tester.pump();

          await waitForNativeSave(
            tester,
            () =>
                next.evaluate().isNotEmpty &&
                tester.widget<FilledButton>(next).onPressed != null,
          );
          await tester.ensureVisible(next);
          await tester.tap(next);
          await waitForNativeSave(
            tester,
            () => find
                .byType(withReceipt ? ReceiptIntakeScreen : ExpenseEditorScreen)
                .evaluate()
                .isNotEmpty,
          );
          if (withReceipt) {
            expect(session.receipts.records.single.draftId, id);
          } else {
            final restored = tester
                .widget<ExpenseEditorScreen>(find.byType(ExpenseEditorScreen))
                .recoveredExpenseWorkflow!;
            expect(restored.session.draftId, id);
            expect(restored.input.vendor, 'Unfinished vendor');
            expect(restored.input.amount, '12.');
          }
          expect(session.expenses.records, isEmpty);
          expect(tester.takeException(), isNull);
          if (!withReceipt) {
            final amount = find.byKey(const ValueKey('expense-amount-field'));
            await tester.ensureVisible(amount);
            await tester.enterText(amount, '12.50');
            final save = find.byKey(const ValueKey('save-expense-button'));
            await tester.ensureVisible(save);
            await tester.pumpAndSettle();
            await tester.tap(save);
            await waitForNativeSave(
              tester,
              () => find.text('Start').evaluate().isNotEmpty,
            );
            expect(session.expenses.records, hasLength(1));
            expect(session.expenses.records.single.amount, 12.50);
            expect(
              await tester.runAsync(
                () => persistence.database
                    .select(persistence.database.localDrafts)
                    .get(),
              ),
              isEmpty,
            );
            return;
          }
          await tester.tap(find.byKey(const ValueKey('receipt-source-text')));
          final manualEntry = find.byKey(
            const ValueKey('manual-receipt-entry'),
          );
          await waitForNativeSave(
            tester,
            () => manualEntry.evaluate().isNotEmpty,
          );
          await tester.ensureVisible(manualEntry);
          await tester.tap(manualEntry);
          final receiptAmount = find.byKey(
            const ValueKey('expense-amount-field'),
          );
          await waitForNativeSave(
            tester,
            () => receiptAmount.evaluate().isNotEmpty,
          );
          await tester.ensureVisible(receiptAmount);
          await tester.enterText(receiptAmount, '23.45');
          final saveReceipt = find.byKey(const ValueKey('save-expense-button'));
          await tester.ensureVisible(saveReceipt);
          await tester.pumpAndSettle();
          await tester.tap(saveReceipt);
          await waitForNativeSave(
            tester,
            () => find.text('Start').evaluate().isNotEmpty,
          );
          expect(session.expenses.records, hasLength(1));
          expect(session.expenses.records.single.amount, 23.45);
          final submitted = (await tester.runAsync(
            () => session.receipts.findById(draftId: id, includeClosed: true),
          ))!.record!;
          expect(
            submitted.submittedExpenseId,
            session.expenses.records.single.id,
          );
          expect(
            await tester.runAsync(
              () => persistence.database
                  .select(persistence.database.localDrafts)
                  .get(),
            ),
            isEmpty,
          );
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(persistence.close);
          await tester.runAsync(() => root.delete(recursive: true));
        }
      },
    );
  }
}
