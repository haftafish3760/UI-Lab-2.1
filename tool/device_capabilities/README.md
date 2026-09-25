# Device capability verification and consumer handoff

The production API is the existing `DeviceWorkloadService.instance`, exported
from `lib/src/data/device_capabilities/device_workload_service.dart`. Do not
create another detector, workload gate, model-name tier table, or storage service.
The full reference audit is
`docs/audits/device_capabilities_full_parity_2026_09_19.md`.

## Reading and using the profile

`await DeviceWorkloadService.instance.refresh()` returns the current typed
profile. It includes `facts` (availability/permission/service readiness),
`extended` (camera, sensors, battery, display, codecs, graphics, connectivity,
Bluetooth), `descriptor` (non-unique product/OS metadata), baseline/effective
tiers and conservative processing budgets. Unknown is not absence or permission.
Camera metadata advertises possible formats, not a promise that every maximum
works simultaneously. `extended.camera` derives a summary from that same
inventory; `largestStillLens` preserves paired width and height.

For expensive work, call `run` on the existing singleton with a bounded
`DeviceWorkloadRequest`. Refresh/checkpoint between units, respect
`stopRequested`, and reject late results. A native call must be individually
bounded: cooperative cancellation cannot forcibly interrupt an opaque plugin.
Never release a resource slot just because the caller stopped waiting.
Use `operationalPolicy` for media/network advice; it is not permission to start
tracking, upload, capture or write. `DeviceTripGuidance.assess` additionally
requires fresh observations, explicit opt-ins and separate background permission.

`toSafeDiagnostics()` retains the small coarse contract. The separate
`toLocalDiagnosticContext()` adds the owner's requested model/OS/CPU/RAM context,
without unique IDs, storage, owner names, business data or sensor samples. Neither
method uploads or persists anything. Future diagnostic transport, retention and
operator access belong to the admin-health contract.

OCR consumer integration is owned by the other task. This handoff does not
authorize this task to edit OCR. Durable Storage owns storage observations and
remaining-space policy; existing resource-gate storage fields are compatibility
until that owner's adapter is connected.

## Repeatable synthetic low-capability checks

Run from the UI Lab root:

```powershell
flutter test test/device_capability_simulation_test.dart
dart tool/device_capabilities/verify_profile_contract.dart
```

The simulation suite supplies all six hardware tiers to the actual workload
service, then injects critical heat, memory pressure, depleted battery and high
battery temperature, checking refusal and recovery. There is no release-mode
simulation switch that can bypass real safety signals. The independent verifier
checks a larger pure-profile matrix and malformed values.

Run all focused Flutter regressions:

```powershell
flutter test test/device_workload_service_test.dart test/device_resource_safety_test.dart test/device_trip_guidance_test.dart test/device_resource_monitor_test.dart test/device_capability_lifecycle_test.dart test/device_extended_capabilities_test.dart test/device_capability_simulation_test.dart test/device_hardware_assessment_test.dart
```

Android host tests use `DeviceExtendedProbeTest` on API 28 and 33. They exercise
real probe methods with simulated Android services, including changing battery
observations while static metadata stays cached. Tests also cover incomplete camera/battery metadata,
permission-triggered cache invalidation and expiry. `DevicePerformanceEvidenceTest`
checks asynchronous result arrival, request coalescing, failure and OS fallback.
The direct Play Services client replaces the reference AndroidX wrapper's
blocking reads and preference-file cache; this adapter retains evidence in memory.
These are host tests, not
emulator or physical-device results. Use a separate Gradle build output via the
existing `qaBuildRoot` property when the normal output is in use, a bounded heap,
and a single-use daemon; preserve other tasks' build services.

## Physical-device acceptance still required

Synthetic tests verify decisions, not thermodynamics. An emulator's RAM/CPU
configuration does not reproduce real radio power, camera ISP costs, battery
condition, GPU throttling or vendor thermal reporting. On representative low-end,
midrange and high-end devices, measure sustained workloads, foreground/background
transitions, permission revocation, battery saver and real thermal responses.
Record metadata read latency and runtime stop latency; check no capture, sensor
sampling or permission prompt occurs during a capability read. No current test
proves that an app can prevent every OS crash or physical battery fault.
