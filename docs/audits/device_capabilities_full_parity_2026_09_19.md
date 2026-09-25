# Full 5.7 device-capability reuse audit

Scope: device capabilities and their consumers, read-only inspection of
`C:/Users/rjenk/Documents/Maintainiac 5.7 Active`. No execution or writes in
that reference. This supersedes narrower inventory/completion statements in
`device_capabilities_2026_09_19.md`; that file retains historical test evidence.
Owner requests the full system in UI Lab, without replacing already suitable
UI Lab code, touching OCR, or duplicating Durable Storage. Gig-driver product
flows are excluded. This audit is source evidence, not physical-device testing.

## Sources inspected

All ten files in `lib/shared/device_capabilities`: barrel, capability/profile
and classifier, grade, service, scope/controller, extended feature models,
parser, operational policy, storage status, Bluetooth models. Both Android
`DeviceCapabilityBridge.kt` and `DeviceCapabilityEvents.kt`, and both iOS
bridge/event files. Documentation: `docs/device_capability_system.md`.
Consumers traced through app startup/scope, dashboard trip summary reporter,
trip operational/consent policy, profile validator, sensor-consent boundary,
capability guidance and Bluetooth binding/coordinator; receipt shared adapter
and camera/assistance-policy references were inspected as integration evidence.
Legacy classifier/grade/parser/scope/native/trip test files were inventoried;
they were not executed against the protected reference.

## What the reference actually does

| Area | Actual capability contract | Reuse decision |
| --- | --- | --- |
| Hardware | Platform/version, manufacturer/model, hardware identifier, SDK, RAM, cores/architecture, application heap, low-RAM flag, physical/emulated flag, Android Media Performance Class | Adapt into existing profile. Keep diagnostic manufacturer/model/OS; exclude unique IDs, registered owner and machine IDs. |
| Runtime | Timestamp, available RAM, power saving, thermal state, free/total storage and fraction | Preserve UI Lab live resource service; storage belongs to Durable Storage. |
| Camera | Availability/count/front/rear; focus, continuous focus, exposure compensation, zoom, macro, torch, RAW, maximum still dimensions | Adapt metadata queries, no capture or permission requests; unknown must remain unknown. |
| Lenses | Position/type, physical member count, paired still dimensions, focal range/aperture, zoom, frame rate, autofocus, stabilization, RAW/depth/HDR | Port native metadata and typed models; distinguish advertised format maxima from simultaneously usable configurations. |
| Sensors | Count and normalized types: inertial, heading, pressure, steps, activity/motion transitions, altitude, light/proximity, environmental, body, gestures, hinge, vendor numeric types | Port inventory without samples or sensor names/IDs. Availability is not authorization or proof of driving. |
| Power | Level, charging/external power, source, temperature, health, chemistry, remaining mAh, explicitly unreliable full-capacity estimate | Reuse existing live safety observations, add missing metadata; never treat an estimate as design capacity or battery safety certification. |
| Display | Native dimensions/density, maximum refresh rate, HDR/wide color | Adapt for diagnostics/media budgets only; never use this to replace logical layout constraints. |
| Media | Hardware decode/encode codec sets: H.264, HEVC, VP9, AV1, Android JPEG | Port metadata; codec availability is not measured throughput. |
| Graphics | GLES/Vulkan or Metal API/version/family, compute/ray-tracing capability | Port with explicit unsupported/unknown distinctions. |
| Network | Connected, Wi-Fi/cellular/Ethernet/VPN, metered/constrained, Android estimated link bandwidth | Port no SSIDs, addresses, carriers or network identities; large-transfer policy requires positive evidence. |
| Bluetooth | Adapter, power, authorization, approved-observation readiness | Port readiness only. Legacy salted connection-address hashes and persistent salt belong to a separately consented trip adapter, not generic capabilities. |
| Lifecycle | Cached hardware/static extension, fresh runtime/battery/network, native events and resume refresh, debounced controller | Keep UI Lab single-flight, deadlines, bounded refresh and live heavy-work monitoring; cache expensive immutable enumeration. |
| Diagnostics | Coarse allowlist of platform, tiers/grades/confidence, resource buckets, sensor/lens classes, graphics/network/power | Extend local diagnostic context with owner-requested model/OS/CPU/RAM. Do not add an uploader, user records, raw error messages or device identifiers. |

### Classification, grades and budgets

Legacy score: RAM <=3 GiB -2, <=4 GiB 0, <=6 GiB +2, <=8 GiB +4,
<=12 GiB +5, otherwise +6. CPU <=4 cores -1, <=6 +1, <=8 +2,
otherwise +3. Android performance class >=31 +2, >=33 +3, >=34 +4,
>=35 +5. Heap <192 MiB -1, >=256 +1, >=512 +2. Compute plus any
hardware decoder adds one; AV1 decode plus HEVC encode adds another.
Score thresholds <=0/2/4/6/9/above9 produce constrained/entry/balanced/
enhanced/performance/flagship. Low-RAM forces constrained. Missing evidence
reduces confidence; low confidence caps effective tier at balanced.

Legacy 1–10 grades use score boundaries -3,-1,1,3,5,7,9,11,13; tier ceilings
2,3,5,6,8,10 cap effective grades. These are heuristic classifications, not
benchmarks or proof of flagship performance. UI Lab's existing conservative
six-tier baseline and stricter live gate are retained rather than silently
raising workloads to legacy maxima. A grade must not be a second admission gate.

| Tier | Heavy slots | Workers | Asset MiB | Live pixels | FPS | OCR batch | PDF DPI | GPS seconds | Video height |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| constrained | 1 | 1 | 48 | 900000 | 4 | 2 | 120 | 12 | 720 |
| entry | 1 | 1 | 64 | 1100000 | 5 | 3 | 140 | 10 | 720 |
| balanced | 1 | 2 | 96 | 1400000 | 7 | 4 | 160 | 8 | 1080 |
| enhanced | 2 | 2 | 128 | 1800000 | 9 | 6 | 180 | 7 | 1080 |
| performance | 2 | 3 | 192 | 2200000 | 12 | 8 | 220 | 6 | 2160 |
| flagship | 3 | 4 | 256 | 2600000 | 15 | 12 | 240 | 5 | 2160 |

Legacy runtime lowers tiers at <512/<1024 MiB available memory, power saving,
unplugged <=10/20% battery, serious/critical heat and storage thresholds.
Operational policy additionally constrains below 3 GB or 5% storage, caps FPS
3–5, batch 1–3, DPI 100–140, GPS 10–20 seconds. Camera processing ceilings are
8/12/16/24/36/50 MP bounded by camera evidence; video prefers hardware HEVC,
then H.264, then platform default. Network transfer requires unconstrained power
and network. Storage status has 250/500/1024 MB color thresholds, not enforcement.
UI Lab intentionally uses one heavy slot and one-image batches, explicit stop
on serious heat, unsafe battery or critical memory; no legacy increase is safe
merely because the old code had it. Consumer owners must use cooperative units.

### Platform and consumer facts

Android uses Camera2 logical and physical characteristics, SensorManager TYPE_ALL,
ActivityManager, battery broadcast/property, display modes, MediaCodecList,
GLES/Vulkan package features and NetworkCapabilities. Its Play Services performance
class can contain updated information beyond the static OS class. This is a
metadata probe, not a stress test. iOS uses AVFoundation discovery, CoreMotion
availability, ProcessInfo, UIDevice, UIScreen, VideoToolbox, Metal and NWPathMonitor.
It cannot expose exact public battery health/temperature/design capacity. The
reference has no equivalent full native Windows/macOS capability bridge; plugin
hardware fallbacks are less complete. Unsupported fields must remain unknown.

The shared service contains no Hive schema or durable capability database.
The Bluetooth event adapter separately persists a random salt and hashes device
addresses. Those are pseudonymous identities, not anonymous capability facts.
Do not port them into this subsystem.

The receipt adapter reads the shared profile, adds native receipt camera and
permission/package information, then applies receipt policy. Trip guidance
separates GPS, background and motion opt-ins; odometer remains canonical, motion
only proposes stop review, maps are not required for GPS. Dashboard summaries
have a path into existing sync/reporting: a method named safe diagnostics is
not proof that every downstream export is safe. UI Lab adds no such connection.

## Defects and limitations that must not be copied blindly

- Windows plugin mapping uses registeredOwner as manufacturer and deviceId as
  hardware identifier; Linux machineId likewise. Exclude these fields.
- Unknown booleans often become false, unknown connectivity can appear unmetered;
  numeric parser accepts strings/truncation and mishandles NaN/infinity.
- Service silently swallows native exceptions, lacks a native deadline; controller
  can publish after disposal, and trailing-only debounce can starve refresh.
- Camera summary independently maximizes width/height; those can be different
  formats. Android lens type is inferred from focal length without sensor size;
  zoom-ratio upper bound is not verified optical zoom. Identical metadata can
  collapse distinct lenses. iOS stabilization/RAW false are placeholders, macro
  from ultrawide presence is inference, and old still-size fallback is video size.
- Android missing temperature is converted to zero. Pre-29 hardware codec names
  are heuristic, not certification. Graphics ray tracing false is unmeasured.
- iOS battery monitoring is enabled without restoring prior ownership. Missing
  NWPath can look disconnected rather than not yet observed.
- Generic native sensor inventory does not establish runtime permission. Body
  sensor presence never authorizes body measurements. Bluetooth denial is labeled
  notRequested on Android, and iOS power false avoids querying a live manager.
- Legacy critical heat reduces budgets but does not enforce cancellation;
  grades/tier claims cannot guarantee no crashes or physical battery damage.
- FullSafetyAssist trip readiness does not encode background readiness; a
  negative classifier score conflicts with a nonnegative consumer validator.

## UI Lab adaptation and acceptance

Extend the existing DeviceWorkloadProfile/Service, DeviceCapabilityFacts,
DeviceResourceMonitor and DeviceTripGuidance. Add typed extended metadata and
native helpers only for missing responsibilities, never another singleton/gate.
No OCR edits. Durable Storage retains storage authority. Local diagnostic
context is a seam for future admin-health work governed by the existing storage
contract's operational-health section, not permission to upload.

Required validation: immutable/bounded payload parsing, missing versus false,
all tiers, pressure monotonicity, concurrency/timeouts/disposal, permission and
opt-in boundaries, local diagnostic allowlist, native build and fault scenarios.
Injected synthetic low-end and pressure profiles test decisions, not physical
thermal behavior. Emulators do not reproduce real battery aging, radio power,
thermal throttling or sustained CPU/GPU throughput. Android/iOS physical-device
calibration and iOS/macOS builds remain explicit release gates on suitable hosts.

Status at audit checkpoint: audit complete for this subsystem and its integration
boundaries. The implementation and validation evidence below distinguish native
coverage from shared policy and identify platform acceptance still outstanding.

## Extended implementation checkpoint

The existing profile now owns parsed extended capabilities and a separately
allowlisted local diagnostic descriptor. The existing service remains the only
admission gate. Models cover lens metadata, normalized sensors, power metadata,
display, hardware codecs, graphics, connectivity and Bluetooth readiness.
Unknown booleans remain nullable; native numeric inputs must be finite, integral
where required, and bounded. Lens collections, parsed sets and sensor type names
are bounded/allowlisted. Dimensions stay paired per lens. Local diagnostics can
include model/OS/CPU/RAM but omit storage, owner, unique IDs and raw sensor data.

Android extended native queries are connected to `readRuntimeCapabilities` on a
serial Flutter background task queue. Expensive camera/media/graphics metadata is
cached for ten minutes and invalidated when camera authorization changes; sensor,
display, battery, network and Bluetooth readiness refresh each read. Each group
fails independently. Network changes feed the existing lifecycle monitor and
late callbacks are rejected after cancellation. This adds only the normal
ACCESS_NETWORK_STATE permission; no new runtime permission request or tracking.

The iOS extended probe is authored and registered in Xcode. It restores battery
monitoring ownership, preserves unknown Bluetooth power and unknown initial
network path, uses paired photo dimensions, and reports stabilization from format
support rather than a false placeholder. It is NOT compiled on this Windows host.
Its enumeration is currently on the main-thread channel with cached static facts;
first-read latency remains a platform acceptance concern to measure and address.

Shared operational advice covers fresh large-transfer eligibility, hardware video
codec preference, video-height ceiling and camera processing pixels bounded by the
existing memory-conscious image budget. It cannot grant permissions, start tracking
or authorize writes. Synthetic tier scenarios inject observations into the actual
service; no simulation override is shipped in the production app.

Verification so far after these changes:

- 53 Flutter tests passed across the eight device suites, including all six
  simulated tiers under critical thermal/memory/battery pressure and recovery.
- Focused analysis of device code and new tests: no issues.
- Independent pure-profile verification: 3,492 checks passed.
- Android Kotlin compilation and twelve native host-test cases passed: ten
  extended-probe cases across API 28/33 and two performance-evidence cases.
  Native tests exposed an AGP/Flutter asset producer dependency, repaired
  by an explicit packaging dependency, and a missing-HDR metadata failure,
  repaired so other display facts survive. Battery updates bypass the static
  camera cache. Missing battery extras, camera booleans and zoom remain unknown;
  camera cache refreshes after permission changes and ten-minute expiry.
  Test XML reports twelve tests, zero failures and zero errors.
- Full-project analysis found 25 findings outside device-capability code;
  concurrent OCR/inventory work was left untouched. Focused analysis is clean.
- Android debug APK assembled successfully in the isolated QA build directory;
  Windows release build passed with the fixed-field product descriptor.
  Initial APK attempt encountered a missing Flutter cache directory; recreating
  that directory without deleting anything allowed the retry to complete.
  No app was installed or user data replaced for these builds.
- Single-use Android build workers exited; the post-build Java process inventory
  was empty. No unrelated process was stopped.
- Apple builds and physical-device tests remain unverified on this Windows host.

The profile now has the reference hardware score/confidence and tier-capped 1–10
grades. Missing evidence remains ungraded. GPU/codec evidence provides the
cross-platform path to performance/flagship tiers, retaining minimum memory/CPU
constraints and all runtime protections. No brand/model lookup contributes.
Derived camera summary preserves unknowns and paired dimensions. Typed readiness
now also covers additional inertial/environmental and pedometer signals, GPS
receiver availability and independent background-location permission.

Android performance-class evidence now uses the direct Play Services client
asynchronously, with one in-flight lookup and in-memory result ownership. OS
performance class remains the fallback; invalid/failed provider results cannot
raise it. The reference AndroidX 1.0.0 wrapper's official source uses blocking
reads and a Jetpack preference DataStore cache, so that wrapper was not copied.
Its device-name fallback table was not imported either: model names must not
increase workloads. No Hive, preference file or capability database was added.
Future durable controls remain under the existing SQLite/Drift authority.

Fresh native background-location denial/restriction or disabled services now
veto a consumer's cached grant. Seven trip-guidance tests cover freshness,
foreground/background/motion separation, opt-in and revocation. Guidance still
never samples location or establishes that movement is a business trip.

## Platform coverage and remaining acceptance

"Authored" means registered source exists; it is not a successful platform build.
Missing public observations remain unknown and cannot authorize higher budgets.

| Responsibility | Android | iOS | Windows | macOS |
| --- | --- | --- | --- | --- |
| CPU, RAM, architecture, non-unique model/OS | Implemented, APK built | Authored | Implemented, release built | Authored |
| Live allocation/memory pressure | System RAM and low-memory events | App headroom and memory warnings, authored | Available system RAM | Immediately-free pages and pressure events, authored |
| Thermal/power/battery | Public OS thermal, saver, battery metadata | Public thermal, saver, level/power; no public exact temperature/health | Public power/level; thermal unknown | Public thermal, saver, battery/power, authored |
| Camera/lens metadata | Camera2 metadata; native unknown/cache tests | AVFoundation metadata, authored | Unknown | Unknown |
| Sensors and permission-separated trip facts | Native inventory and available permission facts | CoreMotion/CoreLocation facts, authored | Unknown | Unknown |
| Display, media, graphics | Native metadata; pre-29 codec acceleration unknown | UIKit/VideoToolbox/Metal, authored | Unknown | Unknown |
| Connectivity and Bluetooth readiness | Metadata only; no connection identities | Network path and authorization; Bluetooth power unknown | Unknown | Unknown |
| Static evidence caching and lifecycle refresh | Background queue, cache, resource/network events | Cached enumeration, resource/network events, authored | Shared lifecycle and native power refresh | Shared lifecycle and native thermal/memory events, authored |
| Six tiers, grades, workload gate, operational advice | Shared tested Dart policy | Same shared policy | Same shared policy | Same shared policy |

Windows/macOS extended metadata is not a regression from 5.7: the reference has
no corresponding full desktop native bridge. UI Lab adds resource adapters and
removes the reference's owner/identifier leakage. This does not mean that desktop
camera/sensor enumeration is implemented. The macOS immediately-free memory
reading is conservative, not an allocation entitlement; no new storage detector
was added. Missing Durable Storage observations refuse disk-growing work.

Remaining release acceptance: compile/run iOS and macOS on an Apple host, measure
iOS first-enumeration latency, and calibrate sustained workloads on representative
physical devices. Verify vendor camera metadata, permission revocation, runtime
thermal/memory recovery and battery behavior on those devices. Neither synthetic
profiles, Robolectric nor successful APK/Windows builds establish thermodynamic
safety or guarantee prevention of every OS/device crash. Unknown observations
and cooperative cancellation limitations are intentional, documented API limits.

The future standalone diagnostic app and OCR consumer wiring
are separate owner scopes, not secretly implemented by this slice.

API references used for the adaptation:

- Flutter background platform channel task queues:
  https://docs.flutter.dev/platform-integration/platform-channels
- Android hardware codec metadata is vendor-reported, not verified throughput:
  https://developer.android.com/reference/android/media/MediaCodecInfo
- Camera formats expose stabilization and paired still-image dimensions:
  https://developer.apple.com/documentation/avfoundation/avcapturedevice/format
- Android performance-class public API and official wrapper source:
  https://developer.android.com/topic/performance/performance-class
  https://dl.google.com/dl/android/maven2/androidx/core/core-performance-play-services/1.0.0/core-performance-play-services-1.0.0-sources.jar
