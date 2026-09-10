import 'expense_workflow_models.dart';
import '../storage/local_draft_checkpoint.dart';
import 'authorized_expense_service.dart';
import 'expense_record.dart';
import 'expense_record_adapter.dart';
import 'expense_repository.dart';
import 'expense_ui_projection.dart';

typedef ExpenseEmployeeLabelResolver = String Function(String employeeId);
typedef ExpenseJobLabelResolver = String? Function(String jobId);

enum ExpenseUiBridgeFailureKind {
  permission,
  conflict,
  storage,
  missingRecord,
  unsupportedReceiptData,
  invalidRecord,
  unknown,
}

class ExpenseUiBridgeException implements Exception {
  const ExpenseUiBridgeException({
    required this.kind,
    required this.userMessage,
    this.cause,
  });

  final ExpenseUiBridgeFailureKind kind;
  final String userMessage;
  final Object? cause;

  @override
  String toString() => userMessage;
}

/// Converts the accepted manual Expense UI model into authorized repository
/// commands without allowing presentation labels or receipt claims to become
/// authorization or evidence identities.
///
/// Receipt evidence and proposals retain their separate workflow ownership.
class ExpenseUiRepositoryBridge {
  factory ExpenseUiRepositoryBridge({
    required AuthorizedExpenseService service,
    required ExpenseEmployeeLabelResolver employeeLabelForId,
    required ExpenseJobLabelResolver jobLabelForId,
  }) => ExpenseUiRepositoryBridge._(service, employeeLabelForId, jobLabelForId);

  ExpenseUiRepositoryBridge._(
    this._service,
    this._employeeLabelForId,
    this._jobLabelForId,
  );

  final AuthorizedExpenseService _service;
  final ExpenseEmployeeLabelResolver _employeeLabelForId;
  final ExpenseJobLabelResolver _jobLabelForId;
  final Map<String, StoredExpenseRecord> _loadedById = {};

  Future<ExpenseUiProjectionRecord?> readCurrent(
    String id,
    ExpenseCommandPermissions permissions,
  ) async {
    final record = await _service.findCurrent(
      expenseId: id,
      permissions: permissions,
    );
    return record == null ? null : _toProjectionRecord(record);
  }

  Future<ExpenseUiProjectionSnapshot> loadProjection({
    required ExpenseCommandPermissions permissions,
    DateTime? fromInclusive,
    DateTime? toExclusive,
  }) async {
    try {
      final stored = await _service.query(
        permissions: permissions,
        fromInclusive: fromInclusive,
        toExclusive: toExclusive,
        includeDeleted: true,
      );
      _loadedById.addEntries(
        stored.map((record) => MapEntry(record.expenseId, record)),
      );
      return ExpenseUiProjectionSnapshot(
        active: stored
            .where((record) => !record.lifecycle.isDeleted)
            .map(_toProjectionRecord),
        deleted: stored
            .where((record) => record.lifecycle.isDeleted)
            .map(_toProjectionRecord),
      );
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  Future<List<ExpenseRecord>> load({
    required ExpenseCommandPermissions permissions,
    DateTime? fromInclusive,
    DateTime? toExclusive,
  }) async {
    final projection = await loadProjection(
      permissions: permissions,
      fromInclusive: fromInclusive,
      toExclusive: toExclusive,
    );
    return projection.records;
  }

  Future<List<ExpenseRecord>> loadDeleted({
    required ExpenseCommandPermissions permissions,
    DateTime? fromInclusive,
    DateTime? toExclusive,
  }) async {
    final projection = await loadProjection(
      permissions: permissions,
      fromInclusive: fromInclusive,
      toExclusive: toExclusive,
    );
    return projection.deletedRecords;
  }

  ExpenseUiProjectionRecord? projectionForId(String expenseId) {
    final stored = _loadedById[expenseId];
    return stored == null ? null : _toProjectionRecord(stored);
  }

  String? receiptIdForId(String expenseId) => _loadedById[expenseId]?.receiptId;

  int? revisionForId(String expenseId) =>
      _loadedById[expenseId]?.lifecycle.revision;

  Future<ExpenseRecord> create({
    required ExpenseRecord record,
    required ExpenseCommandPermissions permissions,
    required String paidByEmployeeId,
    required DateTime occurredAtUtc,
    LocalDraftCheckpoint? draftCheckpoint,
  }) => _create(
    record: record,
    permissions: permissions,
    paidByEmployeeId: paidByEmployeeId,
    occurredAtUtc: occurredAtUtc,
    draftCheckpoint: draftCheckpoint,
  );

  Future<ExpenseRecord> createFromReceiptDraft({
    required ExpenseRecord record,
    required String receiptDraftId,
    required ExpenseCommandPermissions permissions,
    required String paidByEmployeeId,
    required DateTime occurredAtUtc,
  }) {
    if (receiptDraftId.trim().isEmpty) {
      throw const ExpenseUiBridgeException(
        kind: ExpenseUiBridgeFailureKind.invalidRecord,
        userMessage: 'The retained receipt identity is missing.',
      );
    }
    if (record.prepareMaterialsReview || record.requiresSubmitterAttention) {
      throw const ExpenseUiBridgeException(
        kind: ExpenseUiBridgeFailureKind.unsupportedReceiptData,
        userMessage:
            'Finish reviewing receipt and material suggestions before saving.',
      );
    }
    return _create(
      record: record,
      permissions: permissions,
      paidByEmployeeId: paidByEmployeeId,
      occurredAtUtc: occurredAtUtc,
      receiptDraftId: receiptDraftId,
    );
  }

  Future<ExpenseRecord> _create({
    required ExpenseRecord record,
    required ExpenseCommandPermissions permissions,
    required String paidByEmployeeId,
    required DateTime occurredAtUtc,
    String? receiptDraftId,
    LocalDraftCheckpoint? draftCheckpoint,
  }) async {
    if (receiptDraftId == null) _requireSupportedCreateRecord(record);
    if (record.paidByEmployeeId != null &&
        record.paidByEmployeeId != paidByEmployeeId) {
      throw const ExpenseUiBridgeException(
        kind: ExpenseUiBridgeFailureKind.invalidRecord,
        userMessage:
            'The employee on this expense changed before it was saved.',
      );
    }
    try {
      var stored = ExpenseRecordAdapter.fromUiRecord(
        record: record,
        organizationId: permissions.organizationId,
        createdByEmployeeId: permissions.actorEmployeeId,
        paidByEmployeeId: paidByEmployeeId,
        nowUtc: occurredAtUtc,
        receiptId: receiptDraftId,
      );
      stored = stored.copyWith(
        approval: _decisionEvidence(
          stored.approval,
          actorEmployeeId: permissions.actorEmployeeId,
          occurredAtUtc: occurredAtUtc,
        ),
      );
      final created = await _service.create(
        record: stored,
        permissions: permissions,
        occurredAtUtc: occurredAtUtc,
        draftCheckpoint: draftCheckpoint,
      );
      _loadedById[created.expenseId] = created;
      return _toUiRecord(created);
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  Future<ExpenseRecord> update({
    required ExpenseRecord record,
    required ExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? auditNote,
    int? expectedRevision,
    LocalDraftCheckpoint? draftCheckpoint,
  }) async {
    try {
      final current = await _findLoadedRecord(record.id, permissions);
      if (draftCheckpoint != null && expectedRevision == null) {
        throw const ExpenseRevisionConflictException(
          'The saved expense revision is required to confirm this draft.',
        );
      }
      if (expectedRevision != null &&
          current.lifecycle.revision != expectedRevision) {
        throw const ExpenseRevisionConflictException(
          'This expense changed after the draft was started.',
        );
      }
      _requireSupportedUpdateRecord(record, current);
      if (record.paidByEmployeeId != current.paidByEmployeeId) {
        throw const ExpenseUiBridgeException(
          kind: ExpenseUiBridgeFailureKind.invalidRecord,
          userMessage:
              'The employee on this expense changed before it was saved.',
        );
      }
      var stored = ExpenseRecordAdapter.fromUiRecord(
        record: record,
        organizationId: current.organizationId,
        createdByEmployeeId: current.createdByEmployeeId,
        paidByEmployeeId: current.paidByEmployeeId,
        nowUtc: current.lifecycle.createdAtUtc,
        receiptId: current.receiptId,
        receiptImageCountOverride: current.receiptImageCount,
        expenseTimeMinutes: current.expenseTimeMinutes,
        vehicleId: current.vehicleId,
        revision: current.lifecycle.revision,
      );
      final businessValuesChanged = !stored.hasSameBusinessValuesAs(current);
      if (businessValuesChanged &&
          current.approval.state != ExpenseApprovalState.notRequired) {
        stored = stored.copyWith(approval: const ExpenseApproval.pending());
      }
      stored = stored.copyWith(
        approval: _decisionEvidence(
          stored.approval,
          actorEmployeeId: permissions.actorEmployeeId,
          occurredAtUtc: occurredAtUtc,
        ),
      );
      final updated = await _service.update(
        record: stored,
        expectedRevision: current.lifecycle.revision,
        permissions: permissions,
        occurredAtUtc: occurredAtUtc,
        note: auditNote,
        draftCheckpoint: draftCheckpoint,
      );
      _loadedById[updated.expenseId] = updated;
      return _toUiRecord(updated);
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  Future<ExpenseRecord> softDelete({
    required String expenseId,
    required ExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
  }) async {
    try {
      final current = await _findLoadedRecord(expenseId, permissions);
      final deleted = await _service.softDelete(
        expenseId: expenseId,
        expectedRevision: current.lifecycle.revision,
        permissions: permissions,
        occurredAtUtc: occurredAtUtc,
      );
      _loadedById[deleted.expenseId] = deleted;
      return _toUiRecord(deleted);
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  Future<ExpenseRecord> restore({
    required String expenseId,
    required ExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
  }) async {
    try {
      final current = await _findLoadedRecord(
        expenseId,
        permissions,
        includeDeleted: true,
      );
      final restored = await _service.restore(
        expenseId: expenseId,
        expectedRevision: current.lifecycle.revision,
        permissions: permissions,
        occurredAtUtc: occurredAtUtc,
      );
      _loadedById[restored.expenseId] = restored;
      return _toUiRecord(restored);
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  Future<StoredExpenseRecord> _findLoadedRecord(
    String expenseId,
    ExpenseCommandPermissions permissions, {
    bool includeDeleted = false,
  }) async {
    final cached = _loadedById[expenseId];
    if (cached != null) return cached;
    final visible = await _service.query(
      permissions: permissions,
      includeDeleted: includeDeleted,
    );
    _loadedById.addEntries(
      visible.map((record) => MapEntry(record.expenseId, record)),
    );
    return _loadedById[expenseId] ??
        (throw const ExpenseNotFoundException('Expense does not exist.'));
  }

  ExpenseRecord _toUiRecord(StoredExpenseRecord record) =>
      ExpenseRecordAdapter.toUiRecord(
        record: record,
        ownerDisplayName: _employeeLabelForId(record.paidByEmployeeId),
        jobDisplayName: record.jobId == null
            ? null
            : _jobLabelForId(record.jobId!),
      );

  ExpenseUiProjectionRecord _toProjectionRecord(StoredExpenseRecord record) =>
      ExpenseUiProjectionRecord(
        record: _toUiRecord(record),
        exactTotal: record.total,
        paidByEmployeeId: record.paidByEmployeeId,
        expenseDate: record.expenseDate,
        expenseTimeMinutes: record.expenseTimeMinutes,
        categoryId: record.categoryId,
        jobId: record.jobId,
        vehicleId: record.vehicleId,
        approvalState: record.approval.state,
        revision: record.lifecycle.revision,
        isDeleted: record.lifecycle.isDeleted,
      );
}

void _requireSupportedCreateRecord(ExpenseRecord record) {
  final hasReceiptOwnedData =
      record.receiptImageCount > 0 ||
      record.prepareMaterialsReview ||
      record.requiresSubmitterAttention;
  if (hasReceiptOwnedData) {
    throw const ExpenseUiBridgeException(
      kind: ExpenseUiBridgeFailureKind.unsupportedReceiptData,
      userMessage:
          'This receipt contains details that are not connected to durable '
          'receipt storage yet. Nothing was saved or discarded.',
    );
  }
}

void _requireSupportedUpdateRecord(
  ExpenseRecord record,
  StoredExpenseRecord current,
) {
  if (record.prepareMaterialsReview || record.requiresSubmitterAttention) {
    throw const ExpenseUiBridgeException(
      kind: ExpenseUiBridgeFailureKind.unsupportedReceiptData,
      userMessage:
          'This receipt contains details that are not connected to durable '
          'receipt storage yet. Nothing was saved or discarded.',
    );
  }
  final existingImageCount = current.receiptImageCount ?? 0;
  if (record.receiptImageCount != existingImageCount) {
    throw const ExpenseUiBridgeException(
      kind: ExpenseUiBridgeFailureKind.unsupportedReceiptData,
      userMessage:
          'Receipt images must be changed from the receipt evidence flow. '
          'The expense was not changed.',
    );
  }
}

ExpenseApproval _decisionEvidence(
  ExpenseApproval approval, {
  required String actorEmployeeId,
  required DateTime occurredAtUtc,
}) {
  if (approval.state != ExpenseApprovalState.approved &&
      approval.state != ExpenseApprovalState.declined) {
    return approval;
  }
  return ExpenseApproval(
    state: approval.state,
    decidedByEmployeeId: actorEmployeeId,
    decidedAtUtc: occurredAtUtc.toUtc(),
    note: approval.note,
  );
}

ExpenseUiBridgeException _translate(Object error) {
  if (error is ExpenseUiBridgeException) return error;
  if (error is ExpensePermissionDeniedException) {
    return ExpenseUiBridgeException(
      kind: ExpenseUiBridgeFailureKind.permission,
      userMessage: error.message,
      cause: error,
    );
  }
  if (error is ExpenseCorrectionReasonRequiredException ||
      error is ExpenseApprovalResetRequiredException) {
    return ExpenseUiBridgeException(
      kind: ExpenseUiBridgeFailureKind.invalidRecord,
      userMessage: (error as ExpenseRepositoryException).message,
      cause: error,
    );
  }
  if (error is ExpenseRevisionConflictException) {
    return ExpenseUiBridgeException(
      kind: ExpenseUiBridgeFailureKind.conflict,
      userMessage:
          'This expense changed after it was opened. Reload it before '
          'saving another change.',
      cause: error,
    );
  }
  if (error is ExpenseAlreadyExistsException) {
    return ExpenseUiBridgeException(
      kind: ExpenseUiBridgeFailureKind.conflict,
      userMessage:
          'This expense already exists. Reload the expense list before '
          'trying again.',
      cause: error,
    );
  }
  if (error is ExpenseStorageException ||
      error is ExpenseStorageCorruptionException) {
    return ExpenseUiBridgeException(
      kind: ExpenseUiBridgeFailureKind.storage,
      userMessage:
          'The expense was not saved. Previously saved records remain '
          'available. Check device storage and try again.',
      cause: error,
    );
  }
  if (error is ExpenseNotFoundException) {
    return ExpenseUiBridgeException(
      kind: ExpenseUiBridgeFailureKind.missingRecord,
      userMessage: 'This expense is no longer available. Reload the list.',
      cause: error,
    );
  }
  if (error is FormatException || error is ArgumentError) {
    return ExpenseUiBridgeException(
      kind: ExpenseUiBridgeFailureKind.invalidRecord,
      userMessage: 'Review the expense date and amount before saving.',
      cause: error,
    );
  }
  return ExpenseUiBridgeException(
    kind: ExpenseUiBridgeFailureKind.unknown,
    userMessage: 'The expense was not saved. Try again.',
    cause: error,
  );
}
