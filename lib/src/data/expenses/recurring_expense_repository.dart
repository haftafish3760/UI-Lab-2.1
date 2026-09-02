import 'expense_money.dart';
import 'recurring_expense_records.dart';
import 'recurring_expense_terms.dart';

enum RecurringExpenseReadScope { own, team, company }

class RecurringExpenseAccess {
  RecurringExpenseAccess.own({
    required this.organizationId,
    required this.employeeId,
  }) : scope = RecurringExpenseReadScope.own,
       visibleEmployeeIds = {employeeId};

  RecurringExpenseAccess.team({
    required this.organizationId,
    required this.employeeId,
    required Set<String> teamEmployeeIds,
  }) : scope = RecurringExpenseReadScope.team,
       visibleEmployeeIds = {...teamEmployeeIds, employeeId};

  RecurringExpenseAccess.company({
    required this.organizationId,
    required this.employeeId,
  }) : scope = RecurringExpenseReadScope.company,
       visibleEmployeeIds = const {};

  final String organizationId;
  final String employeeId;
  final RecurringExpenseReadScope scope;
  final Set<String> visibleEmployeeIds;

  bool allowsTemplate(StoredRecurringExpenseTemplate record) =>
      record.organizationId == organizationId &&
      (scope == RecurringExpenseReadScope.company ||
          visibleEmployeeIds.contains(record.assignedEmployeeId));

  bool allowsOccurrence(StoredRecurringExpenseOccurrence record) =>
      record.organizationId == organizationId &&
      (scope == RecurringExpenseReadScope.company ||
          visibleEmployeeIds.contains(record.assignedEmployeeId));
}

class RecurringExpenseTemplateQuery {
  const RecurringExpenseTemplateQuery({
    required this.access,
    this.fromInclusive,
    this.toExclusive,
    this.categoryId,
    this.jobId,
    this.vehicleId,
    this.state,
  });

  final RecurringExpenseAccess access;
  final DateTime? fromInclusive;
  final DateTime? toExclusive;
  final String? categoryId;
  final String? jobId;
  final String? vehicleId;
  final RecurringExpenseState? state;

  bool matches(StoredRecurringExpenseTemplate record) {
    if (!access.allowsTemplate(record)) return false;
    if (fromInclusive != null && record.nextDueOn.isBefore(fromInclusive!)) {
      return false;
    }
    if (toExclusive != null && !record.nextDueOn.isBefore(toExclusive!)) {
      return false;
    }
    if (categoryId != null && record.categoryId != categoryId) return false;
    if (jobId != null && record.jobId != jobId) return false;
    if (vehicleId != null && record.vehicleId != vehicleId) return false;
    if (state != null && record.state != state) return false;
    return true;
  }
}

class RecurringExpenseOccurrenceQuery {
  const RecurringExpenseOccurrenceQuery({
    required this.access,
    this.templateId,
    this.fromInclusive,
    this.toExclusive,
    this.state,
  });

  final RecurringExpenseAccess access;
  final String? templateId;
  final DateTime? fromInclusive;
  final DateTime? toExclusive;
  final RecurringExpenseOccurrenceState? state;

  bool matches(StoredRecurringExpenseOccurrence record) {
    if (!access.allowsOccurrence(record)) return false;
    if (templateId != null && record.templateId != templateId) return false;
    if (fromInclusive != null && record.dueOn.isBefore(fromInclusive!)) {
      return false;
    }
    if (toExclusive != null && !record.dueOn.isBefore(toExclusive!)) {
      return false;
    }
    if (state != null && record.state != state) return false;
    return true;
  }
}

class RecurringExpenseMutationResult {
  const RecurringExpenseMutationResult({
    required this.template,
    required this.occurrence,
    this.nextOccurrence,
  });

  final StoredRecurringExpenseTemplate template;
  final StoredRecurringExpenseOccurrence occurrence;
  final StoredRecurringExpenseOccurrence? nextOccurrence;
}

abstract interface class RecurringExpenseRepository {
  Future<List<StoredRecurringExpenseTemplate>> queryTemplates(
    RecurringExpenseTemplateQuery query,
  );

  Future<StoredRecurringExpenseTemplate?> findTemplate({
    required String templateId,
    required RecurringExpenseAccess access,
  });

  Future<List<StoredRecurringExpenseOccurrence>> queryOccurrences(
    RecurringExpenseOccurrenceQuery query,
  );

  Future<StoredRecurringExpenseOccurrence?> findOccurrence({
    required String occurrenceId,
    required RecurringExpenseAccess access,
  });

  Future<RecurringExpenseMutationResult> createTemplate({
    required StoredRecurringExpenseTemplate template,
    required StoredRecurringExpenseOccurrence initialOccurrence,
    required RecurringExpenseMutationContext context,
  });

  Future<RecurringExpenseMutationResult> updateTemplateAndOpenOccurrence({
    required StoredRecurringExpenseTemplate template,
    required int expectedTemplateRevision,
    required RecurringExpenseMutationContext context,
  });

  Future<RecurringExpenseMutationResult> updateOpenOccurrence({
    required String templateId,
    required StoredRecurringExpenseOccurrence occurrence,
    required int expectedTemplateRevision,
    required int expectedRevision,
    required RecurringExpenseMutationContext context,
  });

  Future<StoredRecurringExpenseTemplate> setTemplateState({
    required String templateId,
    required RecurringExpenseState state,
    required int expectedRevision,
    required RecurringExpenseMutationContext context,
  });

  Future<RecurringExpenseMutationResult> skipOccurrence({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required RecurringExpenseMutationContext context,
  });

  /// Commits an occurrence only after an authorized ordinary Expense exists.
  ///
  /// The deterministic [expenseId] makes a retry idempotent. This repository
  /// never creates the Expense and therefore cannot bypass its authorization,
  /// approval, receipt, or audit rules.
  Future<RecurringExpenseMutationResult> recordPaidOccurrence({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required ExpenseMoney actualAmount,
    required DateTime paidOn,
    required String expenseId,
    required RecurringExpenseMutationContext context,
  });
}

class RecurringExpenseMutationContext {
  RecurringExpenseMutationContext({
    required this.actorEmployeeId,
    required DateTime occurredAtUtc,
    required this.permissionRevision,
    this.note,
  }) : occurredAtUtc = occurredAtUtc.toUtc();

  final String actorEmployeeId;
  final DateTime occurredAtUtc;
  final String permissionRevision;
  final String? note;

  RecurringExpenseAuditEvent auditEvent({
    required RecurringExpenseAuditAction action,
    required int? fromRevision,
    required int toRevision,
  }) => RecurringExpenseAuditEvent(
    action: action,
    actorEmployeeId: actorEmployeeId,
    occurredAtUtc: occurredAtUtc,
    fromRevision: fromRevision,
    toRevision: toRevision,
    permissionRevision: permissionRevision,
    note: note,
  );
}

sealed class RecurringExpenseRepositoryException implements Exception {
  const RecurringExpenseRepositoryException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class RecurringExpenseAlreadyExistsException
    extends RecurringExpenseRepositoryException {
  const RecurringExpenseAlreadyExistsException(super.message);
}

class RecurringExpenseNotFoundException
    extends RecurringExpenseRepositoryException {
  const RecurringExpenseNotFoundException(super.message);
}

class RecurringExpenseRevisionConflictException
    extends RecurringExpenseRepositoryException {
  const RecurringExpenseRevisionConflictException(super.message);
}

class RecurringExpenseInvalidTransitionException
    extends RecurringExpenseRepositoryException {
  const RecurringExpenseInvalidTransitionException(super.message);
}

class RecurringExpenseStorageException
    extends RecurringExpenseRepositoryException {
  const RecurringExpenseStorageException(super.message);
}

class RecurringExpenseStorageCorruptionException
    extends RecurringExpenseRepositoryException {
  const RecurringExpenseStorageCorruptionException(super.message);
}

class RecurringExpensePermissionDeniedException
    extends RecurringExpenseRepositoryException {
  const RecurringExpensePermissionDeniedException(super.message);
}
