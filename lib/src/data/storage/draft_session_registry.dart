/// Repository capability for application-owned draft lifecycle coordination.
/// Neither SQL nor widget identity is part of this contract.
abstract interface class ManagedDraftRepository {
  DraftSessionRegistry get draftSessions;
}

abstract interface class PausableDraftSession {
  void pauseInput();
  void resumeInput();
  Future<void> flush();
}

class DraftSessionRegistry {
  final _sessions = <PausableDraftSession>{};
  bool _paused = false;

  void Function() register(PausableDraftSession session) {
    if (_paused) throw StateError('Draft sessions are temporarily paused.');
    _sessions.add(session);
    return () => _sessions.remove(session);
  }

  /// Stops admission and input before waiting for every queued write. Failure
  /// releases the pause; callers must not switch databases after this throws.
  Future<DraftSessionPause> pauseAndFlush() async {
    if (_paused) throw StateError('Draft sessions are already paused.');
    _paused = true;
    final paused = <PausableDraftSession>[];
    try {
      for (final session in _sessions.toList()) {
        session.pauseInput();
        paused.add(session);
      }
      await Future.wait(paused.map((session) => session.flush()));
      return DraftSessionPause._(() {
        for (final session in paused) {
          session.resumeInput();
        }
        _paused = false;
      });
    } on Object {
      for (final session in paused) {
        session.resumeInput();
      }
      _paused = false;
      rethrow;
    }
  }
}

/// A successful flush remains protected until the coordinator explicitly
/// releases it. Release alone never discards or confirms saved input.
class DraftSessionPause {
  DraftSessionPause._(this._release);
  void Function()? _release;
  void release() {
    final release = _release;
    _release = null;
    release?.call();
  }
}
