import 'dart:io';
import 'package:ui_lab_2_1/src/data/expenses/recurring_payment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_occurrence_draft_workflow.dart';
import 'recurring_payment_draft_workflow_test.dart' show seed;
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_workflow.dart';
import 'expense_draft_workflow_test.dart' show initialExpense;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_payment_session.dart';
import 'package:ui_lab_2_1/src/data/expenses/atomic_recurring_expense_payment.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_lab_policy.dart';

Future<RecurringPaymentSession> openExpenseLifecycleSession(
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
  return session;
}

void main() {
  for (final kind in [
    'manual',
    'planned',
    'occurrence',
    'payment',
    'payment-expense-owner',
    'payment-recurring-owner',
  ]) {
    for (final during in [false, true]) {
      test(
        '$kind rejects owner disposal ${during ? 'during' : 'before'} opening',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'expense-owner-lifecycle-',
          );
          final persistence = await LocalPersistence.open(directory: root);
          final owner = await openExpenseLifecycleSession(persistence);
          final occurrenceId = await seed(owner);
          final before = await persistence.database
              .customSelect(
                'SELECT * FROM local_records ORDER BY organization_id, domain, record_id',
              )
              .get();
          final target = switch (kind) {
            'manual' || 'payment-expense-owner' => owner.expenses,
            'payment' => owner,
            _ => owner.recurringExpenses,
          };
          void disposeTarget() => target.dispose();

          try {
            if (!during) disposeTarget();
            final pending = switch (kind) {
              'manual' => owner.expenses.openExpenseDraft(
                initial: initialExpense(),
              ),
              'planned' => owner.recurringExpenses.openPlannedDraft(),
              'occurrence' => owner.recurringExpenses.openOccurrenceDraft(
                templateId: 'plan',
                occurrenceId: occurrenceId,
              ),
              _ => owner.openPaymentDraft(
                templateId: 'plan',
                occurrenceId: occurrenceId,
              ),
            };
            if (during) disposeTarget();
            await expectLater(pending, throwsStateError);
            expect(
              await persistence.drafts.listOwned(
                organizationId: owner.expenses.organizationId,
                ownerId: owner.expenses.actorEmployeeId,
                domains: {
                  'expenses/manual-entry',
                  'expenses/planned-new',
                  'expenses/planned-occurrence',
                  'expenses/planned-payment',
                },
              ),
              isEmpty,
            );
            final pause = await persistence.database.draftSessions
                .pauseAndFlush();
            pause.release();
            await persistence.database.verifyIntegrity();
            final after = await persistence.database
                .customSelect(
                  'SELECT * FROM local_records ORDER BY organization_id, domain, record_id',
                )
                .get();
            expect(after.map((row) => row.data), before.map((row) => row.data));
          } finally {
            for (final controller in [
              owner,
              owner.expenses,
              owner.recurringExpenses,
            ]) {
              if (!identical(controller, target)) controller.dispose();
            }
            await persistence.close();
            await root.delete(recursive: true);
          }
        },
      );
    }
  }
}
