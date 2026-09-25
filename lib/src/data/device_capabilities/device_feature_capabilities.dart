// Adapted from the read-only 5.7 feature contract; unknown is not false.
enum DeviceBatteryHealth { unknown, good, degraded, overheating, failure }

enum DevicePowerSource { unknown, battery, external, usb, ac, wireless }

class DeviceCameraLensCapability {
  const DeviceCameraLensCapability({
    required this.position,
    required this.lensType,
    this.physicalLensCount = 1,
    this.maxStillWidth = 0,
    this.maxStillHeight = 0,
    this.minFocalLengthMm,
    this.maxFocalLengthMm,
    this.minAperture,
    this.maxOpticalOrSensorZoom,
    this.maxZoomRatio,
    this.maxDigitalZoom,
    this.maxVideoFps = 0,
    this.supportsAutofocus,
    this.supportsStabilization,
    this.supportsRaw,
    this.supportsDepth,
    this.supportsHdr,
    this.supportsTorch,
    this.supportsExposureCompensation,
    this.supportsContinuousFocus,
    this.supportsTapFocus,
  });

  final String position;
  final String lensType;
  final int physicalLensCount;
  final int maxStillWidth;
  final int maxStillHeight;
  final double? minFocalLengthMm;
  final double? maxFocalLengthMm;
  final double? minAperture;

  /// OS zoom-ratio range can include digital zoom; it is not optical proof.
  final double? maxZoomRatio;
  final double? maxOpticalOrSensorZoom;
  final double? maxDigitalZoom;
  final int maxVideoFps;
  final bool? supportsTorch,
      supportsExposureCompensation,
      supportsContinuousFocus,
      supportsTapFocus;
  final bool? supportsAutofocus;
  final bool? supportsStabilization;
  final bool? supportsRaw;
  final bool? supportsDepth;
  final bool? supportsHdr;

  int get maxStillMegapixels {
    if (maxStillWidth <= 0 || maxStillHeight <= 0) return 0;
    return ((maxStillWidth * maxStillHeight) / 1000000).round();
  }
}

class DeviceSensorCapabilities {
  const DeviceSensorCapabilities({
    this.sensorCount = 0,
    this.inventoryObserved = false,
    this.types = const <String>{},
    this.permissionGatedTypes = const <String>{},
  });

  final int sensorCount;
  final bool inventoryObserved;
  final Set<String> types;
  final Set<String> permissionGatedTypes;

  bool supports(String type) => types.contains(type);
  bool get hasMotion => supports('accelerometer') && supports('gyroscope');
  bool get hasHeading => supports('magnetometer');
  bool get hasPressure => supports('barometer');
  bool get hasStepDetection =>
      supports('step_counter') || supports('step_detector');
  bool get hasExerciseSignals =>
      hasStepDetection ||
      supports('activity_recognition') ||
      supports('walking_distance') ||
      supports('walking_pace') ||
      supports('walking_cadence') ||
      supports('floor_counting');
  bool get hasMotionStateTransitions =>
      supports('motion_detect') ||
      supports('stationary_detect') ||
      supports('significant_motion') ||
      supports('activity_recognition');
  bool get hasBodySignals =>
      supports('heart_rate') ||
      supports('heart_beat') ||
      permissionGatedTypes.contains('heart_rate');
  bool get hasAltitudeContext =>
      supports('barometer') || supports('floor_counting');
  bool get hasAmbientContext =>
      supports('ambient_light') || supports('proximity');
}

class DeviceBatteryCapabilities {
  const DeviceBatteryCapabilities({
    this.levelPercent,
    this.isCharging,
    this.isExternalPowerConnected,
    this.powerSource = DevicePowerSource.unknown,
    this.health = DeviceBatteryHealth.unknown,
    this.temperatureCelsius,
    this.remainingChargeMah,
    this.estimatedFullCapacityMah,
    this.capacityEstimateReliable = false,
    this.technology,
  });

  final int? levelPercent;
  final bool? isCharging;
  final bool? isExternalPowerConnected;
  final DevicePowerSource powerSource;
  final DeviceBatteryHealth health;
  final double? temperatureCelsius;
  final int? remainingChargeMah;

  /// Android may provide an estimate. iOS does not expose battery design
  /// capacity publicly, so this remains null rather than guessing.
  final int? estimatedFullCapacityMah;
  final bool? capacityEstimateReliable;
  final String? technology;

  bool get isLow => levelPercent != null && levelPercent! <= 20;
  bool get isCritical => levelPercent != null && levelPercent! <= 10;
}

class DeviceDisplayCapabilities {
  const DeviceDisplayCapabilities({
    this.widthPixels = 0,
    this.heightPixels = 0,
    this.densityScale = 1,
    this.maxRefreshRateHz = 0,
    this.supportsHdr,
    this.supportsWideColor,
  });

  final int widthPixels;
  final int heightPixels;
  final double densityScale;
  final double maxRefreshRateHz;
  final bool? supportsHdr;
  final bool? supportsWideColor;

  int get longestEdge =>
      widthPixels > heightPixels ? widthPixels : heightPixels;
}

class DeviceMediaCapabilities {
  const DeviceMediaCapabilities({
    this.hardwareDecodeTypes = const <String>{},
    this.hardwareEncodeTypes = const <String>{},
  });

  final Set<String> hardwareDecodeTypes;
  final Set<String> hardwareEncodeTypes;

  bool canHardwareDecode(String codec) => hardwareDecodeTypes.contains(codec);
  bool canHardwareEncode(String codec) => hardwareEncodeTypes.contains(codec);
}

class DeviceConnectivityCapabilities {
  const DeviceConnectivityCapabilities({
    this.transports = const <String>{},
    this.isConnected,
    this.isMetered,
    this.isConstrained,
    this.downstreamKbps,
    this.upstreamKbps,
  });

  final Set<String> transports;
  final bool? isConnected;
  final bool? isMetered;
  final bool? isConstrained;
  final int? downstreamKbps;
  final int? upstreamKbps;

  bool get permitsLargeTransfer =>
      isConnected == true && isMetered == false && isConstrained == false;
}

class DeviceGraphicsCapabilities {
  const DeviceGraphicsCapabilities({
    this.apiName = 'unknown',
    this.apiVersion = 'unknown',
    this.featureLevel = 'unknown',
    this.supportsCompute,
    this.supportsRayTracing,
  });

  final String apiName;
  final String apiVersion;
  final String featureLevel;
  final bool? supportsCompute;
  final bool? supportsRayTracing;
}

class DeviceExtendedCapabilities {
  const DeviceExtendedCapabilities({
    this.cameraLenses = const [],
    this.cameraInventoryObserved = false,
    this.sensors = const DeviceSensorCapabilities(),
    this.battery = const DeviceBatteryCapabilities(),
    this.display = const DeviceDisplayCapabilities(),
    this.media = const DeviceMediaCapabilities(),
    this.graphics = const DeviceGraphicsCapabilities(),
    this.connectivity = const DeviceConnectivityCapabilities(),
    this.bluetooth = const DeviceBluetoothReadiness(),
  });

  static const empty = DeviceExtendedCapabilities();

  final List<DeviceCameraLensCapability> cameraLenses;
  final bool cameraInventoryObserved;
  DeviceCameraSummary get camera =>
      DeviceCameraSummary(cameraLenses, cameraInventoryObserved);
  final DeviceSensorCapabilities sensors;
  final DeviceBatteryCapabilities battery;
  final DeviceDisplayCapabilities display;
  final DeviceMediaCapabilities media;
  final DeviceGraphicsCapabilities graphics;
  final DeviceConnectivityCapabilities connectivity;
  final DeviceBluetoothReadiness bluetooth;

  DeviceExtendedCapabilities withRuntime({
    required DeviceBatteryCapabilities battery,
    required DeviceConnectivityCapabilities connectivity,
  }) {
    return DeviceExtendedCapabilities(
      cameraLenses: cameraLenses,
      cameraInventoryObserved: cameraInventoryObserved,
      sensors: sensors,
      battery: battery,
      display: display,
      media: media,
      graphics: graphics,
      connectivity: connectivity,
      bluetooth: bluetooth,
    );
  }
}

/// Summary derived from one inventory, not a second camera detector. A logical
/// multi-camera and its physical members can each have a lens record.
class DeviceCameraSummary {
  const DeviceCameraSummary(this.lenses, this.inventoryObserved);
  final List<DeviceCameraLensCapability> lenses;
  final bool inventoryObserved;

  bool? get available => inventoryObserved ? lenses.isNotEmpty : null;
  bool? get hasRearCamera =>
      inventoryObserved ? lenses.any((lens) => lens.position == 'rear') : null;
  bool? get hasFrontCamera =>
      inventoryObserved ? lenses.any((lens) => lens.position == 'front') : null;
  int? get lensRecordCount => inventoryObserved ? lenses.length : null;
  bool? get supportsTorch => _any((lens) => lens.supportsTorch);
  bool? get supportsTapFocus => _any((lens) => lens.supportsTapFocus);
  bool? get supportsContinuousFocus =>
      _any((lens) => lens.supportsContinuousFocus);
  bool? get supportsExposureCompensation =>
      _any((lens) => lens.supportsExposureCompensation);
  bool? get supportsRaw => _any((lens) => lens.supportsRaw);

  /// Both dimensions must come from this same lens/format; never maximize axes
  /// independently. Null means no supported still format was observed.
  DeviceCameraLensCapability? get largestStillLens {
    DeviceCameraLensCapability? best;
    var area = 0;
    for (final lens in lenses) {
      final pixels = lens.maxStillWidth * lens.maxStillHeight;
      if (pixels > area) {
        area = pixels;
        best = lens;
      }
    }
    return best;
  }

  bool? _any(bool? Function(DeviceCameraLensCapability) read) {
    if (!inventoryObserved) return null;
    var unknown = false;
    for (final lens in lenses) {
      final value = read(lens);
      if (value == true) return true;
      if (value == null) unknown = true;
    }
    return unknown ? null : false;
  }
}

/// Adapter readiness only; never discovers or identifies connected accessories.
class DeviceBluetoothReadiness {
  const DeviceBluetoothReadiness({
    this.adapterAvailable,
    this.poweredOn,
    this.authorization = 'unknown',
    this.supportsApprovedDeviceObservation,
  });
  final bool? adapterAvailable, poweredOn, supportsApprovedDeviceObservation;
  final String authorization;
  bool get canObserveApprovedConnections =>
      adapterAvailable == true &&
      poweredOn == true &&
      authorization == 'authorized' &&
      supportsApprovedDeviceObservation == true;
}
