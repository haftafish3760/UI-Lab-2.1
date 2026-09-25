import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_hardware_assessment.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';

void main() {
  const accelerated = DeviceExtendedCapabilities(
    graphics: DeviceGraphicsCapabilities(supportsCompute: true),
    media: DeviceMediaCapabilities(
      hardwareDecodeTypes: {'av1'},
      hardwareEncodeTypes: {'hevc'},
    ),
  );
  test(
    'unknown evidence is ungraded; low-end negative scores remain valid',
    () {
      final unknown = DeviceHardwareAssessment.fromEvidence();
      expect(unknown.grade, isNull);
      expect(unknown.confidence, DeviceEvidenceConfidence.unknown);
      final small = DeviceHardwareAssessment.fromEvidence(
        ramMiB: 2048,
        cores: 4,
        heapMiB: 128,
      );
      expect(small.score, -4);
      expect(small.grade, 1);
      expect(small.confidence, DeviceEvidenceConfidence.high);
    },
  );
  test('reference evidence score accounts for each independent signal', () {
    final full = DeviceHardwareAssessment.fromEvidence(
      ramMiB: 12288,
      cores: 8,
      heapMiB: 512,
      mediaPerformanceClass: 35,
      extended: accelerated,
    );
    // 5 RAM + 2 CPU + 2 heap + 5 platform + 2 media/compute.
    expect(full.score, 16);
    expect(full.measuredSignals, 5);
    expect(full.grade, 10);
    final partial = DeviceHardwareAssessment.fromEvidence(ramMiB: 8192);
    expect(partial.confidence, DeviceEvidenceConfidence.low);
    expect(partial.score, 4);
  });
  test(
    'non-Android acceleration can support a higher baseline without model names',
    () {
      const profile = DeviceWorkloadProfile(
        physicalRamMb: 8192,
        cpuCores: 6,
        availableRamMb: 4096,
        thermal: 'nominal',
        extended: accelerated,
      );
      expect(profile.baselineTier, DeviceWorkloadTier.performance);
      expect(profile.baselineGrade, 6);
      const lowRam = DeviceWorkloadProfile(
        physicalRamMb: 8192,
        cpuCores: 6,
        lowRam: true,
        extended: accelerated,
      );
      expect(lowRam.baselineTier, DeviceWorkloadTier.constrained);
      expect(lowRam.baselineGrade, 2);
    },
  );
  test(
    'runtime grades never exceed hardware and heat never disappears in grade',
    () {
      for (final thermal in [
        'nominal',
        'fair',
        'serious',
        'critical',
        'unknown',
      ]) {
        final profile = DeviceWorkloadProfile(
          physicalRamMb: 16384,
          cpuCores: 10,
          availableRamMb: 4096,
          extended: accelerated,
          thermal: thermal,
        );
        expect(profile.baselineTier, DeviceWorkloadTier.flagship);
        expect(
          profile.effectiveGrade,
          lessThanOrEqualTo(profile.baselineGrade!),
        );
        if (thermal == 'critical' || thermal == 'serious') {
          expect(profile.deferHeavyWork, isTrue);
          expect(profile.effectiveGrade, lessThanOrEqualTo(2));
        }
      }
    },
  );
}
