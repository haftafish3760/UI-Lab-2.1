/// Application-owned lifecycle, independent of any route, widget or SQL schema.
/// The host must block user entry points before pausing and detach its view before
/// closing. The view supplies only its service-draining callback.
class ApplicationStorageLifecycle {
  ApplicationStorageLifecycle({
    required this._pauseDomainSources,
    required this._pauseDrafts,
    required this._pauseStorage,
    required this._closeStorage,
  });
  final Future<void Function()> Function() _pauseDomainSources;
  final Future<void Function()> Function() _pauseDrafts;
  final Future<void Function()> Function() _pauseStorage;
  final Future<void> Function() _closeStorage;
  Future<void Function()> Function()? _viewServices;
  bool _wasAttached = false, _pausing = false, _paused = false, _closed = false;
  bool get isAttached => _viewServices != null;

  void Function() attach(Future<void Function()> Function() pauseViewServices) {
    if (_viewServices != null || _closed || _paused || _pausing) {
      throw StateError(
        'Application storage already has an owner or is paused.',
      );
    }
    _wasAttached = true;
    _viewServices = pauseViewServices;
    return () {
      if (identical(_viewServices, pauseViewServices)) _viewServices = null;
    };
  }

  Future<void Function()> pauseAndFlush() async {
    final services = _viewServices;
    if (services == null || _closed || _pausing || _paused) {
      throw StateError(
        'Application storage cannot pause in its current state.',
      );
    }
    _pausing = true;
    final releases = <void Function()>[];
    void release() {
      for (final callback in releases.reversed) {
        callback();
      }
      releases.clear();
      _paused = false;
    }

    try {
      releases.add(await services());
      releases.add(await _pauseDomainSources());
      releases.add(await _pauseDrafts());
      releases.add(await _pauseStorage());
      _paused = true;
      return release;
    } on Object {
      release();
      rethrow;
    } finally {
      _pausing = false;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    if (_viewServices != null || _pausing || (_wasAttached && !_paused)) {
      throw StateError('Detach the paused application before closing storage.');
    }
    await _closeStorage();
    _closed = true;
  }
}
