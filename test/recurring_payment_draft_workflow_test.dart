import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_payment_session.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_payment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/atomic_recurring_expense_payment.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';

Future<RecurringPaymentSession> openSession(
  LocalPersistence persistence,
) async {
  final expenses = ExpenseUiRepositoryController(
    ExpenseUiRepositoryBridge(
      service: AuthorizedExpenseService(persistence.expenses),
      employeeLabelForId: (_) => 'Alex Morgan',
      jobLabelForId: (_) => null,
    ),
    expenseUiLabOwnerPermissions(),
    drafts: persistence.drafts,
  );
  final recurring = RecurringExpenseUiController(
    AuthorizedRecurringExpenseService(persistence.recurringExpenses),
    recurringExpenseUiLabOwnerPermissions(),
    (_) => 'Alex Morgan',
    drafts: persistence.drafts,
  );
  expect(await expenses.load(), isTrue);
  expect(await recurring.load(), isTrue);
  final session = RecurringPaymentSession(
    drafts: persistence.drafts,
    service: AtomicRecurringExpensePayment(
      expenses: persistence.expenses,
      recurringExpenses: persistence.recurringExpenses,
      employeeLabelForId: (_) => 'Alex Morgan',
    ),
    expenses: expenses,
    recurringExpenses: recurring,
    expensePermissions: expenseUiLabOwnerPermissions(),
    recurringPermissions: recurringExpenseUiLabOwnerPermissions(),
  );
  addTearDown(() {
    session.dispose();
    expenses.dispose();
    recurring.dispose();
  });
  return session;
}

Future<String> seed(RecurringPaymentSession session) async {
  await session.recurringExpenses.create(
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
  return session.recurringExpenses.currentOccurrenceFor('plan')!.id;
}

void main() {
  test(
    'raw recurring amount and payment date reopen after transaction failure and confirm once',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'recurring-draft-workflow-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      var session = await openSession(persistence);
      final occurrence = await seed(session);
      var workflow = await session.openPaymentDraft(
        templateId: 'plan',
        occurrenceId: occurrence,
      );
      workflow.updateAmount('-');
      await expectLater(workflow.confirm(), throwsStateError);
      final date = workflow.input.paidOn;
      await workflow.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openSession(persistence);
      workflow = await session.openPaymentDraft(
        templateId: 'plan',
        occurrenceId: occurrence,
      );
      expect(workflow.input.amount, '-');
      expect(workflow.input.paidOn, date);
      workflow.updateAmount(' 125.50 ');
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_payment BEFORE UPDATE ON local_records WHEN NEW.domain = 'recurring-expenses/templates' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect((await workflow.confirm()).succeeded, isFalse);
      expect(workflow.input.amount, ' 125.50 ');
      expect(
        session.recurringExpenses.currentOccurrenceFor('plan')!.id,
        occurrence,
      );
      await persistence.database.customStatement('DROP TRIGGER fail_payment');
      final result = await workflow.confirm();
      expect(result.succeeded, isTrue);
      expect(result.expense!.amount, 125.5);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );
  test(
    'another payment cannot be overwritten by a retained stale draft',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'recurring-stale-workflow-',
      );
      final persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      final session = await openSession(persistence);
      final occurrence = await seed(session);
      final workflow = await session.openPaymentDraft(
        templateId: 'plan',
        occurrenceId: occurrence,
      );
      workflow.updateAmount('90.');
      expect(
        (await session.markPaid(
          templateId: 'plan',
          occurrenceId: occurrence,
          expectedTemplateRevision: workflow.input.baseTemplateRevision,
          expectedOccurrenceRevision: workflow.input.baseRevision,
          actualAmount: 100,
          paidOn: DateTime(2030, 1, 20),
        )).succeeded,
        isTrue,
      );
      expect((await workflow.confirm()).succeeded, isFalse);
      expect(workflow.input.amount, '90.');
      await workflow.session.close();
      await expectLater(
        session.openPaymentDraft(templateId: 'plan', occurrenceId: occurrence),
        throwsStateError,
      );
    },
  );
}
