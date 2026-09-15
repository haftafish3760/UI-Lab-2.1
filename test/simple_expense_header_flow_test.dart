import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final amount in ['', '0.00', '24.50']) {
    testWidgets(
      'Simple expense saves amount [$amount] without vendor or category',
      (tester) async {
        final store = PrototypeOperationsStore();
        final scope = OperationalScopeController();
        addTearDown(store.dispose);
        addTearDown(scope.dispose);
        ExpenseRecord? confirmed;
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
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
                            expenseDate: DateTime(2026, 9, 15),
                            startNewExpense: true,
                            onConfirm: (record) async {
                              confirmed = record;
                              return record;
                            },
                          ),
                        ),
                      ),
                      child: const Text('Open expense'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open expense'));
        await tester.pumpAndSettle();
        expect(find.text('Vendor or store (optional)'), findsOneWidget);
        final category = tester
            .widget<DropdownButtonFormField<ExpenseCategory>>(
              find.byKey(const ValueKey('expense-category-field')),
            );
        expect(category.initialValue, ExpenseCategory.uncategorized);
        await tester.enterText(
          find.byKey(const ValueKey('expense-amount-field')),
          amount,
        );
        final save = find.byKey(const ValueKey('save-expense-button'));
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        expect(save.hitTestable(), findsOneWidget);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(confirmed, isNotNull);
        expect(confirmed!.vendor, '');
        expect(confirmed!.category, ExpenseCategory.uncategorized);
        expect(
          confirmed!.amount,
          amount.isEmpty ? isNull : double.parse(amount),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
