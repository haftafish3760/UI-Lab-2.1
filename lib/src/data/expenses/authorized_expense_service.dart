import 'expense_record.dart';
import '../storage/local_draft_checkpoint.dart';
import 'expense_repository.dart';

class ExpenseCommandPermissions {
  ExpenseCommandPermissions({
    required this.organizationId,
    required this.actorEmployeeId,
    required this.permissionRevision,
    required this.readScope,
    this.teamEmployeeIds = const {},
    this.canCreate = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canRestore = false,
    this.canApprove = false,
    this.canManageOtherEmployees = false,
  });

  final String organizationId;
  final String actorEmployeeId;
  final String permissionRevision;
  final ExpenseReadScope? readScope;
  final Set<String> teamEmployeeIds;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canRestore;
  final bool canApprove;
  final bool canManageOtherEmployees;

  ExpenseAccess? get readAccess => switch (readScope) {
    null => null,
    ExpenseReadScope.own => ExpenseAccess.own(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
    ),
    ExpenseReadScope.team => ExpenseAccess.team(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
      teamEmployeeIds: teamEmployeeIds,
    ),
    ExpenseReadScope.company => ExpenseAccess.company(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
    ),
  };

  bool canTargetEmployee(String employeeId) {
    if (employeeId == actorEmployeeId) return true;
    if (!canManageOtherEmployees) return false;
    return switch (readScope) {
      ExpenseReadScope.company => true,
      ExpenseReadScope.team => teamEmployeeIds.contains(employeeId),
      ExpenseReadScope.own || null => false,
    };
  }
}

class AuthorizedExpenseService {
  const AuthorizedExpenseService(this._repository);

  final ExpenseRepository _repository;

  Future<StoredExpenseRecord?> findCurrent({
    required String expenseId,
    required ExpenseCommandPermissions permissions,
  }) => _repository.findById(
    expenseId: expenseId,
    access: _requireReadAccess(permissions),
    includeDeleted: true,
  );

  Future<List<StoredExpenseRecord>> query({
    required ExpenseCommandPermissions permissions,
    DateTime? fromInclusive,
    DateTime? toExclusive,
    bool includeDeleted = false,
    String? vendorContains,
    String? categoryId,
    String? jobId,
    String? vehicleId,
    ExpenseApprovalState? approvalState,
  }) async {
    final access = _requireReadAccess(permissions);
    return _repository.query(
      ExpenseQuery(
        access: access,
        fromInclusive: fromInclusive,
        toExclusive: toExclusive,
        includeDeleted: includeDeleted,
        vendorContains: vendorContains,
        categoryId: categoryId,
        jobId: jobId,
        vehicleId: vehicleId,
        approvalState: approvalState,
      ),
    );
  }

  Future<int> approvedTotalMinorUnits({
    required ExpenseCommandPermissions permissions,
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    final access = _requireReadAccess(permissions);
    return _repository.approvedTotalMinorUnits(
      ExpenseQuery(
        access: access,
        fromInclusive: fromInclusive,
        toExclusive: toExclusive,
      ),
    );
  }

  Future<StoredExpenseRecord> create({
    required StoredExpenseRecord record,
    required ExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
    LocalDraftCheckpoint? draftCheckpoint,
  }) async {
    _requireAction(permissions.canCreate, 'create Expenses');
    _requireOrganization(record, permissions);
    if (record.createdByEmployeeId != permissions.actorEmployeeId) {
      throw const ExpensePermissionDeniedException(
        'The creator must match the signed-in employee.',
      );
    }
    _requireTarget(record, permissions);
    if (record.approval.state == ExpenseApprovalState.approved &&
        !permissions.canApprove) {
      throw const ExpensePermissionDeniedException(
        'This employee cannot approve Expenses.',
      );
    }
    return _repository.create(
      record,
      context: _context(permissions, occurredAtUtc, note, draftCheckpoint),
    );
  }

  Future<StoredExpenseRecord> update({
    required StoredExpenseRecord record,
    required int expectedRevision,
    required ExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
    LocalDraftCheckpoint? draftCheckpoint,
  }) async {
    _requireAction(permissions.canEdit, 'edit Expenses');
    final current = await _requireCurrent(record.expenseId, permissions);
    _requireTarget(current, permissions);
    final businessValuesChanged = !record.hasSameBusinessValuesAs(current);
    final receiptCorrection =
        businessValuesChanged && current.receiptId != null;
    if (receiptCorrection && (note == null || note.trim().isEmpty)) {
      throw const ExpenseCorrectionReasonRequiredException(
        'Explain why the confirmed receipt is being corrected.',
      );
    }
    final mustResetApproval =
        businessValuesChanged &&
        current.approval.state != ExpenseApprovalState.notRequired;
    if (mustResetApproval &&
        record.approval.state != ExpenseApprovalState.pending) {
      throw const ExpenseApprovalResetRequiredException(
        'Changed Expense values must return to approval review.',
      );
    }
    final approvalChanged = current.approval.state != record.approval.state;
    final resetForEditedValues =
        mustResetApproval &&
        record.approval.state == ExpenseApprovalState.pending;
    if (approvalChanged && !resetForEditedValues && !permissions.canApprove) {
      throw const ExpensePermissionDeniedException(
        'This employee cannot change Expense approval.',
      );
    }
    return _repository.update(
      record,
      expectedRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc, note, draftCheckpoint),
      auditAction: receiptCorrection
          ? ExpenseAuditAction.corrected
          : approvalChanged
          ? ExpenseAuditAction.approvalChanged
          : ExpenseAuditAction.updated,
    );
  }

  Future<StoredExpenseRecord> softDelete({
    required String expenseId,
    required int expectedRevision,
    required ExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
  }) async {
    _requireAction(permissions.canDelete, 'delete Expenses');
    _requireTarget(await _requireCurrent(expenseId, permissions), permissions);
    return _repository.softDelete(
      expenseId: expenseId,
      expectedRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc, note),
    );
  }

  Future<StoredExpenseRecord> restore({
    required String expenseId,
    required int expectedRevision,
    required ExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
  }) async {
    _requireAction(permissions.canRestore, 'restore Expenses');
    _requireTarget(
      await _requireCurrent(expenseId, permissions, includeDeleted: true),
      permissions,
    );
    return _repository.restore(
      expenseId: expenseId,
      expectedRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc, note),
    );
  }

  Future<StoredExpenseRecord> _requireCurrent(
    String expenseId,
    ExpenseCommandPermissions permissions, {
    bool includeDeleted = false,
  }) async {
    final record = await _repository.findById(
      expenseId: expenseId,
      access: ExpenseAccess.company(
        organizationId: permissions.organizationId,
        employeeId: permissions.actorEmployeeId,
      ),
      includeDeleted: includeDeleted,
    );
    if (record == null) {
      throw const ExpenseNotFoundException('Expense does not exist.');
    }
    return record;
  }

  ExpenseAccess _requireReadAccess(ExpenseCommandPermissions permissions) {
    final access = permissions.readAccess;
    if (access == null) {
      throw const ExpensePermissionDeniedException(
        'This employee cannot view Expenses.',
      );
    }
    return access;
  }

  void _requireOrganization(
    StoredExpenseRecord record,
    ExpenseCommandPermissions permissions,
  ) {
    if (record.organizationId != permissions.organizationId) {
      throw const ExpensePermissionDeniedException(
        'The Expense is outside this company.',
      );
    }
  }

  void _requireTarget(
    StoredExpenseRecord record,
    ExpenseCommandPermissions permissions,
  ) {
    _requireOrganization(record, permissions);
    if (!permissions.canTargetEmployee(record.paidByEmployeeId)) {
      throw const ExpensePermissionDeniedException(
        'This employee cannot change that Expense.',
      );
    }
  }

  void _requireAction(bool allowed, String action) {
    if (!allowed) {
      throw ExpensePermissionDeniedException('This employee cannot $action.');
    }
  }

  ExpenseMutationContext _context(
    ExpenseCommandPermissions permissions,
    DateTime occurredAtUtc,
    String? note, [
    LocalDraftCheckpoint? draftCheckpoint,
  ]) {
    final repository = _repository;
    if (draftCheckpoint != null &&
        (repository is! ExpenseDraftConfirmationRepository ||
            !repository.supportsDraftConfirmation)) {
      throw const ExpenseStorageException(
        'This storage cannot safely confirm a saved draft.',
      );
    }
    return ExpenseMutationContext(
      actorEmployeeId: permissions.actorEmployeeId,
      occurredAtUtc: occurredAtUtc,
      permissionRevision: permissions.permissionRevision,
      note: note,
      draftCheckpoint: draftCheckpoint,
    );
  }
}
