#ifndef RUNNER_DEVICE_RESOURCE_PROBE_H_
#define RUNNER_DEVICE_RESOURCE_PROBE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <memory>

// Resource facts only. No hardware identifiers, sensor samples, or persistence.
class DeviceResourceProbe {
 public:
  explicit DeviceResourceProbe(flutter::BinaryMessenger* messenger);
  ~DeviceResourceProbe();
  void PowerChanged();

 private:
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> methods_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> events_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
};

#endif
