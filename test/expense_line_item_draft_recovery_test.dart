import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_line_item_editor.dart';
import 'package:ui_lab_2_1/src/shared/local_draft_scope.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final rawPrice in ['3.25', '3.251234']) {
    testWidgets(
      'unfinished receipt item at $rawPrice survives parent and database reopen',
      (tester) async {
        final directory = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('expense-editor-recovery-'),
        ))!;
        var persistence = (await tester.runAsync(
          () => LocalPersistence.open(directory: directory),
        ))!;
        final scope = OperationalScopeController();
        late ExpenseUiRepositoryController controller;
        Future<void> mount() async {
          controller = ExpenseUiRepositoryController(
            ExpenseUiRepositoryBridge(
              service: AuthorizedExpenseService(persistence.expenses),
              employeeLabelForId: expenseUiLabEmployeeLabel,
              jobLabelForId: (_) => null,
            ),
            expenseUiLabOwnerPermissions(),
            drafts: persistence.drafts,
          );
          await tester.runAsync(controller.load);
          await tester.pumpWidget(
            LocalDraftScope(
              store: persistence.drafts,
              child: ExpenseUiScope(
                controller: controller,
                child: OperationalScope(
                  controller: scope,
                  child: MaterialApp(
                    theme: AppTheme.light,
                    home: Builder(
                      builder: (context) => Scaffold(
                        body: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ExpenseEditorScreen(
                                expenseDate: DateTime(2030, 1, 2),
                                initialReceiptType: ExpenseReceiptType.detailed,
                              ),
                            ),
                          ),
                          child: const Text('New expense'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('New expense'));
          await tester.pump();
        }

        final vendor = find.byKey(const ValueKey('expense-vendor-field'));
        await mount();
        await waitForNativeSave(tester, () => vendor.evaluate().isNotEmpty);
        await tester.enterText(vendor, '  Partial supplier  ');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final add = find.byKey(const ValueKey('add-expense-line-item'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        await tester.tap(add);
        await tester.pumpAndSettle();
        final description = find.byKey(
          const ValueKey('expense-line-description'),
        );
        final quantity = find.byKey(const ValueKey('expense-line-quantity'));
        final price = find.byKey(const ValueKey('expense-line-unit-price'));
        await tester.enterText(description, '  Copper fitting  ');
        await tester.ensureVisible(price);
        await tester.pumpAndSettle();
        await tester.enterText(price, rawPrice);
        await tester.ensureVisible(quantity);
        await tester.pumpAndSettle();
        await tester.enterText(quantity, '');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        Navigator.of(tester.element(description)).pop();
        await waitForNativeSave(
          tester,
          () => find.byType(ExpenseLineItemEditorScreen).evaluate().isEmpty,
        );
        final save = find.byKey(const ValueKey('save-expense-button'));
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Finish or discard the unfinished item before saving this expense.',
          ),
          findsOneWidget,
        );
        expect(controller.records, isEmpty);
        Navigator.of(tester.element(vendor)).pop();
        await waitForNativeSave(
          tester,
          () => find.byType(ExpenseEditorScreen).evaluate().isEmpty,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        controller.dispose();
        await tester.runAsync(() async {
          await persistence.close();
          persistence = await LocalPersistence.open(directory: directory);
        });
        await mount();
        await waitForNativeSave(
          tester,
          () => find
              .text('Continue an unfinished expense?')
              .evaluate()
              .isNotEmpty,
        );
        await tester.tap(find.text('  Partial supplier  '));
        await waitForNativeSave(tester, () => vendor.evaluate().isNotEmpty);
        final resume = find.text('Continue unfinished item');
        await tester.ensureVisible(resume);
        await tester.pumpAndSettle();
        await tester.tap(resume);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextFormField>(description).controller!.text,
          '  Copper fitting  ',
        );
        expect(tester.widget<TextFormField>(quantity).controller!.text, '');
        expect(tester.widget<TextFormField>(price).controller!.text, rawPrice);
        await tester.ensureVisible(quantity);
        await tester.pumpAndSettle();
        await tester.enterText(quantity, '2');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('save-expense-line-item')));
        await waitForNativeSave(
          tester,
          () => find.byType(ExpenseLineItemEditorScreen).evaluate().isEmpty,
        );
        expect(find.text('Continue unfinished item'), findsNothing);
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await waitForNativeSave(
          tester,
          () => find.byType(ExpenseEditorScreen).evaluate().isEmpty,
        );
        expect(
          controller.records.single.lineItems.single.description,
          'Copper fitting',
        );
        expect(controller.records.single.lineItems.single.quantity, 2);
        expect(
          controller.records.single.lineItems.single.unitPrice,
          double.parse(rawPrice),
        );
        expect(controller.records.single.amount, 6.5);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        controller.dispose();
        scope.dispose();
        await tester.runAsync(() async {
          await persistence.close();
          await directory.delete(recursive: true);
        });
        expect(tester.takeException(), isNull);
      },
    );
  }
}
