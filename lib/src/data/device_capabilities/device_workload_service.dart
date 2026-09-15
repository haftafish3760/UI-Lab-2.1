import 'dart:async';

import 'package:flutter/services.dart';

enum DeviceWorkloadTier { limited, standard, capable }

/// Adapted from 5.7's hardware/runtime split. Unknown facts earn no capacity.
/// Device identity, camera controls and account data are deliberately absent.
class DeviceWorkloadProfile {
  const DeviceWorkloadProfile({
    this.physicalRamMb,
    this.availableRamMb,
    this.heapMb,
    this.lowRam = false,
    this.lowMemory = false,
    this.powerSaving = false,
    this.thermal = 'unknown',
  });

  final int? physicalRamMb;
  final int? availableRamMb;
  final int? heapMb;
  final bool lowRam;
  final bool lowMemory;
  final bool powerSaving;
  final String thermal;

  bool get constrained =>
      physicalRamMb == null ||
      physicalRamMb! <= 3072 ||
      lowRam ||
      lowMemory ||
      powerSaving ||
      (availableRamMb != null && availableRamMb! < 1024) ||
      (heapMb != null && heapMb! < 192) ||
      thermal == 'fair' ||
      thermal == 'serious' ||
      thermal == 'critical';

  bool get deferHeavyWork =>
      lowMemory ||
      thermal == 'serious' ||
      thermal == 'critical' ||
      (availableRamMb != null && availableRamMb! < 256);

  DeviceWorkloadTier get tier => constrained
      ? DeviceWorkloadTier.limited
      : physicalRamMb! >= 8192 &&
            availableRamMb != null &&
            availableRamMb! >= 2048
      ? DeviceWorkloadTier.capable
      : DeviceWorkloadTier.standard;
  int get maxImagePixels => switch (tier) {
    DeviceWorkloadTier.limited => 1000000,
    DeviceWorkloadTier.standard => 2000000,
    DeviceWorkloadTier.capable => 3000000,
  };
  int get maxEncodedImageBytes =>
      constrained ? 12 * 1024 * 1024 : 32 * 1024 * 1024;

  factory DeviceWorkloadProfile.fromMap(Map<Object?, Object?> facts) {
    int? positive(String key) {
      final value = facts[key];
      return value is num && value.isFinite && value > 0 ? value.toInt() : null;
    }

    return DeviceWorkloadProfile(
      physicalRamMb: positive('physicalRamMb'),
      availableRamMb: facts['availableRamMb'] == 0
          ? 0
          : positive('availableRamMb'),
      heapMb: positive('applicationHeapMb'),
      lowRam: facts['lowRam'] == true,
      lowMemory: facts['lowMemory'] == true,
      powerSaving: facts['powerSaving'] == true,
      thermal: facts['thermalState'] is String
          ? facts['thermalState'] as String
          : 'unknown',
    );
  }
}

class DeviceWorkloadUnavailable implements Exception {
  const DeviceWorkloadUnavailable(this.message);
  final String message;
}

typedef DeviceWorkloadProbe = Future<DeviceWorkloadProfile> Function();

/// Shared app-wide admission gate. A timed-out caller cannot start another
/// native task while the first task still owns memory. No unbounded queue.
class DeviceWorkloadService {
  DeviceWorkloadService({DeviceWorkloadProbe? probe})
    : _probe = probe ?? _nativeProbe;
  static final instance = DeviceWorkloadService();
  static const _channel = MethodChannel('maintainiac/device_capabilities');
  final DeviceWorkloadProbe _probe;
  bool _busy = false;
  bool get busy => _busy;
  DeviceWorkloadProfile _latest = const DeviceWorkloadProfile();
  DeviceWorkloadProfile get latest => _latest;

  static Future<DeviceWorkloadProfile> _nativeProbe() async {
    try {
      final facts = await _channel
          .invokeMapMethod<Object?, Object?>('readRuntimeCapabilities')
          .timeout(const Duration(milliseconds: 750));
      return DeviceWorkloadProfile.fromMap(facts ?? const {});
    } catch (_) {
      return const DeviceWorkloadProfile();
    }
  }

  Future<T> run<T>(Future<T> Function(DeviceWorkloadProfile) work) async {
    if (_busy) {
      throw const DeviceWorkloadUnavailable(
        'Another task is still finishing. Wait a moment and try again.',
      );
    }
    _busy = true;
    try {
      // Refresh runtime conditions at admission, not just at startup.
      try {
        _latest = await _probe();
      } catch (_) {
        _latest = const DeviceWorkloadProfile();
      }
      if (_latest.deferHeavyWork) {
        throw const DeviceWorkloadUnavailable(
          'Your device needs a moment to recover. You can enter the expense manually or try reading later.',
        );
      }
      return await work(_latest);
    } finally {
      _busy = false;
    }
  }
}
