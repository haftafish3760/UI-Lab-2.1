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
    'payment amount draft survives reopen and failed atomic confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('payment-app-'),
      ))!;
      var persistence = (await tester.runAsync(
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
            amountKind: ScheduledExpenseAmountKind.enterWhenPaid,
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
      late ExpenseUiRepositoryController expenses;
      late RecurringExpenseUiController recurring;
      Future<void> mount() async {
        await tester.pumpWidget(
          UiLabApp(
            expenseRepository: persistence.expenses,
            recurringExpenseRepository: persistence.recurringExpenses,
            draftStore: persistence.drafts,
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(AppShell));
        expenses = ExpenseUiScope.maybeOf(context)!;
        recurring = RecurringExpenseUiScope.maybeOf(context)!;
        await waitForNativeSave(
          tester,
          () =>
              expenses.phase == ExpenseRepositoryControllerPhase.ready &&
              recurring.recordById('plan') != null,
        );
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const ScheduledExpenseDetailScreen(recordId: 'plan'),
          ),
        );
        await tester.pumpAndSettle();
        final paid = find.byKey(const ValueKey('mark-scheduled-expense-paid'));
        await tester.ensureVisible(paid);
        await tester.pumpAndSettle();
        await tester.tap(paid);
      }

      Future<void> saved() async {
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find.text('Draft saved on this device').evaluate().isNotEmpty,
        );
      }

      await mount();
      await saved();
      final amount = find.byKey(
        const ValueKey('scheduled-expense-actual-amount'),
      );
      await tester.enterText(amount, '135.');
      FocusManager.instance.primaryFocus?.unfocus();
      await saved();
      await tester.tap(find.text('Keep unfinished'));
      await waitForNativeSave(tester, () => amount.evaluate().isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(persistence.close);
      persistence = (await tester.runAsync(
        () => LocalPersistence.open(directory: directory),
      ))!;
      await mount();
      await saved();
      expect(tester.widget<TextFormField>(amount).controller!.text, '135.');
      await tester.enterText(amount, '135.50');
      FocusManager.instance.primaryFocus?.unfocus();
      await saved();
      final confirm = find.byKey(
        const ValueKey('confirm-scheduled-expense-payment'),
      );
      await tester.tap(confirm);
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await waitForNativeSave(
        tester,
        () => find
            .text(
              'The payment and Expense were not saved. Confirmed records and unfinished input were preserved. Retry saving.',
            )
            .evaluate()
            .isNotEmpty,
      );
      expect(expenses.records, isEmpty);
      expect(recurring.revisionForId('plan'), 1);
      expect(recurring.occurrencesFor('plan'), hasLength(1));
      expect(tester.widget<TextFormField>(amount).controller!.text, '135.50');
      await tester.runAsync(
        () => persistence.database.customStatement(
          'DROP TRIGGER fail_payment_app',
        ),
      );
      await tester.tap(confirm);
      await waitForNativeSave(
        tester,
        () => find.byType(ExpenseDetailScreen).evaluate().isNotEmpty,
      );
      expect(expenses.records, hasLength(1));
      expect(expenses.records.single.amount, 135.50);
      expect(recurring.occurrencesFor('plan'), hasLength(2));
      expect(recurring.revisionForId('plan'), 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        expect(
          await persistence.drafts.list(
            organizationId:
                recurringExpenseUiLabOwnerPermissions().organizationId,
            domain: 'expenses/planned-payment',
            ownerId: 'alex',
          ),
          isEmpty,
        );
        await persistence.close();
        await directory.delete(recursive: true);
      });
      expect(tester.takeException(), isNull);
    },
  );
}
