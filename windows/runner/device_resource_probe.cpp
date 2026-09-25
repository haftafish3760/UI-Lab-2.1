#include "device_resource_probe.h"

#include <windows.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>
#include <cstdint>
#include <limits>
#include <string>

namespace {
using Value = flutter::EncodableValue;
using Map = flutter::EncodableMap;

// Only fixed non-unique product fields. Never enumerate the registry or read
// owner/computer names, ProductId, MachineGuid, serials or firmware UUIDs.
std::string ProductLabel(const wchar_t* key, const wchar_t* field) {
  wchar_t buffer[97]{};
  DWORD bytes = sizeof(buffer);
  if (RegGetValueW(HKEY_LOCAL_MACHINE, key, field,
                  RRF_RT_REG_SZ | RRF_ZEROONFAILURE, nullptr, buffer, &bytes)
      != ERROR_SUCCESS) return {};
  const size_t length = wcsnlen_s(buffer, 97);
  if (length == 0 || length > 96) return {};
  const int count = static_cast<int>(length);
  const int size = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
      buffer, count, nullptr, 0, nullptr, nullptr);
  if (size <= 0) return {};
  std::string text(static_cast<size_t>(size), '\0');
  if (WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, buffer, count,
      text.data(), size, nullptr, nullptr) != size) return {};
  return text;
}

Map ProductDescriptor() {
  Map result{{Value("platform"), Value("windows")}};
  const wchar_t* bios = L"HARDWARE\\DESCRIPTION\\System\\BIOS";
  const auto manufacturer = ProductLabel(bios, L"SystemManufacturer");
  const auto model = ProductLabel(bios, L"SystemProductName");
  const auto build = ProductLabel(
      L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion", L"CurrentBuildNumber");
  if (!manufacturer.empty()) result[Value("manufacturer")] = Value(manufacturer);
  if (!model.empty()) result[Value("model")] = Value(model);
  if (!build.empty()) result[Value("osVersion")] = Value("build " + build);
  return result;
}

// The path is used locally to select the app's volume; never returned or logged.
std::wstring StoragePath(const Value* arguments) {
  if (!arguments) return {};
  const auto* map = std::get_if<Map>(arguments);
  if (!map) return {};
  const auto entry = map->find(Value("storagePath"));
  if (entry == map->end()) return {};
  const auto* path = std::get_if<std::string>(&entry->second);
  if (!path || path->empty() || path->size() > 32767 ||
      path->find('\0') != std::string::npos) return {};
  const auto length = static_cast<int>(path->size());
  const int size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                                     path->data(), length, nullptr, 0);
  if (size <= 0) return {};
  std::wstring wide(static_cast<size_t>(size), L'\0');
  if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path->data(),
                          length, wide.data(), size) != size) return {};
  return wide;
}

Map Read(const Value* arguments) {
  Map facts;
  static const Map descriptor = ProductDescriptor();
  facts[Value("descriptor")] = Value(descriptor);
  MEMORYSTATUSEX memory{};
  memory.dwLength = sizeof(memory);
  const bool has_memory = GlobalMemoryStatusEx(&memory) != 0;
  facts[Value("probeAvailable")] = Value(has_memory);
  if (has_memory) {
    facts[Value("physicalRamMb")] = Value(static_cast<int64_t>(memory.ullTotalPhys / 1048576));
    facts[Value("availableRamMb")] = Value(static_cast<int64_t>(memory.ullAvailPhys / 1048576));
  }
  HANDLE pressure = CreateMemoryResourceNotification(LowMemoryResourceNotification);
  if (pressure) {
    BOOL low = FALSE;
    if (QueryMemoryResourceNotification(pressure, &low))
      facts[Value("lowMemory")] = Value(low != FALSE);
    CloseHandle(pressure);
  }
  SYSTEM_INFO system{};
  GetNativeSystemInfo(&system);
  facts[Value("cpuCores")] = Value(static_cast<int64_t>(system.dwNumberOfProcessors));
  switch (system.wProcessorArchitecture) {
    case PROCESSOR_ARCHITECTURE_AMD64:
      facts[Value("cpuArchitecture")] = Value("x86_64"); break;
    case PROCESSOR_ARCHITECTURE_ARM64:
      facts[Value("cpuArchitecture")] = Value("arm64"); break;
    case PROCESSOR_ARCHITECTURE_INTEL:
      facts[Value("cpuArchitecture")] = Value("x86"); break;
  }
  SYSTEM_POWER_STATUS power{};
  if (GetSystemPowerStatus(&power)) {
    if (power.ACLineStatus <= 1)
      facts[Value("externalPower")] = Value(power.ACLineStatus == 1);
    if (power.BatteryFlag != 255 && (power.BatteryFlag & 128) == 0 &&
        power.BatteryLifePercent <= 100)
      facts[Value("batteryPercent")] = Value(static_cast<int64_t>(power.BatteryLifePercent));
    if (power.SystemStatusFlag <= 1)
      facts[Value("powerSaving")] = Value(power.SystemStatusFlag == 1);
  }
  const auto path = StoragePath(arguments);
  ULARGE_INTEGER available{};
  if (!path.empty() && GetDiskFreeSpaceExW(path.c_str(), &available, nullptr, nullptr) &&
      available.QuadPart <= static_cast<ULONGLONG>((std::numeric_limits<int64_t>::max)()))
    facts[Value("freeStorageBytes")] = Value(static_cast<int64_t>(available.QuadPart));
  // No supported measurement here: do not invent temperature, sensors, or health.
  facts[Value("thermalState")] = Value("unknown");
  return facts;
}
}  // namespace

DeviceResourceProbe::DeviceResourceProbe(flutter::BinaryMessenger* messenger) {
  const auto* codec = &flutter::StandardMethodCodec::GetInstance();
  methods_ = std::make_unique<flutter::MethodChannel<Value>>(
      messenger, "app.device_capabilities", codec);
  methods_->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name() != "readRuntimeCapabilities") {
      result->NotImplemented();
      return;
    }
    result->Success(Value(Read(call.arguments())));
  });
  events_ = std::make_unique<flutter::EventChannel<Value>>(
      messenger, "app.device_capability_events", codec);
  events_->SetStreamHandler(std::make_unique<flutter::StreamHandlerFunctions<Value>>(
      [this](const Value*, std::unique_ptr<flutter::EventSink<Value>>&& sink)
          -> std::unique_ptr<flutter::StreamHandlerError<Value>> {
        sink_ = std::move(sink);
        PowerChanged();
        return nullptr;
      },
      [this](const Value*) -> std::unique_ptr<flutter::StreamHandlerError<Value>> {
        sink_.reset();
        return nullptr;
      }));
}

DeviceResourceProbe::~DeviceResourceProbe() {
  events_->SetStreamHandler(nullptr);
  methods_->SetMethodCallHandler(nullptr);
  sink_.reset();
}

void DeviceResourceProbe::PowerChanged() {
  if (sink_) sink_->Success(Value("health"));
}
