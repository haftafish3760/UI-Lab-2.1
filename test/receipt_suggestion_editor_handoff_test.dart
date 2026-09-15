import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_field_proposals.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final editing in [false, true]) {
    testWidgets(
      editing
          ? 'suggestions never replace an existing expense'
          : 'reviewed suggestions seed editable fields without creating an expense',
      (tester) async {
        final store = PrototypeOperationsStore();
        final scope = OperationalScopeController();
        addTearDown(store.dispose);
        addTearDown(scope.dispose);
        final existing = store.expenses.first;
        final count = store.expenses.length;
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: ExpenseEditorScreen(
                  expenseDate: DateTime(2026, 9, 15),
                  existing: editing ? existing : null,
                  suggestedDetails: ReceiptFieldProposals(
                    merchant: 'Juniper Supply',
                    date: DateTime(2026, 9, 14),
                    totalMinor: 1230,
                    subtotalMinor: 1200,
                    taxMinor: 30,
                    rows: const [],
                    warnings: const [],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        String input(String key) => tester
            .widget<TextFormField>(find.byKey(ValueKey(key)))
            .controller!
            .text;
        expect(
          input('expense-vendor-field'),
          editing ? existing.vendor : 'Juniper Supply',
        );
        expect(
          input('expense-amount-field'),
          editing ? existing.amount!.toStringAsFixed(2) : '12.30',
        );
        expect(store.expenses.length, count);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
