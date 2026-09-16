import 'support/expense_setup_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_spending_summary.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/shell/app_navigation.dart';

void main() {
  test(
    'spending periods handle year boundaries, refunds and unknown dates',
    () {
      ExpenseRecord record(String id, Object date, double amount) =>
          ExpenseRecord(
            id: id,
            vendor: 'Fictional supplier',
            category: ExpenseCategory.materials,
            amount: amount,
            date: date,
            owner: 'Employee',
            paidByEmployeeId: 'alex',
          );
      final totals = expensePeriodTotals([
        record('last-year', DateTime(2025, 12, 31), 10),
        record('today', DateTime(2026, 1, 1), 25.25),
        record('refund', DateTime(2026, 1, 1), -5.10),
        record('next-week', DateTime(2026, 1, 5), 12),
        record('unknown', 'not a date', 999),
      ], DateTime(2026, 1, 1));
      expect(totals, {'Day': 2015, 'Week': 3015, 'Month': 3215, 'Year': 3215});
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(1024, 560),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'navigation stays on the same edge across all modules at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const UiLabApp());
        await useCompletedExpenseSetup(tester);
        await tester.pumpAndSettle();
        for (final name in [
          'dashboard',
          'expenses',
          'inventory',
          'maintenance',
          'work',
          'dashboard',
        ]) {
          final destination = find.byKey(
            ValueKey(
              '${size.width >= 1000 ? 'desktop' : 'app'}-destination-$name',
            ),
          );
          await tester.ensureVisible(destination);
          await tester.pumpAndSettle();
          await tester.tap(destination);
          await tester.pumpAndSettle();
          final index = [
            'dashboard',
            'work',
            'expenses',
            'inventory',
            'maintenance',
          ].indexOf(name);
          expect(
            size.width >= 1000
                ? tester
                      .widget<DesktopAppNavigation>(
                        find.byType(DesktopAppNavigation),
                      )
                      .selectedIndex
                : tester
                      .widget<AppBottomNavigation>(
                        find.byType(AppBottomNavigation),
                      )
                      .selectedIndex,
            index,
          );
          expect(
            find.byType(DesktopAppNavigation),
            size.width >= 1000 ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(AppBottomNavigation),
            size.width < 1000 ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull, reason: '$name at $size');
        }
      },
    );
  }

  for (final size in [const Size(320, 740), const Size(1100, 560)]) {
    testWidgets('Expenses reflows at double text size on $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const UiLabApp());
      await useCompletedExpenseSetup(tester);
      await tester.pumpAndSettle();
      final destination = find.byKey(
        ValueKey(
          '${size.width >= 1000 ? 'desktop' : 'app'}-destination-expenses',
        ),
      );
      await tester.ensureVisible(destination);
      await tester.pumpAndSettle();
      await tester.tap(destination);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final add = find.text('Add expense');
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      expect(add.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'phone expense home keeps daily and weekly totals and opens receipt setup',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const UiLabApp());
      await useCompletedExpenseSetup(tester);
      await tester.pumpAndSettle();
      await useCompletedExpenseSetup(tester);
      await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
      await tester.pumpAndSettle();
      for (final period in ['day', 'week']) {
        expect(
          find.byKey(ValueKey('expense-spending-$period')),
          findsOneWidget,
        );
      }
      expect(find.text('Add fuel'), findsNothing);
      await tester.tap(find.text('Add expense'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('expense-entry-choice-screen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('expense-add-actions-screen')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
