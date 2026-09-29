# Repeatable SQLite/Drift checks

From the UI Lab checkout, with Flutter and Python 3.9+ available:

```sh
python3 tooling/storage_qa/run_storage_qa.py
```

This runs the explicit `core`, `domains`, and `editors` lists in `suites.json`.
Each Flutter invocation uses one test worker. No emulator is started, no cloud
project is accessed, and no tests run in Maintainiac 5.7 Active. Tests use their
own synthetic temporary databases; never adapt a fixture to use app-support data.

The host runner now takes a nonblocking OS file lock before invoking Flutter.
A second cooperating storage QA runner on the same host refuses to start until
the first exits. Process exit releases the lock; the lock file is not deleted.
This does not coordinate arbitrary Flutter commands, IDE builds, or the separate
device runners. On the 8-GB Mac, coordinate those with other tasks and keep only
one test/build job active. Reading and editing source can continue, but changing
covered source during a run invalidates its final evidence fingerprint.

For a narrower checkpoint:

```sh
python3 tooling/storage_qa/run_storage_qa.py --suite core
python3 tooling/storage_qa/run_storage_qa.py --suite domains
python3 tooling/storage_qa/run_storage_qa.py --suite editors
python3 -m unittest discover -s tooling/storage_qa -p 'test_*.py'
```

For a complete discovered test-file baseline:

```sh
python3 tooling/storage_qa/run_storage_qa.py --all
```

This discovers every `*_test.dart` under `test/`, including nested folders, and
records the exact inventory in the report. It cannot be combined with `--suite`.
Empty inventories, duplicate paths and paths resolving outside `test/` fail before
execution. Helpers without the test suffix are excluded. Every discovered file
must appear in the test protocol; failures are retained rather than filtered out.
The selected storage lists remain the default. All discovered tests are still
limited to assertions that actually exist; this is not complete product coverage.

`--timeout-seconds` sets the maximum for each suite (default 900). Timeout or
interruption stops that suite's process tree and cannot produce a passing report.
The runner continues other selected suites after an ordinary test failure and
exits nonzero if any selected suite fails. Do not interpret a passing subset as
the result of an unselected suite.

## Evidence output

Each run creates a unique directory under ignored `build/storage_qa/` containing:

- `report.json`: selected commands and test inventory, real/failed/skipped test counts, missing or
  unfinished protocol results, separate protocol completion/success, exit codes, durations, Git HEAD/dirty state,
  platform/Python version, and before/after source fingerprints.
- `flutter-version.txt`: Flutter's version output.
- One `.jsonl` per suite: unabridged Flutter machine output, including errors.

A PASS requires exit code zero, successful protocol completion, at least one
non-hidden executed test, no failures/skips, all declared suite files observed,
no unfinished or unrecognized test completions, and an unchanged source digest.
The digest covers Dart production/test sources, dependency/configuration files,
the suite manifest and runner. It is provenance, not a security signature.
A dirty checkout is reported honestly; it is not silently treated as the Git HEAD
contents. Preserve that exact checkout or patch to reproduce it.

The manifest is intentionally explicit. Add tests to the appropriate list when
adding a persistence workflow; this is a selected regression gate, not automatic
proof that every screen, platform or requirement has coverage. The runner does
not replace `flutter analyze`, platform builds, device interruption checks,
security review, or owner UI acceptance.

## Sharing and reuse

Share the exact checkout/patch and `pubspec.lock`, this runner/manifest, the
selected test files, `test/support/storage/`, and the run directory. Review logs
before distributing them outside the project; do not add real customer fixtures.
No upload or publishing is performed by this runner.

For another Flutter application, copy the runner directory into its `tooling/`,
replace the explicit test lists, and adapt `DatabaseHarness` to its database
factory. Preserve temporary isolation, committed-value assertions, raw-draft
failure checks and protocol validation. A passing run in either application is
not evidence that the other application's implementation is correct.

The Python runner is portable in design; the current execution evidence is on
macOS only. Windows process termination and other host/device paths still need
independent execution. Hardware power-loss, cloud backup/sync, production
identity/authorization, and full UI acceptance are not established by these runs.

## Android runtime checkpoint

The host runner does not start or control a device. A separate, repeatable
acknowledged-draft/process-death procedure and its bounded Android 15 evidence
are documented in [`android_storage_recovery_qa.md`](../../docs/android_storage_recovery_qa.md).
Use an isolated emulator, preserve the APK/XML/database evidence, and keep its
result separate from the selected host test counts. No screenshots are required.

## Capture stopped-app Android SQLite evidence

After independently verifying that the intended debuggable app is stopped:

```sh
python3 tooling/storage_qa/capture_android_database.py \
  --serial emulator-5554 \
  --output build/storage_qa/android-capture-unique-name
```

Use `--adb /path/to/adb` when ADB is not on PATH. The defaults name UI Lab's package,
private SQLite folder and schema 1. Another app can supply `--package`,
`--remote-directory`, `--database` and `--expected-schema`; use its actual values.
The remote directory is relative to that app's data directory. The selected app
must support `run-as`; this tool does not bypass device/app permissions.

The tool creates a new output directory and refuses an existing one. It records
`capture-report.json` and preserves exact captured files under `raw/`. It checks
that the main app process and package-prefixed secondary processes are absent,
includes existing WAL/SHM/rollback sidecars,
compares repeated reads and the file inventory, then checks schema/integrity and
foreign keys on a disposable copy. Raw capture bytes and hashes remain unchanged.
An error exits nonzero and leaves a non-valid report and any partial evidence.
A failed capture is not safe evidence merely because some database files exist.

The tool does not stop/reset the app, delete source files, launch an emulator,
access cloud services or upload anything. Its `capture_valid` flag means only
that the bounded capture checks passed. It is not a live backup mechanism or a
workflow acceptance result, and it cannot prevent an external app restart.
Keep the app stopped throughout capture. Pair the report with APK/source identity,
UI accessibility evidence and the scenario's actual database assertions.

Share this script, its `test_android_capture.py`, the report and raw directory to
repeat or inspect a capture. Script hash, Python/host details, target scope and
file hashes are included in the report. Automated tests exercise a real SQLite
WAL fixture through a fake ADB boundary; current live execution is on macOS/Android
ATD only, not proof of Windows/iOS/device-matrix support.

## Platform application runtime checks

`integration_test/local_restore_runtime_test.dart` runs the existing mounted
restore contract inside a platform app, using Flutter's SDK integration-test
binding. It reuses the same three success, rejected-write and failed-reopen
cases as the host tests, with real temporary SQLite installations. It never
opens the normal application data directory. Notifications are deliberately
unsupported in these fixtures; notification delivery is not part of this gate.

```sh
flutter pub get
flutter test integration_test/local_restore_runtime_test.dart -d macos --no-pub
flutter test integration_test/local_restore_runtime_test.dart -d IOS_SIMULATOR_ID --no-pub --no-uninstall
python3 tooling/storage_qa/run_android_restore_qa.py --serial ANDROID_SERIAL
```

Use one emulator/simulator at a time. Save the full command output and identify
the OS/device used. This is a separate gate: `--all` above discovers `test/`,
not `integration_test/`. The source fingerprint includes both directories,
but inclusion in the fingerprint never means a device test was executed.
The tests constrain their view for repeatability; they do not certify the
physical device's responsive UI, screenshots, native picker interaction,
predictive-back gestures, power loss or OS process termination. Temporary
fixtures may remain after a forcibly interrupted test and are not normal app data.

A platform test builds a test entry point into that platform's debug artifact.
Before distributing or launching a normal build afterward, rebuild with the
normal `lib/main.dart` entry point. Do not distribute the test application.


### Android forced-termination probe

Use the Android wrapper above, not a direct `flutter test` call. It prebuilds and
verifies the QA APK before Flutter reads its application identity, and supplies
`--no-uninstall`. Without that prebuild Flutter can cache the preceding normal
APK identity before rebuilding, then target it during cleanup.

Android integration runs require `STORAGE_QA=true`, which selects the separate
`com.maintainiac.ui_lab_2_1.storageqa` package. The normal application ID is unchanged
when this define is absent. Always verify the APK application ID before installing.
For iOS use `python3 tooling/storage_qa/run_ios_restore_qa.py --device DEVICE_ID`
(add `--simulator` for a simulator). It applies a process-local Xcode override for
`com.maintainiac.uiLab21.storageqa`, prebuilds and verifies both Xcode Debug output and Flutter copied Info.plist before launch,
and keeps the same override plus `--no-uninstall` during the integration run.
`--build-only` verifies the artifact without installation; `--team TEAM_ID` may
select an existing development team. A signing identity alone does not prove a
valid provisioning profile or successful device execution. Never run the raw
integration command against a normal iOS installation. After QA, rebuild the normal
`lib/main.dart` artifact without the override and verify its bundle ID in both output directories. A successful unsigned build can leave a stale Flutter copy; replace that generated copy only from the verified normal Xcode output if necessary. Remove only
the QA bundle from the tested device if cleanup is needed.

`platform_draft_interruption_test.dart` is a two-phase **standalone Android** probe.
Do not run its two phases using `flutter test`: that runner may uninstall the app
and remove the fixture between phases. Use a fresh alphanumeric/underscore run ID
(8–64 characters) and the same ID in both builds:

```sh
flutter build apk --debug --no-pub -t integration_test/platform_draft_interruption_test.dart --dart-define=STORAGE_QA=true --dart-define=STORAGE_INTERRUPTION_RUN=YOUR_UNIQUE_RUN_ID --dart-define=STORAGE_INTERRUPTION_PHASE=write
```

Install with `adb -s SERIAL install -r build/app/outputs/flutter-apk/app-debug.apk`.
Resolve the QA package's activity with `cmd package resolve-activity --brief` and
launch that exact component. Capture its PID-scoped logcat. Wait for the exact
`UILAB_UNCOMMITTED_READY_YOUR_UNIQUE_RUN_ID` marker **from that live process** before
`adb -s SERIAL shell am force-stop com.maintainiac.ui_lab_2_1.storageqa`.
The writer deliberately waits forever and cannot produce a passing test result.

Build again with `STORAGE_INTERRUPTION_PHASE=read`, preserving the run ID and QA
define. Install with `-r` and relaunch without uninstalling or clearing app data.
Success requires `UILAB_RECOVERY_VERIFIED_YOUR_UNIQUE_RUN_ID` from the new process,
plus no test failures. The read verifies exact raw input/revision and SQLite
integrity, then removes only its fixture. Missing fixtures fail instead of reseeding.
Fixtures live in the QA package's private support directory, not Android code cache
or the normal app package. This checks an acknowledged autosave followed by an
uncommitted repository mutation; it is not a power-cut or visible-editor test.
Retain both logs, package/device identity and the externally issued kill command.
Rebuild the normal main entry point afterward; never distribute the probe APK.

### Estimate file-picker interruption probe

`integration_test/estimate_file_picker_interruption_test.dart` is a standalone
Android QA entry point. Build with `STORAGE_QA=true`, a unique
`STORAGE_INTERRUPTION_RUN` (8–64 letters/digits/underscores/hyphens), and
`STORAGE_INTERRUPTION_PHASE=write` or `read`. Follow the existing standalone
force-stop procedure, including APK identity verification and `adb install -r`;
do not use the uninstalling Flutter test driver between phases.

For `write`, observe the `UILAB_ESTIMATE_PICKER_START_<run>` marker AND the actual native
picker plus the live QA process before force-stopping only the QA package.
For `read`, the probe recovers the original intent and opens explicit reselection.
Select a PNG with the exact bytes encoded by `_pngBytes()` in the probe through
DocumentsUI. The success marker is
`UILAB_ESTIMATE_FILE_RECOVERY_VERIFIED_<run>`. Assertions cover raw unfinished
estimate fields, retained original bytes, file provenance, consumed intent,
duplicate-adoption conflict, database reopening, and absence of a confirmed
estimate. The fixture uses development authority, not production authentication.

Compilation or the existing simulated-picker widget tests do not prove this
native sequence passed. Retain PID/activity/force-stop and success logs when
executing it. Rebuild the normal `lib/main.dart` APK afterward.

### Workspace Android image-picker native regression

Run the vendored plugin's complete native suite from the workspace root:

```sh
JAVA_HOME=/opt/homebrew/opt/openjdk@21 ./android/gradlew -p android :image_picker_android:testDebugUnitTest
```

Use an installed Java 21 runtime (substitute its path on another machine). This
command-local environment does not change Flutter's configured build JDK. Some
upstream Robolectric tests default to SDK 36 and fail during initialization under
Java 17; do not skip those classes to report a green suite. Retain the Gradle log
and all `build/image_picker_android/test-results/testDebugUnitTest/TEST-*.xml`
files. Count failures, errors and skipped tests separately. Native journal tests
inject directory flushing in Robolectric; device fsync and process-kill validation
remain separate gates.

### Native image journal delivery interruption

`integration_test/estimate_native_journal_interruption_test.dart` uses the same
standalone QA APK write/read procedure as the file-picker probe, with a unique
`STORAGE_INTERRUPTION_RUN`. Select the synthetic PNG defined in `_pngBytes()`.
Wait for `UILAB_NATIVE_REPLAY_READY_<run>`: actual native retention has returned,
but the probe deliberately withholds those paths from Dart's SQLite coordinator.
Force-stop only the QA package. Optionally remove the known synthetic download
and its observed QA picker-cache copy (never user files), install the read APK
with `adb install -r`, and launch it. Do not run an uninstalling test driver.
`UILAB_NATIVE_JOURNAL_RECOVERY_VERIFIED_<run>` proves replay, adoption, integrity
and another database reopen without reselection. Preserve PID/kill/log evidence.
This probe covers the library delivery boundary, not camera capture or power loss.

For the same native-journal probe's camera lane, build both phases with
`--dart-define=STORAGE_PICKER_SOURCE=camera`. In the write phase add
`--dart-define=STORAGE_CANCEL_FIRST=true` to cancel the first external camera
opening using Back, then capture and confirm the second image. Wait for
`UILAB_NATIVE_CANCEL_VERIFIED_<run>` followed by `UILAB_NATIVE_REPLAY_READY_<run>`.
The probe stores a test-owned SHA-256 expectation before the kill. The read phase
compares the recovered image to that digest. Remove only observed test camera cache
files if testing cache loss. This is normal-delivery interruption, not process death
while the external camera is still open.

### Workspace-owned Android native media tests

Run the native picker/journal suite separately from Flutter tests:

```sh
python3 tooling/storage_qa/run_native_media_qa.py --java-home /path/to/jdk-21
```

The runner does not change the machine's global Java configuration. It forces a
fresh Gradle test execution, captures JUnit XML and raw output under
`build/storage_qa/<run-id>`, and checks every discovered native `*Test.java`/
`*Test.kt` class. Success requires a successful process, nonempty internally
consistent test results, no failures/errors/skips/missing classes, and matching
source fingerprints before and after. A timeout or interruption cannot pass.
Use `--timeout-seconds` to adjust the default 600-second process deadline.

This is JVM/Robolectric evidence. It does not replace actual camera/provider,
process-death, filesystem/power-loss, physical-device, or cloud validation.

### Android staged-copy process termination

`android/app/src/storageQa` contains a native instrumentation probe included only
when building a debug APK with `--dart-define=STORAGE_QA=true`. Verify the built APK
identity is `com.maintainiac.ui_lab_2_1.storageqa` with aapt before installing it on
the selected test device. It also rejects any other target package at runtime.

On the same installed QA APK, with a unique 8–64 character alphanumeric/underscore
run ID, invoke the instrumentation twice:

```sh
adb -s <serial> shell am instrument -w -e phase write -e run <run_id> com.maintainiac.ui_lab_2_1.storageqa/io.flutter.plugins.imagepicker.NativeMediaStagingInterruptionProbe
adb -s <serial> shell am instrument -w -e phase read -e run <run_id> com.maintainiac.ui_lab_2_1.storageqa/io.flutter.plugins.imagepicker.NativeMediaStagingInterruptionProbe
```

The writer is expected to report a process crash. Require its
`UILAB_STAGING_QA: KILL_BEFORE_PUBLICATION` log with PID and verify that PID exited;
a crash without this marker is not valid evidence. Do not reinstall between phases.
Require a different reader PID, `STAGING_INTERRUPTION_VERIFIED`, and instrumentation
code -1. Shell exit zero alone does not prove either phase passed. Reader verifies
unpublished ownership/file persistence, cleanup, original source bytes, retry/replay,
and acknowledged deletion. This kills after copy and directory flush but before
manifest publication; it does not simulate physical power loss or an interrupted
individual write syscall. Remove only the QA package, shut down the emulator started
for the run, rebuild normal main, and verify its APK excludes the probe.
