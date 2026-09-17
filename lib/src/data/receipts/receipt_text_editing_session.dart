import 'package:flutter/foundation.dart';

import '../storage/draft_autosave_session.dart';
import '../storage/draft_session_registry.dart';
import 'receipt_draft_record.dart';
import 'receipt_draft_ui_controller.dart';
import 'receipt_entry_setup.dart';
import 'receipt_submission_session.dart';

/// Unfinished receipt text belongs to the receipt draft, not a particular route.
/// Writes retain the exact input and advance only this session's saved revision.
class ReceiptTextEditingSession extends ChangeNotifier
    implements PausableDraftSession {
  ReceiptTextEditingSession._(this._receipts, this._saved)
    : _text = _saved.entrySetup?.pastedText ?? '';

  final ReceiptDraftUiController _receipts;
  StoredReceiptDraft _saved;
  String _text;
  Future<void> _tail = Future.value();
  void Function()? _unregister;
  bool _closed = false, _paused = false;
  int _generation = 0;
  DraftSaveState _state = DraftSaveState.unchanged;
  String? _failure;

  String get text => _text;
  StoredReceiptDraft get savedReceipt => _saved;
  DraftSaveState get state => _state;
  String? get failure => _failure;

  void updateText(String value) {
    _requireEditable();
    if (value == _text && _failure == null) return;
    _text = value;
    if (_failure != null) {
      notifyListeners();
      return; // Keep input, but require explicit retry after a failed write.
    }
    _enqueue(value);
  }

  void retry() {
    _requireEditable();
    if (_failure == null) return;
    _failure = null;
    _enqueue(_text);
  }

  void _requireEditable() {
    if (_closed || _paused) {
      throw StateError('Receipt editing is paused or closed.');
    }
  }

  void _enqueue(String value) {
    final generation = ++_generation;
    _state = DraftSaveState.saving;
    notifyListeners();
    _tail = _tail.then((_) async {
      if (_failure != null) return;
      try {
        final setup = _saved.entrySetup ?? const ReceiptEntrySetup();
        final stored = await _receipts.update(
          draftId: _saved.draftId,
          expectedRevision: _saved.lifecycle.revision,
          title: _saved.title,
          expenseDate: _saved.expenseDate,
          retainedEvidenceIds: _saved.activeEvidence.map(
            (item) => item.evidenceId,
          ),
          addedEvidence: const [],
          occurredAtUtc: DateTime.now().toUtc(),
          linkedJobId: _saved.linkedJobId,
          linkedJobLabel: _saved.linkedJobLabel,
          entrySetup: ReceiptEntrySetup(
            category: setup.category,
            type: setup.type,
            pastedText: value,
          ),
        );
        if (stored == null) {
          throw StateError(
            _receipts.failure?.message ?? 'Receipt text was not saved.',
          );
        }
        _saved = stored;
        if (generation == _generation) _state = DraftSaveState.savedLocally;
      } on Object catch (error) {
        _failure = error.toString();
        _state = DraftSaveState.notSaved;
      }
      if (!_closed) notifyListeners();
    });
  }

  @override
  void pauseInput() => _paused = true;
  @override
  void resumeInput() => _paused = false;
  @override
  Future<void> flush() async {
    await _tail;
    if (_failure != null) throw StateError(_failure!);
  }

  /// Only for an explicit user decision. Already saved receipt text remains;
  /// this releases unsaved local input without overwriting a concurrent edit.
  Future<void> discardUnsavedAndClose() async {
    _requireEditable();
    _paused = true;
    await _tail;
    _failure = null;
    _text = _saved.entrySetup?.pastedText ?? '';
    await close();
  }

  Future<void> close() async {
    if (_closed) return;
    _paused = true;
    try {
      await flush();
    } on Object {
      _paused = false;
      rethrow;
    }
    if (_closed) return;
    _closed = true;
    _unregister?.call();
    _unregister = null;
    super.dispose();
  }
}

extension ReceiptTextEditingWorkflow on ReceiptSubmissionSession {
  ReceiptTextEditingSession openTextEditing(String receiptId) {
    final source = receipts.recordById(receiptId);
    final permissions = receiptPermissions;
    final managed = drafts;
    if (source == null ||
        source.state != ReceiptDraftState.inProgress ||
        !permissions.canTarget(source) ||
        !(permissions.owns(source)
            ? permissions.canEditOwn
            : permissions.canEditTeam) ||
        managed is! ManagedDraftRepository) {
      throw StateError('This receipt is unavailable for durable text editing.');
    }
    final editor = ReceiptTextEditingSession._(receipts, source);
    editor._unregister = (managed as ManagedDraftRepository).draftSessions
        .register(editor);
    return editor;
  }
}
