import Cocoa
import Darwin
import FlutterMacOS
import IOKit.ps

/// The macOS adapter for the shared capability channel, not another service.
/// No durable data, owner names, hardware IDs, sensor sampling or permissions.
final class MacDeviceResourceProbe: NSObject, FlutterStreamHandler {
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  private var sink: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []
  private var pressure: DispatchSourceMemoryPressure?
  private var lowMemory: Bool?
  private var generation = 0

  func register(_ messenger: FlutterBinaryMessenger) {
    let methods = FlutterMethodChannel(name: "app.device_capabilities", binaryMessenger: messenger)
    methods.setMethodCallHandler { [weak self] call, result in
      guard call.method == "readRuntimeCapabilities" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self else {
        result(FlutterError(code: "probeUnavailable", message: "Capability adapter unavailable", details: nil))
        return
      }
      result(self.read())
    }
    methodChannel = methods
    let events = FlutterEventChannel(name: "app.device_capability_events", binaryMessenger: messenger)
    events.setStreamHandler(self)
    eventChannel = events
  }

  private func read() -> [String: Any] {
    let process = ProcessInfo.processInfo
    var facts: [String: Any] = [
      "probeAvailable": true,
      "physicalRamMb": Int(process.physicalMemory / 1_048_576),
      "cpuCores": process.activeProcessorCount,
      "thermalState": thermalName(process.thermalState),
      "descriptor": descriptor()
    ]
    #if arch(arm64)
    facts["cpuArchitecture"] = "arm64"
    #elseif arch(x86_64)
    facts["cpuArchitecture"] = "x86_64"
    #endif
    if #available(macOS 12.0, *) { facts["powerSaving"] = process.isLowPowerModeEnabled }
    if let lowMemory { facts["lowMemory"] = lowMemory }
    if let free = freeMemoryMiB() { facts["availableRamMb"] = free }
    let battery = readBattery()
    facts["batteryPercent"] = battery["levelPercent"]
    facts["externalPower"] = battery["isExternalPowerConnected"]
    facts["extended"] = ["battery": battery]
    // Disk capacity comes from the Durable Storage owner; no competing probe.
    // Unsupported camera/sensor/graphics fields remain absent, not false.
    return facts
  }

  private func descriptor() -> [String: Any] {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    var result: [String: Any] = ["platform": "macos", "manufacturer": "Apple",
      "osVersion": "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"]
    var bytes = [CChar](repeating: 0, count: 97)
    var count = bytes.count
    if sysctlbyname("hw.model", &bytes, &count, nil, 0) == 0,
       count > 0, count <= bytes.count, bytes[count - 1] == 0 {
      result["model"] = String(cString: bytes)
    }
    return result
  }

  private func freeMemoryMiB() -> Int? {
    var statistics = vm_statistics64_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
    let capacity = Int(count)
    let host = mach_host_self()
    defer { mach_port_deallocate(mach_task_self_, host) }
    let status = withUnsafeMutablePointer(to: &statistics) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: capacity) {
        host_statistics64(host, HOST_VM_INFO64, $0, &count)
      }
    }
    guard status == KERN_SUCCESS else { return nil }
    // Conservative immediately-free pages, not total reclaimable memory or an
    // application allocation entitlement. Do not add speculative pages twice.
    return Int(UInt64(statistics.free_count) * UInt64(vm_kernel_page_size) / 1_048_576)
  }

  private func readBattery() -> [String: Any] {
    guard let raw = IOPSCopyPowerSourcesInfo() else { return [:] }
    let snapshot = raw.takeRetainedValue()
    var result: [String: Any] = [:]
    if let rawType = IOPSGetProvidingPowerSourceType(snapshot) {
      let type = rawType.takeUnretainedValue() as String
      if type == kIOPSACPowerValue { result["isExternalPowerConnected"] = true }
      if type == kIOPSBatteryPowerValue { result["isExternalPowerConnected"] = false }
    }
    guard let rawList = IOPSCopyPowerSourcesList(snapshot) else { return result }
    let sources = rawList.takeRetainedValue() as [CFTypeRef]
    for source in sources {
      guard let rawDescription = IOPSGetPowerSourceDescription(snapshot, source),
            let value = rawDescription.takeUnretainedValue() as? [String: Any],
            value[kIOPSTypeKey] as? String == kIOPSInternalBatteryType else { continue }
      if let capacity = value[kIOPSCurrentCapacityKey] as? Int,
         let maximum = value[kIOPSMaxCapacityKey] as? Int,
         maximum > 0, capacity >= 0, capacity <= maximum {
        result["levelPercent"] = Int((Double(capacity) * 100 / Double(maximum)).rounded())
      }
      if let charging = value[kIOPSIsChargingKey] as? Bool { result["isCharging"] = charging }
      break
    }
    return result
  }

  private func thermalName(_ state: ProcessInfo.ThermalState) -> String {
    switch state {
    case .nominal: return "nominal"
    case .fair: return "fair"
    case .serious: return "serious"
    case .critical: return "critical"
    @unknown default: return "unknown"
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    _ = onCancel(withArguments: nil)
    sink = events
    var names = [ProcessInfo.thermalStateDidChangeNotification]
    if #available(macOS 12.0, *) { names.append(Notification.Name.NSProcessInfoPowerStateDidChange) }
    observers = names.map { name in
      NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        self?.sink?("health")
      }
    }
    let source = DispatchSource.makeMemoryPressureSource(eventMask: [.normal, .warning, .critical], queue: .main)
    let currentGeneration = generation
    source.setEventHandler { [weak self] in
      guard let self, currentGeneration == self.generation, let current = self.pressure else { return }
      self.lowMemory = current.data.contains(.warning) || current.data.contains(.critical)
      self.sink?(self.lowMemory == true ? "memory" : "health")
    }
    pressure = source
    source.resume()
    events("ready")
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    generation += 1
    observers.forEach(NotificationCenter.default.removeObserver)
    observers.removeAll()
    pressure?.cancel()
    pressure = nil
    lowMemory = nil
    return nil
  }
}
