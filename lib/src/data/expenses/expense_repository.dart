import 'expense_record.dart';

enum ExpenseReadScope { own, team, company }

class ExpenseAccess {
  ExpenseAccess.own({required this.organizationId, required this.employeeId})
    : scope = ExpenseReadScope.own,
      visibleEmployeeIds = {employeeId};

  ExpenseAccess.team({
    required this.organizationId,
    required this.employeeId,
    required Set<String> teamEmployeeIds,
  }) : scope = ExpenseReadScope.team,
       visibleEmployeeIds = {...teamEmployeeIds, employeeId};

  ExpenseAccess.company({
    required this.organizationId,
    required this.employeeId,
  }) : scope = ExpenseReadScope.company,
       visibleEmployeeIds = const {};

  final String organizationId;
  final String employeeId;
  final ExpenseReadScope scope;
  final Set<String> visibleEmployeeIds;

  bool allows(StoredExpenseRecord record) {
    if (record.organizationId != organizationId) return false;
    if (scope == ExpenseReadScope.company) return true;
    return visibleEmployeeIds.contains(record.paidByEmployeeId);
  }
}

class ExpenseQuery {
  const ExpenseQuery({
    required this.access,
    this.fromInclusive,
    this.toExclusive,
    this.includeDeleted = false,
    this.vendorContains,
    this.categoryId,
    this.jobId,
    this.vehicleId,
    this.approvalState,
  });

  final ExpenseAccess access;
  final DateTime? fromInclusive;
  final DateTime? toExclusive;
  final bool includeDeleted;
  final String? vendorContains;
  final String? categoryId;
  final String? jobId;
  final String? vehicleId;
  final ExpenseApprovalState? approvalState;

  bool matches(StoredExpenseRecord record) {
    if (!access.allows(record)) return false;
    if (!includeDeleted && record.lifecycle.isDeleted) return false;
    if (fromInclusive != null && record.expenseDate.isBefore(fromInclusive!)) {
      return false;
    }
    if (toExclusive != null && !record.expenseDate.isBefore(toExclusive!)) {
      return false;
    }
    final vendorNeedle = vendorContains?.trim().toLowerCase();
    if (vendorNeedle != null &&
        vendorNeedle.isNotEmpty &&
        !record.vendorName.toLowerCase().contains(vendorNeedle)) {
      return false;
    }
    if (categoryId != null && record.categoryId != categoryId) return false;
    if (jobId != null && record.jobId != jobId) return false;
    if (vehicleId != null && record.vehicleId != vehicleId) return false;
    if (approvalState != null && record.approval.state != approvalState) {
      return false;
    }
    return true;
  }
}

abstract interface class ExpenseRepository {
  Future<List<StoredExpenseRecord>> query(ExpenseQuery query);

  Future<StoredExpenseRecord?> findById({
    required String expenseId,
    required ExpenseAccess access,
    bool includeDeleted = false,
  });

  Future<StoredExpenseRecord> create(
    StoredExpenseRecord record, {
    required ExpenseMutationContext context,
  });

  Future<StoredExpenseRecord> update(
    StoredExpenseRecord record, {
    required int expectedRevision,
    required ExpenseMutationContext context,
    ExpenseAuditAction auditAction = ExpenseAuditAction.updated,
  });

  Future<StoredExpenseRecord> softDelete({
    required String expenseId,
    required int expectedRevision,
    required ExpenseMutationContext context,
  });

  Future<StoredExpenseRecord> restore({
    required String expenseId,
    required int expectedRevision,
    required ExpenseMutationContext context,
  });

  Future<int> approvedTotalMinorUnits(ExpenseQuery query);
}

class ExpenseMutationContext {
  ExpenseMutationContext({
    required this.actorEmployeeId,
    required DateTime occurredAtUtc,
    required this.permissionRevision,
    this.note,
  }) : occurredAtUtc = occurredAtUtc.toUtc();

  final String actorEmployeeId;
  final DateTime occurredAtUtc;
  final String permissionRevision;
  final String? note;

  ExpenseAuditEvent auditEvent({
    required ExpenseAuditAction action,
    required int? fromRevision,
    required int toRevision,
  }) => ExpenseAuditEvent(
    action: action,
    actorEmployeeId: actorEmployeeId,
    occurredAtUtc: occurredAtUtc,
    fromRevision: fromRevision,
    toRevision: toRevision,
    permissionRevision: permissionRevision,
    note: note,
  );
}

sealed class ExpenseRepositoryException implements Exception {
  const ExpenseRepositoryException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class ExpenseAlreadyExistsException extends ExpenseRepositoryException {
  const ExpenseAlreadyExistsException(super.message);
}

class ExpenseNotFoundException extends ExpenseRepositoryException {
  const ExpenseNotFoundException(super.message);
}

class ExpenseRevisionConflictException extends ExpenseRepositoryException {
  const ExpenseRevisionConflictException(super.message);
}

class ExpenseStorageException extends ExpenseRepositoryException {
  const ExpenseStorageException(super.message);
}

class ExpenseStorageCorruptionException extends ExpenseRepositoryException {
  const ExpenseStorageCorruptionException(super.message);
}

class ExpensePermissionDeniedException extends ExpenseRepositoryException {
  const ExpensePermissionDeniedException(super.message);
}

class ExpenseCorrectionReasonRequiredException
    extends ExpenseRepositoryException {
  const ExpenseCorrectionReasonRequiredException(super.message);
}

class ExpenseApprovalResetRequiredException extends ExpenseRepositoryException {
  const ExpenseApprovalResetRequiredException(super.message);
}
