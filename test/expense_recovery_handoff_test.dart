import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_review_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_submission_session.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'receipt_evidence_draft_workflow_test.dart'
    show openEvidenceSession, seedEvidence;
import 'expense_draft_workflow_test.dart' show initialExpense, change;
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final receipt in [false, true]) {
    testWidgets(
      'expense receipt=$receipt accepts selected workflow and retains raw edits on exit',
      (tester) async {
        final fixture = (await tester.runAsync(() async {
          final dir = await Directory.systemTemp.createTemp('expense-handoff-');
          final p = await LocalPersistence.open(directory: dir);
          final app = await openEvidenceSession(p);
          ExpenseDraftController? expense;
          ReceiptReviewDraftController? review;
          if (receipt) {
            await seedEvidence(app, dir);
            review = await app.openReviewDraft(
              receiptId: 'receipt',
              initial: initialExpense(),
            );
            review.updateInput(
              change(review.input, {
                'vendor': 'Selected receipt',
                'amount': '12.',
              }),
            );
            await review.session.flush();
          } else {
            expense = await app.expenses.openExpenseDraft(
              initial: initialExpense(),
            );
            expense.updateInput(
              change(expense.input, {
                'vendor': 'Selected expense',
                'amount': '12.',
              }),
            );
            await expense.session.flush();
          }
          return (dir: dir, p: p, app: app, expense: expense, review: review);
        }))!;
        final scope = OperationalScopeController();
        final session = fixture.expense?.session ?? fixture.review!.session;
        try {
          await tester.pumpWidget(
            ExpenseUiScope(
              controller: fixture.app.expenses,
              child: ReceiptSubmissionScope(
                session: fixture.app,
                child: OperationalScope(
                  controller: scope,
                  child: MaterialApp(
                    theme: AppTheme.light,
                    home: ExpenseEditorScreen(
                      expenseDate: DateTime(2030, 1, 2),
                      receiptDraftId: receipt ? 'receipt' : null,
                      purpose: receipt
                          ? ExpenseEditorPurpose.receiptReview
                          : ExpenseEditorPurpose.manualEntry,
                      recoveredExpenseWorkflow: fixture.expense,
                      recoveredReceiptWorkflow: fixture.review,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final vendor = find.byKey(const ValueKey('expense-vendor-field'));
          await waitForNativeSave(tester, () => vendor.evaluate().isNotEmpty);
          expect(
            tester.widget<TextFormField>(vendor).controller!.text,
            receipt ? 'Selected receipt' : 'Selected expense',
          );
          expect(find.text('Continue an unfinished expense?'), findsNothing);
          expect(session.input['amount'], '12.');
          await tester.enterText(vendor, 'Updated selected input');
          await tester.pump();
          await waitForNativeSave(
            tester,
            () => find.text('Draft saved on this device').evaluate().isNotEmpty,
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(() async {
            await session.close();
            final saved = (await fixture.p.drafts.find(
              organizationId: session.organizationId,
              ownerId: session.ownerId,
              domain: session.domain,
              draftId: session.draftId,
            ))!;
            expect(
              fixture.p.drafts.decode(saved)['vendor'],
              'Updated selected input',
            );
            expect(fixture.p.drafts.decode(saved)['amount'], '12.');
          });
          expect(fixture.app.expenses.records, isEmpty);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          scope.dispose();
          await tester.runAsync(() async {
            await session.close();
            await fixture.p.close();
            await fixture.dir.delete(recursive: true);
          });
        }
      },
    );
  }
}
