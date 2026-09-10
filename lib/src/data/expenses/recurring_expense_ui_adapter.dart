import 'expense_workflow_models.dart';
import 'expense_money.dart';
import 'recurring_expense_records.dart';
import 'recurring_expense_terms.dart';

typedef RecurringExpenseEmployeeLabelResolver =
    String Function(String employeeId);

abstract final class RecurringExpenseUiAdapter {
  static ScheduledExpenseRecord toUiTemplate(
    StoredRecurringExpenseTemplate stored,
    RecurringExpenseEmployeeLabelResolver employeeLabelForId,
  ) => ScheduledExpenseRecord(
    id: stored.templateId,
    title: stored.title,
    category: _category(stored.categoryId),
    amount: stored.expectedAmount.minorUnits / 100,
    nextDueOn: stored.nextDueOn,
    kind: switch (stored.schedule.kind) {
      RecurringExpenseScheduleKind.oneTime => ExpenseScheduleKind.oneTime,
      RecurringExpenseScheduleKind.monthly => ExpenseScheduleKind.monthly,
    },
    ownerEmployeeId: stored.assignedEmployeeId,
    owner: employeeLabelForId(stored.assignedEmployeeId),
    reminderDaysBefore: stored.reminders.daysBefore,
    inAppReminder: stored.reminders.inApp,
    pushReminder: stored.reminders.push,
    soundReminder: stored.reminders.sound,
    amountKind: switch (stored.amountMode) {
      RecurringExpenseAmountMode.fixed => ScheduledExpenseAmountKind.fixed,
      RecurringExpenseAmountMode.enterWhenPaid =>
        ScheduledExpenseAmountKind.enterWhenPaid,
    },
    state: switch (stored.state) {
      RecurringExpenseState.active => ScheduledExpenseState.active,
      RecurringExpenseState.paused => ScheduledExpenseState.paused,
      RecurringExpenseState.ended => ScheduledExpenseState.ended,
    },
    receiptRequired: stored.receiptRequired,
    dueDay: stored.schedule.monthlyDay,
  );

  static ScheduledExpenseOccurrence toUiOccurrence(
    StoredRecurringExpenseOccurrence stored,
  ) => ScheduledExpenseOccurrence(
    id: stored.occurrenceId,
    templateId: stored.templateId,
    dueOn: stored.dueOn,
    expectedAmount: stored.expectedAmount.minorUnits / 100,
    status: switch (stored.state) {
      RecurringExpenseOccurrenceState.due =>
        ScheduledExpenseOccurrenceStatus.due,
      RecurringExpenseOccurrenceState.paid =>
        ScheduledExpenseOccurrenceStatus.paid,
      RecurringExpenseOccurrenceState.skipped =>
        ScheduledExpenseOccurrenceStatus.skipped,
    },
    paidOn: stored.paidOn,
    actualAmount: stored.actualAmount == null
        ? null
        : stored.actualAmount!.minorUnits / 100,
    expenseId: stored.expenseId,
  );

  static StoredRecurringExpenseTemplate newStoredTemplate({
    required ScheduledExpenseRecord record,
    required String organizationId,
    required String createdByEmployeeId,
    required DateTime occurredAtUtc,
  }) => StoredRecurringExpenseTemplate(
    templateId: record.id,
    organizationId: organizationId,
    createdByEmployeeId: createdByEmployeeId,
    assignedEmployeeId: record.ownerEmployeeId,
    title: record.title,
    categoryId: record.category.name,
    categoryLabelSnapshot: record.category.label,
    expectedAmount: _money(record.amount),
    amountMode: _amountMode(record.amountKind),
    schedule: _schedule(record),
    nextDueOn: record.nextDueOn,
    reminders: _reminders(record),
    receiptRequired: record.receiptRequired,
    state: _state(record.state),
    lifecycle: RecurringExpenseLifecycle(
      revision: 1,
      createdAtUtc: occurredAtUtc,
      updatedAtUtc: occurredAtUtc,
    ),
  );

  static StoredRecurringExpenseTemplate updateStoredTemplate({
    required StoredRecurringExpenseTemplate current,
    required ScheduledExpenseRecord record,
  }) => current.copyWith(
    assignedEmployeeId: record.ownerEmployeeId,
    title: record.title,
    categoryId: record.category.name,
    categoryLabelSnapshot: record.category.label,
    expectedAmount: _money(record.amount),
    amountMode: _amountMode(record.amountKind),
    schedule: _schedule(record),
    nextDueOn: record.nextDueOn,
    reminders: _reminders(record),
    receiptRequired: record.receiptRequired,
    state: _state(record.state),
  );

  static ExpenseMoney money(double amount) => _money(amount);

  static RecurringExpenseState storedState(ScheduledExpenseState state) =>
      _state(state);

  static ExpenseCategory _category(String id) {
    for (final category in ExpenseCategory.values) {
      if (category.name == id) return category;
    }
    return ExpenseCategory.other;
  }

  static ExpenseMoney _money(double amount) =>
      ExpenseMoney(minorUnits: (amount * 100).round());

  static RecurringExpenseAmountMode _amountMode(
    ScheduledExpenseAmountKind kind,
  ) => switch (kind) {
    ScheduledExpenseAmountKind.fixed => RecurringExpenseAmountMode.fixed,
    ScheduledExpenseAmountKind.enterWhenPaid =>
      RecurringExpenseAmountMode.enterWhenPaid,
  };

  static RecurringExpenseSchedule _schedule(ScheduledExpenseRecord record) =>
      switch (record.kind) {
        ExpenseScheduleKind.oneTime => const RecurringExpenseSchedule.oneTime(),
        ExpenseScheduleKind.monthly => RecurringExpenseSchedule.monthly(
          record.dueDay ?? record.nextDueOn.day,
        ),
      };

  static RecurringExpenseReminderSettings _reminders(
    ScheduledExpenseRecord record,
  ) => RecurringExpenseReminderSettings(
    daysBefore: record.reminderDaysBefore,
    inApp: record.inAppReminder,
    push: record.pushReminder,
    sound: record.soundReminder,
  );

  static RecurringExpenseState _state(ScheduledExpenseState state) =>
      switch (state) {
        ScheduledExpenseState.active => RecurringExpenseState.active,
        ScheduledExpenseState.paused => RecurringExpenseState.paused,
        ScheduledExpenseState.ended => RecurringExpenseState.ended,
      };
}
