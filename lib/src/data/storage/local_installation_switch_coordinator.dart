import 'local_installation_selection.dart';
import 'prepared_local_restore.dart';

/// Implemented by application lifecycle ownership, not individual screens.
abstract interface class InstallationSwitchRuntime {
  /// Must stop entry points, drain background/domain work and flush all drafts.
  /// On failure, unwind partial pauses before throwing. The returned callback
  /// resumes only a runtime whose close has not begun.
  Future<void Function()> pauseAndFlush();

  /// Must unmount/dispose the old application and close its database before
  /// returning. A thrown close has uncertain partial state and requires restart.
  Future<void> close();

  /// Open the durable selection; never silently fall back. Clean up failed opens.
  Future<void> openSelected();
}

enum InstallationSwitchPhase {
  idle,
  verifying,
  pausing,
  closing,
  selecting,
  opening,
  failed,
}

class InstallationSwitchFailure implements Exception {
  const InstallationSwitchFailure(this.phase, this.cause);
  final InstallationSwitchPhase phase;
  final Object cause;
  @override
  String toString() => 'Installation switch failed during ${phase.name}.';
}

/// Coordinates an explicitly requested switch. It never grants restore
/// authorization, chooses a backup, or interprets a timeout as successful saving.
class LocalInstallationSwitchCoordinator {
  LocalInstallationSwitchCoordinator({
    required this.selection,
    required this.runtime,
  });
  final LocalInstallationSelection selection;
  final InstallationSwitchRuntime runtime;
  InstallationSwitchPhase _phase = InstallationSwitchPhase.idle;
  bool _busy = false;
  bool _closed = false;
  InstallationSwitchPhase get phase => _phase;
  bool get canRetryOpening =>
      !_busy && _closed && _phase == InstallationSwitchPhase.failed;

  Future<void> restore(
    PreparedLocalRestore candidate, {
    required int expectedRevision,
    void Function()? validateAccess,
  }) => _switch(
    expectedRevision: expectedRevision,
    validateAccess: validateAccess,
    verify: () => selection.validateCandidate(candidate),
    commit: () => selection.select(
      installation: candidate,
      expectedRevision: expectedRevision,
    ),
  );

  Future<void> rollback({required int expectedRevision}) => _switch(
    expectedRevision: expectedRevision,
    verify: () =>
        selection.validateRollback(expectedRevision: expectedRevision),
    commit: () => selection.rollback(expectedRevision: expectedRevision),
  );

  Future<void> _switch({
    required int expectedRevision,
    required Future<void> Function() verify,
    void Function()? validateAccess,
    required Future<InstallationSelectionState> Function() commit,
  }) async {
    if (_busy || (_phase == InstallationSwitchPhase.failed && !_closed)) {
      throw StateError(
        'Installation switching is unavailable in this runtime.',
      );
    }
    _busy = true;
    var closeStarted = _closed;
    void Function()? resume;
    try {
      _phase = InstallationSwitchPhase.verifying;
      if ((await selection.read()).revision != expectedRevision) {
        throw StateError('Installation selection changed.');
      }
      await verify();
      validateAccess?.call();
      if (!_closed) {
        _phase = InstallationSwitchPhase.pausing;
        resume = await runtime.pauseAndFlush();
        validateAccess?.call();
        _phase = InstallationSwitchPhase.closing;
        closeStarted = true;
        await runtime.close();
        _closed = true;
      }
      validateAccess?.call();
      _phase = InstallationSwitchPhase.selecting;
      await commit();
      _phase = InstallationSwitchPhase.opening;
      await runtime.openSelected();
      _closed = false;
      _phase = InstallationSwitchPhase.idle;
    } on Object catch (error) {
      final failedAt = _phase;
      if (!closeStarted) {
        resume?.call();
        _phase = InstallationSwitchPhase.idle;
      } else {
        _phase = InstallationSwitchPhase.failed;
      }
      throw InstallationSwitchFailure(failedAt, error);
    } finally {
      _busy = false;
    }
  }

  /// Retry the recorded selection after a failed open or selection update. An
  /// uncertain/failed close must not open a second runtime in this process.
  Future<void> retryOpening() async {
    if (!canRetryOpening) {
      throw StateError('Reopening requires a closed runtime.');
    }
    _busy = true;
    _phase = InstallationSwitchPhase.opening;
    try {
      await runtime.openSelected();
      _closed = false;
      _phase = InstallationSwitchPhase.idle;
    } on Object catch (error) {
      _phase = InstallationSwitchPhase.failed;
      throw InstallationSwitchFailure(InstallationSwitchPhase.opening, error);
    } finally {
      _busy = false;
    }
  }
}
