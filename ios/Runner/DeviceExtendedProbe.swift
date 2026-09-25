import AVFoundation
import CoreBluetooth
import CoreMotion
import Metal
import Network
import UIKit
import VideoToolbox

import Darwin
/// Read-only feature enumeration adapted from 5.7, owned by the existing probe.
final class DeviceExtendedProbe {
  static let shared = DeviceExtendedProbe()
  private let pathMonitor = NWPathMonitor()
  private let pathQueue = DispatchQueue(label: "app.device-capability-network")
  private let pathLock = NSLock()
  private var latestPath: NWPath?
  private var staticFacts: [String: Any]?
  private var staticAt: TimeInterval = 0
  private var cameraAuthorization: AVAuthorizationStatus?
  var onNetworkChange: (() -> Void)?

  private init() {
    pathMonitor.pathUpdateHandler = { [weak self] path in
      guard let self else { return }
      self.pathLock.lock()
      self.latestPath = path
      self.pathLock.unlock()
      DispatchQueue.main.async { [weak self] in self?.onNetworkChange?() }
    }
    pathMonitor.start(queue: pathQueue)
  }
  deinit { pathMonitor.cancel() }

  // Called by the Flutter main-thread handler; stable discovery is cached.
  func read() -> [String: Any] {
    let now = ProcessInfo.processInfo.systemUptime
    let authorization = AVCaptureDevice.authorizationStatus(for: .video)
    if staticFacts == nil || now - staticAt > 600 || cameraAuthorization != authorization {
      cameraAuthorization = authorization
      staticFacts = ["cameraLenses": readCameraLenses(), "media": readMedia(),
        "graphics": readGraphics()]
      staticAt = now
    }
    var facts = staticFacts ?? [:]
    facts["sensors"] = readSensors()
    facts["battery"] = readBattery()
    facts["display"] = readDisplay()
    facts["connectivity"] = readConnectivity()
    facts["bluetooth"] = readBluetoothCapabilities()
    return facts
  }

  func descriptor() -> [String: Any] {
    var system = utsname()
    uname(&system)
    let capacity = MemoryLayout.size(ofValue: system.machine)
    let model = withUnsafePointer(to: &system.machine) { ptr in
      ptr.withMemoryRebound(to: CChar.self, capacity: capacity) {
        String(cString: $0)
      }
    }
    var value: [String: Any] = ["platform": "ios", "manufacturer": "Apple",
      "osVersion": UIDevice.current.systemVersion, "model": model]
    #if targetEnvironment(simulator)
    value["isPhysicalDevice"] = false
    #else
    value["isPhysicalDevice"] = true
    #endif
    return value
  }

  private func readBluetoothCapabilities() -> [String: Any] {
    let authorization: String
    switch CBCentralManager.authorization {
    case .allowedAlways:
      authorization = "authorized"
    case .denied:
      authorization = "denied"
    case .restricted:
      authorization = "restricted"
    case .notDetermined:
      authorization = "notRequested"
    @unknown default:
      authorization = "unknown"
    }
    return [
      "adapterAvailable": true,
      // Do not create a central manager or prompt merely to populate a
      // capabilities screen. A user-approved adapter owns live observation.
      "authorization": authorization,
      "supportsApprovedDeviceObservation": false
    ]
  }

  private func cameraDevices() -> [AVCaptureDevice] {
    let types: [AVCaptureDevice.DeviceType] = [
      .builtInWideAngleCamera,
      .builtInUltraWideCamera,
      .builtInTelephotoCamera,
      .builtInDualCamera,
      .builtInDualWideCamera,
      .builtInTripleCamera,
      .builtInTrueDepthCamera,
      .builtInLiDARDepthCamera
    ]
    return AVCaptureDevice.DiscoverySession(
      deviceTypes: types,
      mediaType: .video,
      position: .unspecified
    ).devices
  }

  private func readCameraLenses() -> [[String: Any]] {
    return cameraDevices().map { device in
      let dimensions = maxStillDimensions(device)
      let maxFps = device.formats.flatMap(\.videoSupportedFrameRateRanges)
        .map(\.maxFrameRate).max() ?? 0
      return [
        "position": positionName(device.position),
        "lensType": lensType(device.deviceType),
        "physicalLensCount": max(1, device.constituentDevices.count),
        "maxStillWidth": dimensions.width,
        "maxStillHeight": dimensions.height,
        "maxZoomRatio": Double(device.maxAvailableVideoZoomFactor),
        "maxDigitalZoom": Double(device.maxAvailableVideoZoomFactor),
        "maxVideoFps": Int(maxFps.rounded()),
        "supportsAutofocus": device.isFocusModeSupported(.autoFocus) ||
          device.isFocusModeSupported(.continuousAutoFocus),
        "supportsStabilization": device.formats.contains { $0.isVideoStabilizationModeSupported(.standard) },
        "supportsTorch": device.hasTorch,
        "supportsTapFocus": device.isFocusPointOfInterestSupported,
        "supportsContinuousFocus": device.isFocusModeSupported(.continuousAutoFocus),
        "supportsExposureCompensation": device.maxExposureTargetBias > device.minExposureTargetBias,
        "supportsDepth": device.formats.contains { !$0.supportedDepthDataFormats.isEmpty },
        "supportsHdr": device.formats.contains(where: \.isVideoHDRSupported)
      ]
    }
  }

  private func maxStillDimensions(_ device: AVCaptureDevice) -> (width: Int, height: Int) {
    var best = (width: 0, height: 0)
    for format in device.formats {
      let dimensions: CMVideoDimensions
      if #available(iOS 16.0, *), let maximum = format.supportedMaxPhotoDimensions.max(by: {
        Int64($0.width) * Int64($0.height) < Int64($1.width) * Int64($1.height)
      }) {
        dimensions = maximum
      } else {
        dimensions = format.highResolutionStillImageDimensions
      }
      if Int64(dimensions.width) * Int64(dimensions.height) > Int64(best.width) * Int64(best.height) {
        best = (Int(dimensions.width), Int(dimensions.height))
      }
    }
    return best
  }

  private func positionName(_ position: AVCaptureDevice.Position) -> String {
    switch position {
    case .back: return "rear"
    case .front: return "front"
    case .unspecified: return "unknown"
    @unknown default: return "unknown"
    }
  }

  private func lensType(_ type: AVCaptureDevice.DeviceType) -> String {
    switch type {
    case .builtInUltraWideCamera: return "ultrawide"
    case .builtInTelephotoCamera: return "telephoto"
    case .builtInTrueDepthCamera: return "true_depth"
    case .builtInLiDARDepthCamera: return "lidar"
    case .builtInDualCamera: return "dual"
    case .builtInDualWideCamera: return "dual_wide"
    case .builtInTripleCamera: return "triple"
    case .builtInWideAngleCamera: return "wide"
    default: return "unknown"
    }
  }

  private func readSensors() -> [String: Any] {
    let motion = CMMotionManager()
    var types: [String] = []
    if motion.isAccelerometerAvailable { types.append("accelerometer") }
    if motion.isGyroAvailable { types.append("gyroscope") }
    if motion.isMagnetometerAvailable { types.append("magnetometer") }
    if motion.isDeviceMotionAvailable { types.append("device_motion") }
    if CMPedometer.isStepCountingAvailable() { types.append("step_counter") }
    if CMPedometer.isDistanceAvailable() { types.append("walking_distance") }
    if CMPedometer.isFloorCountingAvailable() { types.append("floor_counting") }
    if CMPedometer.isPaceAvailable() { types.append("walking_pace") }
    if CMPedometer.isCadenceAvailable() { types.append("walking_cadence") }
    if CMPedometer.isPedometerEventTrackingAvailable() {
      types.append("pedometer_event_tracking")
    }
    if CMMotionActivityManager.isActivityAvailable() {
      types.append("activity_recognition")
    }
    if CMAltimeter.isRelativeAltitudeAvailable() {
      types.append("barometer")
      types.append("relative_altitude")
    }
    return ["sensorCount": types.count, "types": types]
  }

  private func readBattery() -> [String: Any] {
    let previous = UIDevice.current.isBatteryMonitoringEnabled
    UIDevice.current.isBatteryMonitoringEnabled = true
    defer { UIDevice.current.isBatteryMonitoringEnabled = previous }
    let level = UIDevice.current.batteryLevel
    let state = UIDevice.current.batteryState
    guard state != .unknown else { return [:] }
    let externalPower = state == .charging || state == .full
    return [
      "levelPercent": level >= 0 ? Int((level * 100).rounded()) : -1,
      "isCharging": state == .charging,
      "isExternalPowerConnected": externalPower,
      "powerSource": externalPower ? "external" : "battery",
      "health": "unknown",
      "capacityEstimateReliable": false
    ]
  }

  private func readDisplay() -> [String: Any] {
    let screen = UIScreen.main
    let bounds = screen.nativeBounds
    var facts: [String: Any] = [
      "widthPixels": Int(bounds.width.rounded()),
      "heightPixels": Int(bounds.height.rounded()),
      "densityScale": Double(screen.nativeScale),
      "maxRefreshRateHz": Double(screen.maximumFramesPerSecond),
      "supportsWideColor": screen.traitCollection.displayGamut == .P3
    ]
    if #available(iOS 16.0, *) {
      facts["supportsHdr"] = screen.potentialEDRHeadroom > 1
    }
    return facts
  }

  private func readMedia() -> [String: Any] {
    let codecs: [(String, CMVideoCodecType)] = [
      ("h264", kCMVideoCodecType_H264),
      ("hevc", kCMVideoCodecType_HEVC),
      ("vp9", fourCC("vp09")),
      ("av1", fourCC("av01"))
    ]
    return [
      "hardwareDecodeTypes": codecs.compactMap {
        VTIsHardwareDecodeSupported($0.1) ? $0.0 : nil
      },
      "hardwareEncodeTypes": hardwareEncoderTypes()
    ]
  }

  private func hardwareEncoderTypes() -> [String] {
    var rawEncoders: CFArray?
    guard VTCopyVideoEncoderList(nil, &rawEncoders) == noErr,
          let encoders = rawEncoders as? [[CFString: Any]] else {
      return []
    }
    return Array(Set(encoders.compactMap { encoder in
      guard encoder[kVTVideoEncoderList_IsHardwareAccelerated] as? Bool == true,
            let number = encoder[kVTVideoEncoderList_CodecType] as? NSNumber else {
        return nil
      }
      return codecName(CMVideoCodecType(number.uint32Value))
    })).sorted()
  }

  private func codecName(_ value: CMVideoCodecType) -> String? {
    switch value {
    case kCMVideoCodecType_H264: return "h264"
    case kCMVideoCodecType_HEVC: return "hevc"
    case fourCC("vp09"): return "vp9"
    case fourCC("av01"): return "av1"
    default: return nil
    }
  }

  private func fourCC(_ value: String) -> CMVideoCodecType {
    return value.utf8.reduce(0) { ($0 << 8) | CMVideoCodecType($1) }
  }

  private func readGraphics() -> [String: Any] {
    guard let device = MTLCreateSystemDefaultDevice() else {
      return [
        "apiName": "unknown",
        "apiVersion": "unknown",
        "featureLevel": "unknown",
        "supportsCompute": false,
        "supportsRayTracing": false
      ]
    }
    var families: [(String, MTLGPUFamily)] = [
      ("apple7", .apple7), ("apple6", .apple6), ("apple5", .apple5),
      ("apple4", .apple4), ("apple3", .apple3), ("apple2", .apple2),
      ("apple1", .apple1)
    ]
    if #available(iOS 16.0, *) { families.insert(("apple8", .apple8), at: 0) }
    if #available(iOS 17.0, *) { families.insert(("apple9", .apple9), at: 0) }

    return [
      "apiName": "metal",
      "apiVersion": "current",
      "featureLevel": families.first { device.supportsFamily($0.1) }?.0 ?? "unknown",
      "supportsCompute": true,
      "supportsRayTracing": device.supportsRaytracing
    ]
  }

  private func readConnectivity() -> [String: Any] {
    pathLock.lock()
    let path = latestPath
    pathLock.unlock()
    guard let path else { return [:] }
    var transports: [String] = []
    if path.usesInterfaceType(.wifi) == true { transports.append("wifi") }
    if path.usesInterfaceType(.cellular) == true { transports.append("cellular") }
    if path.usesInterfaceType(.wiredEthernet) == true { transports.append("ethernet") }
    return [
      "transports": transports,
      "isConnected": path.status == .satisfied,
      "isMetered": path.isExpensive,
      "isConstrained": path.isConstrained
    ]
  }

}
