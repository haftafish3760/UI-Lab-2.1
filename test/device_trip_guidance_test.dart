import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_trip_guidance.dart';

void main() {
  test('native background revocation defeats a cached consumer grant', () {
    for (final permission in CapabilityPermission.values) {
      final advice = DeviceTripGuidance.assess(
        DeviceWorkloadProfile(
          observedAt: DateTime.now(),
          facts: DeviceCapabilityFacts(
            features: {
              DeviceFeature.location: const DeviceFeatureStatus(
                availability: CapabilityAvailability.available,
                permission: CapabilityPermission.granted,
                serviceEnabled: true,
              ),
              DeviceFeature.backgroundLocation: DeviceFeatureStatus(
                availability: CapabilityAvailability.available,
                permission: permission,
              ),
            },
          ),
        ),
        locationOptIn: true,
        motionOptIn: false,
        backgroundOptIn: true,
        backgroundPermission: CapabilityPermission.granted,
      );
      expect(advice.mayUseForegroundLocation, isTrue);
      expect(
        advice.mayUseBackgroundLocation,
        permission == CapabilityPermission.granted ||
            permission == CapabilityPermission.unknown,
      );
    }
  });
  test('trip readiness refuses missing, expired and future observations', () {
    final now = DateTime.utc(2026, 9, 19);
    for (final offset in <Duration?>[
      null,
      const Duration(seconds: -11),
      const Duration(seconds: 3),
      const Duration(seconds: -10),
      const Duration(seconds: 2),
    ]) {
      final advice = DeviceTripGuidance.assess(
        DeviceWorkloadProfile(
          observedAt: offset == null ? null : now.add(offset),
          facts: DeviceCapabilityFacts(
            features: {
              DeviceFeature.location: const DeviceFeatureStatus(
                availability: CapabilityAvailability.available,
                permission: CapabilityPermission.granted,
                serviceEnabled: true,
              ),
            },
          ),
        ),
        now: now,
        locationOptIn: true,
        motionOptIn: true,
        backgroundOptIn: true,
        backgroundPermission: CapabilityPermission.granted,
      );
      final valid = offset?.inSeconds == -10 || offset?.inSeconds == 2;
      expect(advice.mayUseForegroundLocation, valid);
      expect(advice.mayUseBackgroundLocation, valid);
      expect(advice.reasons.contains('observationNotFresh'), !valid);
    }
  });
  test('unknown or disabled location service cannot authorize tracking', () {
    for (final enabled in <bool?>[null, false, true]) {
      final advice = DeviceTripGuidance.assess(
        DeviceWorkloadProfile(
          observedAt: DateTime.now(),
          facts: DeviceCapabilityFacts(
            features: {
              DeviceFeature.location: DeviceFeatureStatus(
                availability: CapabilityAvailability.available,
                permission: CapabilityPermission.granted,
                serviceEnabled: enabled,
              ),
            },
          ),
        ),
        locationOptIn: true,
        motionOptIn: true,
        backgroundOptIn: true,
        backgroundPermission: CapabilityPermission.granted,
      );
      expect(advice.mayUseForegroundLocation, enabled == true);
      expect(advice.mayUseBackgroundLocation, enabled == true);
      expect(advice.reasons.contains('locationNotReady'), enabled != true);
    }
  });
  const ready = DeviceFeatureStatus(
    availability: CapabilityAvailability.available,
    permission: CapabilityPermission.granted,
    serviceEnabled: true,
  );
  final facts = DeviceCapabilityFacts(
    features: {
      DeviceFeature.location: ready,
      DeviceFeature.activityRecognition: ready,
      DeviceFeature.stepCounter: ready,
    },
  );
  test('all hardware available still cannot bypass opt-in', () {
    final advice = DeviceTripGuidance.assess(
      DeviceWorkloadProfile(facts: facts, observedAt: DateTime.now()),
      locationOptIn: false,
      motionOptIn: false,
      backgroundOptIn: false,
      backgroundPermission: CapabilityPermission.granted,
    );
    expect(advice.mode, TripCapabilityMode.manual);
    expect(advice.mayUseActivityRecognition, isFalse);
    expect(advice.mayUsePedometer, isFalse);
    expect(advice.mayUseBackgroundLocation, isFalse);
  });
  test('foreground permission never grants background permission', () {
    final advice = DeviceTripGuidance.assess(
      DeviceWorkloadProfile(facts: facts, observedAt: DateTime.now()),
      locationOptIn: true,
      motionOptIn: true,
      backgroundOptIn: true,
      backgroundPermission: CapabilityPermission.denied,
    );
    expect(advice.mode, TripCapabilityMode.motionAssisted);
    expect(advice.mayUseForegroundLocation, isTrue);
    expect(advice.mayUseBackgroundLocation, isFalse);
    expect(advice.inferredActivityRequiresReview, isTrue);
  });
  test('step counter cannot prove activity classification', () {
    final advice = DeviceTripGuidance.assess(
      DeviceWorkloadProfile(
        observedAt: DateTime.now(),
        facts: DeviceCapabilityFacts(
          features: {
            DeviceFeature.location: ready,
            DeviceFeature.stepCounter: ready,
          },
        ),
      ),
      locationOptIn: true,
      motionOptIn: true,
      backgroundOptIn: false,
      backgroundPermission: CapabilityPermission.unknown,
    );
    expect(advice.mode, TripCapabilityMode.locationOnly);
    expect(advice.mayUsePedometer, isTrue);
    expect(advice.mayUseActivityRecognition, isFalse);
  });
  test('critical heat and revoked permission each restore manual fallback', () {
    for (final profile in [
      DeviceWorkloadProfile(
        facts: facts,
        thermal: 'critical',
        observedAt: DateTime.now(),
      ),
      DeviceWorkloadProfile(
        facts: DeviceCapabilityFacts(),
        observedAt: DateTime.now(),
      ),
    ]) {
      final advice = DeviceTripGuidance.assess(
        profile,
        locationOptIn: true,
        motionOptIn: true,
        backgroundOptIn: true,
        backgroundPermission: CapabilityPermission.granted,
      );
      expect(advice.mode, TripCapabilityMode.manual);
      expect(advice.mayUseBackgroundLocation, isFalse);
      expect(advice.reasons, isNot(contains('observationNotFresh')));
    }
  });
}
