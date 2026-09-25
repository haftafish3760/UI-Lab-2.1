import 'device_capability_facts.dart';
import 'device_workload_profile.dart';

enum TripCapabilityMode { manual, locationOnly, motionAssisted }

/// A proposal for a trip module, never an instruction to start sensors.
/// Background authorization must be supplied separately by that module.
class DeviceTripGuidance {
  const DeviceTripGuidance._({
    required this.mode,
    required this.mayUseForegroundLocation,
    required this.mayUseBackgroundLocation,
    required this.mayUseActivityRecognition,
    required this.mayUsePedometer,
    required this.samplingIntervalSeconds,
    required this.reasons,
  });
  final TripCapabilityMode mode;
  final bool mayUseForegroundLocation;
  final bool mayUseBackgroundLocation;
  final bool mayUseActivityRecognition;
  final bool mayUsePedometer;
  final int samplingIntervalSeconds;
  final List<String> reasons;

  // Even available motion classification cannot prove a business trip or stop.
  bool get inferredActivityRequiresReview => true;

  factory DeviceTripGuidance.assess(
    DeviceWorkloadProfile profile, {
    required bool locationOptIn,
    required bool motionOptIn,
    required bool backgroundOptIn,
    required CapabilityPermission backgroundPermission,
  }) {
    final facts = profile.facts ?? DeviceCapabilityFacts();
    final reasons = <String>[...profile.stopReasons];
    final location = facts[DeviceFeature.location];
    if (!locationOptIn) reasons.add('locationNotOptedIn');
    if (!location.technicallyUsable) reasons.add('locationNotReady');
    final allowed =
        locationOptIn && location.technicallyUsable && !profile.deferHeavyWork;
    final activity =
        allowed &&
        motionOptIn &&
        facts[DeviceFeature.activityRecognition].technicallyUsable;
    final pedometer =
        allowed &&
        motionOptIn &&
        (facts[DeviceFeature.stepCounter].technicallyUsable ||
            facts[DeviceFeature.stepDetector].technicallyUsable);
    if (allowed && !activity) reasons.add('locationOnlyNeedsReview');
    final background =
        allowed &&
        backgroundOptIn &&
        backgroundPermission == CapabilityPermission.granted;
    if (backgroundOptIn && !background) reasons.add('backgroundNotReady');
    return DeviceTripGuidance._(
      mode: !allowed
          ? TripCapabilityMode.manual
          : activity
          ? TripCapabilityMode.motionAssisted
          : TripCapabilityMode.locationOnly,
      mayUseForegroundLocation: allowed,
      mayUseBackgroundLocation: background,
      mayUseActivityRecognition: activity,
      mayUsePedometer: pedometer,
      samplingIntervalSeconds: profile.tripLocationIntervalSeconds,
      reasons: List.unmodifiable(reasons),
    );
  }
}
