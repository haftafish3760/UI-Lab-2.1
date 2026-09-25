import 'device_capability_facts.dart';
import 'device_diagnostic_descriptor.dart';
import 'device_operational_policy.dart';
import 'device_feature_capabilities.dart';
import 'device_feature_capability_parser.dart';
import 'device_hardware_assessment.dart';

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
    this.extended = const DeviceExtendedCapabilities(),
    this.descriptor = const DeviceDiagnosticDescriptor(),
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
  final bool? lowRam, lowMemory, powerSaving;
  final bool probeAvailable;
  final String thermal, batteryHealth;
  final DateTime? observedAt;
  final DeviceCapabilityFacts? facts;
  final DeviceExtendedCapabilities extended;
  final DeviceDiagnosticDescriptor descriptor;
  DeviceHardwareAssessment get hardwareAssessment =>
      DeviceHardwareAssessment.fromEvidence(
        ramMiB: probeAvailable ? physicalRamMb : null,
        cores: probeAvailable ? cpuCores : null,
        heapMiB: probeAvailable ? heapMb : null,
        mediaPerformanceClass: probeAvailable ? mediaPerformanceClass : null,
        extended: probeAvailable
            ? extended
            : const DeviceExtendedCapabilities(),
      );
  int? get baselineGrade =>
      hardwareAssessment.gradeCappedToTier(baselineTier.index);
  int? get effectiveGrade => hardwareAssessment.gradeCappedToTier(tier.index);
  DeviceOperationalPolicy get operationalPolicy =>
      DeviceOperationalPolicy(this);
  static const storageReserveBytes = 100 * 1024 * 1024;

  /// Readiness is transient. An undated profile is not live evidence.
  bool isFreshAt(DateTime now) {
    final at = observedAt;
    return at != null &&
        now.difference(at) <= const Duration(seconds: 10) &&
        at.difference(now) <= const Duration(seconds: 2);
  }

  DeviceWorkloadTier get baselineTier {
    final ram = physicalRamMb;
    if (!probeAvailable ||
        lowRam == true ||
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
    // Cross-platform path from the audited reference: public GPU/codec evidence
    // contributes without requiring Android-specific performance-class fields.
    if (extended.graphics.supportsCompute == true &&
        extended.media.hardwareDecodeTypes.isNotEmpty) {
      final score = hardwareAssessment.score;
      if (ram >= 11264 && score > 9) return DeviceWorkloadTier.flagship;
      if (ram >= 7680 && score > 6) return DeviceWorkloadTier.performance;
    }
    return DeviceWorkloadTier.enhanced;
  }

  bool get constrained => tier.index <= DeviceWorkloadTier.entry.index;
  bool get deferHeavyWork => stopReasons.isNotEmpty;
  List<String> get stopReasons => List.unmodifiable([
    if (!probeAvailable) 'probeUnavailable',
    if (lowMemory == true || (availableRamMb != null && availableRamMb! < 256))
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

    if (powerSaving == true ||
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
    if (powerSaving == null || lowRam == null || lowMemory == null) cap(2);
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

  /// Explicit local diagnostic context for the future admin-health boundary.
  /// Storage, sensor samples, business records and unique IDs are excluded.
  /// No persistence or remote transport is performed by this method.
  Map<String, Object> toLocalDiagnosticContext() => {
    'schemaVersion': 1,
    ...descriptor.toLocalDiagnostics(),
    ...toSafeDiagnostics(),
    'cpuArchitecture': ?cpuArchitecture,
    'cpuCores': ?cpuCores,
    'physicalRamMiB': ?physicalRamMb,
    'availableRamMiB': ?availableRamMb,
    'applicationHeapMiB': ?heapMb,
    'mediaPerformanceClass': ?mediaPerformanceClass,
    'hardwareConfidence': hardwareAssessment.confidence.name,
    'baselineGrade': ?baselineGrade,
    'effectiveGrade': ?effectiveGrade,
    'thermal': thermal,
    'powerSaving': ?powerSaving,
    'batteryPercent': ?batteryPercent,
    'externalPower': ?externalPower,
    'batteryHealth': batteryHealth,
    'lensCount': extended.cameraLenses.length,
    'sensorInventoryObserved': extended.sensors.inventoryObserved,
    if (extended.sensors.inventoryObserved) ...{
      'motionAvailable': extended.sensors.hasMotion,
      'stepsAvailable': extended.sensors.hasStepDetection,
    },
    'graphicsApi': extended.graphics.apiName,
    'hardwareDecoders': extended.media.hardwareDecodeTypes.toList(),
    'hardwareEncoders': extended.media.hardwareEncodeTypes.toList(),
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
      descriptor: DeviceDiagnosticDescriptor.fromMap(raw['descriptor']),
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
      lowRam: raw['lowRam'] is bool ? raw['lowRam'] as bool : null,
      lowMemory: raw['lowMemory'] is bool ? raw['lowMemory'] as bool : null,
      powerSaving: raw['powerSaving'] is bool
          ? raw['powerSaving'] as bool
          : null,
      thermal:
          const {'nominal', 'fair', 'serious', 'critical'}.contains(thermal)
          ? thermal as String
          : 'unknown',
      observedAt: DateTime.now().toUtc(),
      facts: DeviceCapabilityFacts.fromMap(raw['features']),
      extended: const DeviceFeatureCapabilityParser().parse(
        raw['extended'] is Map
            ? Map<Object?, Object?>.from(raw['extended'] as Map)
            : const {},
      ),
      probeAvailable: raw['probeAvailable'] == true,
    );
  }
}
