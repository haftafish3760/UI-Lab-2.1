import 'expense_workflow_models.dart';
import 'expense_ui_repository_controller.dart';
import 'recurring_expense_ui_controller.dart';

class RecurringExpensePaymentResult {
  const RecurringExpensePaymentResult._({
    required this.succeeded,
    this.expense,
    this.message,
  });

  const RecurringExpensePaymentResult.success(ExpenseRecord expense)
    : this._(succeeded: true, expense: expense);

  const RecurringExpensePaymentResult.failure(String message)
    : this._(succeeded: false, message: message);

  final bool succeeded;
  final ExpenseRecord? expense;
  final String? message;
}

/// Coordinates the two durable aggregates involved in marking an obligation
/// paid without pretending they share one transactional file.
///
/// The ordinary Expense is created first with a deterministic ID. If linking
/// the occurrence is interrupted, retry finds and validates that exact Expense
/// before idempotently completing the occurrence. It never creates a second
/// Expense for the same planned payment.
class RecurringExpensePaymentCoordinator {
  const RecurringExpensePaymentCoordinator({
    required this.expenses,
    required this.recurringExpenses,
  });

  final ExpenseUiRepositoryController expenses;
  final RecurringExpenseUiController recurringExpenses;

  Future<RecurringExpensePaymentResult> markPaid({
    required ScheduledExpenseRecord template,
    required ScheduledExpenseOccurrence occurrence,
    required double actualAmount,
    required DateTime paidOn,
  }) async {
    if (expenses.organizationId != recurringExpenses.organizationId ||
        expenses.actorEmployeeId != recurringExpenses.actorEmployeeId) {
      return const RecurringExpensePaymentResult.failure(
        'Expense and planned-payment sessions do not match.',
      );
    }
    if (occurrence.templateId != template.id ||
        !recurringExpenses.canRecordPaymentFor(template.id) ||
        !expenses.canCreateForEmployee(template.ownerEmployeeId) ||
        !actualAmount.isFinite ||
        actualAmount <= 0) {
      return const RecurringExpensePaymentResult.failure(
        'This planned payment cannot be recorded with the current input or permissions.',
      );
    }
    final current = recurringExpenses.recordById(template.id);
    if (current == null ||
        current.ownerEmployeeId != template.ownerEmployeeId ||
        current.title != template.title ||
        current.category != template.category) {
      return const RecurringExpensePaymentResult.failure(
        'This planned expense changed. Review it before recording payment.',
      );
    }
    final expenseId = _expenseId(occurrence.id);
    final deleted = expenses.deletedRecords.where(
      (record) => record.id == expenseId,
    );
    if (deleted.isNotEmpty) {
      return const RecurringExpensePaymentResult.failure(
        'The Expense for this payment was removed. Restore it before marking '
        'the payment paid.',
      );
    }
    var expense = expenses.recordById(expenseId);
    if (expense != null &&
        !_matches(
          expense,
          template: template,
          amount: actualAmount,
          paidOn: paidOn,
        )) {
      return const RecurringExpensePaymentResult.failure(
        'An Expense with this payment identity contains different confirmed '
        'values. Review it before trying again.',
      );
    }
    expense ??= await expenses.create(
      record: ExpenseRecord(
        id: expenseId,
        vendor: template.title,
        category: template.category,
        amount: actualAmount,
        date: _dateOnly(paidOn),
        owner: template.owner,
        paidByEmployeeId: template.ownerEmployeeId,
        receiptStatus: template.receiptRequired
            ? 'Receipt required'
            : 'Receipt optional',
      ),
      paidByEmployeeId: template.ownerEmployeeId,
      occurredAtUtc: DateTime.now().toUtc(),
    );
    if (expense == null) {
      return RecurringExpensePaymentResult.failure(
        expenses.failure?.message ??
            'The Expense could not be saved. The payment was not marked paid.',
      );
    }
    final linked = await recurringExpenses.recordPaid(
      templateId: template.id,
      occurrenceId: occurrence.id,
      actualAmount: actualAmount,
      paidOn: paidOn,
      expenseId: expense.id,
    );
    if (!linked) {
      return RecurringExpensePaymentResult.failure(
        'The Expense was saved, but the planned payment still needs to be '
        'linked. ${recurringExpenses.failureMessage ?? ''}'
        ' Try Mark paid again; it will reuse the saved Expense.',
      );
    }
    return RecurringExpensePaymentResult.success(expense);
  }

  bool _matches(
    ExpenseRecord expense, {
    required ScheduledExpenseRecord template,
    required double amount,
    required DateTime paidOn,
  }) {
    final date = expense.resolvedDate;
    return expense.vendor == template.title &&
        expense.category == template.category &&
        expense.amount != null &&
        (expense.amount! * 100).round() == (amount * 100).round() &&
        expense.paidByEmployeeId == template.ownerEmployeeId &&
        date != null &&
        date.year == paidOn.year &&
        date.month == paidOn.month &&
        date.day == paidOn.day;
  }
}

String _expenseId(String occurrenceId) => 'EXP-RECURRING-$occurrenceId';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
