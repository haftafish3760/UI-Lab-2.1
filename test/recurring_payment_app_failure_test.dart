import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/shell/app_shell.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/scheduled_expense_detail_screen.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'app payment action rolls back expense on plan failure and retries once',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('payment-app-'),
      ))!;
      final persistence = (await tester.runAsync(
        () => LocalPersistence.open(directory: directory),
      ))!;
      await tester.runAsync(() async {
        final seed = RecurringExpenseUiController(
          AuthorizedRecurringExpenseService(persistence.recurringExpenses),
          recurringExpenseUiLabOwnerPermissions(),
          (_) => 'Alex Morgan',
        );
        await seed.load();
        await seed.create(
          ScheduledExpenseRecord(
            id: 'plan',
            title: 'Insurance',
            category: ExpenseCategory.vehicleInsurance,
            amount: 100,
            nextDueOn: DateTime(2030, 1, 20),
            kind: ExpenseScheduleKind.monthly,
            ownerEmployeeId: 'alex',
            owner: 'Alex Morgan',
            dueDay: 20,
          ),
        );
        seed.dispose();
        await persistence.database.customStatement(
          "CREATE TRIGGER fail_payment_app BEFORE UPDATE ON local_records WHEN NEW.domain = 'recurring-expenses/templates' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
        );
      });
      await tester.pumpWidget(
        UiLabApp(
          expenseRepository: persistence.expenses,
          recurringExpenseRepository: persistence.recurringExpenses,
          draftStore: persistence.drafts,
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(AppShell));
      final expenses = ExpenseUiScope.maybeOf(context)!;
      final recurring = RecurringExpenseUiScope.maybeOf(context)!;
      await waitForNativeSave(
        tester,
        () =>
            expenses.phase == ExpenseRepositoryControllerPhase.ready &&
            recurring.recordById('plan') != null,
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ScheduledExpenseDetailScreen(recordId: 'plan'),
        ),
      );
      await tester.pumpAndSettle();
      final paid = find.byKey(const ValueKey('mark-scheduled-expense-paid'));
      await tester.ensureVisible(paid);
      await tester.pumpAndSettle();
      await tester.tap(paid);
      await tester.pump();
      expect(tester.widget<FilledButton>(paid).onPressed, isNull);
      await waitForNativeSave(
        tester,
        () => find.text('Planned expense not changed').evaluate().isNotEmpty,
      );
      expect(expenses.records, isEmpty);
      expect(recurring.revisionForId('plan'), 1);
      expect(recurring.occurrencesFor('plan'), hasLength(1));
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => persistence.database.customStatement(
          'DROP TRIGGER fail_payment_app',
        ),
      );
      await tester.tap(paid);
      await waitForNativeSave(
        tester,
        () => find.byType(ExpenseDetailScreen).evaluate().isNotEmpty,
      );
      expect(expenses.records, hasLength(1));
      expect(expenses.records.single.amount, 100);
      expect(recurring.occurrencesFor('plan'), hasLength(2));
      expect(recurring.revisionForId('plan'), 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      expect(tester.takeException(), isNull);
    },
  );
}
