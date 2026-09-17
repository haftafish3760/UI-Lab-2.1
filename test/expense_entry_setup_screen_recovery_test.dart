import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_entry_setup_input.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_entry_setup_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_entry_choice_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_choice_card.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'setup screen restores detail and pending category after SQLite reopen',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      final initial = ExpenseEntrySetupInput(
        date: DateTime(2030),
        category: ExpenseCategory.uncategorized,
        receiptType: ExpenseReceiptType.basic,
      );
      var workflow = (await tester.runAsync(
        () => ExpenseEntrySetupWorkflow.open(
          repository: LocalDraftStore(db),
          organizationId: 'company',
          ownerId: 'owner',
          initial: initial,
          authorize: () {},
        ),
      ))!;
      Future<void> mount() => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ExpenseEntryChoiceScreen(
            canAttachReceipt: true,
            workflow: workflow,
          ),
        ),
      );
      try {
        await mount();
        await tester.tap(
          find.byKey(const ValueKey('receipt-every-item-choice')),
        );
        final category = find.byKey(const ValueKey('choose-receipt-category'));
        await tester.ensureVisible(category);
        await tester.pumpAndSettle();
        await tester.tap(category);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Fuel').first);
        await waitForNativeSave(
          tester,
          () => workflow.session.savedRevision >= 3,
        );
        final id = workflow.session.draftId;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(workflow.session.close);
        await tester.runAsync(() => harness.close(db));
        db = (await tester.runAsync(harness.open))!;
        workflow = (await tester.runAsync(
          () => ExpenseEntrySetupWorkflow.open(
            repository: LocalDraftStore(db),
            organizationId: 'company',
            ownerId: 'owner',
            initial: initial,
            authorize: () {},
            recoveryDraftId: id,
          ),
        ))!;
        await mount();
        expect(
          tester
              .widget<ReceiptChoiceCard>(
                find.byKey(const ValueKey('receipt-every-item-choice')),
              )
              .selected,
          isTrue,
        );
        expect(workflow.input.pendingCategory, ExpenseCategory.fuel);
        expect(workflow.input.category, ExpenseCategory.uncategorized);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(workflow.session.close);
        await tester.runAsync(harness.dispose);
      }
    },
  );
}
