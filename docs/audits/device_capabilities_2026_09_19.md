# Device capabilities audit — September 19, 2026

Status: source audit in progress; target implementation not yet complete.
Protected source: `C:/Users/rjenk/Documents/Maintainiac 5.7 Active`, HEAD
`c7b89705e15dc67dea989075abc2b2d296b8947f`. No builds/tests execute there.
UI Lab began on `codex/desktop-inventory-handoff-20260917` with unrelated dirty
Inventory, parser, layout, dependencies, generated Windows and documentation work.
Those changes are preserved. No delegation or screenshots.

## Current ownership boundary — supersedes earlier delivery plans

September 19 takeover checkpoint: the owner confirmed the previous device task
was stopped and assigned continued implementation here. OCR remains separately
owned and untouched. An explicit active goal now names Maintainiac 5.7 Active as
the read-only reference. Reinspected its capability service, controller/scope,
operational policy and storage assessment: retain capability/budget concepts;
adapt the lifecycle; exclude owner/device identifiers and replace advisory-only
storage handling with the existing UI Lab admission gate.

Trip guidance now rejects missing/expired/future-dated observations and requires
location services explicitly enabled. The shared freshness rule is ten seconds
with two seconds future tolerance. Monitor lifecycle callbacks are ignored after
detachment. Added tests cover freshness boundaries, unknown location-service
state, continuous health events and post-disposal callbacks. All 32 focused
device tests passed; the six trip tests passed again after strengthening the
older pressure/permission fixtures. The standalone invariant tool passed 3,492
assertions. Formatting and focused analysis (including the tool) are clean.

Full-app analysis found 27 findings during this changing-worktree snapshot:
three were device-tool import style findings, since fixed; the remaining 24 were
in OCR/inventory/other tools and were left to their owners. No full-app clean
analysis is claimed. Windows debug compilation reached linking but the running
debug executable was locked (LNK1168); it was not closed. Windows release and
Android debug builds are pending at this checkpoint. These checks do not prove
physical thermal calibration, iOS compilation, macOS support, or that every app
consumer uses the admission gate.

Renewed owner direction after the handoff: this task is authorized to continue
implementation and independent testing of the device capabilities system itself.
The interim engine handoff restriction below is superseded. OCR files and
consumer integrations remain outside this task; 5.7 remains read-only.

Latest resumed checkpoint: 29 focused tests pass and focused analysis reports no
issues. `dart format` now exits successfully. A timed-out native probe retains
its in-flight ownership until its actual future settles; repeated admissions
cannot stack more platform probes, late results cannot revive a timed-out
observation, and late errors are consumed. Added tests reproduce these cases.
Channel booleans for low-RAM, low-memory and power-saving now preserve unknown
instead of silently becoming false; unknown values cap the effective tier at
balanced. Valid explicit false values remain distinguishable. The Android debug
build was launched and remains pending; no native build success is claimed.

Windows implementation checkpoint: added `windows/runner/device_resource_probe`
and registered it with the runner's lifetime. The neutral method channel reads
RAM, current available memory, memory-pressure notification state, CPU
architecture/parallelism, external power, battery percentage when present,
battery saver, and caller-available bytes for the application support directory.
The directory is supplied locally using the same path-provider root as default
SQLite persistence; it is not returned, logged, or stored by this subsystem.
Custom database/export locations on other volumes are not covered by this root
measurement. Missing/inaccessible paths leave disk space unknown and therefore
cannot admit disk-growing work. No cleanup or directory deletion is performed.
Power broadcasts refresh shared status; active polling covers ongoing work.
Thermal state and sensor support remain unknown rather than guessed. The bridge
is authored but its Windows build remains pending. Dart's 29 focused tests pass
after the platform adapter addition; those tests do not execute the C++ bridge.

Windows API evidence:
- [GlobalMemoryStatusEx](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-globalmemorystatusex)
  supplies volatile memory observations, not a reservation.
- [GetDiskFreeSpaceExW](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getdiskfreespaceexw)
  distinguishes caller-available space from total free space and requires a
  directory on the target volume. The implementation uses caller-available bytes.
- [SYSTEM_POWER_STATUS](https://learn.microsoft.com/en-us/windows/win32/api/winbase/ns-winbase-system_power_status)
  distinguishes unknown battery/AC values and absence of a system battery.

Resumed validation checkpoint: all 26 tests across device_workload_service,
device_resource_safety, device_trip_guidance, device_resource_monitor and the new
device_capability_lifecycle suites passed. Focused `flutter analyze --no-pub`
on the capability directory and those five suites reported no issues. The new
tests exercise refresh coalescing, pending-probe disposal, combined stop reasons,
and a memory warning during admission whose cooldown expires before the probe
returns. Stop reasons now survive that race and subsequent memory warnings.
Widget test teardown runs stream cancellation/closure outside fake time to avoid
hanging. No OCR or native implementation was changed in this resumed slice.

`dart format` wrote the requested capability/test formatting successfully but
exited nonzero afterward because its telemetry timestamp file outside the
workspace was denied. This is not a clean formatter process result. Native
builds and physical-device safety validation remain outstanding.

The owner assigned the capabilities-engine import and OCR work to another Codex
task. This audit task must leave all existing implementation and OCR changes
alone: no deletion, removal, reversal, import, or feature connection. Earlier
integration plans and OCR change descriptions below are historical records, not
authorization to continue that work. The audit remains incomplete; neither the
import nor application-wide safeguards are certified by this document.

## Additional read-only trip consumer findings

## Completion evidence required from the importing implementation

This handoff does not certify completion. The historical 19 passing Dart tests
below predate later changes and cannot certify the current shared worktree.
Ownership remains with the other task; this audit has not modified its engine,
started builds against its changing files, or performed corrective cleanup.

| Owner requirement | Current evidence and unresolved acceptance |
| --- | --- |
| Complete reference audit | Core source, native bridges/events, tier budgets, lifecycle, trip consumers and summary upload path inspected. Runtime reproduction and complete consumer coverage remain unproven; OCR is excluded from further work by owner direction. |
| Six useful tiers | Six source tiers and target contract exist. Physical calibration, lowest-supported-device evidence and cross-platform parity are unverified. |
| Shared status | Source controller publishes a profile/error/loading state. Identified freshness, debounce and disposal gaps need independent behavioral verification in the imported implementation. |
| No fingerprinting | Source collects unnecessary identifiers and allows some derived resource statuses into cloud summaries. Target must prove absence at collection, persistence, logging, export and sync boundaries. |
| RAM and CPU evidence | Source reads RAM and core count with platform differences. Core count is not processor throughput; missing data and app-memory headroom need distinct status and conservative admission. |
| Pedometer, gyroscope and trip support | Source inventories sensors. Per-feature support, permission, enabled state and opt-in must remain separate. Availability does not prove walking/driving recognition. |
| Heat and battery protection | Source policy remains advisory with positive budgets under critical heat. Live refusal/stop behavior, monitoring lifecycle, and recovery need runtime evidence; charging must not override unsafe heat. |
| At least 100 MB reserve | Source allows low-space trip text writes. Target needs byte-based peak-budget admission plus reserve, concurrent-request accounting, write-failure handling, and no automatic reclamation. |
| No deletion or overwrite to make room | No global compliance demonstrated. Owner explicitly prohibits touching existing OCR code. Any remaining changes belong to that implementation owner and require user-controlled, confirmed deletion behavior. |
| SQLite architecture | Capability snapshots in source are ephemeral, not Hive records. Any durable settings require SQLite ownership; no new snapshot database is justified merely by the migration request. |
| Brand neutrality | Source method/event channels and platform labels contain the old name. Target needs consistent neutral identifiers without business-name coupling. |
| Independent validation | Source native tests check text, not execution. Current target requires refreshed unit/lifecycle evidence, relevant platform builds and physical-device/resource-pressure verification. |

Contract inconsistency requiring resolution by the implementation owner:
`docs/device_capabilities_blueprint.md` currently says to "roll back temporary
output" after a failed write. That phrase must not be interpreted as permission
to delete or overwrite app-created information: the owner's later preservation
instruction explicitly provides no temporary-file exception. Refuse/defer work
and preserve existing artifacts; leave consumer-specific behavior to its owner.

The audit's source findings are ready as import-review input. The original
implementation objective remains incomplete. Continuing implementation here
would conflict with the owner's transfer of that work to the other Codex task.

Source paths below are relative to the protected 5.7 repository. These findings
were rechecked against source; they are not executed native-device test results.

- `lib/shared/trip_tracking/trip_tracking_device_operational_policy.dart:238`:
  `TripTrackingStorageDecision.evaluate` permits text trip logs in every return
  branch, including invalid policy, unknown free space, and space below its
  default 25 MB threshold. This advice cannot enforce the owner's 100 MB reserve.
  An importing implementation needs a separate, enforced write admission budget
  covering peak additional storage. No existing records may be reclaimed to
  satisfy that budget. The source explicitly declares purge permissions false;
  this finding concerns admission, not evidence of actual deletion.
- Same file, line 431: location availability is hardcoded true. Activity
  recognition availability is inferred from `sensors.hasMotion` and profile
  trust. Those facts do not independently establish a working location provider,
  an activity recognition API, or permission. Background capability is likewise
  inferred from resource policy/trust. Preserve separate statuses for hardware,
  platform support, service state, permission, user consent, and resource policy.
- Same file, line 437: low-power-mode availability is derived from current power
  saving or low battery. The current condition and whether the platform can
  report that condition must be distinct facts.
- `lib/shared/trip_tracking/trip_tracking_device_profile_validator.dart:71`:
  freshness validation executes only when the caller supplies `currentAt`.
  Omitting it bypasses both stale and future snapshot checks. Resource admission
  needs a required freshness policy, including refresh failure behavior.
- Same file, line 90: temperature range comparisons do not reject NaN. Add an
  explicit finite-number check before trusting temperature evidence. A passing
  profile validator alone does not establish safe workload admission.

Independent verification still needed by the implementation owner: exercise
unknown/zero/below-reserve storage, reserve plus in-flight write budgets, missing
permissions/provider, stale and future timestamps, and nonfinite temperature.
Expected safety behavior is refusal or deferral with a shared reason, without
deleting or overwriting existing information. This audit did not change any
runtime, OCR, trip, or imported-engine file to address these findings.

## Inspected architecture and disposition

### Report and upload boundary trace

### Desktop and persistence boundaries

Read-only inspection of `device_capability_service.dart:232–295` confirms that
desktop support is partial. macOS supplies RAM and architecture through
`device_info_plus`; Windows supplies RAM but also reads registered owner and
device ID; Linux has an identity branch reading machine ID. Core count comes
from `Platform.numberOfProcessors`. None of those establishes current thermal
state, power state, available memory, or usable sensors.

The inspected Windows `runner/flutter_window.cpp` and macOS
`Runner/MainFlutterWindow.swift` register generated plugins but contain no custom
capabilities bridge. A search of those platform trees found no registration of
the custom capability channels/runtime methods. The source checkout has no Linux
platform directory. This is a source-support gap, not a tested statement about
every plugin's desktop behavior. The service catches missing native methods and
returns empty maps (`device_capability_service.dart:217`), while missing event
channels end their streams. A successful Dart profile call therefore does not
prove working desktop health monitoring.

The capability service caches futures in process memory and contains no Hive or
SQLite persistence. That particular cache does not need a Hive-to-SQLite table
conversion. Related feature preferences and business records are separate and
must not be mistaken for this ephemeral cache. UI Lab's SQLite architecture
should remain authoritative for any deliberately persisted settings; live
resource snapshots need fresh observation and must not become a durable device
identity or a substitute for current readings.

Import acceptance needs explicit platform evidence: field-level unknown states
when native support is missing, functioning health events where supported, and
safe admission when required resource facts cannot be established. Copying the
mobile bridges alone cannot establish equivalent desktop support. No platform
implementation or database was changed during this inspection.

### Report and upload boundary trace (continued)

The protected source has an explicit cloud-queue path for coarse capability and
storage status, so its device-derived information cannot be described as wholly
local merely because raw hardware identifiers are absent from a summary:

1. `lib/screens/dashboard/data/dashboard_trip_tracking_summary_reporter.dart:140`
   creates a summary from storage and the shared device profile, then queues it
   with the validated account/dashboard identity. `_safeDeviceProfile` catches
   exceptions but imposes no timeout or freshness check itself (line 190).
2. `dashboard_trip_tracking_summary.dart:490` derives `storageState` from an
   `AppStorageCheck`. This is derived resource information, not only a user
   preference.
3. `dashboard_firestore_mirror.dart:333` forwards `storageState`,
   `deviceCapabilityState`, and `sensorAssistState` to the document builder.
   `flushSummary` invokes the upload coordinator at line 382.
4. `lib/shared/firebase/maintainiac_firestore_documents.dart:560` serializes the
   status fields. `maintainiac_firestore_upload_policy.dart:306` explicitly
   permits storage tokens including `low_storage` and `full`, capability tokens
   including `motion_ready`, and sensor-assist tokens. Its validation at lines
   675–686 accepts those allowlisted fields.

This proves a source-level export path, not that an upload occurred on a user's
device. Coarse allowlists are useful data minimization, but do not by themselves
make resource observations local or anonymous. For the new resource-protection
purpose, keep capability/health snapshots and derived resource statuses out of
business sync and analytics. Reusing this mirror contract unchanged would carry
an additional data flow that the device-protection requirement does not need.
No report, queue, sync implementation, or configuration was changed by this audit.

| Source | Behavior | Disposition |
| --- | --- | --- |
| `lib/shared/device_capabilities/device_capability.dart` | Hardware/runtime/camera profile, RAM/core/heap/media/GPU score, six tiers and per-tier budgets | Adapt separation; replace unchecked additive scoring and advisory-only enforcement |
| `device_capability_grade.dart` | Additional 1–10 grade layered over six tiers | Omit competing ranking; owner requested six tiers |
| `device_capability_service.dart` | DeviceInfo/DiskSpace plugins, method/event channels, cached hardware/camera/extended facts, runtime refresh | Replace identity collection, indefinite waits, ambiguous unknown defaults and zero-space parsing |
| `device_capability_scope.dart` | Shared ChangeNotifier, native-event debounce, refresh coalescing | Adapt observable shared state; refresh callers must await fresh data, dispose safely |
| `device_feature_capabilities.dart`, `device_feature_capability_parser.dart` | Lenses, normalized sensors, battery, display, codecs, graphics, connectivity | Adapt useful allowlisted facts; no raw/vendor sensor identifiers or unrelated fingerprint inventory |
| `device_operational_policy.dart` | OCR/camera/PDF/trip/video/network recommendations | Adapt bounded workload advice; enforce admission separately |
| `device_storage_status.dart` | Green/yellow/orange/red warnings; explicitly never blocks an action | Replace for workload writes: enforce reserve plus peak output budget |
| `device_bluetooth_capabilities.dart` | Availability/authorization plus opaque connected-device observations | Exclude identity/connection tracking from resource capability service |
| Android `DeviceCapabilityBridge.kt` | RAM/heap/media performance, lenses, sensors, battery, display, codecs, GPU, network | Rebuild minimal public-API probes, isolate field failures, use app volume |
| Android `DeviceCapabilityEvents.kt` | Battery/power/network/thermal and Bluetooth ACL events | Adapt health events only; exclude Bluetooth identities and persistent salt |
| iOS `DeviceCapabilityBridge.swift`, `DeviceCapabilityEvents.swift` | ProcessInfo thermal/power/RAM, CoreMotion availability, AVFoundation lenses, battery, Metal/media/network | Adapt availability/thermal lifecycle; no claimed exact temperature or battery health |
| Receipt `receipt_device_capability_service.dart` | Shared profile mapped into receipt-specific hardware classifier plus permission/native camera facts | Avoid a second conflicting classifier; keep one policy and permission boundary |
| Trip `trip_tracking_capability_guidance.dart` | Readiness/opt-in advice, fallback and dashboard-safe map | Adapt concepts; do not treat capability as authorization or proven activity |
| UI Lab `device_workload_service.dart`, Android bridge, iOS AppDelegate | Three tiers, one heavy task, preflight/checkpoint memory/power/thermal checks | Extend existing gate rather than add a competing singleton |

5.7 capability snapshots/cache do not use Hive. Android Bluetooth salt uses
SharedPreferences. Business/trip/receipt stores elsewhere are not authority for
device health. No Hive profile migration is required; UI Lab remains SQLite.

## Findings from code inspection

1. **Unnecessary identity collection:** Windows reads registered owner and device
   ID; Linux reads machine ID; mobile reads model/hardware names. Safe diagnostic
   omission does not justify collecting these in the first place.
2. **No storage reservation:** warning policy never blocks; operational advice
   reduces workloads but cannot preserve a 100 MB floor or account for scratch.
   DiskSpace `value > 0` maps an actually full disk to unknown.
3. **Advice is not admission:** per-tier heavy-task counts do not themselves limit
   actual callers. Thermal critical still yields a nonzero budget. The new gate
   must refuse work, not merely publish a smaller tier.
4. **Unknowns look healthy:** many missing booleans become false; missing Android
   battery temperature becomes 0 C. iOS Bluetooth powered-off is reported where
   live power was deliberately not queried. Zero available memory is discarded
   by the shared positive-number parser.
5. **Parser robustness:** legacy numeric helpers call `toInt()` on nonfinite
   values; double parser admits NaN/infinity; arbitrary strings and vendor sensor
   types enter profiles. Input normalization needs bounded typed allowlists.
6. **Confidence/scoring:** core count is not CPU speed, media codec support is not
   OCR throughput. Baseline is captured before the low-confidence cap. Heuristic
   scores and named-phone fixtures do not constitute calibration.
7. **Refresh race/lifecycle:** controller refresh returns immediately when already
   loading, so `await refreshForHeavyWork` can still expose an older profile.
   In-flight completions can notify after dispose; no probe deadline is present.
8. **Native metadata accuracy:** independent maximum camera width/height can form
   an unsupported pair. Lens-type inference from focal length alone is not proven.
   Pre-29 hardware codec naming is heuristic. iOS lack of RAW/stabilization evidence
   is represented as false. Extended hardware failures need field isolation.
9. **Unexpected Bluetooth scope:** Android events hash device MAC addresses with
   a persistent local salt whenever OS permission permits; this is more than
   passive resource sensing. No such behavior belongs in the target subsystem.
10. **UI Lab gaps:** three tiers, no storage/battery/sensor/CPU facts, no live event
    monitoring; Android LIGHT heat is mapped to nominal. Gate timeout ownership is
    useful and must be retained. OCR currently is the only connected consumer.

These are source findings, not claims of reproduced native failures. Existing
legacy classifier/native/scope/trip/receipt tests are evidence of intended
contracts, not independent proof. Disposable characterization and new target
tests must record actual results separately.

## Remaining audit and delivery work

### Shared status lifecycle and test-evidence limits

Native event and sensor inspection adds these boundaries:

- Android `DeviceCapabilityBridge.kt:220` enumerates all sensors and publishes
  normalized types plus a count. Its permission-gated list is inferred from
  declared heart-rate features missing from enumeration; it is not a per-feature
  permission result for step counting or activity recognition. Inventory alone
  cannot prove that a caller may start collecting samples.
- iOS `DeviceCapabilityBridge.swift:224` queries CoreMotion/pedometer availability,
  including activity availability. These are capability queries, not observed
  walking/driving/still classifications. The importer needs explicit permission
  and user-intent status in addition to availability.
- The inspected Android and iOS capability event files publish battery, power,
  thermal, and network events. Neither contains a memory-pressure callback.
  Other application code may respond to memory pressure, but these shared event
  bridges do not demonstrate that resource consumers receive it.
- iOS event subscription enables battery monitoring. Cancellation removes
  observers and cancels its network monitor but does not restore the previous
  battery-monitoring state. Ownership of monitoring needs an explicit lifecycle
  contract so cancellation neither leaves task-owned observation enabled nor
  disables another legitimate subscriber's observation.
- Android thermal events are registered only on API 29 and newer. Older supported
  systems need explicit unknown/fallback behavior; absence of events is not
  evidence that the device is cool. No physical-device behavior was tested here.

Read-only inspection of the complete `device_capability_scope.dart` and its
scope tests establishes these specific boundaries:

- Live events use a trailing 250 ms debounce that cancels and restarts on each
  event. A sustained stream spaced less than 250 ms apart can postpone refresh
  indefinitely. A critical pressure event needs prompt handling or a bounded
  maximum refresh delay, rather than dependence on an event-free interval.
- A refresh requested during another load returns immediately, setting only a
  pending flag. Awaiting that returned future does not await the pending fresh
  profile. The shared `refreshForHeavyWork` wrapper inherits that limitation.
- Refresh errors leave the previous profile in place and store `lastError`
  separately. Every admission consumer would have to account for stale/error
  state; reading the last tier alone is insufficient.
- Disposal cancels the timer/subscription but does not guard an already pending
  probe completion. The completion still assigns the profile, notifies listeners,
  and may schedule a pending refresh. Disposal needs explicit in-flight handling.

The scope test file has two tests: shared controller exposure and a short burst
of two events producing one refresh. Its fake returns immediately. It does not
exercise overlapping refreshes, endless event bursts, probe failure/hang, or
disposal during a pending load. The native contract test checks source substrings
and line counts. It does not compile a bridge, invoke platform APIs, verify event
delivery, or measure thermal behavior. These are useful structural checks but
cannot substantiate the claimed native safety behavior independently.

Required independent lifecycle cases for the importing task: hold the first probe
with a completer while a second caller requests refresh; dispose before probe
completion; sustain events past the maximum acceptable refresh delay; fail or
hang a refresh after a previously healthy reading; and deliver a critical event
during active work. Assertions must inspect returned status, admission, stop
signals, event latency, and ownership until work actually finishes. Do not infer
safe cancellation merely from a caller's timeout.

### Six-tier classification trace

The reference classifier (`device_capability.dart:320`) is additive rather than
a measured performance benchmark. RAM contributes -2 through 6 points; core
count -1 through 3; Android media performance class 0 through 5; application heap
-1 through 2; compute plus hardware codec support up to 2. Score boundaries are
<=0 constrained, <=2 entry, <=4 balanced, <=6 enhanced, <=9 performance, and
otherwise flagship. Three present signals produce "high" confidence; this counts
signals and does not measure their accuracy or actual workload throughput.

The following source-derived examples expose contracts requiring independent
tests. They are arithmetic/branch analysis, not executed Flutter results:

- A 3 GB, four-core device with a 128 MB heap and no other positive signals
  scores -4 and legitimately classifies constrained. The trip validator rejects
  any score below zero. Consequently classifier output and consumer validation
  disagree for a valid low-end profile.
- A high baseline with critical thermal state is capped to balanced. Balanced
  still recommends one heavy task, two workers, and a 96 MB in-memory asset.
  The operational policy reduces some rates but does not represent zero-admission
  for critical heat. Publishing these values alone does not stop active work.
- Unknown storage leaves the tier unchanged. Below 250 MB sets constrained, but
  constrained still has positive budgets. No reserve accounting occurs here.
- A device can retain its high baseline while dynamic memory/storage/heat lower
  its effective tier. Consumers must use current admission/status, not baseline
  alone, when starting or continuing resource-heavy work.

Selected reference budgets, for understanding the source rather than approving
these numbers for import:

| Tier | Heavy tasks | Workers | In-memory asset MB | Live pixels | Trip interval seconds |
| --- | ---: | ---: | ---: | ---: | ---: |
| constrained | 1 | 1 | 48 | 900000 | 12 |
| entry | 1 | 1 | 64 | 1100000 | 10 |
| balanced | 1 | 2 | 96 | 1400000 | 8 |
| enhanced | 2 | 2 | 128 | 1800000 | 7 |
| performance | 2 | 3 | 192 | 2200000 | 6 |
| flagship | 3 | 4 | 256 | 2600000 | 5 |

No source evidence inspected establishes these budgets as calibrated on the
owner's oldest supported devices or current low-cost hardware. Tier names must
not be presented as guarantees against overheating, battery drain, or crashes.
Validation must cover pressure transitions during work as well as cold-start
classification; a six-tier table alone does not fulfill the shared safety system.

September 19 additional owner constraint: resource pressure must never delete or
overwrite any existing user or app-created information. Deletion requires an
explicit user action followed by confirmation. No temporary-file exception is
authorized. Existing automatic OCR scratch deletion conflicts with this new
requirement and remains unfinished work; do not claim compliance from the
admission gate alone. The owning rule is in `data_storage_sync_contract.md`.

Current execution evidence: the two UI Lab suites
`device_workload_service_test.dart` and `device_resource_safety_test.dart` ran
15 tests successfully on this Windows host. This is focused Dart evidence only.
The iOS probe and privacy-manifest integration are authored but not compiled.

Later checkpoint: the trip guidance suite also passed (19 total tests across
three files). Native health event bridges, foreground refresh, memory-warning
cooldown and sticky stop reasons have since been added; their new monitor tests
are not yet verified. Full analysis before the latest fixes reported 16 info-level
findings, nine in capability files and seven outside this task, no errors/warnings.
The nine capability findings were addressed but require a new analyzer result.

OCR integration now declares a 16 MiB additional output budget and 32 MiB memory
budget, stops scheduling on the shared live stop flag, and refreshes before a
single-image write. Native Android region output checks its volume before writing
and caps the output stream at 16 MiB. Automatic deletion was removed from those
processing-handle disposal/failure paths under the owner's new preservation rule.
This is incomplete: copies still use cache/temp locations, user-visible retained
artifact management and confirmed deletion are not yet implemented, and broader
repository cleanup paths remain under audit. These changes need regression and
native build verification. Never claim the whole app complies yet.

Independent API references used during implementation:
- Android PowerManager thermal status/listeners:
  https://developer.android.com/reference/android/os/PowerManager
- Android notes that vendor thermal status can be incomplete; physical validation
  and headroom support remain necessary:
  https://developer.android.com/games/optimize/adpf/thermal
- Apple app allocation headroom is transient advisory information:
  https://developer.apple.com/documentation/os/os_proc_available_memory
- Apple disk-space reason E174.1 supports pre-write space checks with observable
  behavior and prohibits sending that information/derivatives off-device:
  https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons
  The authored manifest covers this new disk-space use, not a full app privacy audit.

- Complete consumers/settings/export/sync tracing and independent legacy cases.
- Implement six-tier models, typed availability, native probes/events, shared
  status, enforceable workload storage/memory/thermal/battery decisions.
- Connect existing OCR at admission and work/write boundaries; document remaining
  writers explicitly rather than claim all app storage is governed.
- Run focused and broader regressions, analysis and Android build; record native
  iOS/desktop and physical-device limits accurately. Clean task-owned build workers.
