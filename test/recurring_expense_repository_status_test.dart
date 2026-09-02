import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_recurring_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/recurring_expense_repository_status.dart';

void main() {
  testWidgets('failed first load is not presented as an honest empty state', (
    tester,
  ) async {
    late Directory directory;
    final repository = await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp(
        'recurring-status-failed-',
      );
      return FileRecurringExpenseRepository.open(directory);
    });
    final controller = _controller(repository!, readScope: null);
    expect(await controller.load(), isFalse);

    await tester.pumpWidget(_statusApp(controller));
    expect(
      find.text('You do not have permission to change that planned expense.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.runAsync(() => directory.delete(recursive: true));
  });

  testWidgets('damaged-snapshot recovery remains visible until acknowledged', (
    tester,
  ) async {
    late Directory directory;
    final repository = await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp(
        'recurring-status-recovered-',
      );
      return FileRecurringExpenseRepository.open(directory);
    });
    final controller = _controller(
      repository!,
      recoveredFromDamagedSnapshot: true,
    );

    await tester.pumpWidget(_statusApp(controller));
    expect(find.textContaining('last valid saved copy'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'I understand'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('recurring-expense-repository-status')),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}

Widget _statusApp(RecurringExpenseUiController controller) => MaterialApp(
  home: RecurringExpenseUiScope(
    controller: controller,
    child: const Scaffold(body: RecurringExpenseRepositoryStatus()),
  ),
);

RecurringExpenseUiController _controller(
  RecurringExpenseRepository repository, {
  RecurringExpenseReadScope? readScope = RecurringExpenseReadScope.company,
  bool recoveredFromDamagedSnapshot = false,
}) => RecurringExpenseUiController(
  AuthorizedRecurringExpenseService(repository),
  RecurringExpenseCommandPermissions(
    organizationId: 'organization-1',
    actorEmployeeId: 'employee-alex',
    permissionRevision: 'permissions-1',
    readScope: readScope,
    canManage: true,
    canRecordPayment: true,
    canManageOtherEmployees: true,
  ),
  (_) => 'Alex Morgan',
  recoveredFromDamagedSnapshot: recoveredFromDamagedSnapshot,
);
