import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'device_workload_profile.dart';
export 'device_workload_profile.dart';
export 'device_capability_facts.dart';
export 'device_feature_capabilities.dart';
export 'device_operational_policy.dart';
export 'device_diagnostic_descriptor.dart';

class DeviceWorkloadUnavailable implements Exception {
  const DeviceWorkloadUnavailable(this.message, {this.reasons = const []});
  final String message;
  final List<String> reasons;
  @override
  String toString() => message;
}

typedef DeviceWorkloadProbe = Future<DeviceWorkloadProfile> Function();

/// Peak additional scratch/output space. Callers must bound their writer to it.
class DeviceWorkloadRequest {
  const DeviceWorkloadRequest({this.storageBytes = 0, this.memoryBytes = 0});
  final int storageBytes, memoryBytes;
}

class DeviceWorkloadStatus {
  const DeviceWorkloadStatus(
    this.profile,
    this.busy,
    this.stopRequested,
    this.reasons,
  );
  final DeviceWorkloadProfile profile;
  final bool busy, stopRequested;
  final List<String> reasons;
}

/// One app-wide owner. A caller timeout never releases underlying native work.
class DeviceWorkloadService {
  DeviceWorkloadService({
    DeviceWorkloadProbe? probe,
    this.pollInterval = const Duration(seconds: 3),
    this.probeTimeout = const Duration(seconds: 2),
    DateTime Function()? now,
  }) : _probe = probe ?? _nativeProbe,
       _now = now ?? DateTime.now;
  static final instance = DeviceWorkloadService();
  static const _channel = MethodChannel('app.device_capabilities');
  final DeviceWorkloadProbe _probe;
  final DateTime Function() _now;
  final Duration pollInterval, probeTimeout;
  final _changes = StreamController<DeviceWorkloadStatus>.broadcast();
  Stream<DeviceWorkloadStatus> get changes => _changes.stream;
  bool _busy = false, _stopRequested = false, _disposed = false;
  bool get busy => _busy;
  bool get stopRequested => _stopRequested;
  List<String> _reasons = const [];
  DateTime? _memoryPressureUntil;
  DeviceWorkloadProfile _latest = const DeviceWorkloadProfile(
    probeAvailable: false,
  );
  DeviceWorkloadProfile get latest => _latest;
  DeviceWorkloadStatus get status =>
      DeviceWorkloadStatus(_latest, _busy, _stopRequested, _reasons);
  Timer? _monitor;
  Future<DeviceWorkloadProfile>? _refreshing;
  bool _probeInFlight = false;
  DeviceWorkloadRequest _request = const DeviceWorkloadRequest();

  static Future<DeviceWorkloadProfile> _nativeProbe() async {
    String? storagePath;
    if (Platform.isWindows) {
      try {
        storagePath = (await getApplicationSupportDirectory()).path;
      } catch (_) {
        // Memory/power facts remain useful; unknown disk space refuses writes.
      }
    }
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'readRuntimeCapabilities',
      {'storagePath': ?storagePath},
    );
    return DeviceWorkloadProfile.fromMap(raw ?? const {});
  }

  /// Concurrent callers await the same fresh observation, never an old cache.
  Future<DeviceWorkloadProfile> refresh() {
    if (_disposed) throw StateError('Device workload service is disposed.');
    return _refreshing ??= _read().whenComplete(() => _refreshing = null);
  }

  Future<DeviceWorkloadProfile> _read() async {
    DeviceWorkloadProfile value;
    try {
      // A deadline only stops waiting; it cannot cancel a platform method.
      // Retain probe ownership until the underlying operation actually settles.
      if (_probeInFlight) {
        throw StateError('Previous capability probe has not finished.');
      }
      _probeInFlight = true;
      final pending = Future<DeviceWorkloadProfile>.sync(
        _probe,
      ).whenComplete(() => _probeInFlight = false);
      value = await pending.timeout(probeTimeout);
      if (value.observedAt != null && !value.isFreshAt(_now())) {
        value = const DeviceWorkloadProfile(probeAvailable: false);
      }
    } catch (_) {
      value = const DeviceWorkloadProfile(probeAvailable: false);
    }
    if (_disposed) return value;
    _latest = value;
    final currentReasons = _evaluate(value, _request);
    _reasons = _busy && _stopRequested
        ? List.unmodifiable({..._reasons, ...currentReasons})
        : currentReasons;
    if (_busy && _reasons.isNotEmpty) _stopRequested = true;
    _publish();
    return value;
  }

  List<String> _evaluate(
    DeviceWorkloadProfile profile,
    DeviceWorkloadRequest request,
  ) => List.unmodifiable([
    ...profile.stopReasons,
    if (_memoryPressureUntil != null && _now().isBefore(_memoryPressureUntil!))
      'memoryPressure',
    if (request.storageBytes > 0 && profile.freeStorageBytes == null)
      'storageUnknown',
    if (profile.freeStorageBytes != null &&
        profile.freeStorageBytes! - request.storageBytes <
            DeviceWorkloadProfile.storageReserveBytes)
      'storageBudget',
    if (request.memoryBytes > profile.maxWorkingMemoryBytes ||
        (profile.availableRamMb != null &&
            request.memoryBytes > profile.availableRamMb! * 1024 * 1024 ~/ 4))
      'memoryBudget',
  ]);

  void _publish() {
    if (!_disposed) _changes.add(status);
  }

  void requireActive() {
    if (!_busy) throw StateError('No admitted workload.');
    if (_stopRequested) {
      final storageBlocked =
          _reasons.contains('storageReserve') ||
          _reasons.contains('storageBudget');
      throw DeviceWorkloadUnavailable(
        storageBlocked
            ? 'Work paused because storage is low. Choose what to remove '
                  'before trying again. Nothing is deleted automatically.'
            : _reasons.contains('storageUnknown')
            ? 'Work paused because available storage could not be checked. '
                  'Try again when storage can be checked.'
            : 'Work paused to protect your device. Try again after it has recovered.',
        reasons: _reasons,
      );
    }
  }

  Future<T> run<T>(
    Future<T> Function(DeviceWorkloadProfile) work, {
    DeviceWorkloadRequest request = const DeviceWorkloadRequest(),
  }) async {
    if (_disposed) throw StateError('Device workload service is disposed.');
    if (request.storageBytes < 0 || request.memoryBytes < 0) {
      throw ArgumentError('Workload budgets must be nonnegative.');
    }
    if (_busy) {
      throw const DeviceWorkloadUnavailable(
        'Another task is still finishing. Wait a moment and try again.',
        reasons: ['busy'],
      );
    }
    _busy = true;
    _stopRequested = false;
    _request = request;
    try {
      final profile = await refresh();
      _reasons = List.unmodifiable({
        if (_stopRequested) ..._reasons,
        ..._evaluate(profile, request),
      });
      _stopRequested = _stopRequested || _reasons.isNotEmpty;
      requireActive();
      _monitor = Timer.periodic(pollInterval, (_) {
        unawaited(refresh());
      });
      _publish();
      final result = await work(profile);
      requireActive();
      return result;
    } finally {
      _monitor?.cancel();
      _monitor = null;
      _busy = false;
      _request = const DeviceWorkloadRequest();
      _publish();
    }
  }

  Future<DeviceWorkloadProfile> checkpoint() async {
    requireActive();
    final profile = await refresh();
    requireActive();
    return profile;
  }

  void signalMemoryPressure() {
    if (_disposed) return;
    _memoryPressureUntil = _now().add(const Duration(seconds: 10));
    if (_busy) _stopRequested = true;
    _reasons = List.unmodifiable({..._reasons, 'memoryPressure'});
    _publish();
  }

  Future<void> dispose() async {
    if (_busy) {
      throw StateError('Cannot dispose a service that owns native work.');
    }
    _disposed = true;
    _monitor?.cancel();
    await _changes.close();
  }
}
