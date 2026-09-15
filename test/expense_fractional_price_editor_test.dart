import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_line_item_editor.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final price in [3.499, 0.0]) {
    testWidgets(
      'fuel price $price can be reopened, edited and saved precisely',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        ExpenseLineItem? saved;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    saved = await showExpenseLineItemEditor(
                      context,
                      defaultCategory: ExpenseCategory.fuel,
                      initial: ExpenseLineItem(
                        id: 'fuel',
                        description: 'Regular unleaded',
                        category: ExpenseCategory.fuel,
                        quantity: 16.81,
                        unit: 'gallon',
                        unitPrice: price,
                      ),
                    );
                  },
                  child: const Text('Open fuel'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open fuel'));
        await tester.pumpAndSettle();
        final field = find.byKey(const ValueKey('expense-line-unit-price'));
        expect(
          tester.widget<TextFormField>(field).controller!.text,
          price == 0 ? '0.00' : '3.499',
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, price == 0 ? '0' : '3.499123');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save').first);
        await tester.pumpAndSettle();
        expect(saved!.unitPrice, price == 0 ? 0 : 3.499123);
        expect(saved!.total, price == 0 ? 0 : 58.82);
        expect(saved!.quantity, 16.81);
        expect(saved!.unitsPerPackage, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
