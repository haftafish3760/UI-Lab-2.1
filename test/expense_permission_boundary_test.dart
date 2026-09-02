import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expenses_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_intake_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/scheduled_expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets('denied Expense route does not query or render records', (
    tester,
  ) async {
    await _pumpExpenses(
      tester,
      permissions: const ExpensePermissions(
        canView: false,
        canViewAmounts: false,
        canCreate: false,
        canAttachReceipt: false,
        canEditOwn: false,
        canEditTeam: false,
        canReviewCompanyExpenses: false,
        canManageScheduledExpenses: false,
        canConfigureDisplay: false,
      ),
    );

    expect(
      find.text('You do not have permission to view expenses.'),
      findsOneWidget,
    );
    expect(find.textContaining('Central Supply'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('amount-denied Expense view hides totals and edit actions', (
    tester,
  ) async {
    await _pumpExpenses(
      tester,
      permissions: const ExpensePermissions(
        canView: true,
        canViewAmounts: false,
        canCreate: false,
        canAttachReceipt: false,
        canEditOwn: false,
        canEditTeam: false,
        canReviewCompanyExpenses: false,
        canManageScheduledExpenses: false,
        canConfigureDisplay: false,
      ),
    );

    expect(find.text('Daily total'), findsNothing);
    expect(find.byKey(const ValueKey('daily-expense-total')), findsNothing);
    expect(find.text(r'$231.50'), findsNothing);
    expect(
      find.byKey(const ValueKey('expenses-settings-button')),
      findsNothing,
    );
    expect(find.byType(FloatingActionButton), findsNothing);

    await _pumpExpenseDetail(
      tester,
      permissions: const ExpensePermissions(
        canView: true,
        canViewAmounts: false,
        canCreate: false,
        canAttachReceipt: false,
        canEditOwn: false,
        canEditTeam: false,
        canReviewCompanyExpenses: false,
        canManageScheduledExpenses: false,
        canConfigureDisplay: false,
      ),
    );
    expect(find.byKey(const ValueKey('edit-expense-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('expense-detail-actions-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('expense-receipt-details')), findsNothing);
    expect(
      find.text('Receipt amounts are not available for this employee.'),
      findsOneWidget,
    );
  });

  testWidgets('receipt-only grant exposes only the permitted add action', (
    tester,
  ) async {
    await _pumpExpenses(
      tester,
      permissions: const ExpensePermissions(
        canView: true,
        canViewAmounts: true,
        canCreate: false,
        canAttachReceipt: true,
        canEditOwn: false,
        canEditTeam: false,
        canReviewCompanyExpenses: false,
        canManageScheduledExpenses: false,
        canConfigureDisplay: false,
      ),
    );

    expect(find.text('Add receipt'), findsOneWidget);
    await tester.tap(find.text('Add receipt'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('expense-add-actions-screen')),
      findsOneWidget,
    );
    expect(find.text('Record expense'), findsNothing);
    expect(find.text('Add fuel'), findsNothing);
    expect(find.text('Add receipt'), findsOneWidget);
    await tester.tap(find.text('Add receipt'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('receipt-intake-screen')), findsOneWidget);
    expect(
      find.text('You do not have permission to add receipts.'),
      findsNothing,
    );
  });

  testWidgets('manual editor rejects a direct route without create access', (
    tester,
  ) async {
    await _pumpExpenseRoute(
      tester,
      home: ExpenseEditorScreen(
        expenseDate: DateTime(2026, 9, 1),
        permissions: _readOnlyPermissions,
      ),
    );

    expect(
      find.text('You do not have permission to change this expense.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('save-expense-button')), findsNothing);
  });

  testWidgets('receipt intake rejects a direct route without receipt access', (
    tester,
  ) async {
    await _pumpExpenseRoute(
      tester,
      home: ReceiptIntakeScreen(
        expenseDate: DateTime(2026, 9, 1),
        permissions: _readOnlyPermissions,
      ),
    );

    expect(
      find.text('You do not have permission to add receipts.'),
      findsOneWidget,
    );
    expect(find.text('Take photo'), findsNothing);
  });

  testWidgets('planned expense editor rejects an unauthorized direct route', (
    tester,
  ) async {
    await _pumpExpenseRoute(
      tester,
      home: const ScheduledExpenseEditorScreen(
        permissions: _readOnlyPermissions,
      ),
    );

    expect(
      find.text('You do not have permission to manage planned expenses.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('save-scheduled-expense')), findsNothing);
  });
}

const _readOnlyPermissions = ExpensePermissions(
  canView: true,
  canViewAmounts: true,
  canCreate: false,
  canAttachReceipt: false,
  canEditOwn: false,
  canEditTeam: false,
  canReviewCompanyExpenses: false,
  canManageScheduledExpenses: false,
  canConfigureDisplay: false,
);

Future<void> _pumpExpenses(
  WidgetTester tester, {
  required ExpensePermissions permissions,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = PrototypeOperationsStore();
  final scope = OperationalScopeController();
  addTearDown(store.dispose);
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: ExpensesScreen(permissions: permissions),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpExpenseDetail(
  WidgetTester tester, {
  required ExpensePermissions permissions,
}) async {
  final store = PrototypeOperationsStore();
  final scope = OperationalScopeController();
  addTearDown(store.dispose);
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: ExpenseDetailScreen(
            expenseId: 'EXP-1048',
            permissions: permissions,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpExpenseRoute(
  WidgetTester tester, {
  required Widget home,
}) async {
  final store = PrototypeOperationsStore();
  final scope = OperationalScopeController();
  addTearDown(store.dispose);
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(theme: AppTheme.light, home: home),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
