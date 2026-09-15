import '../device_capabilities/device_workload_service.dart';

/// Stops scheduling work; native operations already in flight still own their
/// resources and the app-wide workload gate until their cleanup completes.
void requireReceiptReadActive(bool Function() expired) {
  if (expired()) {
    throw const DeviceWorkloadUnavailable(
      'Reading stopped. Try again or enter the details yourself.',
    );
  }
}
