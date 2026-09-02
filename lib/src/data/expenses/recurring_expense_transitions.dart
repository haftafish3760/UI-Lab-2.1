import 'expense_record.dart';
import 'recurring_expense_records.dart';
import 'recurring_expense_repository.dart';
import 'recurring_expense_terms.dart';

class RecurringExpenseAdvancement {
  const RecurringExpenseAdvancement({
    required this.template,
    this.nextOccurrence,
  });

  final StoredRecurringExpenseTemplate template;
  final StoredRecurringExpenseOccurrence? nextOccurrence;
}

String recurringExpenseOccurrenceId(String templateId, DateTime dueOn) =>
    '$templateId:${expenseDateKey(dueOn)}';

void validateInitialRecurringOccurrence(
  StoredRecurringExpenseTemplate template,
  StoredRecurringExpenseOccurrence occurrence,
) {
  if (template.lifecycle.revision != 1 ||
      occurrence.lifecycle.revision != 1 ||
      template.state == RecurringExpenseState.ended ||
      occurrence.templateId != template.templateId ||
      occurrence.organizationId != template.organizationId ||
      occurrence.assignedEmployeeId != template.assignedEmployeeId ||
      occurrence.state != RecurringExpenseOccurrenceState.due ||
      expenseDateKey(occurrence.dueOn) != expenseDateKey(template.nextDueOn) ||
      occurrence.expectedAmount != template.expectedAmount) {
    throw const RecurringExpenseInvalidTransitionException(
      'The first payment must match the new recurring expense.',
    );
  }
}

RecurringExpenseAdvancement advanceRecurringExpenseTemplate({
  required StoredRecurringExpenseTemplate template,
  required StoredRecurringExpenseOccurrence completed,
  required RecurringExpenseAuditAction action,
  required RecurringExpenseMutationContext context,
  required Set<String> existingOccurrenceIds,
}) {
  final nextDue = template.schedule.nextDueAfter(completed.dueOn);
  final nextRevision = template.lifecycle.revision + 1;
  if (nextDue == null) {
    return RecurringExpenseAdvancement(
      template: template.copyWith(
        state: RecurringExpenseState.ended,
        lifecycle: template.lifecycle.nextRevision(context.occurredAtUtc),
        auditTrail: [
          ...template.auditTrail,
          context.auditEvent(
            action: RecurringExpenseAuditAction.templateEnded,
            fromRevision: template.lifecycle.revision,
            toRevision: nextRevision,
          ),
        ],
      ),
    );
  }
  final nextId = recurringExpenseOccurrenceId(template.templateId, nextDue);
  if (existingOccurrenceIds.contains(nextId)) {
    throw RecurringExpenseRevisionConflictException(
      'The next payment $nextId already exists.',
    );
  }
  final advanced = template.copyWith(
    nextDueOn: nextDue,
    lifecycle: template.lifecycle.nextRevision(context.occurredAtUtc),
    auditTrail: [
      ...template.auditTrail,
      context.auditEvent(
        action: action,
        fromRevision: template.lifecycle.revision,
        toRevision: nextRevision,
      ),
    ],
  );
  final next = StoredRecurringExpenseOccurrence(
    occurrenceId: nextId,
    templateId: template.templateId,
    organizationId: template.organizationId,
    assignedEmployeeId: template.assignedEmployeeId,
    dueOn: nextDue,
    expectedAmount: template.expectedAmount,
    state: RecurringExpenseOccurrenceState.due,
    lifecycle: RecurringExpenseLifecycle(
      revision: 1,
      createdAtUtc: context.occurredAtUtc,
      updatedAtUtc: context.occurredAtUtc,
    ),
    auditTrail: [
      context.auditEvent(
        action: RecurringExpenseAuditAction.occurrenceCreated,
        fromRevision: null,
        toRevision: 1,
      ),
    ],
  );
  return RecurringExpenseAdvancement(template: advanced, nextOccurrence: next);
}
