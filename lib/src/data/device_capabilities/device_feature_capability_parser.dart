import 'device_feature_capabilities.dart';

class DeviceFeatureCapabilityParser {
  const DeviceFeatureCapabilityParser();

  DeviceExtendedCapabilities parse(Map<Object?, Object?> value) {
    return DeviceExtendedCapabilities(
      cameraLenses: _cameraLenses(value['cameraLenses']),
      cameraInventoryObserved: value['cameraLenses'] is List,
      sensors: _sensors(_map(value['sensors'])),
      battery: _battery(_map(value['battery'])),
      display: _display(_map(value['display'])),
      media: _media(_map(value['media'])),
      graphics: _graphics(_map(value['graphics'])),
      connectivity: _connectivity(_map(value['connectivity'])),
      bluetooth: _bluetooth(_map(value['bluetooth'])),
    );
  }

  List<DeviceCameraLensCapability> _cameraLenses(Object? raw) {
    if (raw is! List) return const [];
    return List.unmodifiable(
      raw
          .take(64)
          .map(_map)
          .where((item) => item.isNotEmpty)
          .map(
            (item) => DeviceCameraLensCapability(
              position: _choice(item['position'], {
                'front',
                'rear',
                'external',
              }),
              lensType: _choice(item['lensType'], {
                'front',
                'wide',
                'ultrawide',
                'telephoto',
                'true_depth',
                'lidar',
                'dual',
                'dual_wide',
                'triple',
                'logical_multi_camera',
                'inferred_wide',
                'inferred_ultrawide',
                'inferred_telephoto',
              }),
              physicalLensCount:
                  _boundedInt(item['physicalLensCount'], 64, min: 1) ?? 1,
              maxStillWidth: _boundedInt(item['maxStillWidth'], 65536) ?? 0,
              maxStillHeight: _boundedInt(item['maxStillHeight'], 65536) ?? 0,
              minFocalLengthMm: _positiveDouble(item['minFocalLengthMm']),
              maxFocalLengthMm: _positiveDouble(item['maxFocalLengthMm']),
              minAperture: _positiveDouble(item['minAperture']),
              maxOpticalOrSensorZoom: _positiveDouble(
                item['maxOpticalOrSensorZoom'],
              ),
              maxZoomRatio: _positiveDouble(item['maxZoomRatio']),
              maxDigitalZoom: _positiveDouble(item['maxDigitalZoom']),
              maxVideoFps: _boundedInt(item['maxVideoFps'], 10000) ?? 0,
              supportsAutofocus: _boolean(item['supportsAutofocus']),
              supportsStabilization: _boolean(item['supportsStabilization']),
              supportsRaw: _boolean(item['supportsRaw']),
              supportsDepth: _boolean(item['supportsDepth']),
              supportsHdr: _boolean(item['supportsHdr']),
              supportsTorch: _boolean(item['supportsTorch']),
              supportsTapFocus: _boolean(item['supportsTapFocus']),
              supportsContinuousFocus: _boolean(
                item['supportsContinuousFocus'],
              ),
              supportsExposureCompensation: _boolean(
                item['supportsExposureCompensation'],
              ),
            ),
          ),
    );
  }

  DeviceSensorCapabilities _sensors(Map<Object?, Object?> value) {
    final types = _sensorTypes(value['types']);
    return DeviceSensorCapabilities(
      sensorCount: _boundedInt(value['sensorCount'], 4096) ?? types.length,
      inventoryObserved: value['types'] is List,
      types: types,
      permissionGatedTypes: _sensorTypes(value['permissionGatedTypes']),
    );
  }

  DeviceBatteryCapabilities _battery(Map<Object?, Object?> value) {
    return DeviceBatteryCapabilities(
      levelPercent: _boundedPercent(value['levelPercent']),
      isCharging: _boolean(value['isCharging']),
      isExternalPowerConnected: _boolean(value['isExternalPowerConnected']),
      powerSource: _powerSource(value['powerSource']),
      health: _batteryHealth(value['health']),
      temperatureCelsius: _temperature(value['temperatureCelsius']),
      remainingChargeMah: _positiveInt(value['remainingChargeMah']),
      estimatedFullCapacityMah: _positiveInt(value['estimatedFullCapacityMah']),
      capacityEstimateReliable: value['capacityEstimateReliable'] == true,
      technology: _text(value['technology']),
    );
  }

  DeviceDisplayCapabilities _display(Map<Object?, Object?> value) {
    return DeviceDisplayCapabilities(
      widthPixels: _nonNegativeInt(value['widthPixels']) ?? 0,
      heightPixels: _nonNegativeInt(value['heightPixels']) ?? 0,
      densityScale: _positiveDouble(value['densityScale']) ?? 1,
      maxRefreshRateHz: _positiveDouble(value['maxRefreshRateHz']) ?? 0,
      supportsHdr: _boolean(value['supportsHdr']),
      supportsWideColor: _boolean(value['supportsWideColor']),
    );
  }

  DeviceMediaCapabilities _media(Map<Object?, Object?> value) {
    return DeviceMediaCapabilities(
      hardwareDecodeTypes: Set.unmodifiable(
        _stringSet(value['hardwareDecodeTypes']).intersection(_codecs),
      ),
      hardwareEncodeTypes: Set.unmodifiable(
        _stringSet(value['hardwareEncodeTypes']).intersection(_codecs),
      ),
    );
  }

  DeviceGraphicsCapabilities _graphics(Map<Object?, Object?> value) {
    return DeviceGraphicsCapabilities(
      apiName: _choice(value['apiName'], {
        'metal',
        'vulkan+opengl_es',
        'opengl_es',
        'direct3d',
      }),
      apiVersion: _text(value['apiVersion']) ?? 'unknown',
      featureLevel: _text(value['featureLevel']) ?? 'unknown',
      supportsCompute: _boolean(value['supportsCompute']),
      supportsRayTracing: _boolean(value['supportsRayTracing']),
    );
  }

  DeviceConnectivityCapabilities _connectivity(Map<Object?, Object?> value) {
    return DeviceConnectivityCapabilities(
      transports: Set.unmodifiable(
        _stringSet(value['transports']).intersection({
          'wifi',
          'cellular',
          'ethernet',
          'vpn',
          'bluetooth',
          'other',
        }),
      ),
      isConnected: _boolean(value['isConnected']),
      isMetered: _boolean(value['isMetered']),
      isConstrained: _boolean(value['isConstrained']),
      downstreamKbps: _nonNegativeInt(value['downstreamKbps']),
      upstreamKbps: _nonNegativeInt(value['upstreamKbps']),
    );
  }

  static Map<Object?, Object?> _map(Object? value) {
    return value is Map ? Map<Object?, Object?>.from(value) : const {};
  }

  static Set<String> _sensorTypes(Object? value) => Set.unmodifiable(
    _stringSet(value).where(
      (type) =>
          _sensorsAllowed.contains(type) ||
          RegExp(r'^type_[0-9]{1,10}$').hasMatch(type),
    ),
  );
  static const _sensorsAllowed = {
    'accelerometer',
    'magnetometer',
    'orientation_legacy',
    'gyroscope',
    'barometer',
    'ambient_light',
    'proximity',
    'gravity',
    'linear_acceleration',
    'rotation_vector',
    'humidity',
    'ambient_temperature',
    'magnetometer_uncalibrated',
    'game_rotation_vector',
    'gyroscope_uncalibrated',
    'significant_motion',
    'step_detector',
    'step_counter',
    'geomagnetic_rotation_vector',
    'heart_rate',
    'heart_rate_ecg',
    'tilt_detector',
    'wake_gesture',
    'glance_gesture',
    'pickup_gesture',
    'wrist_tilt_gesture',
    'device_orientation',
    'pose_6dof',
    'stationary_detect',
    'motion_detect',
    'heart_beat',
    'dynamic_sensor_metadata',
    'additional_sensor_info',
    'low_latency_offbody_detect',
    'accelerometer_uncalibrated',
    'hinge_angle',
    'head_tracker',
    'limited_axes_accelerometer',
    'limited_axes_gyroscope',
    'limited_axes_accelerometer_uncalibrated',
    'limited_axes_gyroscope_uncalibrated',
    'heading',
    'device_motion',
    'walking_distance',
    'floor_counting',
    'walking_pace',
    'walking_cadence',
    'pedometer_event_tracking',
    'activity_recognition',
    'relative_altitude',
  };
  static const _codecs = {'h264', 'hevc', 'vp9', 'av1', 'jpeg'};
  static bool? _boolean(Object? value) => value is bool ? value : null;
  static String _choice(Object? value, Set<String> choices) =>
      value is String && choices.contains(value) ? value : 'unknown';
  static Set<String> _stringSet(Object? value) {
    if (value is! List) return const {};
    return Set.unmodifiable(value.take(256).map(_text).whereType<String>());
  }

  static int? _boundedPercent(Object? value) {
    final parsed = _nonNegativeInt(value);
    return parsed != null && parsed <= 100 ? parsed : null;
  }

  static int? _boundedInt(Object? value, int max, {int min = 0}) {
    final parsed = _nonNegativeInt(value);
    return parsed != null && parsed >= min && parsed <= max ? parsed : null;
  }

  static int? _positiveInt(Object? value) {
    final parsed = _nonNegativeInt(value);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static int? _nonNegativeInt(Object? value) =>
      value is num &&
          value.isFinite &&
          value >= 0 &&
          value <= 1 << 31 &&
          value == value.truncateToDouble()
      ? value.toInt()
      : null;
  static double? _positiveDouble(Object? value) {
    final parsed = _number(value);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static double? _number(Object? value) =>
      value is num && value.isFinite && value.abs() <= 1e9
      ? value.toDouble()
      : null;
  static double? _temperature(Object? value) {
    final parsed = _number(value);
    return parsed != null && parsed >= -40 && parsed <= 100 ? parsed : null;
  }

  static String? _text(Object? value) =>
      value is String && RegExp(r'^[a-zA-Z0-9_.+ -]{1,64}$').hasMatch(value)
      ? value
      : null;
  static DeviceBluetoothReadiness _bluetooth(Map<Object?, Object?> value) =>
      DeviceBluetoothReadiness(
        adapterAvailable: _boolean(value['adapterAvailable']),
        poweredOn: _boolean(value['poweredOn']),
        authorization: _choice(value['authorization'], {
          'authorized',
          'denied',
          'restricted',
          'notRequested',
        }),
        supportsApprovedDeviceObservation: _boolean(
          value['supportsApprovedDeviceObservation'],
        ),
      );

  static DevicePowerSource _powerSource(Object? value) {
    return DevicePowerSource.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => DevicePowerSource.unknown,
    );
  }

  static DeviceBatteryHealth _batteryHealth(Object? value) {
    return DeviceBatteryHealth.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => DeviceBatteryHealth.unknown,
    );
  }
}
