import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_trip_guidance.dart';

void main() {
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
      DeviceWorkloadProfile(facts: facts),
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
      DeviceWorkloadProfile(facts: facts),
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
      DeviceWorkloadProfile(facts: facts, thermal: 'critical'),
      DeviceWorkloadProfile(facts: DeviceCapabilityFacts()),
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
    }
  });
}
