import 'dart:io';
import 'package:path/path.dart' as paths;
import 'local_installation_selection.dart';
import 'local_checkpoint_catalog.dart';
import 'local_installation_switch_coordinator.dart';
import 'prepared_local_restore.dart';
import 'verified_local_snapshot_bundle.dart';

import 'local_restore_controller.dart';
export 'local_restore_controller.dart';

/// App-private whole-installation restore. Review is not an authorization grant;
/// the owning application supplies a live authorization check. It is rechecked
/// after asynchronous discovery/review and before closing/selecting a runtime.
/// There is no external-file import, cloud payload, merge or automatic fallback.
class LocalRestoreWorkflow implements LocalRestoreController {
  LocalRestoreWorkflow({
    required LocalInstallationSelection selection,
    required InstallationSwitchRuntime runtime,
    required this._authorize,
    required this._currentDatabaseFile,
  }) : _selection = selection {
    _switch = LocalInstallationSwitchCoordinator(
      selection: selection,
      runtime: runtime,
    );
  }
  final LocalInstallationSelection _selection;
  final void Function() _authorize;
  final File Function() _currentDatabaseFile;
  late final LocalInstallationSwitchCoordinator _switch;
  _PendingRestoreReview? _pending;
  bool _busy = false;
  @override
  bool get isBusy => _busy;
  @override
  bool get canRetryOpening => !_busy && _switch.canRetryOpening;

  @override
  Future<List<LocalCheckpointSummary>> listCheckpoints() async {
    _begin();
    try {
      final database = await _currentDatabaseFile().resolveSymbolicLinks();
      final revision = (await _selection.read()).revision;
      final entries = await listLocalCheckpoints(File(database));
      if (await _currentDatabaseFile().resolveSymbolicLinks() != database ||
          (await _selection.read()).revision != revision) {
        throw StateError('The active installation changed during discovery.');
      }
      _authorize();
      return entries;
    } finally {
      _busy = false;
    }
  }

  @override
  Future<LocalRestoreReview> reviewCheckpoint(String checkpointId) async {
    _begin();
    // Attempting a new selection invalidates the old review, even if validation
    // fails. A stale confirmation must never restore the previously shown item.
    _pending = null;
    try {
      if (checkpointId.isEmpty ||
          checkpointId == '.' ||
          checkpointId == '..' ||
          checkpointId.contains('/') ||
          checkpointId.contains('\\')) {
        throw ArgumentError('Select an app-private checkpoint identifier.');
      }
      final database = File(
        await _currentDatabaseFile().resolveSymbolicLinks(),
      );
      final directory = Directory(
        paths.join(database.parent.path, 'database_checkpoints', checkpointId),
      );
      if (await directory.resolveSymbolicLinks() != directory.path) {
        throw StateError('Checkpoint location is redirected.');
      }
      final state = await _selection.read();
      final source = await VerifiedLocalSnapshotBundle.open(directory);
      final review = _VerifiedRestoreReview(
        checkpointId,
        await source.databaseFile.length(),
        source.attachments.length,
      );
      if (await _currentDatabaseFile().resolveSymbolicLinks() !=
              database.path ||
          (await _selection.read()).revision != state.revision) {
        throw StateError('The active installation changed during review.');
      }
      _authorize();
      _pending = _PendingRestoreReview(
        review,
        directory,
        database,
        source.manifestDigest,
        state.revision,
      );
      return review;
    } finally {
      _busy = false;
    }
  }

  @override
  void cancelReview(LocalRestoreReview review) {
    if (_busy) throw StateError('Restore operation is in progress.');
    if (identical(_pending?.review, review)) _pending = null;
  }

  @override
  Future<void> confirm(LocalRestoreReview review) async {
    _begin();
    try {
      final pending = _pending;
      if (pending == null || !identical(pending.review, review)) {
        throw StateError('Review this checkpoint again before confirming.');
      }
      if ((await _selection.read()).revision != pending.selectionRevision ||
          await _currentDatabaseFile().resolveSymbolicLinks() !=
              pending.database.path) {
        throw StateError('The active installation changed after review.');
      }
      final source = await VerifiedLocalSnapshotBundle.open(pending.source);
      if (source.manifestDigest != pending.manifestDigest) {
        throw StateError('The checkpoint changed after review.');
      }
      _authorize();
      // Stage only after confirmation, from reverified reviewed bytes. Never
      // activate a writable candidate left over from an earlier review.
      final candidate = await PreparedLocalRestore.prepare(
        source: source,
        liveDatabaseFile: pending.database,
      );
      await _switch.restore(
        candidate,
        expectedRevision: pending.selectionRevision,
        validateAccess: _authorize,
      );
      _pending = null;
    } finally {
      _busy = false;
    }
  }

  @override
  Future<void> retryOpening() async {
    _begin();
    try {
      await _switch.retryOpening();
      _pending = null;
    } finally {
      _busy = false;
    }
  }

  void _begin() {
    _authorize();
    if (_busy) throw StateError('Restore operation is in progress.');
    _busy = true;
  }
}

class _PendingRestoreReview {
  const _PendingRestoreReview(
    this.review,
    this.source,
    this.database,
    this.manifestDigest,
    this.selectionRevision,
  );
  final LocalRestoreReview review;
  final Directory source;
  final File database;
  final String manifestDigest;
  final int selectionRevision;
}

/// Displayable review facts, independent of SQL, files, routes and layout.
/// Identity binds confirmation to this workflow's exact reviewed selection.
class _VerifiedRestoreReview implements LocalRestoreReview {
  _VerifiedRestoreReview(
    this.checkpointId,
    this.databaseBytes,
    this.attachmentCount,
  );
  @override
  final String checkpointId;
  @override
  final int databaseBytes;
  @override
  final int attachmentCount;
}
