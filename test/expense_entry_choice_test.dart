import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_entry_flow.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_choice_card.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_intake_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 700.0, 1440.0]) {
      testWidgets('receipt setup to source and back: width $width dark $dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => openExpenseEntryFlow(
                    context,
                    expenseDate: DateTime(2026, 9, 15),
                    permissions: const ExpensePermissions.development(),
                    onConfirm: (record) async => record,
                  ),
                  child: const Text('Start'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();
        expect(find.text('Add receipt'), findsNothing);
        expect(find.text('Enter without a receipt'), findsNothing);
        expect(find.byType(TextFormField), findsNothing);
        final simple = find.byKey(const ValueKey('receipt-total-only-choice'));
        final detailed = find.byKey(
          const ValueKey('receipt-every-item-choice'),
        );
        expect(tester.getTopLeft(simple).dy, tester.getTopLeft(detailed).dy);
        await tester.ensureVisible(detailed);
        await tester.tap(detailed);
        await tester.pump();
        final category = find.byKey(const ValueKey('choose-receipt-category'));
        await tester.ensureVisible(category);
        await tester.tap(category);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('receipt-category-search')),
          'parking',
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey('receipt-category-receiptParking')),
        );
        await tester.tap(
          find.byKey(const ValueKey('confirm-receipt-category')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Parking'), findsOneWidget);
        final next = find.byKey(const ValueKey('continue-expense-setup'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        final source = tester.widget<ReceiptIntakeScreen>(
          find.byType(ReceiptIntakeScreen),
        );
        expect(source.initialCategory, ExpenseCategory.receiptParking);
        expect(source.initialReceiptType, ExpenseReceiptType.detailed);
        expect(find.byType(TextFormField), findsNothing);
        for (final row in [
          ['camera', 'photos'],
          ['pdf', 'text'],
        ]) {
          final left = find.byKey(ValueKey('receipt-source-${row[0]}'));
          final right = find.byKey(ValueKey('receipt-source-${row[1]}'));
          expect(tester.getTopLeft(left).dy, tester.getTopLeft(right).dy);
          expect(
            tester.getTopLeft(left).dx,
            lessThan(tester.getTopLeft(right).dx),
          );
        }
        expect(
          tester
              .widget<ReceiptChoiceCard>(
                find.byKey(const ValueKey('receipt-source-pdf')),
              )
              .onTap,
          isNull,
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Parking'), findsOneWidget);
        expect(tester.widget<ReceiptChoiceCard>(detailed).selected, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'category cancel does not apply a pending change; no category is available',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => openExpenseEntryFlow(
                context,
                expenseDate: DateTime(2026),
                permissions: const ExpensePermissions.development(),
                initialCategory: ExpenseCategory.fuel,
                onConfirm: (r) async => r,
              ),
              child: const Text('Start'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choose-receipt-category')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('receipt-category-uncategorized')),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Fuel'), findsOneWidget);
    },
  );
}
