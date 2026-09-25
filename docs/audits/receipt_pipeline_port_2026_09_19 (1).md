# Receipt pipeline port: live checkpoint

## Authority and boundaries

Owner authorized transferring the 5.7 receipt camera, OCR and parser flow into
UI Lab 2.1, converting Hive persistence to SQLite, retaining receipt drafts and
Data Saver, and repairing long-receipt stitching and ghost guidance. All edits
are in UI Lab. Maintainiac 5.7 Active is a read-only source. Device capability
implementation belongs to another Codex; consume its shared interface.

The owner accepts the capture/import choices and useful portions of the 5.7
photo-review experience. Do not turn expense intake into a professional camera
app: flash and autofocus are appropriate; manual-focus sliders are not requested.
Stitching and ghost guidance have owner-reported functional and visual defects.
Neither source presence nor legacy passing tests establishes correctness.

## Verified source assessment

Source root: `C:/Users/rjenk/OneDrive/Documents/maintainiac5.7/Maintainiac_5.7_Active`.
Destination root: `C:/Users/rjenk/Documents/UI Lab 2.1`.

| Source | Disposition and required work |
| --- | --- |
| `lib/shared/widgets/receipt_capture/receipt_ocr_service.dart` | Adapt recognition, PDF and handoff behavior behind target interfaces; inspect all parts before extraction. |
| `receipt_capture_settings_store.dart` in the same directory | Replace direct Hive box access with target SQLite preferences. |
| `receipt_native_capture_recovery_store.dart` and staging manifest parts | Replace Hive recovery index; retain originals, checksums and interrupted capture recovery. |
| `receipt_proof_storage.dart` and parts | Assess file adoption/rollback against target atomic media adoption; do not create a competing owner of evidence. |
| `receipt_stitch_acceptance.dart` | Copied to target receipt data directory, then hardened there. Original SHA-256: `28765c7ae325ea58f8a2e3174f47b4369914355b9913941d9fd9831edb9459db`. |
| `receipt_native_camera_session_ghost_guide.dart` | Dart previous-guide policy always reports top placement, including next-context retake. Must reconcile with distinct native next-guide support before diagnosing a specific device defect. |
| `receipt_native_camera_shell_ghost_guidance.dart` | Flutter reference strip is fixed at top, 14% viewport height, opacity .18. Review readability and direction. |
| Android `ReceiptCameraPreviousSectionGuide.kt` | Separate top/bottom panels exist. Fixed 152-dp bands and CENTER_CROP risk cutting off reference content. Capture actual behavior before attributing the reported failure solely to Dart. |
| `receipt_photo_review_stitch_ghost_preview.dart` | Uses viewport-relative overlap and independently transformed images; audit consistency with actual image composition coordinates. |
| `receipt_stitch_order_solver.dart` and text evidence helpers | Audit repeated-line ambiguity, bounded ordering and competing placements; matching text is not proof of duplicate purchase lines. |

## Existing target systems to retain

- `NativeReceiptPhotoReader` already invokes bundled ML Kit on Android/iOS,
  uses shared workload admission and cleans up recognition resources. It has a
  ten-second UI timeout. Timeout does not mean the native operation has stopped.
- `receipt_section_reader.dart` and `receipt_ocr_sections.dart` read regions of
  ONE upright photo. They are explicitly not multi-photo stitching.
- `LocalReceiptDraftRepository.withStorage` accepts the SQLite snapshot store;
  the class also has an older dual-slot JSON opening path. Verify actual startup
  wiring, rather than infer the selected backend from the class name.
- `ReceiptEvidenceDraftController` uses shared draft autosaving and atomic
  evidence review, validates source revision and authorization, and persists
  selection, order, undo and extracted proposals. Extend this authority rather
  than adding an unrelated receipt database.
- `tooling/storage_qa` is a reusable runner with machine-readable reports and
  separate native media checks. It is not yet a complete stitching QA system.

## Reproduced defects and evidence

New independent target tests initially failed in three places in the unmodified
copied acceptance code: non-finite confidence could pass, matching-cell counts
larger than total cells could pass, and height zero/one caused an invalid clamp.
Target now rejects invalid scores/counts and returns zero overlap for tiny images.
An explicit ambiguous-placement veto is added; image matching still must produce
that ambiguity evidence, so this parameter alone is not completed protection.

Six focused tests pass, including a valid candidate, malformed evidence, text
without geometric support and ambiguous placement. These are policy tests only;
the copied module is not connected to a finished target image stitcher yet.

Added `receipt_ghost_geometry.dart` to define upright image-space source strips
and fitted destination rectangles. Previous-section bottom goes at the camera
top; next-section top goes at the camera bottom. Three independently calculated
geometry tests cover directional placement, narrow long images without cropping
or stretching, and invalid dimensions. Nine focused tests now pass. Targeted
Dart analysis reports no issues. The copied source file's hash was rechecked
and remains unchanged. The geometry is not yet wired to the camera renderer.

## Remaining completion evidence

### September 19 extraction checkpoint

Transferred the image processor's 75 remaining dependency files into
`lib/src/data/receipts/image_pipeline/`, using the already-hardened target
acceptance and text modules. Split overlap offsets into a separate part.
`receipt_image_pipeline_source_manifest.json` records all 79 source hashes;
the extraction verified every source hash remained unchanged. This dependency
closure has no Hive imports. It is not yet connected to the application UI.

Repeated identical rows and alternating repeated products both incorrectly
passed the legacy text matcher. Target matching now requires unique text
anchors; three regression cases include distinct valid overlap.

An actual image-file test then reproduced `duplicate_section_image` for two
different generated receipt sections with similar layouts. Removed thumbnail
similarity as a reason to discard a source. Exact byte duplicates still require
review. The explicit manual join now produces a decodable JPEG while retaining
both original PNGs byte for byte. This is synthetic image evidence, not a claim
of camera/OCR accuracy or automatic overlap correctness. Thirteen focused tests
pass, including this real image-processing execution.

Removed automatic artifact deletion from transferred preview, compression and
isolate paths to honor the current owner preservation rule. Remaining writes,
storage admission, artifact indexing and interruption recovery still require
integration with shared SQLite/media authority. Static analysis of the initial
extraction showed unused legacy branches and style issues; those are not yet
resolved. No device or visual acceptance is claimed.

Automatic image tests now exercise two 400-by-800 sections of a generated
receipt with a known 400-pixel overlap: the processor finds that overlap and
produces the expected 1200-pixel output (within the stated test tolerance).
A second test with periodic identical rows reproduced a false accepted join:
geometry and continuity both scored 1.0 despite multiple possible placements.
Added a bounded competing-placement check in the transformed image frame and
connected it to the acceptance veto. That example now retains original sources
for review. This check currently compares alternative vertical displacements at
the selected transform; alternative rotations/scales and real camera images
remain unverified. It does not establish universal ambiguity detection.

Also fixed normalized-text/position index drift when OCR includes empty
detections. Coordinates now use the same nonempty line sequence as matching.
Sixteen focused tests pass after these changes. These remain generated-image
and unit tests; device capture and UI integration are still pending.

Added `ReceiptStitchService` using the existing device-workload owner without
editing that owner's files. It reserves memory/storage, inspects encoded image
dimensions before Dart decoding, bounds combined output, and rejects unprepared
large sources. The capture adapter must still supply suitably reduced working
copies while retaining originals; this service is not yet invoked by the UI.
The manual composition test now runs through this real shared admission path.
Low-storage refusal is tested with unavailable file paths to establish that
admission happens before file access. Pre-start cancellation is also tested.

The isolate now accepts a cancellation predicate and waits for its exit signal
before returning, so the resource slot is not released merely on timeout.
The final JPEG writer enforces a 16-MiB encoded bound and refuses an existing
destination. Artifact destination selection still needs shared durable-media
integration; system-temp paths are not completed draft persistence. Mid-work
resource-pressure testing remains outstanding. All five image-pipeline tests
pass at this checkpoint; prior geometry/text/acceptance suites were not rerun
because their code was unchanged.

SQLite stitching checkpoint: the existing evidence-review payload now includes
typed stitching state, ordered source IDs/hashes and a retained attachment ID.
Selection/reading preserves it; reorder/removal invalidates the derived preview
without deleting bytes. Workflow validation rejects source-hash mismatches.
`ReceiptStitchDraftWorkflow` flushes processing intent, checks retained sources,
runs shared-admission stitching, retains the derived image through the existing
SQL attachment manifest, then flushes the review reference. It does not publish
an expense. Failure retains originals and a retryable draft marker.

Two native SQLite tests pass: interrupted-processing recovery, and a real image
composition through this workflow followed by database close/reopen and hash-
verified attachment resolution. The existing five review regressions also pass.
Shared attachment import now retains failed partial files instead of deleting
them automatically, consistent with the owner preservation rule.

Still required before UI exposure: working-copy preparation for large camera
photos, retained-preview display, final receipt confirmation of this metadata,
authorization revalidation during processing, persistence-failure injection,
camera/Data Saver port and actual device QA. The new workflow is not yet called
from a screen. A ready preview marker alone is not final workflow completion.

Working-copy/confirmation follow-up: `ReceiptStitchService` now prepares bounded
PNG copies sequentially before the isolated matcher, with shared checkpoints
before writes. Its storage reservation includes working copies and output.
Source paths remain original paths in returned metadata and fallback. A
2400-by-3200 input test verifies reduction below 800,000 pixels, preserved aspect
ratio and unchanged original bytes. This is not yet device-memory profiling or
EXIF camera-orientation validation.

Confirmed receipt records now retain stitching metadata too. Atomic evidence
confirmation validates source identities/hashes and the scoped attachment
manifest before saving the reference with the receipt transaction. The recovery
test now confirms the review, closes/reopens SQLite again and recovers the same
preview from the confirmed record. Source order/hash changes make its active
preview unavailable. Three focused confirmation/recovery cases pass. Existing
legacy reviews without stitching metadata retain their prior validation path.

1. Inventory complete camera/native/OCR/parser dependency graph and record each
   extraction; preserve original files and other agents' changes.
2. Copy/adapt useful capture and preview UI; implement consistent image-space
   ghost geometry for previous and next sections, including middle retakes.
3. Integrate real multi-photo registration, composition and OCR handoff. Test
   fifty identical purchase rows, repeated overlap patterns, rotation, perspective,
   missing overlap, missing middle, out-of-order/duplicate photos and seam text.
4. Persist edits, original media, order, capture progress, processing state and
   review in SQLite drafts. Reopen after process termination and prove retry does
   not create duplicate expenses. Do not retain only temporary picker paths.
5. Preserve Data Saver with explicit user choice, working-copy compression,
   source retention and demonstrated OCR quality/resource budgets.
6. Connect shared device capability policy without replacing the other agent's
   work; test cancellation, resource pressure, invalid files and native errors.
7. Extend the shared harness, run relevant regressions/builds, and exercise real
   images and actual S24 UI. Do not replace or uninstall the existing phone app
   to bypass a signing mismatch. iOS requires separate platform evidence.
8. Review responsive preview, accessible controls and entire capture-to-expense
   flow visually. Passing policy tests do not establish visual acceptance.

No port-completion, stitch-quality, device-QA or release-readiness claim is made.

September 19 actual Windows UI checkpoint:
- Receipt review now exposes explicit Combine receipt sections for 2–8 ordered
  photos, retained combined preview/original switching, and recoverable retry.
  Permission and source revision are rechecked through the UI callback.
- Windows debug build passed. Both receipt_evidence_draft_recovery_test cases
  passed, including tapping Combine with unavailable capabilities and retaining
  both originals. The prior two SQLite composition/recovery cases passed.
- Used the running Windows app through its real native file picker to import
  section_0.png and section_400.png from receipt_auto_test_fa357bbf. These are
  generated test receipts, not real camera photographs or OCR accuracy evidence.
- Closed UI Lab normally and launched the rebuilt executable. Expenses showed
  one retained draft with two images; reopening recovered both original previews.
- The rebuilt review visibly exposes Combine. Clicking it showed a retryable
  failure and retained both originals. No expense was finalized.
- Windows has no app.device_capabilities/readRuntimeCapabilities bridge under
  windows/. Shared admission cannot establish storage availability on this host.
  Preserve the admission safeguard; coordinate the separately owned platform
  capability implementation. Do not characterize this as successful UI stitching.
- Error wording currently hides the actionable admission reason behind a generic
  processing message. Persist/display a safe typed reason as a follow-up.
- Visual finding at the observed 1268x714 window: ordering takes roughly half
  the review width while the receipt occupies a narrow strip; reading controls
  continue below the fold. Compact preview layout remains unfinished.
- Camera, ghost overlay, Data Saver, combined-image OCR handoff, responsive width
  sweep and S24 real-camera QA remain outstanding. No completion claim.

Resource refusal follow-up: known shared-admission reasons now persist as safe
reason codes in the SQLite stitching draft. Retry guidance distinguishes unknown
storage/capabilities, insufficient storage, memory, heat and battery. Raw exception
text is never persisted/displayed. The review renders this guidance after recovery.
Three stitching-draft tests pass, including failed admission followed by SQLite
close/reopen, retained reason and byte-for-byte preserved originals. Windows
capability bridging is still a separate unfinished integration; this change does
not bypass it. The newly changed wording has not yet been visually rechecked in
a rebuilt executable.

Android camera extraction checkpoint:
- Read-only reuse assessment found the existing CameraX activity and 22 helper
  files reusable without Hive; Flutter's service contract also pulls in old
  capability/cloud/pack policy that should not replace UI Lab shared services.
- Copied/adapted 23 Kotlin files and camera icon resources into UI Lab only,
  recorded source hashes in receipt_native_camera_source_manifest.json, and
  added the source project's CameraX 1.5.0 dependencies.
- Fixed ghost CENTER_CROP to FIT_CENTER, bounded source decode to roughly one
  million pixels, recycled intermediate orientation/crop bitmaps, and made the
  previous bottom strip use the same requested height as the next top strip.
  The old .80 start plus .34 height truncated one side to .20.
- Removed four automatic capture-file deletion calls. New captures use filesDir
  rather than disposable cache. Added per-capture free-storage reserve admission,
  section count guard, and recoverable output-directory failure handling.
- Activity is deliberately not yet registered/launched: request-bound native
  SQLite journaling, shared capability admission, permissions, result recovery,
  retake context, and Flutter gateway connection must be integrated next.
  Existing image-picker capture still operates. No camera-completion claim.
- Full APK attempt failed on locked generated assets. Direct compilation then
  met another generated-directory lock. Added optional Gradle qaBuildRoot to
  use a fresh output directory without deleting the old one. Full Flutter step
  there reported a localization-directory access failure. Native-only compile:
  gradlew :app:compileDebugKotlin -x :app:compileFlutterBuildDebug
  -PqaBuildRoot=<UI Lab>/build/receipt-camera-qa-20260919 passed (144 tasks).
  This proves Kotlin compilation, not APK packaging or phone behavior.
- All 23 original native-source hashes match. Native ghost visual/regression
  tests and runtime camera verification remain required.
