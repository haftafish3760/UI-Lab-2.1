import 'dart:async';
import 'dart:convert';

import 'draft_repository.dart';
import 'draft_session_registry.dart';
import 'local_draft_checkpoint.dart';
import 'local_record_command.dart';

enum DraftSaveState { unchanged, saving, savedLocally, notSaved, discarded }

/// One editor session. UI reads status; it never interprets an enqueued write
/// as a durable save. No debounce timer or background lifecycle callback is
/// required for persistence to start when input changes.
class DraftAutosaveSession implements PausableDraftSession {
  DraftAutosaveSession({
    required this.store,
    required this.organizationId,
    required this.domain,
    required this.draftId,
    required this.ownerId,
  });

  final DraftRepository store;
  final String organizationId;
  final String domain;
  final String draftId;
  final String ownerId;
  final _changes = StreamController<DraftSaveState>.broadcast();
  Stream<DraftSaveState> get changes => _changes.stream;
  Future<void> _tail = Future.value();
  Map<String, Object?> _input = const {};
  int _revision = 0;
  int _inputGeneration = 0;
  DraftSaveState _state = DraftSaveState.unchanged;
  Object? _failure;
  bool _initialized = false;
  bool _closed = false;
  bool _committingInput = false;
  bool _paused = false;
  Future<void>? _initialization;
  void Function()? _unregister;

  @override
  void pauseInput() {
    _paused = true;
    _emit();
  }

  @override
  void resumeInput() {
    _paused = false;
    _emit();
  }

  DraftSaveState get state => _state;
  int get savedRevision => _revision;
  bool get hasFailure => _failure != null;
  bool get isClosed => _closed;
  bool get isCommittingInput => _committingInput || _paused;
  Map<String, Object?> get input => _copy(_input);

  Future<void> initialize() async {
    if (_initialized || _initialization != null || _closed) {
      throw StateError('Draft session was already initialized.');
    }
    final repository = store;
    if (repository is ManagedDraftRepository) {
      _unregister = (repository as ManagedDraftRepository).draftSessions
          .register(this);
    }
    return _initialization = _loadInitialInput();
  }

  Future<void> _loadInitialInput() async {
    try {
      final draft = await store.find(
        organizationId: organizationId,
        domain: domain,
        draftId: draftId,
        ownerId: ownerId,
      );
      if (draft != null) {
        _input = store.decode(draft);
        _revision = draft.revision;
        _state = DraftSaveState.savedLocally;
      }
      _initialized = true;
      _emit();
    } on Object {
      _unregister?.call();
      _unregister = null;
      rethrow;
    }
  }

  void replaceInput(Map<String, Object?> input) {
    if (!_initialized || _closed || _committingInput || _paused) {
      throw StateError('Draft session is not editable.');
    }
    final copy = _copy(input);
    if (canonicalJson(copy) == canonicalJson(_input) && _failure == null) {
      return;
    }
    _input = copy;
    _scheduleSave();
  }

  void retry() {
    if (!_initialized || _closed || _committingInput || _paused) {
      throw StateError('Draft session is not editable.');
    }
    if (_failure != null) _scheduleSave();
  }

  void _scheduleSave() {
    final generation = ++_inputGeneration;
    final pending = _copy(_input);
    _state = DraftSaveState.saving;
    _emit();
    _tail = _tail.then((_) async {
      try {
        _revision = await store.save(
          organizationId: organizationId,
          domain: domain,
          draftId: draftId,
          ownerId: ownerId,
          expectedRevision: _revision,
          payload: pending,
          occurredAt: DateTime.now().toUtc(),
        );
        _failure = null;
        if (generation == _inputGeneration) {
          _state = DraftSaveState.savedLocally;
        }
      } on Object catch (error) {
        _failure = error;
        if (generation == _inputGeneration) _state = DraftSaveState.notSaved;
      }
      _emit();
    });
  }

  /// Applies a workflow-owned atomic commit without exposing SQL or media rules.
  /// The callback must commit this exact input and return its durable revision.
  /// Publication occurs only after the outer transaction succeeds.
  Future<void> commitInput({
    required int expectedRevision,
    required Map<String, Object?> input,
    required Future<int> Function(Map<String, Object?> prepared) commit,
  }) {
    if (!_initialized || _closed || _committingInput || _paused) {
      throw StateError('Draft session is not editable.');
    }
    final prepared = _copy(input);
    // Freeze ordinary replacements until publication, otherwise a queued input
    // captured before adoption could silently overwrite the workflow result.
    _committingInput = true;
    final operation = _tail.then((_) async {
      try {
        if (_failure != null || _revision != expectedRevision) {
          throw const LocalRecordConflict(
            'The draft input changed before workflow commit.',
          );
        }
        _state = DraftSaveState.saving;
        _emit();
        final revision = await commit(_copy(prepared));
        // The workflow callback owns the transaction. Publish after it returns.
        _revision = revision;
        _input = prepared;
        _inputGeneration++;
      } finally {
        _committingInput = false;
        _state = _failure != null
            ? DraftSaveState.notSaved
            : _revision > 0
            ? DraftSaveState.savedLocally
            : DraftSaveState.unchanged;
        _emit();
      }
    });
    // Keep the ordinary save queue usable after a failed workflow operation. The
    // caller receives the original failure and can retry its workflow.
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  /// Freeze input while a domain command consumes its exact durable checkpoint.
  /// The callback must atomically commit records and consume that checkpoint.
  /// Failed commands retain editable input; successful commands seal this session
  /// against duplicate confirmation or recreating an already-consumed draft.
  Future<bool> confirm(
    Future<bool> Function(LocalDraftCheckpoint checkpoint) commit,
  ) {
    if (!_initialized || _closed || _committingInput || _paused) {
      throw StateError('Draft session is not editable.');
    }
    _committingInput = true;
    final operation = _tail.then((_) async {
      try {
        if (_failure != null || _revision <= 0) {
          throw StateError('Confirmation requires durably saved input.');
        }
        final saved = await commit(
          LocalDraftCheckpoint(
            domain: domain,
            draftId: draftId,
            revision: _revision,
          ),
        );
        if (saved) _closed = true;
        return saved;
      } finally {
        _committingInput = false;
        _emit();
      }
    });
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  /// Await before a user-confirmed submission or deliberate route completion.
  /// Backgrounding cannot guarantee OS execution; saves have already started.
  @override
  Future<void> flush() async {
    if (!_initialized) await _initialization;
    while (true) {
      final pending = _tail;
      await pending;
      if (identical(pending, _tail)) break;
    }
    if (_failure != null) {
      throw StateError('The latest draft changes have not been saved locally.');
    }
  }

  /// Explicit discard only. Simply leaving an editor must call close instead.
  Future<void> discard() async {
    if (!_initialized || _closed || _committingInput || _paused) {
      throw StateError('Draft session is not ready for discard.');
    }
    // Freeze input while the discard decision is being applied.
    _closed = true;
    final operation = _tail.then((_) async {
      try {
        if (_revision > 0 &&
            !await store.consumeIfUnchanged(
              organizationId: organizationId,
              domain: domain,
              draftId: draftId,
              ownerId: ownerId,
              expectedRevision: _revision,
            )) {
          throw const LocalRecordConflict(
            'A newer draft was preserved. Reload before discarding it.',
          );
        }
        _state = DraftSaveState.discarded;
        _failure = null;
        _emit();
      } on Object {
        _closed = false;
        rethrow;
      }
    });
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  /// The caller must handle a flush failure before claiming the draft is safe.
  /// The last committed checkpoint remains available after this object closes.
  Future<void> close() async {
    _closed = true;
    try {
      await flush();
    } finally {
      _unregister?.call();
      _unregister = null;
      await _changes.close();
    }
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(_state);
  }
}

Map<String, Object?> _copy(Map<String, Object?> input) =>
    (jsonDecode(canonicalJson(input)) as Map).cast<String, Object?>();
