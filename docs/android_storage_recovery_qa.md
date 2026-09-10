# Android storage recovery checkpoint

Observed 2026-09-09. This is a bounded runtime check, not complete device QA or
owner visual acceptance. The owning requirements remain in
`data_storage_sync_contract.md`; overall limits are in
`sqlite_migration_verification_status.md`.

## Evidence

`build/storage_qa/android_recovery_20260909/report.json` records the APK SHA-256,
Android API, scenario, assertions, and stopped-database file hashes. Numbered XML
files preserve the actual accessibility trees before entry, after local-save
acknowledgment, after cold launch/recovery, and after confirmation. The process
interruption JSON records a nonempty PID before force-stop and its absence after.
The stopped app's SQLite main/WAL/SHM files are retained together in that private
ignored evidence folder; the main file alone would omit committed WAL data.
Only synthetic fixture/test data was used. Review evidence before sharing it;
never substitute a user's private database for these fixtures.

The current debug APK built and installed on the existing Android 15/API 35
`MaintainiacSizeAudit` ARM64 emulator. It ran alone, headless, with 1536 MB RAM and
two cores. No AVD wipe or physical-phone installation occurred. The connected
iPhone and protected 5.7 reference were not changed. No screenshots were taken.
The emulator was shut down after verification, leaving its synthetic app data.

## Repeatable procedure

Use an explicitly selected isolated emulator and serial. Run only one emulator
at a time on the owner's 8 GB Mac. Build the current APK before launching it;
preserve the APK hash and build log. Do not clear an existing app's data merely
to make a test pass.

1. Open the app and navigate Business menu → Employees → Add employee.
2. Read the current UI accessibility tree before each action. Derive tap
   coordinates from its bounds; do not reuse recorded screen coordinates.
   Normalize whitespace in content descriptions when matching labels.
3. Enter a unique synthetic name, an incomplete phone value such as `555-`,
   and incomplete pay text such as `28.`. Preserve the raw text exactly.
4. Observe `Draft saved on this device` together with the entered fields.
   Capture the XML evidence. An enqueued write is not an acknowledgment.
5. Press Home, record the app PID, and execute `am force-stop` for the selected
   UI Lab package. Verify its PID is absent. Do not use editor Back or Save.
6. Cold-launch the app. Navigate through the same entry point. Before opening
   the draft, confirm the directory has not gained an employee. Open Add employee
   and compare each recovered raw field to its pre-interruption value.
7. Confirm Save employee. Check exactly one new directory record appears.
8. Force-stop again before inspecting database files. Copy main, WAL and SHM
   together from the stopped isolated debug app, preserving hashes. Open the
   copy read-only. Verify SQLite integrity, exactly one expected employee record,
   its exact phone/pay values, revision 1, and no remaining employee-editor draft.
9. Shut down only the emulator started for this check. Preserve logs/XML/report;
   do not modify the protected reference or upload app data.

## Observed result and limits

The test name `QA-Android-Recovery-1427`, phone `555-`, empty emergency field,
and pay `28.` recovered exactly after process death. The directory had three
fixture employees before confirmation and four afterward. The stopped database
contained one matching new employee at revision 1, exact field values, zero
employee-editor drafts, and `PRAGMA integrity_check` returned `ok`.

This proves one acknowledged employee-draft/confirmation path on one Android 15
emulator at a wide 1260×768 viewport. It does not prove physical battery loss,
loss of unacknowledged keystrokes, every workflow, phone-sized layout, older
Android versions, physical Android hardware, iOS, Windows, encryption, production
account authorization, cloud sync/backup, or visual acceptance. The automated
host suite and this runtime checkpoint remain separate evidence sets.

## Phone-width Expense recovery — 2026-09-09

The current debug APK was built and installed over the isolated emulator's
existing synthetic data. Only one Android 15/API 35 emulator ran, with 1536 MB
RAM and two cores. Display overrides were temporarily 1080×1920 at 420 dpi
(about 411 logical pixels wide), restored to 1260×768/160 dpi before shutdown.
No screenshot, physical-device install, data wipe, upload or 5.7 write occurred.

The exercised route was Expenses → Add expense → Record expense. Input used
vendor `QA-Android-Expense-1635`, total-only mode, amount `7.`, blank subtotal,
and tax `0.00`. The UI acknowledged local saving. Home and force-stop terminated
a verified live app PID without editor Back/Save. The stopped database contained
the exact raw input and no confirmed record for that vendor. After cold launch,
Record expense offered the named unfinished expense; selecting it restored the
vendor and incomplete amount exactly in the native accessibility tree.

Attempting Save with `7.` correctly displayed decimal validation and retained
the editor. Completing the text to `7.50` and saving returned to Expenses, whose
total increased from $308.22 to $315.72. After another force-stop, the copied
SQLite main/WAL/SHM set contained exactly one matching expense, revision 1,
750 cents, and no matching recovery draft. `PRAGMA integrity_check` returned
`ok`. The emulator process exited and `adb devices -l` was empty afterward.

Evidence: `build/storage_qa/android_expense_recovery_20260909/report.json`,
numbered UI XML files, interruption PID evidence, APK/build evidence and separate
before/after stopped database copies. The procedure follows the same safety and
copy rules above; use fresh UI bounds and a unique synthetic vendor on rerun.

This adds one acknowledged manual-expense interruption/confirmation path at
phone width. It does not establish physical battery/power-loss recovery,
unacknowledged keystroke durability, all workflows, other Android versions,
iOS/Windows, production security or owner visual acceptance.

### Android external-camera process-death recovery — 2026-09-09

Evidence: `build/storage_qa/android_native_media_recovery_20260909/report.json`,
numbered accessibility XML, three stopped-process SQLite/WAL/SHM sets, retained
original copies and an empty crash buffer. The APK/source identity matches selected
harness `20260909T174430Z-205835a1`. No app/test source changed during this runtime
check. One API 35 ARM64 ATD emulator was used; no screenshots were taken.

The receipt camera was launched through Expenses → Add expense → Add receipt →
Capture receipt photos. With com.android.camera2/CaptureActivity foreground,
`am kill com.maintainiac.ui_lab_2_1` removed app PID 1852. A stopped-process SQL
copy showed receipt `receipt-draft-1788976235868937` at revision 1 with no evidence
and the exact scoped pending request. The camera remained available. Capturing
and accepting its photo restarted Maintainiac as PID 2297. After another app
force-stop, SQL showed returned source metadata and one retained attachment.
Its 75,783 bytes matched SHA-256
`e6703c8e662e920c33dca3e2386643c362bceca2de7e01c201d281809d8395bc`.

After relaunch, the original receipt draft offered Recover photos. Selecting it
showed one photo for review. A third stopped-process SQL check verified receipt
revision 2 with exactly one active evidence item, matching original bytes/hash,
no pending picker request, unchanged confirmed Expense records and integrity_check
ok. Recovery did not create an Expense or submit the receipt. The emulator was
shut down; its original 1080x1920/420 overrides were unchanged, and adb subsequently
reported no attached device. No 5.7 changes occurred.

This proves the exercised receipt-camera interruption path on this emulator.
It does not prove physical power loss, unacknowledged callback durability,
estimate/gallery runtime parity, older-device coverage or production security.

Reproduction rule for this case: confirm the external camera is foreground and
record the app PID before using `am kill`; verify the app PID is absent afterward.
Do not substitute force-stop at this step, since force-stop can cancel delivery
instead of modelling background process reclamation. Keep SQLite main/WAL/SHM
copies together and copy only while the app is confirmed stopped. After the
native result returns, additional force-stops can verify retained-result restart
behavior. Derive every tap from a fresh accessibility tree when layouts change.

### Reusable Android SQLite evidence capture — 2026-09-09

`tooling/storage_qa/capture_android_database.py` replaces ad hoc raw-file capture
for later device checks. It requires an explicit serial and new output directory,
refuses a running main/package-prefixed secondary process, captures existing main,
WAL, SHM and rollback sidecars, compares repeated reads, and validates schema,
integrity and foreign keys on a disposable copy. Raw bytes/hashes remain intact;
reports identify the script, host, target and bounded checks. The helper does not
stop/reset the app, mutate device files or upload evidence. It is a stopped-app
QA helper, not a live backup or proof of workflow completion.

Fifteen Python harness tests passed. A live API 35 ATD run refused capture while
Maintainiac was running; after an explicit operator force-stop, capture succeeded.
An independent read recovered the prior receipt at revision 2 with one image and
verified unchanged raw hashes. Final helper source (including the secondary-process
guard) was exercised again against the stopped emulator. Evidence is in
`build/storage_qa/android_capture_tool_20260909/validation.json` and its paired
capture reports/raw files. The emulator was shut down afterward. Android device
scenario documentation and the shared harness README describe reuse and limits.
No Dart/app behavior, Firebase configuration or protected 5.7 files changed in
this checkpoint. Existing migration/device/security boundaries remain open.

### Android estimate camera process-death recovery — 2026-09-09

Evidence: `build/storage_qa/android_estimate_camera_recovery_20260909/report.json`,
numbered accessibility XML and three stopped-app captures from the reusable
Android capture helper. The source fingerprint matches selected harness
`20260909T174430Z-205835a1`; no app/test source changed during this runtime check.
One API 35 ARM64 ATD emulator was used without screenshots.

Through Work → Estimates → New estimate, entered
`QA-Android-Estimate-Camera-1802` and raw discount `7.`. After opening Job-site
photos → Take photo, the external camera stayed foreground while `am kill`
removed Maintainiac PID 1791. The first capture proved estimate input
`estimate-input-15e5a6d2de9b277501fbd63d35144481` and its scoped picker request
both at revision 39, with the exact title/discount and empty photo editor.
Accepting the camera image restarted Maintainiac as PID 2431. A second app
force-stop/capture verified the retained 74,906-byte original and its hash.

Relaunch offered the same unfinished estimate by name. Its original photo screen
showed Recover photos; recovery displayed one photo, and Save photos and notes
returned it to the parent draft. The title and raw `7.` were visible after recovery.
The final stopped capture showed revision 41, one site photo, null nested photo
editor and no picker request. All other raw fields matched the pre-camera input
exactly. Every confirmed Work, Expense and Receipt record matched the initial
capture. Original bytes matched SHA-256
`b34be1a9bd8bdba2532d261feecf3546e8e7292686abdfa1382f729fc9f63442`.
All captures passed schema/integrity/foreign-key checks. The emulator shut down
and adb reported no attached devices. Protected 5.7 remained unchanged.

This proves the exercised estimate camera path on this emulator, complementing
the earlier receipt-camera check. Gallery/document selection, physical power loss,
older and physical devices, production security/cloud and owner visual acceptance
remain separate boundaries. It does not eliminate the native callback-to-SQL
acknowledgment window. The raw draft remains unfinished; no business estimate was
confirmed by this check.


### Receipt document-picker interruption check — 2026-09-09

Evidence: `build/storage_qa/android_document_recovery_20260909/report.json`,
three stopped-app SQLite captures, accessibility XML and retained synthetic PDF.
The APK comes from selected checkpoint `20260909T182553Z-41c7ef5b`; no production
source changed during this check. A new coordinator boundary regression also
passed with the two existing coordinator tests, and analysis was clean.

On one API 35 ARM64 ATD emulator at 1080×1920 / density 420, opened Expenses →
Add expense → Add receipt → Choose a receipt file. While Android DocumentsUI
remained foreground, `am kill` removed Maintainiac PID 1873. The first capture
proved a revision-1 receipt and matching files-source request. Choosing the PDF
restarted Maintainiac as PID 2261. The second stopped capture showed the same
request and records; the plugin had not durably returned the file to the app.

After relaunch, Receipt drafts → original receipt showed Unfinished file selection
and Choose file again. Reselecting the same Downloads PDF displayed one retained
item and cleared the pending notice. The final stopped capture proved revision 2,
one PDF, consumed request, preserved original receipt fields and unchanged
pre-existing unrelated records. Exactly one attachment manifest was added.
The retained 430-byte PDF matched the source byte-for-byte and SHA-256
`ea688b683d3ce01221aac808fe97b4030109e9529e5edcb8b28a5efc3efa6022`.
No expense was confirmed. The verifier accounts separately for that expected
new attachment manifest; it does not call all database rows unchanged.

This proves explicit receipt file reselection after process death for the exercised
Downloads provider and PDF. It does not prove automatic recovery of an unreturned
file, estimate file-picker runtime parity, gallery behavior, every provider/device
or physical power loss. No screenshots were taken. Protected 5.7 was unchanged.


### Gallery interruption: retained draft and manual reselection — 2026-09-09

Evidence: `build/storage_qa/android_gallery_recovery_20260909/report.json`,
accessibility XML and four valid stopped-database captures. The first attempted
capture is preserved separately as refused: `am kill` left the app running while
Android PhotoPicker remained foreground. A subsequent run-as SIGKILL terminated
Maintainiac PID 1841 without closing the gallery. This differs from the earlier
camera background-reclamation check and must not be described as the same test.

The revision-1 receipt and library-source request were durable before termination.
Selecting the gallery PNG and Add returned Android to its ATD launcher rather than
delivering the result to Maintainiac. After relaunch, Recover photos reported no
returned files. The receipt and pending request were unchanged. Thus this run
DID NOT prove automatic gallery-image recovery; it exposed the undelivered-result
limit in this harsher interruption path.

The existing fallback was then exercised: explicitly discard only the pending
selection, whose dialog promises the saved receipt/evidence remain. A stopped
capture verified all records unchanged and only the picker request consumed.
After another relaunch, opening the original receipt and selecting the PNG again
produced exactly one retained image and revision 2. All other existing records
and the receipt's non-evidence fields were unchanged. One attachment manifest was
added. Retained image bytes matched the original 68-byte fixture and SHA-256
`6b1048f8a6d40bac0b2954c18fefa40c4ea7a96120fc2e54b7317c0e43c2bbec`.
No Expense was confirmed, no screenshots were taken, and 5.7 was not modified.

The report separates `fallback_verified: true` from
`automatic_image_recovery: false`. This is one API 35 ARM64 ATD/provider case,
not every device, gallery, interruption or physical battery-loss guarantee.
The APK came from selected checkpoint `20260909T184353Z-05832843`; no app source
changed during this runtime check. Estimate file/gallery runtime coverage and
broader provider/device coverage remain separate outstanding work.
