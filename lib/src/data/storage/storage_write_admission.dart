import 'dart:async';

import 'serialized_async_actions.dart';

/// The reader must measure the volume containing the destination, not an
/// arbitrary device volume. Null means unavailable, never unlimited capacity.
typedef StorageFreeBytesReader = Future<int?> Function();

enum StorageCapacityLevel { available, low, reserveReached, unknown }

class StorageCapacityStatus {
  const StorageCapacityStatus({
    required this.freeBytes,
    required this.reservedBytes,
  });
  final int? freeBytes;
  final int reservedBytes;
  int? get unreservedBytes =>
      freeBytes == null ? null : freeBytes! - reservedBytes;
  StorageCapacityLevel get level {
    final free = unreservedBytes;
    if (free == null) return StorageCapacityLevel.unknown;
    if (free <= StorageWriteAdmission.reserveBytes) {
      return StorageCapacityLevel.reserveReached;
    }
    return free < StorageWriteAdmission.warningBytes
        ? StorageCapacityLevel.low
        : StorageCapacityLevel.available;
  }
}

class StorageWriteDeferred implements Exception {
  const StorageWriteDeferred(this.status);
  final StorageCapacityStatus status;
  @override
  String toString() => status.freeBytes == null
      ? 'Available storage could not be checked. Your saved information is retained.'
      : 'There is not enough free storage for this operation. '
            'Your saved information is retained. Choose what to remove, then retry.';
}

/// Shared by all writers on one destination volume. Reservations are memory
/// only: reporting low space must not itself require a successful database write.
/// This is admission, not an OS quota. Callers must bound scratch/WAL/output
/// growth, checkpoint between units, and still handle native write failures.
class StorageWriteAdmission {
  StorageWriteAdmission({
    required this.readFreeBytes,
    this.probeTimeout = const Duration(seconds: 2),
  }) {
    if (probeTimeout <= Duration.zero) {
      throw ArgumentError.value(probeTimeout, 'probeTimeout');
    }
  }

  static const reserveBytes = 100 * 1024 * 1024;
  static const warningBytes = 1024 * 1024 * 1024;
  final StorageFreeBytesReader readFreeBytes;
  final Duration probeTimeout;
  Future<int?>? _pendingProbe;
  final _admissions = SerializedAsyncActions();
  final _changes = StreamController<StorageCapacityStatus>.broadcast();
  final _leases = <StorageWriteLease>{};
  bool _closed = false;
  int? _freeBytes;
  int get _reservedBytes =>
      _leases.fold(0, (sum, lease) => sum + lease.peakBytes);
  StorageCapacityStatus get status => StorageCapacityStatus(
    freeBytes: _freeBytes,
    reservedBytes: _reservedBytes,
  );
  Stream<StorageCapacityStatus> get changes => _changes.stream;

  Future<void> _observe() async {
    if (_closed) throw StateError('Storage admission is closed.');
    int? observed;
    try {
      // A timeout cannot cancel native work. Reuse the outstanding probe so
      // retries cannot create an unbounded pile of native capacity requests.
      final probe = _pendingProbe ?? _startProbe();
      observed = await probe.timeout(probeTimeout);
    } on Object {
      observed = null;
    }
    if (_closed) throw StateError('Storage admission is closed.');
    _freeBytes = observed != null && observed >= 0 ? observed : null;
    _changes.add(status);
  }

  Future<int?> _startProbe() {
    final probe = Future<int?>.sync(readFreeBytes);
    _pendingProbe = probe;
    unawaited(
      probe.then<void>(
        (_) {
          if (identical(_pendingProbe, probe)) _pendingProbe = null;
        },
        onError: (Object _, StackTrace _) {
          if (identical(_pendingProbe, probe)) _pendingProbe = null;
        },
      ),
    );
    return probe;
  }

  Future<StorageCapacityStatus> refresh() => _admissions.run(() async {
    await _observe();
    return status;
  });

  Future<StorageWriteLease> acquire({required int peakBytes}) {
    if (peakBytes <= 0) throw ArgumentError.value(peakBytes, 'peakBytes');
    return _admissions.run(() async {
      await _observe();
      final available = status.unreservedBytes;
      if (available == null || available - peakBytes < reserveBytes) {
        throw StorageWriteDeferred(status);
      }
      final lease = StorageWriteLease._(this, peakBytes);
      _leases.add(lease);
      _changes.add(status);
      return lease;
    });
  }

  Future<T> run<T>({
    required int peakBytes,
    required Future<T> Function(StorageWriteLease lease) write,
  }) async {
    final lease = await acquire(peakBytes: peakBytes);
    try {
      return await write(lease);
    } finally {
      lease.release();
    }
  }

  Future<void> _checkpoint(StorageWriteLease lease) =>
      _admissions.run(() async {
        if (!_leases.contains(lease)) {
          throw StateError('Storage lease is released.');
        }
        await _observe();
        if (!_leases.contains(lease)) {
          throw StateError('Storage lease is released.');
        }
        final available = status.unreservedBytes;
        if (available == null || available < reserveBytes) {
          throw StorageWriteDeferred(status);
        }
      });

  void _release(StorageWriteLease lease) {
    if (_leases.remove(lease) && !_closed) _changes.add(status);
  }

  Future<void> close() async {
    if (_leases.isNotEmpty) {
      throw StateError('Storage writes are still active.');
    }
    _closed = true;
    await _changes.close();
  }
}

class StorageWriteLease {
  StorageWriteLease._(this._owner, this.peakBytes);
  final StorageWriteAdmission _owner;
  final int peakBytes;
  Future<void> checkpoint() => _owner._checkpoint(this);
  void release() => _owner._release(this);
}
