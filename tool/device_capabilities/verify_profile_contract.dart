import 'dart:convert';
import 'dart:io';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_profile.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_capability_facts.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_trip_guidance.dart';

/// Standalone independent invariant checks. No Flutter/native services, network,
/// file writes or legacy executable invocation. Not a device calibration test.
void main() {
  var checks = 0;
  void require(bool condition, String description) {
    checks++;
    if (!condition) throw StateError(description);
  }

  require(DeviceWorkloadTier.values.length == 6, 'Exactly six tiers');
  require(
    DeviceWorkloadProfile.storageReserveBytes >= 100000000,
    'Reserve must be at least the owner-required 100 MB',
  );
  for (final ram in [null, 1024, 2048, 4096, 6144, 8192, 12288, 16384]) {
    for (final cores in [null, 2, 4, 6, 8]) {
      for (final thermal in [
        'unknown',
        'nominal',
        'fair',
        'serious',
        'critical',
      ]) {
        for (final available in [null, 0, 128, 256, 512, 1024, 4096]) {
          final profile = DeviceWorkloadProfile(
            physicalRamMb: ram,
            cpuCores: cores,
            thermal: thermal,
            availableRamMb: available,
            heapMb: 512,
            mediaPerformanceClass: 35,
          );
          require(
            profile.tier.index <= profile.baselineTier.index,
            'Runtime conditions cannot raise hardware capacity',
          );
          require(
            profile.maxImagePixels <= 3000000,
            'All tiers respect the bounded image contract',
          );
          if (thermal == 'serious' || thermal == 'critical' || available == 0) {
            require(
              profile.deferHeavyWork,
              'Unsafe conditions must defer work',
            );
          }
        }
      }
    }
  }
  for (final value in [double.nan, double.infinity, -1, '8192', 1.5, [], {}]) {
    final profile = DeviceWorkloadProfile.fromMap({
      'physicalRamMb': value,
      'freeStorageBytes': value,
      'availableRamMb': value,
    });
    require(
      profile.physicalRamMb == null &&
          profile.freeStorageBytes == null &&
          profile.availableRamMb == null,
      'Malformed numbers cannot earn capacity',
    );
  }
  final zero = DeviceWorkloadProfile.fromMap({
    'probeAvailable': true,
    'freeStorageBytes': 0,
    'availableRamMb': 0,
  });
  require(
    zero.freeStorageBytes == 0 && zero.availableRamMb == 0,
    'Zero must remain real evidence, not unknown',
  );
  final identity = DeviceWorkloadProfile.fromMap({
    'deviceId': 'private-identifier',
    'registeredOwner': 'private-person',
    'physicalRamMb': 12345,
  });
  final diagnostics = jsonEncode(identity.toSafeDiagnostics());
  require(
    !diagnostics.contains('private-') && !diagnostics.contains('12345'),
    'Diagnostics omit identity and exact resource values',
  );
  final facts = DeviceCapabilityFacts(
    features: {
      for (final feature in DeviceFeature.values)
        feature: const DeviceFeatureStatus(
          availability: CapabilityAvailability.available,
          permission: CapabilityPermission.granted,
          serviceEnabled: true,
        ),
    },
  );
  final advice = DeviceTripGuidance.assess(
    DeviceWorkloadProfile(facts: facts),
    locationOptIn: false,
    motionOptIn: false,
    backgroundOptIn: false,
    backgroundPermission: CapabilityPermission.granted,
  );
  require(
    !advice.mayUseForegroundLocation &&
        !advice.mayUseActivityRecognition &&
        !advice.mayUseBackgroundLocation,
    'Availability cannot override opt-in',
  );
  stdout.writeln(
    jsonEncode({
      'result': 'passed',
      'checks': checks,
      'scope': 'pure profile invariants; no native or physical-device claim',
    }),
  );
}
