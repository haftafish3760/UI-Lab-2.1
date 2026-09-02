import 'expense_record.dart';
import 'recurring_expense_records.dart';
import 'recurring_expense_repository.dart';

StoredRecurringExpenseTemplate requireRecurringTemplate(
  Map<String, StoredRecurringExpenseTemplate> templates,
  String id,
  int expectedRevision,
) {
  final current = templates[id];
  if (current == null) {
    throw RecurringExpenseNotFoundException(
      'Recurring expense $id does not exist.',
    );
  }
  if (current.lifecycle.revision != expectedRevision) {
    throw RecurringExpenseRevisionConflictException(
      'Recurring expense $id changed after it was opened.',
    );
  }
  return current;
}

StoredRecurringExpenseOccurrence requireRecurringOccurrence(
  Map<String, StoredRecurringExpenseOccurrence> occurrences,
  String id,
  int expectedRevision,
) {
  final current = occurrences[id];
  if (current == null) {
    throw RecurringExpenseNotFoundException(
      'Recurring payment $id does not exist.',
    );
  }
  if (current.lifecycle.revision != expectedRevision) {
    throw RecurringExpenseRevisionConflictException(
      'Recurring payment $id changed after it was opened.',
    );
  }
  return current;
}

StoredRecurringExpenseOccurrence requireOpenRecurringOccurrence(
  Iterable<StoredRecurringExpenseOccurrence> occurrences,
  String templateId,
) =>
    openRecurringOccurrenceOrNull(occurrences, templateId) ??
    (throw RecurringExpenseNotFoundException(
      'Recurring expense $templateId has no open payment.',
    ));

StoredRecurringExpenseOccurrence? openRecurringOccurrenceOrNull(
  Iterable<StoredRecurringExpenseOccurrence> occurrences,
  String templateId,
) {
  final open = occurrences
      .where((item) => item.templateId == templateId && item.isOpen)
      .toList();
  if (open.length > 1) {
    throw RecurringExpenseStorageCorruptionException(
      'Recurring expense $templateId has more than one open payment.',
    );
  }
  return open.firstOrNull;
}

void ensureRecurringOccurrenceDateAvailable(
  Iterable<StoredRecurringExpenseOccurrence> occurrences,
  String templateId,
  String currentOccurrenceId,
  DateTime dueOn,
) {
  final conflict = occurrences.any(
    (item) =>
        item.occurrenceId != currentOccurrenceId &&
        item.templateId == templateId &&
        expenseDateKey(item.dueOn) == expenseDateKey(dueOn),
  );
  if (conflict) {
    throw const RecurringExpenseRevisionConflictException(
      'Another payment already uses that due date.',
    );
  }
}

void requireRecurringTemplateIdentity(
  StoredRecurringExpenseTemplate current,
  StoredRecurringExpenseTemplate proposed,
) {
  if (proposed.organizationId != current.organizationId ||
      proposed.createdByEmployeeId != current.createdByEmployeeId ||
      proposed.templateId != current.templateId) {
    throw const RecurringExpenseRevisionConflictException(
      'Template organization, creator, and identity cannot be rewritten.',
    );
  }
}

int compareRecurringTemplatesByDueDate(
  StoredRecurringExpenseTemplate a,
  StoredRecurringExpenseTemplate b,
) {
  final date = a.nextDueOn.compareTo(b.nextDueOn);
  return date != 0 ? date : a.templateId.compareTo(b.templateId);
}

int compareRecurringOccurrencesByDueDate(
  StoredRecurringExpenseOccurrence a,
  StoredRecurringExpenseOccurrence b,
) {
  final date = a.dueOn.compareTo(b.dueOn);
  return date != 0 ? date : a.occurrenceId.compareTo(b.occurrenceId);
}
