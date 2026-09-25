/// Capability inventory, never sensor samples or device identity.
enum CapabilityAvailability { unknown, unavailable, available }

enum CapabilityPermission { unknown, notRequested, denied, restricted, granted }

enum DeviceFeature {
  accelerometer,
  gyroscope,
  magnetometer,
  barometer,
  stepCounter,
  stepDetector,
  significantMotion,
  gravity,
  linearAcceleration,
  rotationVector,
  stationaryDetection,
  motionDetection,
  ambientLight,
  proximity,
  deviceMotion,
  relativeAltitude,
  walkingDistance,
  walkingPace,
  walkingCadence,
  floorCounting,
  pedometerEvents,
  activityRecognition,
  location,
  gpsReceiver,
  backgroundLocation,
  rearCamera,
  frontCamera,
}

class DeviceFeatureStatus {
  const DeviceFeatureStatus({
    this.availability = CapabilityAvailability.unknown,
    this.permission = CapabilityPermission.unknown,
    this.serviceEnabled,
  });
  final CapabilityAvailability availability;
  final CapabilityPermission permission;
  final bool? serviceEnabled;

  /// Still requires feature-specific user opt-in; this never authorizes tracking.
  bool get technicallyUsable =>
      availability == CapabilityAvailability.available &&
      permission == CapabilityPermission.granted &&
      serviceEnabled != false;
}

class DeviceCapabilityFacts {
  DeviceCapabilityFacts({
    Map<DeviceFeature, DeviceFeatureStatus> features = const {},
  }) : features = Map.unmodifiable(features);
  final Map<DeviceFeature, DeviceFeatureStatus> features;
  DeviceFeatureStatus operator [](DeviceFeature feature) =>
      features[feature] ?? const DeviceFeatureStatus();

  factory DeviceCapabilityFacts.fromMap(Object? raw) {
    final map = raw is Map ? raw : const {};
    return DeviceCapabilityFacts(
      features: {
        for (final feature in DeviceFeature.values)
          feature: _parse(map[feature.name]),
      },
    );
  }

  static DeviceFeatureStatus _parse(Object? raw) {
    if (raw is! Map) return const DeviceFeatureStatus();
    return DeviceFeatureStatus(
      availability: CapabilityAvailability.values.firstWhere(
        (v) => v.name == raw['availability'],
        orElse: () => CapabilityAvailability.unknown,
      ),
      permission: CapabilityPermission.values.firstWhere(
        (v) => v.name == raw['permission'],
        orElse: () => CapabilityPermission.unknown,
      ),
      serviceEnabled: raw['serviceEnabled'] is bool
          ? raw['serviceEnabled'] as bool
          : null,
    );
  }
}
