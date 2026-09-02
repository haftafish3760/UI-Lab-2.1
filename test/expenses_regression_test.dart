import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expenses_screen.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets('Expenses renders a legacy string date without a TypeError', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final legacy = ExpenseRecord(
      id: 'legacy',
      vendor: 'Legacy Vendor',
      category: ExpenseCategory.materials,
      amount: 12.50,
      date: today.toIso8601String(),
      owner: 'Alex Morgan',
      paidByEmployeeId: 'alex',
    );

    final scope = OperationalScopeController();
    final store = PrototypeOperationsStore();
    addTearDown(scope.dispose);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: MaterialApp(
          home: OperationalScope(
            controller: scope,
            child: ExpensesScreen(initialExpenses: [legacy]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Legacy Vendor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expenses reflows at 320 LP with enlarged accessible text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    final store = PrototypeOperationsStore();
    addTearDown(scope.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const ExpensesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('expenses-1-column-layout')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('expenses-date-heading')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expense-record-EXP-1048')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
