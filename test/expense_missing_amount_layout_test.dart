import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_record_card.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_spending_summary.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_total_summary_card.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_amount_summary.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  final day = DateTime(2026, 9, 15);
  final unknown = ExpenseRecord(
    id: 'missing',
    vendor: '',
    amount: null,
    category: ExpenseCategory.uncategorized,
    date: day,
    owner: 'Alex',
  );
  for (final width in [320.0, 700.0, 1440.0]) {
    testWidgets('missing amount card and recap reflow at $width with 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ExpenseRecordCard(expense: unknown, onTap: () {}),
                    ExpenseSpendingSummary(records: [unknown], date: day),
                    ExpenseTotalSummaryCard(
                      label: 'Total expenses for this day',
                      icon: Icons.payments_outlined,
                      summary: ExpenseAmountSummary([unknown]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Amount not entered'), findsNWidgets(6));
      expect(find.text(r'$0.00'), findsNothing);
      expect(
        find.text('1 receipt has no amount. Not included in the total.'),
        findsNWidgets(5),
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('amount permission also hides the missing amount label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ExpenseRecordCard(
                expense: unknown,
                showAmount: false,
                onTap: () {},
              ),
              ExpenseTotalSummaryCard(
                label: 'No category',
                icon: Icons.receipt_outlined,
                summary: ExpenseAmountSummary([unknown]),
                showAmounts: false,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Amount not entered'), findsNothing);
    expect(
      find.text('1 receipt has no amount. Not included in the total.'),
      findsNothing,
    );
    expect(
      find.textContaining('Business expense', findRichText: true),
      findsOneWidget,
    );
  });
}
