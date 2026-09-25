import 'device_capability_facts.dart';

enum DeviceWorkloadTier {
  constrained,
  entry,
  balanced,
  enhanced,
  performance,
  flagship;

  // Compatibility names for the previous OCR API; these add no extra tiers.
  static const limited = constrained;
  static const standard = balanced;
  static const capable = performance;
}

/// All memory sizes are MiB. Storage is exact bytes on the app data volume.
/// Direct construction is for trusted adapters/tests; channel data uses fromMap.
class DeviceWorkloadProfile {
  const DeviceWorkloadProfile({
    this.physicalRamMb,
    this.availableRamMb,
    this.heapMb,
    this.cpuCores,
    this.cpuArchitecture,
    this.mediaPerformanceClass,
    this.freeStorageBytes,
    this.batteryPercent,
    this.batteryTemperatureC,
    this.externalPower,
    this.batteryHealth = 'unknown',
    this.lowRam = false,
    this.lowMemory = false,
    this.powerSaving = false,
    this.thermal = 'unknown',
    this.observedAt,
    this.facts,
    this.probeAvailable = true,
  });
  final int? physicalRamMb,
      availableRamMb,
      heapMb,
      cpuCores,
      mediaPerformanceClass;
  final String? cpuArchitecture;
  final int? freeStorageBytes, batteryPercent;
  final double? batteryTemperatureC;
  final bool? externalPower;
  final bool lowRam, lowMemory, powerSaving, probeAvailable;
  final String thermal, batteryHealth;
  final DateTime? observedAt;
  final DeviceCapabilityFacts? facts;
  static const storageReserveBytes = 100 * 1024 * 1024;

  DeviceWorkloadTier get baselineTier {
    final ram = physicalRamMb;
    if (!probeAvailable ||
        lowRam ||
        ram == null ||
        ram <= 3072 ||
        (heapMb != null && heapMb! < 192)) {
      return DeviceWorkloadTier.constrained;
    }
    if (ram <= 4096) return DeviceWorkloadTier.entry;
    if (ram <= 6144) return DeviceWorkloadTier.balanced;
    // Parallelism alone cannot establish flagship throughput. Higher tiers
    // require independent platform performance evidence, not model names.
    if (cpuCores == null) return DeviceWorkloadTier.balanced;
    if (cpuCores! <= 4) return DeviceWorkloadTier.entry;
    if (ram >= 11264 &&
        (mediaPerformanceClass ?? 0) >= 34 &&
        (heapMb ?? 0) >= 256) {
      return DeviceWorkloadTier.flagship;
    }
    if (ram >= 7680 && (mediaPerformanceClass ?? 0) >= 31) {
      return DeviceWorkloadTier.performance;
    }
    return DeviceWorkloadTier.enhanced;
  }

  bool get constrained => tier.index <= DeviceWorkloadTier.entry.index;
  bool get deferHeavyWork => stopReasons.isNotEmpty;
  List<String> get stopReasons => List.unmodifiable([
    if (!probeAvailable) 'probeUnavailable',
    if (lowMemory || (availableRamMb != null && availableRamMb! < 256))
      'memoryCritical',
    if (thermal == 'serious' || thermal == 'critical') 'thermalPressure',
    if (batteryHealth == 'overheating' ||
        batteryHealth == 'failure' ||
        (batteryTemperatureC != null && batteryTemperatureC! >= 45))
      'batteryUnsafe',
    if (batteryPercent != null &&
        batteryPercent! <= 10 &&
        externalPower != true)
      'batteryCritical',
    if (freeStorageBytes != null && freeStorageBytes! < storageReserveBytes)
      'storageReserve',
  ]);

  DeviceWorkloadTier get tier {
    if (deferHeavyWork) return DeviceWorkloadTier.constrained;
    var index = baselineTier.index;
    void cap(int maximum) {
      if (index > maximum) index = maximum;
    }

    if (powerSaving ||
        thermal == 'fair' ||
        (availableRamMb != null && availableRamMb! < 1024)) {
      cap(0);
    }
    if (batteryPercent != null &&
        batteryPercent! <= 20 &&
        externalPower != true) {
      cap(1);
    }
    if (thermal == 'unknown' || availableRamMb == null) cap(2);
    if (freeStorageBytes != null && freeStorageBytes! < 512 * 1024 * 1024) {
      cap(1);
    }
    return DeviceWorkloadTier.values[index];
  }

  int get maxImagePixels =>
      const [1000000, 1200000, 2000000, 2400000, 2800000, 3000000][tier.index];
  int get maxEncodedImageBytes => (constrained ? 12 : 32) * 1024 * 1024;
  int get maxWorkingMemoryBytes =>
      const [48, 64, 96, 112, 128, 160][tier.index] * 1024 * 1024;
  int get recommendedWorkerCount => tier.index >= 4 ? 2 : 1;
  int get maxOcrBatchImages => 1; // Sequential bounded units on every tier.
  int get maxPdfRasterDpi => const [100, 120, 140, 160, 180, 200][tier.index];
  int get liveAnalysisFps => const [2, 3, 4, 5, 6, 8][tier.index];
  int get tripLocationIntervalSeconds =>
      const [20, 15, 12, 10, 8, 5][tier.index];

  Map<String, Object> toSafeDiagnostics() => {
    'baselineTier': baselineTier.name,
    'effectiveTier': tier.name,
    'probeAvailable': probeAvailable,
    'deferred': deferHeavyWork,
    'reasons': stopReasons,
  };

  factory DeviceWorkloadProfile.fromMap(Map<Object?, Object?> raw) {
    int? integer(String key, {int min = 0, int max = 1 << 52}) {
      final value = raw[key];
      if (value is! num ||
          !value.isFinite ||
          value < min ||
          value > max ||
          value != value.truncateToDouble()) {
        return null;
      }
      return value.toInt();
    }

    final temperature = raw['batteryTemperatureC'];
    final thermal = raw['thermalState'];
    final health = raw['batteryHealth'];
    final arch = raw['cpuArchitecture'];
    return DeviceWorkloadProfile(
      physicalRamMb: integer('physicalRamMb', min: 1, max: 1048576),
      availableRamMb: integer('availableRamMb', max: 1048576),
      heapMb: integer('applicationHeapMb', min: 1, max: 1048576),
      cpuCores: integer('cpuCores', min: 1, max: 1024),
      cpuArchitecture:
          const {
            'arm64-v8a',
            'armeabi-v7a',
            'arm64',
            'x86',
            'x86_64',
          }.contains(arch)
          ? arch as String
          : null,
      mediaPerformanceClass: integer(
        'mediaPerformanceClass',
        min: 30,
        max: 100,
      ),
      freeStorageBytes: integer('freeStorageBytes'),
      batteryPercent: integer('batteryPercent', max: 100),
      batteryTemperatureC:
          temperature is num &&
              temperature.isFinite &&
              temperature >= -40 &&
              temperature <= 100
          ? temperature.toDouble()
          : null,
      externalPower: raw['externalPower'] is bool
          ? raw['externalPower'] as bool
          : null,
      batteryHealth:
          const {'good', 'degraded', 'overheating', 'failure'}.contains(health)
          ? health as String
          : 'unknown',
      lowRam: raw['lowRam'] == true,
      lowMemory: raw['lowMemory'] == true,
      powerSaving: raw['powerSaving'] == true,
      thermal:
          const {'nominal', 'fair', 'serious', 'critical'}.contains(thermal)
          ? thermal as String
          : 'unknown',
      observedAt: DateTime.now().toUtc(),
      facts: DeviceCapabilityFacts.fromMap(raw['features']),
      probeAvailable: raw['probeAvailable'] == true,
    );
  }
}
