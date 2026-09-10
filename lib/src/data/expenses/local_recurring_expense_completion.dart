part of 'local_recurring_expense_repository.dart';

extension _RecurringExpenseCompletion on LocalRecurringExpenseRepository {
  Future<RecurringExpenseMutationResult> _completeOccurrence({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required RecurringExpenseAuditAction action,
    required RecurringExpenseMutationContext context,
    ExpenseMoney? actualAmount,
    DateTime? paidOn,
    String? expenseId,
  }) => _writes.run(() async {
    final currentOccurrence = _occurrences[occurrenceId];
    if (currentOccurrence == null ||
        currentOccurrence.templateId != templateId) {
      throw RecurringExpenseNotFoundException(
        'Recurring payment $occurrenceId does not exist.',
      );
    }
    if (!currentOccurrence.isOpen) {
      final repeatedPaid =
          action == RecurringExpenseAuditAction.occurrencePaid &&
          currentOccurrence.state == RecurringExpenseOccurrenceState.paid &&
          currentOccurrence.expenseId == expenseId;
      final repeatedSkip =
          action == RecurringExpenseAuditAction.occurrenceSkipped &&
          currentOccurrence.state == RecurringExpenseOccurrenceState.skipped;
      if (repeatedPaid || repeatedSkip) {
        return RecurringExpenseMutationResult(
          template: _templates[templateId]!,
          occurrence: currentOccurrence,
          nextOccurrence: openRecurringOccurrenceOrNull(
            _occurrences.values,
            templateId,
          ),
        );
      }
      throw const RecurringExpenseInvalidTransitionException(
        'This payment was already completed differently.',
      );
    }
    final currentTemplate = requireRecurringTemplate(
      _templates,
      templateId,
      expectedTemplateRevision,
    );
    requireRecurringOccurrence(
      _occurrences,
      occurrenceId,
      expectedOccurrenceRevision,
    );
    if (!currentTemplate.isActive) {
      throw const RecurringExpenseInvalidTransitionException(
        'Resume the recurring expense before completing this payment.',
      );
    }
    if (actualAmount != null &&
        actualAmount.currencyCode !=
            currentOccurrence.expectedAmount.currencyCode) {
      throw const RecurringExpenseInvalidTransitionException(
        'Paid and expected currency must match.',
      );
    }
    final completed = currentOccurrence.copyWith(
      state: action == RecurringExpenseAuditAction.occurrencePaid
          ? RecurringExpenseOccurrenceState.paid
          : RecurringExpenseOccurrenceState.skipped,
      paidOn: paidOn == null
          ? null
          : DateTime(paidOn.year, paidOn.month, paidOn.day),
      actualAmount: actualAmount,
      expenseId: expenseId,
      lifecycle: currentOccurrence.lifecycle.nextRevision(
        context.occurredAtUtc,
      ),
      auditTrail: [
        ...currentOccurrence.auditTrail,
        context.auditEvent(
          action: action,
          fromRevision: currentOccurrence.lifecycle.revision,
          toRevision: currentOccurrence.lifecycle.revision + 1,
        ),
      ],
    );
    final advancement = advanceRecurringExpenseTemplate(
      template: currentTemplate,
      completed: completed,
      action: action,
      context: context,
      existingOccurrenceIds: _occurrences.keys.toSet(),
    );
    final nextOccurrences = {..._occurrences, occurrenceId: completed};
    final nextOccurrence = advancement.nextOccurrence;
    if (nextOccurrence != null) {
      nextOccurrences[nextOccurrence.occurrenceId] = nextOccurrence;
    }
    await _persist({
      ..._templates,
      templateId: advancement.template,
    }, nextOccurrences);
    return RecurringExpenseMutationResult(
      template: advancement.template,
      occurrence: completed,
      nextOccurrence: advancement.nextOccurrence,
    );
  });
}
