import 'dart:async';

/// Runs local mutations in arrival order without poisoning later writes when
/// one action fails.
class SerializedAsyncActions {
  Future<void> _tail = Future.value();
  bool _paused = false;

  /// Rejects new work immediately, but lets previously admitted operations
  /// finish in order. Operation errors still belong to their original callers;
  /// draining means settled, not that each operation succeeded.
  Future<AsyncActionPause> pauseAndDrain() async {
    if (_paused) throw StateError('Operations are already paused.');
    _paused = true;
    await _tail;
    return AsyncActionPause._(() => _paused = false);
  }

  Future<T> run<T>(Future<T> Function() action) {
    if (_paused) {
      return Future<T>.error(StateError('Operations are temporarily paused.'));
    }
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

/// Release is idempotent and admits future work without replaying rejected work.
class AsyncActionPause {
  AsyncActionPause._(this._release);
  void Function()? _release;
  void release() {
    final release = _release;
    _release = null;
    release?.call();
  }
}

/// Pause outer queues before queues they call. Sequential acquisition preserves
/// the service dependency order; partial acquisition is unwound on failure.
Future<AsyncActionPause> pauseOperationSources(
  Iterable<Future<AsyncActionPause> Function()> sources,
) async {
  final held = <AsyncActionPause>[];
  void release() {
    for (final pause in held.reversed) {
      pause.release();
    }
  }

  try {
    for (final source in sources) {
      held.add(await source());
    }
    return AsyncActionPause._(release);
  } on Object {
    release();
    rethrow;
  }
}
