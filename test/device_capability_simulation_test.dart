import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';

// Synthetic evidence is injected through the same service used by the app.
// There is intentionally no production override or phone model lookup.
void main() {
  const scenarios = <DeviceWorkloadTier, Map<String, Object>>{
    DeviceWorkloadTier.constrained: {'physicalRamMb': 2048, 'cpuCores': 4},
    DeviceWorkloadTier.entry: {'physicalRamMb': 4096, 'cpuCores': 4},
    DeviceWorkloadTier.balanced: {'physicalRamMb': 6144, 'cpuCores': 8},
    DeviceWorkloadTier.enhanced: {'physicalRamMb': 8192, 'cpuCores': 8},
    DeviceWorkloadTier.performance: {
      'physicalRamMb': 8192,
      'cpuCores': 8,
      'mediaPerformanceClass': 31,
    },
    DeviceWorkloadTier.flagship: {
      'physicalRamMb': 12288,
      'cpuCores': 8,
      'mediaPerformanceClass': 35,
    },
  };
  for (final scenario in scenarios.entries) {
    test(
      '${scenario.key.name}: pressure interrupts and recovery re-admits',
      () async {
        final conditions = <Object?, Object?>{
          'probeAvailable': true,
          'applicationHeapMb': 512,
          'availableRamMb': 1800,
          'lowRam': false,
          'lowMemory': false,
          'powerSaving': false,
          'thermalState': 'nominal',
          'batteryPercent': 80,
          'externalPower': false,
          ...scenario.value,
        };
        final service = DeviceWorkloadService(
          probe: () async => DeviceWorkloadProfile.fromMap(conditions),
        );
        addTearDown(service.dispose);
        expect((await service.refresh()).tier, scenario.key);
        await service.run((profile) async {
          expect(profile.tier, scenario.key);
        });
        for (final pressure in <Map<String, Object>>[
          {'thermalState': 'serious'},
          {'availableRamMb': 100},
          {'batteryPercent': 0},
          {'batteryTemperatureC': 46},
        ]) {
          final previous = Map<Object?, Object?>.from(conditions);
          conditions.addAll(pressure);
          await expectLater(
            service.run((_) async => fail('unsafe admission')),
            throwsA(isA<DeviceWorkloadUnavailable>()),
          );
          expect(
            service.latest.tier.index,
            lessThanOrEqualTo(scenario.key.index),
          );
          conditions
            ..clear()
            ..addAll(previous);
          await service.run((_) async {});
        }
      },
    );
  }
}
