import AVFoundation
import CoreLocation
import CoreMotion
import Foundation
import Flutter
import os
import UIKit

/// Availability queries only. Never start updates, capture, or authorization.
enum DeviceResourceProbe {
  static func read() -> [String: Any] {
    let process = ProcessInfo.processInfo
    let thermal: String
    switch process.thermalState {
    case .nominal: thermal = "nominal"
    case .fair: thermal = "fair"
    case .serious: thermal = "serious"
    case .critical: thermal = "critical"
    @unknown default: thermal = "unknown"
    }
    var facts: [String: Any] = [
      "probeAvailable": true,
      "physicalRamMb": Int(process.physicalMemory / 1_048_576),
      // App allocation headroom, not total system-free RAM. Never cache it.
      "availableRamMb": Int(os_proc_available_memory() / 1_048_576),
      "cpuCores": process.activeProcessorCount,
      "powerSaving": process.isLowPowerModeEnabled,
      "thermalState": thermal,
      "features": features(),
      "extended": DeviceExtendedProbe.shared.read(),
      "descriptor": DeviceExtendedProbe.shared.descriptor()
    ]
    #if arch(arm64)
    facts["cpuArchitecture"] = "arm64"
    #elseif arch(x86_64)
    facts["cpuArchitecture"] = "x86_64"
    #endif
    if let capacity = try? URL(fileURLWithPath: NSHomeDirectory())
      .resourceValues(forKeys: [.volumeAvailableCapacityKey]).volumeAvailableCapacity {
      facts["freeStorageBytes"] = capacity
    }
    let device = UIDevice.current
    let previouslyMonitoring = device.isBatteryMonitoringEnabled
    device.isBatteryMonitoringEnabled = true
    defer { device.isBatteryMonitoringEnabled = previouslyMonitoring }
    if device.batteryLevel >= 0 {
      facts["batteryPercent"] = Int((device.batteryLevel * 100).rounded())
    }
    switch device.batteryState {
    case .charging, .full: facts["externalPower"] = true
    case .unplugged: facts["externalPower"] = false
    case .unknown: break
    @unknown default: break
    }
    // iOS exposes no public exact battery temperature/health or charger type.
    return facts
  }

  private static func motionPermission(_ value: CMAuthorizationStatus) -> String {
    switch value {
    case .authorized: return "granted"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notRequested"
    @unknown default: return "unknown"
    }
  }

  private static func cameraPermission() -> String {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: return "granted"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notRequested"
    @unknown default: return "unknown"
    }
  }

  private static func status(_ available: Bool, _ permission: String) -> [String: Any] {
    ["availability": available ? "available" : "unavailable", "permission": permission]
  }

  private static func features() -> [String: Any] {
    let motion = CMMotionManager()
    // Raw inertial sensor availability doesn't prove permission for motion history.
    let motionAuth = motionPermission(CMMotionActivityManager.authorizationStatus())
    let cameras = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified
    ).devices
    var features: [String: Any] = [
      "accelerometer": status(motion.isAccelerometerAvailable, "unknown"),
      "gyroscope": status(motion.isGyroAvailable, "unknown"),
      "magnetometer": status(motion.isMagnetometerAvailable, "unknown"),
      "barometer": status(CMAltimeter.isRelativeAltitudeAvailable(), "unknown"),
      "stepCounter": status(CMPedometer.isStepCountingAvailable(), motionPermission(CMPedometer.authorizationStatus())),
      "deviceMotion": status(motion.isDeviceMotionAvailable, "unknown"),
      "relativeAltitude": status(CMAltimeter.isRelativeAltitudeAvailable(), motionPermission(CMAltimeter.authorizationStatus())),
      "walkingDistance": status(CMPedometer.isDistanceAvailable(), motionPermission(CMPedometer.authorizationStatus())),
      "walkingPace": status(CMPedometer.isPaceAvailable(), motionPermission(CMPedometer.authorizationStatus())),
      "walkingCadence": status(CMPedometer.isCadenceAvailable(), motionPermission(CMPedometer.authorizationStatus())),
      "floorCounting": status(CMPedometer.isFloorCountingAvailable(), motionPermission(CMPedometer.authorizationStatus())),
      "pedometerEvents": status(CMPedometer.isPedometerEventTrackingAvailable(), motionPermission(CMPedometer.authorizationStatus())),
      "activityRecognition": status(CMMotionActivityManager.isActivityAvailable(), motionAuth),
      "rearCamera": status(cameras.contains { $0.position == .back }, cameraPermission()),
      "frontCamera": status(cameras.contains { $0.position == .front }, cameraPermission())
    ]
    let authorization: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      authorization = CLLocationManager().authorizationStatus
    } else {
      authorization = CLLocationManager.authorizationStatus()
    }
    let permission: String
    switch authorization {
    case .authorizedAlways, .authorizedWhenInUse: permission = "granted"
    case .denied: permission = "denied"
    case .restricted: permission = "restricted"
    case .notDetermined: permission = "notRequested"
    @unknown default: permission = "unknown"
    }
    // Location services availability is not proof of a dedicated GPS receiver.
    features["location"] = ["availability": "available", "permission": permission,
      "serviceEnabled": CLLocationManager.locationServicesEnabled()]
    features["backgroundLocation"] = ["availability": "available",
      "permission": authorization == .authorizedAlways ? "granted" :
        (authorization == .authorizedWhenInUse ? "denied" : permission),
      "serviceEnabled": CLLocationManager.locationServicesEnabled()]
    return features
  }
}

final class DeviceResourceEvents: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []
  private var previousBatteryMonitoring = false
  private var listening = false

  func register(_ messenger: FlutterBinaryMessenger) {
    FlutterEventChannel(name: "app.device_capability_events", binaryMessenger: messenger)
      .setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    _ = onCancel(withArguments: nil)
    sink = events
    DeviceExtendedProbe.shared.onNetworkChange = { [weak self] in self?.sink?("network") }
    previousBatteryMonitoring = UIDevice.current.isBatteryMonitoringEnabled
    UIDevice.current.isBatteryMonitoringEnabled = true
    listening = true
    let notifications: [(Notification.Name, String)] = [
      (UIDevice.batteryLevelDidChangeNotification, "health"),
      (UIDevice.batteryStateDidChangeNotification, "health"),
      (Notification.Name.NSProcessInfoPowerStateDidChange, "health"),
      (ProcessInfo.thermalStateDidChangeNotification, "thermal"),
      (UIApplication.didReceiveMemoryWarningNotification, "memory")
    ]
    observers = notifications.map { name, reason in
      NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        self?.sink?(reason)
      }
    }
    events("ready")
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observers.forEach(NotificationCenter.default.removeObserver)
    observers.removeAll()
    sink = nil
    DeviceExtendedProbe.shared.onNetworkChange = nil
    if listening { UIDevice.current.isBatteryMonitoringEnabled = previousBatteryMonitoring }
    listening = false
    return nil
  }
}
