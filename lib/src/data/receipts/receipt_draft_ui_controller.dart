import 'receipt_entry_setup.dart';
import 'package:flutter/widgets.dart';

import 'authorized_receipt_draft_service.dart';
import 'receipt_draft_record.dart';
import 'receipt_draft_repository.dart';
import 'receipt_selected_details.dart';
import 'receipt_item_read.dart';

enum ReceiptDraftUiPhase { idle, loading, ready, failed }

enum ReceiptDraftUiOperation { load, create, update, submit, discard }

enum ReceiptDraftUiFailureKind {
  permission,
  conflict,
  storage,
  corruption,
  notFound,
  invalid,
  unknown,
}

@immutable
class ReceiptDraftUiFailure {
  const ReceiptDraftUiFailure({
    required this.operation,
    required this.kind,
    required this.message,
    this.draftId,
  });

  final ReceiptDraftUiOperation operation;
  final ReceiptDraftUiFailureKind kind;
  final String message;
  final String? draftId;

  bool get requiresReload => kind == ReceiptDraftUiFailureKind.conflict;
}

@immutable
class ReceiptDraftLookupResult {
  const ReceiptDraftLookupResult.found(StoredReceiptDraft this.record)
    : failure = null;

  const ReceiptDraftLookupResult.failed(ReceiptDraftUiFailure this.failure)
    : record = null;

  final StoredReceiptDraft? record;
  final ReceiptDraftUiFailure? failure;

  bool get succeeded => record != null;
}

/// Owns one authorized, offline Receipt Draft session for the accepted UI.
///
/// Source evidence is copied by [ReceiptDraftRepository]. The controller keeps
/// only durable repository records and preserves its last known-good list when
/// a load or mutation fails.
class ReceiptDraftUiController extends ChangeNotifier {
  ReceiptDraftUiController(
    this._service,
    this._permissions, {
    bool recoveredFromDamagedSnapshot = false,
  }) : _showRecoveryNotice = recoveredFromDamagedSnapshot;

  final AuthorizedReceiptDraftService _service;
  final ReceiptDraftCommandPermissions _permissions;
  final Map<String, StoredReceiptDraft> _drafts = {};
  final Set<String> _pendingDraftIds = {};
  ReceiptDraftUiPhase _phase = ReceiptDraftUiPhase.idle;
  ReceiptDraftUiFailure? _failure;
  bool _showRecoveryNotice;
  bool _disposed = false;

  ReceiptDraftUiPhase get phase => _phase;
  String get organizationId => _permissions.organizationId;
  String get actorEmployeeId => _permissions.actorEmployeeId;
  ReceiptDraftUiFailure? get failure => _failure;
  bool get isLoading => _phase == ReceiptDraftUiPhase.loading;
  bool get showRecoveryNotice => _showRecoveryNotice;
  bool isPending(String draftId) => _pendingDraftIds.contains(draftId);

  List<StoredReceiptDraft> get records {
    final result = _drafts.values.toList()
      ..sort((left, right) {
        final updated = right.lifecycle.updatedAtUtc.compareTo(
          left.lifecycle.updatedAtUtc,
        );
        return updated != 0 ? updated : left.draftId.compareTo(right.draftId);
      });
    return List.unmodifiable(result);
  }

  StoredReceiptDraft? recordById(String draftId) => _drafts[draftId];

  /// Reads one authorized draft without adding a submitted/discarded record to
  /// the active-draft projection.
  Future<ReceiptDraftLookupResult> findById({
    required String draftId,
    bool includeClosed = false,
  }) async {
    try {
      final record = await _service.find(
        draftId: draftId,
        permissions: _permissions,
        includeClosed: includeClosed,
      );
      if (record == null) {
        return ReceiptDraftLookupResult.failed(
          ReceiptDraftUiFailure(
            operation: ReceiptDraftUiOperation.load,
            kind: ReceiptDraftUiFailureKind.notFound,
            message: 'The retained receipt evidence is no longer available.',
            draftId: draftId,
          ),
        );
      }
      return ReceiptDraftLookupResult.found(record);
    } on Object catch (error) {
      final kind = _kindFor(error);
      return ReceiptDraftLookupResult.failed(
        ReceiptDraftUiFailure(
          operation: ReceiptDraftUiOperation.load,
          kind: kind,
          message: _readMessageFor(kind),
          draftId: draftId,
        ),
      );
    }
  }

  Future<bool> load() async {
    _phase = ReceiptDraftUiPhase.loading;
    _failure = null;
    _notify();
    try {
      final records = await _service.query(permissions: _permissions);
      _drafts
        ..clear()
        ..addEntries(records.map((item) => MapEntry(item.draftId, item)));
      _phase = ReceiptDraftUiPhase.ready;
      _notify();
      return true;
    } on Object catch (error) {
      _fail(error, ReceiptDraftUiOperation.load);
      return false;
    }
  }

  Future<StoredReceiptDraft?> create({
    required String draftId,
    required String title,
    required DateTime expenseDate,
    required List<ReceiptEvidenceImport> evidence,
    required DateTime occurredAtUtc,
    String? linkedJobId,
    String? linkedJobLabel,
    ReceiptEntrySetup? entrySetup,
  }) => _mutate(
    draftId: draftId,
    operation: ReceiptDraftUiOperation.create,
    action: () => _service.create(
      draft: StoredReceiptDraft(
        draftId: draftId,
        organizationId: _permissions.organizationId,
        ownerEmployeeId: _permissions.actorEmployeeId,
        title: title.trim(),
        expenseDate: expenseDate,
        linkedJobId: linkedJobId,
        linkedJobLabel: linkedJobLabel,
        entrySetup: entrySetup,
        evidence: const [],
        lifecycle: ReceiptDraftLifecycle(
          revision: 1,
          createdAtUtc: occurredAtUtc,
          updatedAtUtc: occurredAtUtc,
        ),
      ),
      evidence: evidence,
      permissions: _permissions,
      occurredAtUtc: occurredAtUtc,
    ),
  );

  Future<StoredReceiptDraft?> update({
    required String draftId,
    required String title,
    required DateTime expenseDate,
    required Iterable<String> retainedEvidenceIds,
    required List<ReceiptEvidenceImport> addedEvidence,
    required DateTime occurredAtUtc,
    int? expectedRevision,
    String? linkedJobId,
    String? linkedJobLabel,
    ReceiptSelectedDetails? selectedDetails,
    List<ReceiptItemRead>? itemReads,
    ReceiptEntrySetup? entrySetup,
    bool replaceSelectedDetails = false,
  }) => _mutate(
    draftId: draftId,
    operation: ReceiptDraftUiOperation.update,
    action: () async {
      final current = _requireDraft(draftId);
      if (expectedRevision != null &&
          expectedRevision != current.lifecycle.revision) {
        throw const ReceiptDraftRevisionConflictException(
          'Receipt evidence changed after this review began.',
        );
      }
      final orderedRetainedIds = retainedEvidenceIds.toList(growable: false);
      final retained = orderedRetainedIds.toSet();
      if (retained.length != orderedRetainedIds.length) {
        throw const FormatException(
          'Receipt evidence order cannot contain duplicate items.',
        );
      }
      final activeById = {
        for (final item in current.activeEvidence) item.evidenceId: item,
      };
      if (orderedRetainedIds.any((id) => !activeById.containsKey(id))) {
        throw const FormatException(
          'Receipt evidence order contains an unavailable item.',
        );
      }
      final requested = current.copyWith(
        entrySetup: entrySetup,
        itemReads: itemReads,
        selectedDetails: replaceSelectedDetails
            ? selectedDetails
            : current.selectedDetails,
        title: title.trim(),
        expenseDate: expenseDate,
        linkedJobId: linkedJobId,
        linkedJobLabel: linkedJobLabel,
        evidence: [
          for (var index = 0; index < orderedRetainedIds.length; index++)
            if (activeById[orderedRetainedIds[index]] case final item?)
              item.copyWith(order: index),
          for (final item in current.evidence)
            if (!item.isActive) item,
        ],
      );
      return _service.update(
        draft: requested,
        addedEvidence: addedEvidence,
        expectedRevision: current.lifecycle.revision,
        permissions: _permissions,
        occurredAtUtc: occurredAtUtc,
      );
    },
  );

  Future<bool> submit({
    required String draftId,
    required String expenseId,
    required DateTime occurredAtUtc,
  }) async {
    final result = await _mutate(
      draftId: draftId,
      operation: ReceiptDraftUiOperation.submit,
      retainClosedResult: false,
      action: () {
        final current = _requireDraft(draftId);
        return _service.submit(
          draftId: draftId,
          expenseId: expenseId,
          expectedRevision: current.lifecycle.revision,
          permissions: _permissions,
          occurredAtUtc: occurredAtUtc,
        );
      },
    );
    return result != null;
  }

  Future<bool> discard({
    required String draftId,
    required DateTime occurredAtUtc,
  }) async {
    final result = await _mutate(
      draftId: draftId,
      operation: ReceiptDraftUiOperation.discard,
      retainClosedResult: false,
      action: () {
        final current = _requireDraft(draftId);
        return _service.discard(
          draftId: draftId,
          expectedRevision: current.lifecycle.revision,
          permissions: _permissions,
          occurredAtUtc: occurredAtUtc,
        );
      },
    );
    return result != null;
  }

  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    if (_phase == ReceiptDraftUiPhase.failed) {
      _phase = ReceiptDraftUiPhase.ready;
    }
    _notify();
  }

  void dismissRecoveryNotice() {
    if (!_showRecoveryNotice) return;
    _showRecoveryNotice = false;
    _notify();
  }

  Future<StoredReceiptDraft?> _mutate({
    required String draftId,
    required ReceiptDraftUiOperation operation,
    required Future<StoredReceiptDraft> Function() action,
    bool retainClosedResult = true,
  }) async {
    if (_disposed || !_pendingDraftIds.add(draftId)) return null;
    _failure = null;
    _notify();
    try {
      final result = await action();
      if (retainClosedResult && result.state == ReceiptDraftState.inProgress) {
        _drafts[result.draftId] = result;
      } else {
        _drafts.remove(result.draftId);
      }
      _phase = ReceiptDraftUiPhase.ready;
      return result;
    } on Object catch (error) {
      _fail(error, operation, draftId: draftId);
      return null;
    } finally {
      _pendingDraftIds.remove(draftId);
      _notify();
    }
  }

  StoredReceiptDraft _requireDraft(String draftId) =>
      _drafts[draftId] ??
      (throw const ReceiptDraftNotFoundException(
        'That receipt draft is no longer available.',
      ));

  void _fail(
    Object error,
    ReceiptDraftUiOperation operation, {
    String? draftId,
  }) {
    final kind = _kindFor(error);
    _failure = ReceiptDraftUiFailure(
      operation: operation,
      kind: kind,
      message: _messageFor(kind, error),
      draftId: draftId,
    );
    _phase = ReceiptDraftUiPhase.failed;
    _notify();
  }

  String _messageFor(ReceiptDraftUiFailureKind kind, Object error) =>
      switch (kind) {
        ReceiptDraftUiFailureKind.permission =>
          'You do not have permission to change that receipt draft.',
        ReceiptDraftUiFailureKind.conflict =>
          'That receipt draft changed. Reload it and try again.',
        ReceiptDraftUiFailureKind.storage ||
        ReceiptDraftUiFailureKind.corruption =>
          'The receipt draft could not be saved safely. Try again.',
        ReceiptDraftUiFailureKind.notFound =>
          'That receipt draft is no longer available.',
        ReceiptDraftUiFailureKind.invalid =>
          error is ReceiptDraftRepositoryException
              ? error.message
              : 'Check the receipt draft details and try again.',
        ReceiptDraftUiFailureKind.unknown =>
          'The receipt draft could not be changed. Try again.',
      };

  ReceiptDraftUiFailureKind _kindFor(Object error) => switch (error) {
    ReceiptDraftPermissionDeniedException() =>
      ReceiptDraftUiFailureKind.permission,
    ReceiptDraftAlreadyExistsException() ||
    ReceiptDraftRevisionConflictException() =>
      ReceiptDraftUiFailureKind.conflict,
    ReceiptDraftStorageCorruptionException() =>
      ReceiptDraftUiFailureKind.corruption,
    ReceiptDraftStorageException() => ReceiptDraftUiFailureKind.storage,
    ReceiptDraftNotFoundException() => ReceiptDraftUiFailureKind.notFound,
    ArgumentError() || FormatException() => ReceiptDraftUiFailureKind.invalid,
    _ => ReceiptDraftUiFailureKind.unknown,
  };

  String _readMessageFor(ReceiptDraftUiFailureKind kind) => switch (kind) {
    ReceiptDraftUiFailureKind.permission =>
      'You do not have permission to view that receipt evidence.',
    ReceiptDraftUiFailureKind.corruption || ReceiptDraftUiFailureKind.storage =>
      'The retained receipt evidence could not be read safely. Try again.',
    ReceiptDraftUiFailureKind.notFound =>
      'The retained receipt evidence is no longer available.',
    ReceiptDraftUiFailureKind.conflict ||
    ReceiptDraftUiFailureKind.invalid ||
    ReceiptDraftUiFailureKind.unknown =>
      'The retained receipt evidence could not be opened. Try again.',
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ReceiptDraftUiScope extends InheritedNotifier<ReceiptDraftUiController> {
  const ReceiptDraftUiScope({
    required ReceiptDraftUiController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ReceiptDraftUiController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ReceiptDraftUiScope>()
      ?.notifier;

  static ReceiptDraftUiController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'ReceiptDraftUiScope is missing.');
    return controller!;
  }
}
