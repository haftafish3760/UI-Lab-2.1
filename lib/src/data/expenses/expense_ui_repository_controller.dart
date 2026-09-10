import 'package:flutter/widgets.dart';

import 'expense_workflow_models.dart';
import '../storage/draft_repository.dart';
import '../storage/local_draft_checkpoint.dart';
import 'authorized_expense_service.dart';
import 'expense_ui_projection.dart';
import 'expense_ui_repository_bridge.dart';

enum ExpenseRepositoryControllerPhase { idle, loading, ready, failed }

enum ExpenseRepositoryOperation { load, create, update, delete, restore }

@immutable
class ExpenseRepositoryFailure {
  const ExpenseRepositoryFailure({
    required this.operation,
    required this.kind,
    required this.message,
    this.expenseId,
  });

  final ExpenseRepositoryOperation operation;
  final ExpenseUiBridgeFailureKind kind;
  final String message;
  final String? expenseId;

  bool get requiresReload => kind == ExpenseUiBridgeFailureKind.conflict;
}

/// Owns one authorized, offline Expense session for the accepted UI.
///
/// The controller deliberately stays separate from [ExpensePrototypeStore]
/// until every Expense read and mutation can switch in one bounded cutover.
class ExpenseUiRepositoryController extends ChangeNotifier {
  ExpenseUiRepositoryController(
    this._bridge,
    this._permissions, {
    bool recoveredFromDamagedSnapshot = false,
    this.drafts,
  }) : _showRecoveryNotice = recoveredFromDamagedSnapshot;

  final DraftRepository? drafts;
  final ExpenseUiRepositoryBridge _bridge;
  final ExpenseCommandPermissions _permissions;
  ExpenseUiProjectionSnapshot _projection = ExpenseUiProjectionSnapshot.empty;
  final Set<String> _pendingExpenseIds = {};
  ExpenseRepositoryControllerPhase _phase =
      ExpenseRepositoryControllerPhase.idle;
  ExpenseRepositoryFailure? _failure;
  DateTime? _fromInclusive;
  DateTime? _toExclusive;
  bool _creating = false;
  bool _showRecoveryNotice;
  bool _disposed = false;

  void requireActiveDraftOwner() {
    if (_disposed) {
      throw StateError('The expense workflow owner is no longer active.');
    }
  }

  ExpenseRepositoryControllerPhase get phase => _phase;
  String get organizationId => _permissions.organizationId;
  String get actorEmployeeId => _permissions.actorEmployeeId;
  bool canCreateForEmployee(String employeeId) =>
      !_disposed &&
      _permissions.canCreate &&
      _permissions.readAccess != null &&
      _permissions.canTargetEmployee(employeeId);
  bool canEditExpense(String expenseId) {
    final record = recordById(expenseId);
    return _permissions.canEdit &&
        record != null &&
        record.paidByEmployeeId != null &&
        _permissions.canTargetEmployee(record.paidByEmployeeId!);
  }

  bool canEditForEmployee(String employeeId) =>
      _permissions.canEdit &&
      _permissions.readAccess != null &&
      _permissions.canTargetEmployee(employeeId);

  Future<ExpenseUiProjectionRecord?> readCurrentExpense(String id) =>
      _bridge.readCurrent(id, _permissions);

  int? revisionForId(String expenseId) => _bridge.revisionForId(expenseId);
  ExpenseRepositoryFailure? get failure => _failure;
  ExpenseUiProjectionSnapshot get projection => _projection;
  List<ExpenseRecord> get records => _projection.records;
  List<ExpenseRecord> get deletedRecords => _projection.deletedRecords;
  bool get isLoading => _phase == ExpenseRepositoryControllerPhase.loading;
  bool get isCreating => _creating;
  bool get isBusy => isLoading || _creating || _pendingExpenseIds.isNotEmpty;
  bool get showRecoveryNotice => _showRecoveryNotice;
  bool isPending(String expenseId) => _pendingExpenseIds.contains(expenseId);

  ExpenseRecord? recordById(String expenseId) =>
      _projection.recordById(expenseId);

  String? receiptIdForExpense(String expenseId) =>
      _bridge.receiptIdForId(expenseId);

  Future<bool> load({DateTime? fromInclusive, DateTime? toExclusive}) async {
    _fromInclusive = fromInclusive;
    _toExclusive = toExclusive;
    _phase = ExpenseRepositoryControllerPhase.loading;
    _failure = null;
    _notify();
    try {
      _projection = await _loadProjection();
      _phase = ExpenseRepositoryControllerPhase.ready;
      _notify();
      return true;
    } on ExpenseUiBridgeException catch (error) {
      _failure = _failureFrom(error, ExpenseRepositoryOperation.load);
      _phase = ExpenseRepositoryControllerPhase.failed;
      _notify();
      return false;
    }
  }

  Future<ExpenseRecord?> create({
    required ExpenseRecord record,
    required String paidByEmployeeId,
    required DateTime occurredAtUtc,
    LocalDraftCheckpoint? draftCheckpoint,
  }) async {
    if (_disposed || _creating) return null;
    _creating = true;
    _failure = null;
    _notify();
    try {
      final created = await _bridge.create(
        record: record,
        permissions: _permissions,
        paidByEmployeeId: paidByEmployeeId,
        occurredAtUtc: occurredAtUtc,
        draftCheckpoint: draftCheckpoint,
      );
      _applyCachedProjection(created.id);
      _phase = ExpenseRepositoryControllerPhase.ready;
      return created;
    } on ExpenseUiBridgeException catch (error) {
      _failure = _failureFrom(
        error,
        ExpenseRepositoryOperation.create,
        expenseId: record.id,
      );
      return null;
    } finally {
      _creating = false;
      _notify();
    }
  }

  Future<ExpenseRecord?> createFromReceiptDraft({
    required ExpenseRecord record,
    required String receiptDraftId,
    required String paidByEmployeeId,
    required DateTime occurredAtUtc,
  }) async {
    if (_disposed || _creating) return null;
    _creating = true;
    _failure = null;
    _notify();
    try {
      final created = await _bridge.createFromReceiptDraft(
        record: record,
        receiptDraftId: receiptDraftId,
        permissions: _permissions,
        paidByEmployeeId: paidByEmployeeId,
        occurredAtUtc: occurredAtUtc,
      );
      _applyCachedProjection(created.id);
      _phase = ExpenseRepositoryControllerPhase.ready;
      return created;
    } on ExpenseUiBridgeException catch (error) {
      _failure = _failureFrom(
        error,
        ExpenseRepositoryOperation.create,
        expenseId: record.id,
      );
      return null;
    } finally {
      _creating = false;
      _notify();
    }
  }

  Future<ExpenseRecord?> update({
    required ExpenseRecord record,
    required DateTime occurredAtUtc,
    String? auditNote,
    int? expectedRevision,
    LocalDraftCheckpoint? draftCheckpoint,
  }) => _mutateRecord(
    expenseId: record.id,
    operation: ExpenseRepositoryOperation.update,
    action: () => _bridge.update(
      record: record,
      permissions: _permissions,
      occurredAtUtc: occurredAtUtc,
      auditNote: auditNote,
      expectedRevision: expectedRevision,
      draftCheckpoint: draftCheckpoint,
    ),
  );

  Future<bool> softDelete({
    required String expenseId,
    required DateTime occurredAtUtc,
  }) async {
    final deleted = await _mutateRecord(
      expenseId: expenseId,
      operation: ExpenseRepositoryOperation.delete,
      action: () => _bridge.softDelete(
        expenseId: expenseId,
        permissions: _permissions,
        occurredAtUtc: occurredAtUtc,
      ),
    );
    return deleted != null;
  }

  Future<ExpenseRecord?> restore({
    required String expenseId,
    required DateTime occurredAtUtc,
  }) => _mutateRecord(
    expenseId: expenseId,
    operation: ExpenseRepositoryOperation.restore,
    action: () => _bridge.restore(
      expenseId: expenseId,
      permissions: _permissions,
      occurredAtUtc: occurredAtUtc,
    ),
  );

  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    if (_phase == ExpenseRepositoryControllerPhase.failed) {
      _phase = ExpenseRepositoryControllerPhase.ready;
    }
    _notify();
  }

  void dismissRecoveryNotice() {
    if (!_showRecoveryNotice) return;
    _showRecoveryNotice = false;
    _notify();
  }

  Future<ExpenseRecord?> _mutateRecord({
    required String expenseId,
    required ExpenseRepositoryOperation operation,
    required Future<ExpenseRecord> Function() action,
  }) async {
    if (_disposed || _pendingExpenseIds.contains(expenseId)) return null;
    _pendingExpenseIds.add(expenseId);
    _failure = null;
    _notify();
    try {
      final result = await action();
      _applyCachedProjection(result.id);
      _phase = ExpenseRepositoryControllerPhase.ready;
      return result;
    } on ExpenseUiBridgeException catch (error) {
      _failure = _failureFrom(error, operation, expenseId: expenseId);
      if (error.kind == ExpenseUiBridgeFailureKind.conflict) {
        await _reloadAfterConflict();
      }
      return null;
    } finally {
      _pendingExpenseIds.remove(expenseId);
      _notify();
    }
  }

  Future<ExpenseUiProjectionSnapshot> _loadProjection() =>
      _bridge.loadProjection(
        permissions: _permissions,
        fromInclusive: _fromInclusive,
        toExclusive: _toExclusive,
      );

  Future<void> _reloadAfterConflict() async {
    final conflict = _failure;
    try {
      _projection = await _loadProjection();
      _phase = ExpenseRepositoryControllerPhase.ready;
    } on ExpenseUiBridgeException {
      // Preserve the conflict instruction and the last known-good lists.
    } finally {
      _failure = conflict;
    }
  }

  void _applyCachedProjection(String expenseId) {
    final changed = _bridge.projectionForId(expenseId);
    if (changed == null) {
      throw StateError('The saved Expense projection is unavailable.');
    }
    if (_isInLoadedWindow(changed)) {
      _projection = _projection.upsert(changed);
    } else {
      _projection = _projection.remove(expenseId);
    }
  }

  bool _isInLoadedWindow(ExpenseUiProjectionRecord projection) {
    final date = projection.expenseDate;
    if (_fromInclusive != null && date.isBefore(_fromInclusive!)) return false;
    if (_toExclusive != null && !date.isBefore(_toExclusive!)) return false;
    return true;
  }

  ExpenseRepositoryFailure _failureFrom(
    ExpenseUiBridgeException error,
    ExpenseRepositoryOperation operation, {
    String? expenseId,
  }) => ExpenseRepositoryFailure(
    operation: operation,
    kind: error.kind,
    message: error.userMessage,
    expenseId: expenseId,
  );

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ExpenseUiScope extends InheritedNotifier<ExpenseUiRepositoryController> {
  const ExpenseUiScope({
    required ExpenseUiRepositoryController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ExpenseUiRepositoryController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ExpenseUiScope>();
    assert(scope != null, 'ExpenseUiScope is missing.');
    return scope!.notifier!;
  }

  static ExpenseUiRepositoryController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExpenseUiScope>()?.notifier;
}
