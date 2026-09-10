import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets(
    'failed expense confirmation keeps input and retry includes edited date',
    (tester) async {
      final scope = OperationalScopeController();
      addTearDown(scope.dispose);
      final initial = ExpenseRecord(
        id: 'expense-edit',
        vendor: 'Original vendor',
        category: ExpenseCategory.office,
        amount: 12,
        date: DateTime(2026, 4, 5),
        owner: 'Alex Morgan',
      );
      var calls = 0;
      ExpenseRecord? returned;
      ExpenseRecord? submitted;
      await tester.pumpWidget(
        OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    returned = await Navigator.of(context).push<ExpenseRecord>(
                      MaterialPageRoute(
                        builder: (_) => ExpenseEditorScreen(
                          expenseDate: initial.resolvedDate!,
                          existing: initial,
                          onConfirm: (record) async {
                            calls++;
                            submitted = record;
                            return calls == 1 ? null : record;
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('Edit expense'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit expense'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('expense-vendor-field')),
        'Revised vendor',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('expense-receipt-date-field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('6'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save-expense-button'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseEditorScreen), findsOneWidget);
      expect(returned, isNull);
      expect(submitted!.resolvedDate, DateTime(2026, 4, 6));
      expect(submitted!.vendor, 'Revised vendor');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('expense-vendor-field')),
            )
            .controller!
            .text,
        'Revised vendor',
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseEditorScreen), findsNothing);
      expect(returned!.id, initial.id);
      expect(returned!.resolvedDate, DateTime(2026, 4, 6));
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
