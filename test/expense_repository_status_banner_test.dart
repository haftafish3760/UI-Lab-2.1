import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/shell/expense_repository_status_banner.dart';

void main() {
  testWidgets('failed Expense session stays visible and offers Retry', (
    tester,
  ) async {
    final controller = ExpenseUiRepositoryController(
      ExpenseUiRepositoryBridge(
        service: AuthorizedExpenseService(_FailingExpenseRepository()),
        employeeLabelForId: (id) => id,
        jobLabelForId: (_) => null,
      ),
      ExpenseCommandPermissions(
        organizationId: 'company-1',
        actorEmployeeId: 'alex',
        permissionRevision: 'permissions-1',
        readScope: ExpenseReadScope.own,
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseUiScope(
          controller: controller,
          child: const Scaffold(body: ExpenseRepositoryStatusBanner()),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('expense-repository-failure-banner')),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('not saved'), findsOneWidget);
  });
}

class _FailingExpenseRepository implements ExpenseRepository {
  @override
  Future<List<StoredExpenseRecord>> query(ExpenseQuery query) =>
      throw const ExpenseStorageException('Cannot read Expenses.');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
