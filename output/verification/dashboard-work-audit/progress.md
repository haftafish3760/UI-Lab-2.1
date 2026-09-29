# Dashboard and Work verification — active

Owner authorization: September 24, 2026. Preserve overall UI; subtle polish and useful widescreen improvements. No Expenses implementation, Maintenance, Inventory, customer portal, payment processing, broad security scan, or skills-based scheduling. No messages sent. Launch for owner review only when requested; device QA remains authorized.

## Evidence
- GitHub integration: fast-forward d6fb427 to e59c128 in the original checkout; local generated PDFs/assets retained. Merge success is not build/runtime acceptance.
- Audit found approval recording incorrectly gated by signature permission.
- Audit found estimate access selected using development presets; calendar-day estimate detail has an empty create-job callback. Both require correction.

## Acceptance coverage (not yet verified)
- Dashboard: Today’s plan / Today’s entries together; conditional actionable alerts; owner field and admin views; employee day/break/time history; permission-aware counts and actions.
- Work: all list/detail/create/edit/reopen/delete paths; customer/company data; estimates, quotes, jobs, invoices, manual payments and deposits; expense link integration.
- Scheduling: explicit schedule/assignment, working availability, conflicts, first available suggestions, reschedule/cancel and date/time boundaries. No employee skill requirement.
- Approvals: documented methods independent of signature capture, revision binding, revocation after material edits, authorization at action and persistence boundaries.
- Recovery: durable partial drafts on interruption; title/customer/date naming and modification timestamps; Back goes one step with save/discard/keep editing; no unchanged-form prompts; iOS gesture and Android Back verification.
- Documents: distinct professional templates and logo slots; overflow/page breaks; issued revision snapshots; local PDF generation and native share sheet without sending.
- UI: existing composition retained; consistent compact sections and visible plain-language controls; bounded adaptive widescreen layout; light/dark, large text, focus/keyboard and accessibility.
- Business card: company contact QR, no portal.

## Test data
No device records created in this pass yet. Isolated database tests use temporary harnesses. Record IDs of any device fixtures here and remove only those fixtures after testing.

## Open limits
This is an active audit, not a release-readiness claim. Production employee permission provisioning and authenticated session wiring require investigation; current UI Lab bootstrap explicitly uses demo authority.

## First bounded fixes
- Added independent, default-deny runtime grants for recording customer approval and collecting signatures. Enforced added approval and current-signature writes in the Work session; signature draft opening/recovery also checks capture authority. Approved billable job additions require approval-recording authority.
- Estimate detail uses separate controls and action checks for documented approval versus in-person signature.
- Replaced calendar-day estimate's empty create-job callback with the existing job editor/conversion flow.
- Focused tests: 13 passed (permission combinations, UI controls, database reopen, approval/job/addition/invoice handoff, action recovery). Calendar-day create-job route: 1 passed.
- Broader baseline: 42 passed / 8 failed. Several tests still target removed FABs/old item controls or omit the required operations scope; assignment test expects a former Technician dropdown. Investigate and update behavior-based coverage, not simply suppress failures.
- Full analysis: 37 warnings/info, no errors; mostly incoming receipt/catalog/device code. Leave other agent's subsystem implementation untouched. Focused changed-file analysis separately recorded in /tmp/dashboard-work-focused-analysis.log.
- Flutter resolved four lockfile versions to the installed SDK's dependency constraints (intl, matcher, test_api, vector_math). This lockfile delta is explicit and retained pending platform builds.
- No app launch/install or device data changes in this slice.

## Next findings to resolve
- Primary estimate/invoice Back currently flushes and exits without the requested Save draft / Discard / Keep editing choice. Invoice's custom PopScope also lacks the shared iOS edge-back policy.
- Draft catalog uses Untitled rather than customer fallback; modification time already exists, creation time presentation needs checking.
- Day screen permissions still derive from view presets; employee configured flags are explicitly not connected authentication authority. Must connect/derive safely instead of promoting UI role labels.
- Scheduling currently reschedules fixed duration, with no discovered real availability/conflict suggestions. Investigate actual employee availability and all save paths before implementation.

## Draft navigation slice
- Estimate, invoice, and job editors now compare current typed input with their entry baseline. Changed forms ask Save draft / Discard changes / Keep editing; automatic incremental persistence remains active for interruptions.
- Invoice editor now uses shared Back handling, including guarded iOS leading-edge gestures. Save failures keep the editor open and permit retry; explicit discard affects the draft, not committed records.
- Primary recovery titles now fall back to customer names for unnamed estimate/invoice/job input.
- Tests: 11 passed for shared exit choices plus real estimate/invoice database recovery and primary recovery; 7 passed for job recovery, customer-name fallback, primary recovery, and calendar-day job navigation. These include simulated iOS gesture behavior, not physical iPhone acceptance.
- Focused analysis: seven changed targets clean (/tmp/primary-draft-analysis.log).
- Mac debug build passed after estimate/invoice changes; incremental build covering job changes is tracked at /tmp/dashboard-work-mac-build.log. No launch or installation performed.
- Corrected two remaining Dashboard labels from Company work today to Today’s plan, as explicitly requested.

Still unresolved: draft creation timestamps (schema currently stores only last update), preventing empty seeded recovery entries, restored-draft dirty baseline refinement, scheduling availability/conflicts, real employee permission provisioning, broad remaining workflow/visual/device coverage. Scope remains unchanged.

## Scheduling availability foundation
- Added shared booking-overlap/opening calculation for assigned employee IDs and vehicle; adjacent bookings allowed; excludes current job and completed jobs; respects explicit search windows and not-before time. No employee skills/capabilities.
- Added Find an opening to persisted job rescheduling. User chooses search dates and daily From/Until hours; default displayed search hours are 9 AM–5 PM, not claimed company working hours. Selecting a result fills the schedule form; it does not silently book or save.
- Results explicitly cover visible bookings only and ask the user to confirm working hours/travel. Missing duration or unresolved legacy employee assignments prevents a false availability result. This is NOT complete company-wide availability yet.
- Corrected scheduling day-end calculation to next civil midnight rather than 24 elapsed hours across clock changes.
- Ten tests passed: resource conflicts, chained overlaps, boundary adjacency, vehicle sharing, excluding current job, overnight bookings, incomplete data, small-screen 1.6x light/dark selection, and schedule recovery/save retry. Focused analyzer clean.
- Platform build log: /tmp/scheduling-mac-build.log (must inspect final result before claiming built). No device data created and no launch.
- Current Work pass adds a saved 0/15/30/60/120-minute minimum gap (30-minute new-job default), company-wide local booking lookup for opening suggestions, and transaction-time conflict rejection for create/reschedule/manual schedule changes. Hidden job details stay out of the picker. Focused tests cover minimum gap and a hidden creator's booking. Still required: saved working hours/time off, multi-device reconciliation, reschedule duration editing, richer job phases, permission-source integration, and physical-device validation. Do not present this as complete scheduling optimization.
- Item revision audit found that rebuilding a Job after changing items dropped its saved crew IDs, purchase-order number and new schedule gap. The revision now carries those fields forward; a regression test covers crew, vehicle and gap.
- Cross-workflow checks: estimate→job→invoice handoff, job conversion, payments, Work persistence and schedule screen passed in a focused run. The two invoice SQLite-action tests used an empty invoice that the current issue action correctly rejects; a valid item fixture restores both success/failure tests. Three older job-material billing/UI tests remain failing for reasons outside this scheduling change; their totals and widget selectors need separate investigation.
- Latest Android debug APK was built and installed with replace-in-place on connected SM-S938U, then launched as com.tameyourbiz.app. The device is currently locked, so rendered Work QA has not been performed on this new slice. Later code changes require another build before calling the phone installation latest.
- New Job now offers the same "Find an opening" search as rescheduling, using its selected crew, vehicle, expected duration and saved gap. Selecting an opening fills start/end; save still rechecks the complete local company schedule. A new APK including this and the item-field preservation fix built successfully, but S25 wireless ADB went offline during install. This newer build is NOT installed. The earlier install/launch statement above applies only to the preceding source state.
- Broader `test/job* test/work*` run: 171 passed, 42 failed. The scheduling recovery widget test failed because the added gap control moved Save below the 800×600 viewport; updating the test to scroll to the button restored its pass. Other failures include stale route/widget expectations, legacy draft payload equality, job-material billing, and native-widget timing. These remain unresolved; broad Work QA does not pass. Logs: `/tmp/work-regression-20260925.log`, `/tmp/schedule-recovery-isolated.log`.

## Scheduling authority and company contact card
- Added canScheduleJobs (default deny; explicit demo-owner grant). Schedule creation/change validates permission and start/end order inside the commit transaction. Job schedule open/recovery/confirm and job action buttons enforce it separately from ordinary notes/status actions.
- Eight focused scheduling/creation/handoff tests passed, including denied direct reschedule writes with allowed notes and invalid end-time rejection. Focused analyzer clean.
- Added offline vCard company contact QR at the bottom of Company profile, alongside saved logo. Address is opt-in per display. Internal IDs, payment terms and local logo paths are excluded. Uses vCard 3.0 syntax for contact exchange; reference https://www.rfc-editor.org/rfc/rfc2426 (format specification, not proof of scanner compatibility).
- Removed customer-portal routes from document delivery choices per release-one scope. Existing dormant portal implementation/data retained.
- Four contact tests passed: escaping, UTF-8 folding, address opt-in, 320 LP / 1.6x text light/dark layout. Physical scanner/import behavior remains unverified. Logo is displayed alongside QR, not encoded as a contact photo.
- Existing estimate_delivery_draft_recovery_test fails on exact expected native-sharing-error wording despite recorded preparation; investigate actual failure before accepting sharing flow. No messages sent.
- Mac build log for current slice: /tmp/company-contact-mac-build.log; inspect result before claiming built. No launches or device test entries.
- Pending owner question: individual-phone employee invitations, shared device, or both. Firebase sign-in adapter exists, but Work bootstrap remains explicit demo authority with no membership-to-permission integration. Continue independent workflow work while awaiting answer.
- Current Mac debug build passed (/tmp/company-contact-mac-build.log); app not launched.
- Delivery-test investigation: text-message composition now deliberately raises the specific missing-recipient-composer message on the test host. Updated obsolete generic-error expectation while retaining its assertions for durable preparation, retry without duplicate delivery, and no claim of sending. Rerun result in /tmp/delivery-retry-regression.log.

## Owner clarification and S25 deployment
- Owner confirmed employee invitations for their own phones are required, particularly for small businesses. Shared-device support was not resolved by that answer.
- Built current Android debug APK successfully (/tmp/dashboard-work-s25-build.log), installed with adb install -r on verified SM-S938U wireless transport 3451, and launched the installed activity; foreground activity verified. No uninstall or data clearing. This proves installation/launch, not workflow acceptance or complete data integrity.
- Stopped the task Gradle daemon after build; no GradleDaemon or KotlinCompileDaemon process remained.

## Dashboard daily lane
- Today’s entries now follows Today’s plan in the same rendered lane whenever both widgets are selected. Single-widget visibility and existing customize/remove controls remain available. No broad redesign.
- Twelve dashboard regression tests passed, including measured same-column placement at 320, 390, 844, 1440 and 2000 logical pixels with 1x and 2x text. Log: /tmp/dashboard-plan-entries-test.log. This newer layout change is not in the S25 build installed earlier; physical visual acceptance remains pending.

## Owner device walkthrough findings — pending fixes
- Jobs entry must clearly offer creation from an existing estimate, with approved scope carried into the job. New shared JobStartScreen is in progress, not tested or installed yet.
- On S24 Build shelf estimate: owner reports Customer approval is buried at the bottom and tapping it does not open a way to record approval. Must inspect actual route/view permissions and move the actionable approval control into the main workflow; do not count a read-only status section as an approval action. Not yet resolved.
- Owner located Build shelf on S24. Read-only inspection copies of both device databases passed SQLite quick_check; S24 contains Estimate 97372 titled Build shelf and customer John Smith; no matching shelf record or John Smith customer found in S25 snapshot. No device records changed or deleted.
- Owner wants installation notification and can open the app themselves; do not automatically launch following future installs unless requested.

## Estimate editor approval correction in progress
- Owner clarified: compact bottom approval action alongside Preview/Save; add Close with save/discard handling; plain approval status, no revision explanation card. Removed the inert Customer approval overview card.
- Added bottom Close and Not approved — Add approval / Approved — View approval controls. Approval saves the current revision, opens existing detail/approval flow, and returns the latest persisted record. Current approval label uses the pending document state so material edits do not claim old approval.
- New native-SQLite widget flow passes: editor action -> approval dialog -> verbal approval -> database reopen with matching approved revision. Five existing permission-controls/editor-recovery tests also pass. Logs /tmp/estimate-editor-approval-entry.log and /tmp/approval-entry-tests.log. Device interaction still pending.
- Prior S24 APK installed with replace-in-place and opened successfully (/tmp/dashboard-work-s24-build.log). That build includes daily-lane and JobStart changes but predates these approval/Close controls. Gradle stopped, no Gradle/Kotlin daemon remaining at that time.

- Latest approval/Close APK built (/tmp/s24-approval-controls-build.log) and installed successfully with adb install -r on S24 USB transport 3192. No clearing/uninstall. Owner can open it; no new launch/navigation performed after this installation. New JobStart estimate-to-job route test passed (/tmp/job-start-estimate-test.log). Build daemons stopped and absent. Full physical workflow testing remains outstanding; this is not completion.

## Additional owner requirements from live walkthrough
- Owner explicitly classifies New estimate and Jobs/Scheduling/Quotes/Invoices workspaces as needing persistent bottom navigation, left hamburger and right page-specific settings. Investigate shared shell routing and draft guards before implementation; no one-off duplicate navigation bars.
- Customer approval must be clearly actionable, permission-gated and open approval/signature choices. Latest compact bottom-action wording/status request remains applicable.
- Small-company users with limited technology experience are the usability target. Subscription figures mentioned were tentative, not approved pricing.
- Owner uninstalled apps from S24 to remove duplicate launcher confusion. Before reinstall, adb pm list packages showed com.tameyourbiz.app absent; older com.maintainiac.ui_lab_2_1 and other historical packages remained. Did not uninstall any other packages. Reinstalled latest APK and launched exact com.tameyourbiz.app activity; screenshot /tmp/s24-reinstalled-latest.png verified Work screen.
- Before owner uninstall, inspection copies of SQLite main/WAL from both phones were saved at /var/folders/fy/sx7cyjf905g817cbs548x3y40000gn/T/company-draft-readonly-l3pf7qh0. These are database inspection copies, NOT a complete backup of attachments. No restore performed. Do not claim uninstall preserved prior records.

## Shared shell and action-wrapper correction (not installed)
- Added independent Dashboard/Work nested navigation inside the shared shell, preserving bottom/rail navigation and parked module routes. Android Back asks the active nested route to handle its guard before changing modules. Root Dashboard retains normal root Back handling through navigation notifications.
- Five shell tests passed, including real Work -> Estimates -> New estimate routes, visible bottom navigation, Android Back one route, and module switch/return. /tmp/shared-shell-navigation-test.log. Dirty-form exit in this shell and physical gestures still need explicit verification.
- Owner clarified the Manage this estimate issue was the enclosing container/padding, not equal button widths. Removed blue SectionCard wrapper and reverted the just-created equal-width grid; natural-width Wrap remains. Shortened Create and assign job to Create job; removed redundant introductory paragraph. Six approval/conversion/editor tests passed /tmp/estimate-unwrapped-actions-tests.log.
- Header hamburger and contextual settings wiring still pending; do not claim the complete navigation request fulfilled.

## Owner correction — estimate editor footer, 2026-09-25
- Owner supplied S24 screenshot showing the fixed footer consuming three rows.
- Keep Close, Preview, and Save estimate together in one compact bottom action row.
- Remove icons from these footer action buttons to leave more space for labels on smaller screens. Preserve readable text and accessible touch targets.
- Customer approval belongs in a compact tappable section at the end of the scrollable form, rather than taking a separate fixed footer row.
- This entry records the requested layout; no implementation or device verification of this correction has occurred yet.

## September 25 — estimate approval and review repair in progress
- Built current source and installed successfully on S25 Ultra SM-S938U at 192.168.1.142:35493 before the walkthrough. That baseline build predates the repairs below.
- Confirmed live editor footer consumes three rows; observed editor, Work, Estimates and Drafts via device UI tree. Did not approve or sign the owner's records.
- Source now places approval last in the form and removes footer icons; approval pushes a full-screen route directly and returns to the same editor with a renewed recovery session.
- Full-screen approval offers the existing actual signature capture separately from recorded verbal/message/email approval. Review now includes prices and supports three shared layout lanes on wide screens.
- Six focused approval/permission/signature recovery tests pass, including cancellation/return, persisted verbal approval, handwriting recovery and atomic save-failure retry. Physical signing, rendered updated build, wide-screen and iOS acceptance remain pending.
- Owner clarified more-work and renewed quote approval after ANY price change. Unapproved-quote-to-job behavior is awaiting an answer; remote signing links deferred. Quotes are still not connected. No claim of complete Work QA.

## September 25 — repaired build installed and checked on S25
- Final APK built successfully in 21.7 seconds (`/tmp/estimate-final-build.log`), installed with `adb install -r` reporting Success, and launched the exact `com.tameyourbiz.app` activity on verified SM-S938U. No uninstall or app-data clearing.
- Physical UI evidence confirms Close / Preview / Save estimate share one text-only footer row. Approval is the final scrollable section. Android Back from approval returns to the same estimate with identical Terms, Approval and footer bounds before/after (`/tmp/s25-final-before-approval.xml`, `/tmp/s25-final-after-approval.xml`). Preview Back also returned to that editor.
- Inspected the full-screen signing review and scrolled to the actual signature pad, consent and save control (`/tmp/s25-sign-review.png`, `/tmp/s25-sign-pad.png`). No signature, approval or message was sent for the owner's customer. Discarded the empty unfinished signature opened during inspection; saved estimate unchanged by that discard.
- Two database-backed editor entry tests pass: verbal approval and actual drawn signature both return to the same editable estimate; saved approval/signature checked after database reopen (`/tmp/estimate-sign-entry-tests.log`). The earlier expanded suite had 19 passing tests, and seven responsive layout tests passed at phone/wide widths and 1x/2x text. Focused analysis clean; full analysis still reports unrelated existing issues.
- The PDF preview is still a full printed page on the phone, with small text. Asked owner whether Preview should default to a readable sectional view with View PDF, or retain PDF-first with improved controls. No default preview redesign pending that answer.
- Three-lane wide estimate review is widget-tested, not yet accepted in a live desktop walkthrough. iOS physical gestures, Quotes, additional-work changes, scheduling and payment association remain outstanding. This is not full Work acceptance.
- Gradle daemon stopped after the final build; process inspection found no GradleDaemon or KotlinCompileDaemon remaining.

## September 25 — Work scheduling, signing, and estimate terminology follow-up
- Company-wide locally saved Job bookings now drive Find an opening in both New Job and Reschedule. A selectable minimum gap (0/15/30/60/120 minutes; 30-minute new-job default) is saved with each job. Same-employee/vehicle overlaps and too-close bookings are rejected again inside the save transaction. Old records default to zero gap. This is local booking safety, not an optimizer for travel, skills, time off, or multiple unsynced phones.
- An item-revision path now retains existing employee assignments, vehicle, purchase-order number, and schedule gap. Focused booking/permission/estimate-signature tests passed; the broader Job/Work suite still has unrelated and stale-route failures, so full Work QA is not passing.
- In-person estimate signing now requires an explicit Tap to sign step that reveals a bounded pad, then a revision-specific acceptance checkbox; the stroke remains thin. The signature draft/recovery, failed-save retry, and return-to-editor tests passed. Estimate review lists work, prices, adjustments, total, and terms.
- The Estimate editor no longer offers the misleading Flat rate pricing choice; new Estimates default to the existing time-and-materials model internally, while already saved pricing data is preserved. A linked Job calls the estimate price an estimated cost. Quote requirements confirmed by the owner are in the Work lifecycle blueprint; quote workflow remains unconnected.
- The latest Android debug APK (`/tmp/work-final-build.log`) built, installed with `adb install -r`, and launched `com.tameyourbiz.app` on verified SM-S938U. The device remained locked with NotificationShade in focus; no rendered QA of this latest APK was possible. No uninstall or data clearing occurred. Task Gradle daemon was stopped.
- Outstanding product choices: how to treat scheduled Jobs without an assigned person/vehicle, and whether an unapproved Quote may become a scheduled Job. Preview presentation remains awaiting owner preference. Do not claim remote signing, Quotes, or complete Work acceptance.
- Additional recovery test repairs: estimate action Back now uses the current full-screen signing AppBar control; saved estimate item recovery expects the current Save progress path and updated item labels; nested invoice item recovery follows the explicit Save unfinished item and Save draft prompts. Each isolated regression passed (`/tmp/estimate-action-regression-2.log`, `/tmp/estimate-item-regression-4.log`, `/tmp/invoice-item-regression-6.log`). These fixes restore coverage but do not resolve all broad-suite failures.
- Final combined focused run: 23 tests passed across booking conflicts/permissions, estimate save and approval, in-person signing recovery, estimate item recovery, and invoice nested-item recovery (`/tmp/work-final-focused-tests.log`). Focused analysis of seven changed scheduling/signing/editor source files found no issues. Broad Work regression and physical latest-APK acceptance remain unfinished.

## September 25 continuation — remote, navigation, Mac, and estimate lifecycle
- `git fetch origin --prune` succeeded. The checked-out branch and its upstream are 0 ahead/0 behind; no new Windows/GitHub commit is available to integrate. The dirty local Work/Dashboard changes remain untouched.
- Android Back, iOS leading-edge draft swipe, nested estimate-item exit, and shared-shell routing tests passed together (`/tmp/work-back-navigation-regression.log`, 15 tests). This does not prove physical iOS gesture behavior.
- Current macOS debug app built successfully (`/tmp/work-current-macos-build.log`). An older Mac app process remains running, so the newly built binary has not been launched or visually accepted on Mac; no computer screenshot was taken.
- Dashboard/estimate/opening-picker widget layout suite passed at narrow/wide logical widths and 1x/2x text (`/tmp/dashboard-work-layout-current.log`, 21 tests). Rendered Mac acceptance still pending.
- Updated outdated estimate lifecycle tests to the current direct action row, guarded PDF preview, Work drafts route, company review scope, and customer Work history. The complete estimate lifecycle test file now passes 19 tests (`/tmp/estimate-lifecycle-final.log`). No customer document was sent.
- S25 Ultra is ADB-connected and identified as SM-S938U, but remains locked with NotificationShade focused. S24 Ultra is absent from `adb devices -l`. Physical Work walkthrough on both requested phones remains unverified.

## September 25 continuation — payment truth and broad Work regression
- Dashboard, Payments and Invoice detail now calculate remaining balance from recorded payments linked by either the invoice's stable ID or displayed number. The report projection likewise shows the remaining amount, rather than the full total, for partially paid outstanding/overdue invoices and excludes payments after the selected as-of date.
- The in-memory payment path rejects duplicate IDs, invalid invoice references, nonpositive payments and overpayment; the payment picker uses remaining balance as the source of truth even if a saved status is stale. Focused analysis is clean; report, payment, draft-recovery and SQLite-action tests pass.
- A 123-file broad Work-related test invocation reached 315 passes and 49 failures. It included standalone `_part.dart` files that must not be run directly. Other failures include outdated assertions for the removed estimate action FAB and the now-connected Scheduling route; they are not evidence of those old UI designs returning. The responsive Work test now passes all 15 cases, the estimate local-pane test was updated to supply its required store scope, and the startup persistence test now creates its own records rather than assuming demo seed data. Remaining failures require separate triage; full Work regression is **not** green.
- This source is newer than the installed S25 APK and earlier Mac build. No current-source device build, installation or rendered acceptance has been claimed for this continuation.
- Subsequently built the current Android source successfully (`/tmp/work-current-android-build.log`), installed it with `adb install -r` on verified SM-S938U, and launched the package-resolved activity `com.tameyourbiz.app/com.maintainiac.ui_lab_2_1.MainActivity`. The first attempted launch with `.MainActivity` failed because the manifest activity is in a different namespace; the resolved launch command succeeded. The phone remained locked with NotificationShade focused, so no screen rendering or workflow acceptance was observed. Stopped the task Gradle daemon and confirmed no Gradle/Kotlin daemon remains.
- Focused Work landing, estimate local-pane, payment, and startup SQLite persistence tests pass after the current changes. The broad suite still requires triage and a rerun without standalone `_part.dart` support files.
- Current macOS debug source also built successfully (`/tmp/work-payment-macos-build.log`). The previously running older Mac app was not interrupted, and this build has not been launched or visually accepted.
- Serialized broad Work regression (excluding standalone `_part.dart` helpers) completed with 336 passing and 23 failing tests (`/tmp/work-audit-serial-tests.log`). After that run, focused reruns passed for three stale-harness/route groups: Job detail ownership, Job contact accessibility, and the New Job chooser; the estimate unfinished labor/material recovery test now handles the explicit Save draft exit and both cases pass. The broad result predates these test repairs and remains red. The editor recovery handoff failure reproduced in isolation and is still unresolved.

## September 25 safe-stop checkpoint
- The owner clarified that a safe stopping point should be reported. No new feature work was begun after that direction. The current job line-item recovery test expects older item labels and remains an unresolved regression; an incomplete attempted test update was reverted, leaving no partial edit to that test.
- Focused analysis of nine payment/report/editor source files passed with no issues. `git diff --check` passed. A 31-test repaired focused run passed (`/tmp/work-audit-repaired-tests.log`), alongside isolated estimate/job route and recovery reruns noted above. The complete Work regression has **not** passed; the last serialized broad result was 336 passed, 23 failed, before several focused test repairs.
- The latest Android APK built successfully (`/tmp/work-safe-stop-android-build.log`), installed via `adb install -r`, and launched on verified S25 Ultra SM-S938U with `com.tameyourbiz.app` in foreground. The phone was unlocked at this last check. No fresh screen-by-screen walkthrough, visual layout acceptance, or signing test was performed on this build. The S24 was absent. The Mac process running an older build was not interrupted, so the new Mac build was not visually reviewed.
- Outstanding substantive scope includes broad Work regression failures, full device walkthrough, Jobs/Scheduling and Quote/Invoice lifecycle completion, navigation/layout polish, permission and cross-device enforcement, and remote customer signing. This is a safe pause in a much larger unfinished objective, not completion.

## September 25 continuation — job recovery and Work home
- The unfinished nested Job item recovery test now follows the current Save unfinished item / Save draft choices and field labels. It passes through database close/reopen, resumes the same unfinished item, completes it, and confirms no premature Job record (`/tmp/job-item-recovery-updated.log`). This was test restoration around the existing guarded UI, not new runtime acceptance.
- Work home's Plan and Entries rows now have stable identity keys and more compact spacing while retaining customer, work title, document number, status, time, and assignee. The five Work home regression tests pass at phone and wide logical widths; the restored exact-row test opens the matching Job and Invoice (`/tmp/work-home-and-job-recovery.log`). Physical layout still needs inspection. The normal phone row target in `operations_screen_blueprint.md` is 56–60 LP; current rows remain taller for multiline content, so this is improvement but not final visual acceptance.
- Nine Job material/billing tests pass together (`/tmp/job-material-final.log`). Their prior failures included stale labels and a fixture that could not persist customer-approved additions. The updated receipt-line test uses disposable SQLite-backed Work records, records synthetic verbal approval, and verifies exact expense-line provenance and unchanged source Estimate. Unapproved additions stay out of invoice candidates; an approved addition enters the Invoice draft. The existing popup used to record extra-work approval still needs the owner's requested full-screen, readable review treatment.
- `test/work_editor_recovery_handoff_test.dart` remains red in isolation: the helper's bounded wait does not observe `session.flush()` finishing after an edited title. The editor had published the changed title into the draft session during diagnostic inspection, but the storage/handoff wait is unresolved. Temporary diagnostic edits were removed from that test.

## September 26 — Record payment local verification
- The direct payment entry uses a labeled line-form layout. Empty Save now reports the missing amount before attempting draft confirmation. Failed Discard stays on the form with its input. A recovered draft that fails the current access check closes its open session.
- Focused widget and SQLite tests passed: a payment without an invoice saves and opens from Payments; it survives database reopen; an unfinished payment survives Back, reopens with its entered amount and description, and the visible Discard action removes it without recording money; a second confirmation cannot record the same payment twice. A wide dark-mode form at 1.8× text also passed without a framework layout exception. This is automated evidence, not visual acceptance.
- Focused `flutter analyze` passed. The Android storage-QA debug APK built successfully after the production-code changes. The task-owned Gradle daemon was stopped and verified absent.
- S24 Ultra was absent from `adb devices -l`, so the latest QA APK was not installed or physically checked there. Earlier isolated S24 QA navigation may have left an agent-created unfinished payment draft in `com.maintainiac.ui_lab_2_1.storageqa`; its exact presence and cleanup remain unverified until that device reconnects. Do not touch the S25 main app to resolve this QA state.
- The reported S25 Samsung keyboard symptom was not reproduced or fixed. No commit or push was made. Record payment remains open for physical review and QA-data cleanup before claiming end-to-end acceptance.
- Payments previously showed its Record payment control from a screen-level development grant even when the active saved Work session denied payment recording. The control and tap handler now require the session's actual `canRecordPayments` grant. A view-only session can still open Payments without seeing the action; a permitted session retains it. The save layer's grant check remains in force.
- Updated the invoice-payment picker regression to run against disposable SQLite-backed Work records and native-save waits. Twelve focused payment/access tests passed together; focused analysis and the storage-QA Android debug build passed. The daemon was stopped, `git diff --check` was clean, and S24 remained absent from ADB. This is still not physical workflow acceptance.
- An invalid Save message on the long direct-payment form is now shown immediately in a SnackBar as well as retained below the form, so the reason is visible without first scrolling to the form bottom. The focused flow and access tests and analyzer passed. Phone behavior with the Samsung keyboard remains unverified.
- Rebuilt the current storage-QA Android APK successfully. Android package inspection confirms `com.maintainiac.ui_lab_2_1.storageqa` and launcher label `Tame Your Biz QA`; it was not installed because only the S25 main phone was attached. Stopped the Gradle daemon and verified no task-owned Gradle/Kotlin worker remained. `git diff --check` passed.
- Earlier review found that the received-date pickers permitted future dates through 2100. The current source now defaults to today when Record payment starts from a future calendar day, limits both direct and invoice payment pickers to today or earlier, and rejects a recovered future received date at confirmation. This applies to those form workflows; it does not establish a separate promised/postdated-payment workflow or a repository-wide date rule.
- The payment form now distinguishes an unsaved local draft failure from a Work write failure when Save is retried, avoiding a stale Work error after the draft save fails. Capturing current input is inside the Save error boundary. Focused payment/recovery/access tests and source analysis passed. This source change is newer than the last QA APK and has not been installed on S24.
- A widget test now injects an SQLite failure into the direct-payment draft insert: entered amount/description remain on screen, Save creates no payment and reports the local draft failure, then Retry followed by Save records exactly the intended amount. Thirteen focused payment tests passed together and focused analysis was clean. This failure test used a disposable database only; no device data was changed.
- The current source (including the draft-failure message) built as a storage-QA Android debug APK. The Gradle daemon was stopped and verified absent; `git diff --check` passed. S24 remained disconnected, so this APK is built but neither installed nor physically accepted.
- Extended the 1280-LP, 1.8× text, dark-mode payment test through Save, the Payments list, and the saved payment detail screen. It passed without a framework layout exception. A broader 22-test payment run covering direct payment, invoice payment, recovery handoff, allocation and persistence passed; this remains automated layout/behavior evidence, not Mac rendered or S24 physical acceptance.
- September 26: fetched `origin` and confirmed this branch is 0 ahead/0 behind its upstream, with no Windows/GitHub commit to integrate. Four focused received-date cases passed, then a 26-test payment regression passed across direct and invoice drafts, access, persistence, recovery, and allocation. Focused analysis passed. These checks precede the final factory cleanup and do not constitute physical payment acceptance; S24 is still absent from ADB. No commit or push was made.
- Owner-requested Payments date parity: the Payments workspace now uses the same previous/next selected-date bar as Estimates and Invoices. Calendar selection and arrows update the payment list in place. The Payments day-arrow widget test passed.
- Owner-requested draft clarity: Estimate and Invoice workspace draft shortcuts are omitted when there are no authorized saved drafts or unfinished inputs; an input-load failure still exposes the route for retry. The filtered destination is titled `Estimate drafts` or `Invoice drafts`, and rows identify their document type, title, customer/number, and saved date. A disposable SQLite test verified an unfinished invoice input remains reachable before any invoice record exists. The initially hung widget test used a draft close that needed frame pumping; it was corrected to the existing bounded native-operation helper and passed. Focused Invoice/Estimate/Payments suite passed 47 tests, source/test analysis was clean, and `git diff --check` passed.
- Built the current normal Android debug APK and replaced the existing `com.tameyourbiz.app` install in place (`adb install -r` reported Success) on verified S25 Ultra SM-S938U. Launched its exact MainActivity; activity and window state both show it foreground. No app data clearing, screenshot, draft deletion, commit, or push occurred. The task-owned Gradle daemon was stopped and no Gradle/Kotlin daemon remained. This proves build/install/launch, not on-device inspection of the changed Payments and draft screens. S24 remains absent from ADB.

## September 27 — single estimate-form flow, current continuation
- Previous goal turn made source/test/build progress; this continuation added native-host and physical-device evidence. The broader Dashboard/Work objective remains active and unproven.
- New/Edit estimate now places Preview PDF, Review estimate, Save estimate and Close inside its scroll, with consistent tinted secondary buttons and primary Save. Photos is a bordered entry with Add photos inside. Subtotal, editable discount/tax and total share one Price summary; amounts align right. Estimate-section borders use an existing stronger theme color without changing other forms' default border.
- Estimate information puts the title first, labels Estimate number, and uses the in-field Description of work hint “Describe the work to be completed.” Existing review composition and persistence commands were retained.
- Final presentation regression: 18 widget tests passed; focused analyzer clean. Earlier estimate recovery/photo/approval/review coverage plus scrolling suite passed 34 distinct tests across runs. Ten native macOS integration cases passed using logical narrow/wide viewport overrides, light/dark, 1x/2x text, temporary SQLite recovery and failed-save retry. This is not manual Mac window visual acceptance.
- Latest Android debug APK built and installed in place on S24 Ultra SM-S928U / R5CX14WC8FA. Physical inspection verified form actions absent at the top and present after scrolling, Photos route opening, title/description placement, final borders, and right-aligned price values. Saved screenshots and logs are in estimate-form-2026-09-27/.
- On S24 created only a temporary estimate-editor draft named QA%SEstimate%SFlow%S0927, force-stopped/relaunched the app, recovered the same dated draft and exact entered title, then explicitly confirmed Discard input. Verified that named draft disappeared while pre-existing drafts remained. A second blank draft used for final layout inspection was explicitly discarded from its own editor after installation. No business estimate, customer, photo, signature, or payment was created, and no message was sent in this continuation.
- User-owned Google Drive is recorded as the intended optional estimate/job image backup destination. No OAuth setup, upload, restore, cloud permission deployment or verified-backup claim was made. Local storage and cloud backup remain separate. QuickBooks is excluded by latest direction.
- Android Gradle daemon stopped after build; no task-owned Gradle/Kotlin/build worker remained at the verification check. No commit/push and no protected 5.7 edits.
- Remaining: full estimate lifecycle device acceptance (including actual capture/signing/share/revision behavior), Mac visual review, actual Drive backup/restore and broader Work/Dashboard requirements. Other workflows were not started during this single-flow pass.
- Final cleanup check: Estimate drafts shows only the three pre-existing estimate drafts (Kitchen faucet replacement, and the September 27/September 25 untitled inputs). Fixed the observed recovery heading to “Continue your estimate draft”; three draft-shortcut tests passed and the final Android rebuild passed.
- Refreshed origin: current branch and upstream are 0 ahead / 0 behind at d54594f. No newer Windows/GitHub commits to integrate; all local changes were retained.

## September 27 — estimate photo management and local evidence recovery
- Stayed within the estimate flow. Added visible View photo and Edit photo details controls, a read-only in-app zoomable photo route using the shared retained-path preview, and explicit confirmation before unlinking a photo and its note from the estimate. Cancellation preserves attachment/details; confirmed unlinking never deletes the image file. No upload, compression, QuickBooks, expense/parser or other workflow changes.
- Twelve focused host regression cases passed for photo management, pending notes, native-media coordinator recovery, retained-path resolution and signature recovery. Six-item focused analysis clean; diff whitespace check clean.
- Eight native S24 QA cases passed: light/dark photo management at enlarged text, unfinished photo-note recovery, handwritten signature/consent recovery with failed-save atomicity and retry, and four independent approval/signature storage-authority combinations. Signature harness initially failed because its instantaneous synthetic drag produced no ink on Android; a timed gesture and explicit pre-navigation ink/consent assertions passed. No signature production logic was altered for this test fix.
- Tests used disposable SQLite and synthetic files, cleaned by the harness, in the separate STORAGE_QA package. This does not establish actual camera/gallery capture, external email/text delivery, deployed Firebase rules, production employee authentication, or Google Drive backup/restore. The broader goal remains unfinished.
- Final two native photo cases also passed after correcting the synthetic PNG chunk checksum and adding an explicit unavailable-image assertion. Normal Android debug build passed, installed in place on S24 R5CX14WC8FA with Success, and exact com.tameyourbiz.app MainActivity verified as top-resumed. No app data cleared and no normal-app records created in this pass. Source/test evidence is in estimate-evidence-2026-09-27/. This is build/install/launch plus isolated runtime coverage, not owner visual acceptance or full estimate lifecycle acceptance.
- Stopped the task Gradle daemon after Android work; subsequent process check found no Gradle/Kotlin daemon or active Flutter build/test worker. Existing unrelated working-tree changes preserved; no commit/push or protected-reference edits.

## September 27 — S24 integration-runner incident; prior preservation claim withdrawn
- Normal package com.tameyourbiz.app was absent after native PDF test work; adb pm list packages -u and dumpsys package both failed to find it. No further phone installation/restoration/testing was performed after discovery. Do not interpret earlier install/launch or green isolated tests as proof that normal-app records were preserved. The earlier statement “No app data cleared” was not adequately verified and is withdrawn as a preservation claim.
- Local Flutter source explains a likely cleanup path: integration_test_device.dart caches ApplicationPackage before startApp; Android startApp rebuilds/reloads its own builtPackage, but cleanup uses the original cached object. Test command defaults uninstall=true. A normal APK previously at app-debug.apk can therefore cause normal-package cleanup even when the newly built APK is STORAGE_QA. This is source-based causal evidence, not a captured historical adb uninstall trace. Exact lost record set and earliest affected run remain unknown.
- Recovery inspection: September 24 database+WAL inspection copies exist at /var/folders/fy/sx7cyjf905g817cbs548x3y40000gn/T/company-draft-readonly-l3pf7qh0/s24. A newer September 27 03:11 local-time copy exists at /var/folders/fy/sx7cyjf905g817cbs548x3y40000gn/T/s24-employees-readonly-cnl4qefo. Only duplicate copies were opened. Both quick_check results were ok. The newer copy contains 7 Work records and 2 estimate-editor drafts; it predates later observed estimate inputs. Neither is a complete verified attachment backup. Nothing restored or overwritten.
- Added tool/safe_android_integration.py: explicitly selected device, isolated prebuild, APK package verification, forced STORAGE_QA, --no-uninstall, and normal-package presence check after execution. Local safety tests cover package rejection, required flags/device and override rejection. Not yet device-validated; do not claim it guarantees all device data safety. Future device QA must use this guarded path, with no concurrent Android builds.
- Native PDF evidence before discovery: email chooser visibly offered Gmail/Outlook and the expected synthetic PDF attachment, then was dismissed without choosing a destination or sending. Exact attachment copied and rendered as a readable one-page estimate. Final isolated native test passed; 9 host delivery/export tests passed. Test data/audit confirmed unchanged source revision and unconfirmed external handoff. These successes do not offset the package-loss incident or prove the whole workflow. No template redesign or production app change in this continuation.
- Latest owner storage direction: backup off by default; consent belongs to the person using the device, separate from company access; explicit choice before removing a local backed-up copy; never reclaim existing files automatically; retain 100 MB threshold. Owner also proposed approval below threshold. Current implementation uses a hard 100 MiB admission reserve; threshold override is an unresolved product/safety decision, not implemented.

## September 28 — local safeguards follow-up
- Guarded Android runner now has eight passing local tests, including failed build and wrong APK preventing test execution, forced no-uninstall cleanup policy, and disappeared-normal-package reporting without automatic reinstall. Subprocesses were mocked; neither phone was changed. No device validation claim.
- Updated the authoritative backup contract with owner-explicit default-off, device-user guided consent and separately confirmed removal of verified local copies. Current StorageWriteAdmission is still not referenced by production writers; no claim of app-wide storage enforcement. Asked owner whether to retain the hard 100 MB reserve or allow a low-space override; no response or override implementation yet.

## September 28 — estimate photo storage call-path assessment
- Direct estimate photo retention calls WorkPersistenceSession.retainEstimatePhoto -> LocalAttachmentStore.retain. Recoverable native picker results call MediaPickerResultRetention.retain -> the same attachment store. Neither path currently invokes StorageWriteAdmission. Attachments are copied and hash/size verified before their SQL manifest is published; failed partial files are preserved. This is source inspection, not full-disk runtime proof.
- Multi-photo recovery gap: MediaPickerResultRetention checkpoints retainedAttachmentIds only after the entire batch. A failure after an earlier attachment commit leaves that file/manifest retained, while retry starts the source list again with fresh attachment IDs. Requires durable per-source idempotency and failure/restart tests; prechecking sizes alone will not solve it. Do not silently delete earlier retained files as a workaround.
- Current Android capability bridge reads filesDir volume capacity; StorageWriteAdmission requires the actual destination volume. A complete connection must cover relocated storage, copy scratch bytes, SQLite/WAL overhead and concurrent writes, not just a UI warning.
- Read-only 5.7 reuse assessment reconfirmed AppStorageGuard uses 50 MiB normal / 25 MiB text reserves; do not import those thresholds. Reuse the current admission abstraction and retention verification, adapting their production integration. No protected-reference edits, threshold override, device operation or attachment deletion in this assessment.

### September 28 — physical iPhone installation
- Owner requested iPhone SE third generation over USB, Profile build, no paid Apple enrollment; owner reported uninstalling old expired UI Lab QA copy.
- Existing Apple Development identity and team used through a temporary xcconfig, without changing project signing configuration. Profile build passed; codesign deep/strict verification passed; exact normal bundle com.tameyourbiz.app verified, provisioning expires 2026-10-05 06:15:45 UTC.
- devicectl installed Runner.app successfully on paired iPhone 328F18E6-DE9C-5995-8103-7F2518F05513. Launch rejected by iOS security with signature/entitlements/user-trust diagnostic; device-user developer trust is the next check. Installation proven; launch and rendered acceptance not proven. No device tests or agent uninstall performed. Logs /tmp/uilab-iphone-profile-build.log.

### September 28 — resumed Work workflow audit
- Owner confirmed Profile app launched on physical iPhone after trusting developer identity; Developer Mode already enabled. Device launch command succeeded. This is launch evidence, not full workflow acceptance.
- Current Work home has directory routes; Quotes explicitly remains disconnected. Estimate/Invoice workspaces remain date-first with all-date text search but lack the prominent all-date status destinations requested. Do not call status navigation completed.
- Estimate main/editor review actions already occur inside scrolling content. Found pinned actions still in Photos, Labor/materials, and Approval. Photos Save moved after photo rows within existing scroll; unchanged callback retains same draft and pending-note guards.
- Seven local photo/back tests passed, including 320-LP 1.8x light/dark photo preview, confirmed unlink preserving original bytes/restart, save action scrolling out of viewport, and back choices. Focused analysis clean. Profile iOS build currently running in session 72352; no device installation for this change yet.
- Remaining sequence: finish estimate secondary action placement and navigation; complete all-date status destinations and responsive Work/Invoice overview; connected scheduling and job transitions; then invoice/payment linkage. Permissions, persistence, localization, unit behavior, and physical narrow/wide evidence remain acceptance gates throughout, not assumed complete. No parser/Expenses implementation or template redesign authorized in this lane.

- Expanded footer correction to EstimateItemsScreen and EstimateApprovalScreen. No estimate-prefixed screen retains bottomNavigationBar/persistentFooterButtons. This source search does not cover shared child editors; those still require audit. Added long-list regression proving Labor Save is reached by scrolling and leaves viewport when returning to top. Fourteen item/approval tests passed; eight photo/signature/item tests passed in prior run; focused analysis of all five edited Dart files clean. Combined Profile build running session 21461; not installed.

## September 28 — Work landing record-scope prerequisite

- Revalidated Work landing/source routes and read the protected 5.7 invoice home read-only. Its sample-data-based implementation is not suitable for importing as the durable Work overview. No protected files changed.
- Added `workRecordIsVisible`: persisted Work landing records now intersect session visibility with stable actor/selected employee IDs. Technician presentation ignores stale employee selection. Assignment and admin presentation cannot bypass creator visibility. Legacy no-session presentation remains separate; this is not proof of complete permissions or cloud enforcement.
- Focused four visibility tests passed. Focused analysis of three Dart files passed. Combined visibility/Work suite: 21 passed, 5 failed. Failure evidence: `/tmp/work-visibility-tests.log`; failures concern estimate-to-job offscreen tap, preview delivery label, item-editor label, and two estimate-number layout assertions. These require investigation; broader regression is not green.
- No new build/install in this slice, consistent with batching meaningful workflow changes before device rounds. Overview cards and all-date status lists remain unfinished. Next: connect permission-scoped status queries and live lists to exact-record routes; resolve estimate regression evidence without changing the approved review design.
- Earlier combined estimate-footer Profile build and Mac debug build completed successfully; this does not prove device/rendered acceptance of the footer changes.

## September 28 — Work overview and all-date record navigation

- Added four horizontal, labeled overview actions under Work header: estimates awaiting customer, unscheduled jobs, active jobs, outstanding invoices. Counts derive from the same scoped record query used by the list, without the selected-day or hide-completed filter. No records created or seeded.
- Added live all-date list, customer/title/number search, and filters for all estimates/jobs/invoices plus approved/declined/expired estimates, completed jobs, paid/overdue invoices. Exact-record tap rechecks visibility against current store data. General module permission architecture remains incomplete as previously documented.
- Focused suite: 29 tests passed (`/tmp/work-overview-regression.log`). Includes 320 LP 2x text in light/dark, open-record identity, refresh after an in-memory test-store save, and scoped record regression. The five prior estimate failures were resolved by scrolling to controls, asserting current labels, and checking the actual title-to-number keyboard order. Analysis of seven files passed.
- Mac debug build succeeded before a final semantics-role and singular-record-label polish. Native AX inspection verified Work overview then Active jobs -> all-date 1-record list -> exact Job 2004, Casey Brooks, Scheduled heating inspection, September 16. No stored data changed. No computer screenshots captured, so no pixel-layout acceptance claimed. Final post-polish rebuild is pending session 50193 at this checkpoint.
- Still open: dates on all-date rows, additional status/payment classification tests, broader permission enforcement, window-size/visual verification and physical devices, full remaining document/job/payment flows, localization and detailed/summary presentation. Quotes remain last.

- Final post-polish Mac debug rebuild completed successfully (session 50193 exit 0). Running native inspection above predates only that final accessibility-role/plural-label polish; latest build not relaunched.

## September 28 — All-date context, status checks and physical S9 Plus

- Added relevant row dates (scheduled range, completed, invoice due, created; explicit missing-date text). Estimate expiry projection now accepts the reporting date; existing callers retain the current-date getter. Added separate company-review, ready-to-send, changes-requested and draft filters. Company pending review cannot appear ready for sending or customer approved.
- Date/status plus estimate lifecycle suite: 25 tests passed. Additional final Work/overview/status suite after inline-action correction: 29 passed. Tests cover partial/full settlement, overdue day boundary, unrelated job deposits, reporting-date expiry, company-review separation, and the longest dropdown option at 320 LP and 2x text in both themes.
- S9 Plus `344f575934553098`, model SM_G965U, Android 10, is now authorized. Pre-install normal package was absent; /data had 24,028,916 KiB available. Normal debug APK package and expected development certificate verified. `adb install -r` succeeded without uninstall/clear. Launch reported Status ok. Fresh Work overview reported zero records, and its awaiting-customer card opened All dates / 0 records with the empty-state message. This is Work UI evidence, not a full database clean-install audit.
- Physical hierarchy exposed Add work FAB covering the Invoices shortcut. Replaced it with a scrolling inline action below Work header for all widths, with regression assertion against floating actions. Corrected APK build pending session 52611 at this checkpoint. No screenshots or emulator used. Gradle/Kotlin workers from first build exited after Gradle stop; clean up again after correction build.

- Correction build completed, expected `com.tameyourbiz.app` and SHA-256 development signer reverified; S9 update via install -r succeeded and app launched Status ok. Current native hierarchy proves Add work is inline at [907,596][1392,788], separate from Invoices at [736,2128][1048,2295]. Tapping Invoices opened the Invoices workspace with zero saved invoice activity. This confirms control placement/hit target and routing through accessibility; no screenshot-based visual acceptance claimed. Device density override 640 on 1440 physical width corresponds to approximately 360 logical pixels.
- Final seven-file analysis clean. Gradle stop completed and final pgrep found no Gradle/Kotlin build workers. No uninstall, clear, device settings change, permission change or business-record creation occurred. Device hierarchy files a1–a6 retained in /data/local/tmp/uilab-work-overview-20260928-*.xml.
- Fresh Dashboard still displays legacy Transit 12 context and a demo advertisement label; this is a remaining app-wide fixture/identity gap, not evidence of saved Work records. iPhone and updated desktop visual/size checks remain outstanding.

## September 28 — Work primary/supporting desktop composition

- Shared layout model now supports an optional supporting-lane width; all existing equal-lane callers retain default behavior. Work uses a record area up to 760 LP and calendar up to 400 LP with 24 LP gap. Split depends on local width and shared text-scale penalty. Wide Work record rows put identity beside status/timing; narrow rows stack in the same reading order. Updated owning UI and operations rules to reconcile older equal-lane guidance with owner wide-screen feedback.
- Focused Work/layout/overview suite: 29 passed (`/tmp/work-adaptive-focused.log`). Additional real-row geometry test passed (`/tmp/work-row-composition.log`) at 390/1440 LP. Seven-file analysis clean. Mac debug build succeeded and was relaunched from an idle job-detail route. Native AX verified overview controls including button semantics. Fill and Move & Resize -> Left were exercised through native menu; Work remained readable to AX. Live pixel appearance and exact content LP were not captured; no computer screenshots. Do not call this complete visual/size acceptance.
- Broad operations layout suite is NOT green: failures include missing Expense 1/2/3-column keys and a DesktopAppNavigation ListView expectation. These have not been baseline-proven unrelated. Default equal-lane behavior has direct tests, but broader regression remains open; no Expense code changed.
- Latest desktop build includes this composition; S9 installed build predates it. iPhone update/testing, desktop precise-size/visual verification, and remaining Work workflows are still pending. No records modified during native checks.

## September 28 — current Work Profile build installed on iPhone

- Revalidated connected physical iPhone SE 3 (328F18E6-DE9C-5995-8103-7F2518F05513), existing com.tameyourbiz.app installation, branch and dirty tree. No simulator used.
- Current source built successfully with flutter build ios --profile --no-pub using existing temporary Signing.xcconfig; Xcode build 43 seconds, Runner.app 112.2 MB. codesign --verify --deep --strict passed; bundle identifier com.tameyourbiz.app and team 3BQ4C6C4XA verified.
- devicectl update installation succeeded, then process launch succeeded at 03:37:49 local. No uninstall, clear, cleanup, or business-record operation performed. This proves build/sign/install/launch only, not iPhone rendered-flow acceptance or a data-integrity audit.
- Remaining Work acceptance includes actual iPhone navigation/layout checks, broader layout regression investigation, localization and Detailed/Summary presentation. Full goal remains active.

## September 28 — localized Work overview and all-date lists

- Connected overview cards, filters, list controls, empty/unavailable messages, status labels, date prefixes and plural counts to the existing generated English, U.S. Spanish and Canadian French catalog (including base language fallbacks). No private translation map or persisted translated record identity. Original customer/title text is preserved. Added exhaustive enum-to-catalog projection in work_overview_localization.dart.
- Focused overview/query/localization suite: 13 passed, including 320 LP / 2x text / light and dark across en_US, es_US and fr_CA with exact saved-record callback identity. Four-file analysis clean; git diff --check clean. Mac debug build succeeded. Current phone installations predate this catalog update; no new phone install or rendered multilingual inspection claimed. Human service-business translation review is outstanding. Other Work screens still have untranslated strings.
- Broader layout failure inspection found existing desktop navigation uses SingleChildScrollView rather than the test-assumed ListView; Expenses home no longer declares the test-assumed 1/2/3-column keys. No Expenses source or tests changed, and the broader suite remains unresolved rather than being marked green.

## September 28 — Detailed/Summary durable estimate foundation

- Investigated current record, draft, confirmation, revision, document adapter, and editor paths. Work had pricing method but no independent document presentation. Read protected 5.7 invoice record and migration-map disposition; no matching presentation field found in the targeted source search. Reused UI Lab codecs and draft/revision workflows; no protected source edited or copied. Legacy runtime suitability remains unverified.
- Added stable detailed/summary presentation to Work records and estimate draft payloads. Legacy missing fields preserve Detailed; unknown enum values fail instead of silently disclosing item details. Record copies, item revisions, estimate stage transitions and estimate editor recovery preserve the choice. Estimate style changes invalidate prior signature/company review through existing revision logic. Source-estimate job creation carries presentation; existing invoice revisions retain it. New invoice source inheritance and invoice selection remain pending in their flow.
- 24 focused presentation/lifecycle/estimate recovery tests passed. Includes actual SQLite draft recovery, confirmation and database reopen, unchanged labor/material data and internal costs, and style-only approval invalidation. Two lifecycle test taps now scroll to their controls after Work gained the overview; hit-test warnings were investigated rather than suppressed. Eleven-file analysis clean, diff check clean, Mac debug build passed. No phone installation or visible feature completion claimed.
- IMPORTANT: selector, plain Summary entry experience and shared customer document projection are not implemented yet. Do not expose the style choice until preview/output honor it and tests prove no item detail leakage. Estimate review design and templates remain untouched. Full goal remains active.

## September 28 — estimate presentation selector and customer output

- Added localized Customer document selector in estimate editor, with Detailed and Summary explanations. Approved estimate review structure is unchanged. Selector uses existing draft capture/recovery/revision paths.
- Summary customer projection carries a subtotal and no item objects, preserving all original internal estimate items. Existing standard/service/plumbing/masonry PDF compositions omit item rows for Summary; no template artwork or decorative redesign. Template browsing preview uses the same exclusion policy. Detailed output remains itemized.
- 15 document/presentation/scrolling tests passed, including PDF generation through every catalog template entirely in memory (no existing PDF files overwritten). One additional end-to-end editor selection/save test passed, proving returned Summary record retains items and total and customer projection excludes them. Eight-file analysis clean, diff check clean. Mac debug build passed. No rendered PDF/device acceptance claimed, no new phone install.
- Simplified one-price entry is still pending, as are invoice/quote style selectors, complete localization and the broader permissions/runtime gates. Customer document selector completion does not mark the entire estimate flow complete.

## September 28 — Work landing correction in progress

Owner rejected oversized 220-LP Work cards, buried date, ambiguous Browse records and top Add work. Scope restricted to Work landing; no client-form/list redesign in this pass. Reused OperationalSummaryStrip unchanged, preserving Dashboard dimensions and design. Work now shows Paid invoice payments (including partial/applied payments), Unpaid balance and Overdue subset; all-time label, visible-record scoping, and exact filter destinations. Added payment-bearing/partially-paid query cases. Date moved above cards. Removed top Add work row; compact lower-right action has reserved bottom space on phones, ordinary bottom button on wide layouts. No record deletion, data reset, or template/review redesign.

Evidence: first focused suite 42 passed; after reserved action clearance, 35 focused tests passed; 4 financial-query tests passed; focused analysis clean. Android debug and first Mac build passed. First S9 update via install -r succeeded after verifying installed/new signing SHA256 match. Physical screenshot confirmed card/date changes but exposed overlay on Invoices shortcut; this caused the reserved-bottom-space correction. Latest corrected build/install/runtime verification continues. Earlier desktop 480-LP attention test was stale against the existing 760-LP primary lane; now asserts alignment with the owning record lane. Tests scroll to offscreen records before tapping.

Unfinished: actual final S9 visual confirmation, Mac corrected runtime/resize, nonempty durable demo data and missing draft investigation, other Work workflows and full permission/Firebase integration. Do not equate synthetic tests with connected cloud or real-record acceptance.

Final bounded landing check: corrected Android and macOS builds passed. S9 second install -r succeeded; screenshots /tmp/s9-work-final-landing.png and /tmp/s9-work-final-scrolled.png show 96x120-LP Dashboard-matching money cards, date above cards, and Add work in reserved bottom-right space. Scrolling exposes Estimates/Invoices completely above the action area. Unpaid tap opened Outstanding invoices (empty current S9 scope), screenshot /tmp/s9-work-unpaid-list.png. Mac old process quit normally and new build launched; AX confirms Paid $400.00, Unpaid $0.00, Overdue $0.00; Paid opened the existing paid invoice list (Invoice 2006). Actual Window Fill/Left resize actions exercised; AX-only evidence, exact logical window bounds and visual wide-screen acceptance not established. No Mac screenshot taken. Gradle stopped; no Gradle/Kotlin worker processes found. No record was deleted, no app uninstall or data clear performed. Existing list dropdown and client screen still await their own bounded pass; no claim those owner corrections are finished.

## September 28 — Invoice status-list slice

The all-date invoice list reached from Work money cards now has invoice-only horizontal ChoiceChips (All, Unpaid, Partially paid, Overdue, Paid, Payments received, Drafts), a localized Invoices header, search, and divider-separated tappable invoice rows. Rows show invoice total and remaining balance plus ledger-derived paid/partial/overdue status. Non-invoice overview routes retain their dropdown/container behavior for a separate pass. Selected chip is revealed horizontally without scrolling the parent page. Current record visibility is rechecked on opening. Separate Invoice home/calendar is unchanged; it still requires convergence later.

Focused regression 10 passed, final 4 invoice-list tests passed including English/Spanish/French 320-LP 2x selected-status accessibility; focused analysis clean. Android and macOS builds passed. S9 install -r succeeded, no uninstall or clear. Mac runtime update could not be verified because CUA reports the Mac locked; do not claim new Mac list visually accepted. Gradle stopped and no worker processes remained.

Physical S9 screenshot /tmp/s9-invoice-status-rendered.png verifies Work Unpaid opens the Invoices status-list screen, Unpaid selected, horizontal compact chips, search and honest empty state. No invoice records are visible in this S9 scope, so populated rows/exact-record opening are test-proven only for this slice; durable demo records and missing estimate draft investigation remain outstanding.

## September 28 — Invoice-list saved-data prerequisite

Read-only inspection of the connected SM-G965U at 192.168.1.171:5555 found the established SQLite database and WAL. Two consecutive binary reads of both files were identical; retained host snapshot is `/var/folders/fy/sx7cyjf905g817cbs548x3y40000gn/T/s9-invoice-record-audit-nufnf2tb`. SQLite quick_check on that host copy returned `ok`. local_records contains zero rows across all domains; local_drafts contains two work/estimate-editor rows owned by alex. Thus the invoice empty state reflects the saved database, not merely a status filter hiding invoices. Two unfinished estimate drafts remain stored; their complete UI recovery and historical provenance are not established by this read-only check.

No device files were written, deleted, reset or replaced during this audit. The existing loadRequestedWorkExamples helper explicitly deletes Work records/drafts/history; it must not be invoked against this installation. Populated invoice-list device acceptance still requires an explicitly isolated, labeled set of ordinary persisted development records. Current tests cover in-memory records; they do not substitute for that device acceptance. Continue this same invoice-list workflow before expanding to another screen.

Added `test/work_invoice_persisted_list_test.dart` to close the in-memory-only regression gap: commits invoices/payments through SqliteWorkRepository into a test-owned disk database, verifies integrity, closes/reopens, opens a restricted WorkPersistenceSession, and exercises the actual invoice list. It proves persisted partial balance $60, paid balance $0, scoped exclusion of another creator's invoice/payment, no search disclosure, and exact record IDs from row taps despite identical customer/title text. One focused widget test passed and focused analysis reported no issues. No production source or device database changed; no platform rebuild required for this test-only addition. This verifies the row callback, not the full invoice-review route or physical populated-list acceptance. Startup already accepts injected storageDirectory, which may support isolated device verification; production selection, labeling and preservation still need investigation before use.

## September 28 — Populated S9 invoice-list verification

Reused current openUiLabApplication storageDirectory injection and LocalDatabase/SqliteWorkRepository, rather than adding another storage implementation or invoking the destructive historical example loader. Added explicit debug-only `tool/work_review_main.dart`, host-only `tool/prepare_work_review_workspace_test.dart`, and usage documentation. Normal main.dart is unchanged. Review target requires an existing, matching isolated directory/marker, rejects release/profile and fixture-seeding flags, disables native notifications, and labels the full app TEST WORKSPACE. This is development tooling, not a production workspace/account system.

Five fictional invoice inputs exist externally at `/tmp/work-invoice-review-20260928-input.json`; they are not Dart constants or app assets. Prepared through repository commits to `/tmp/work-invoice-review-20260928-prepared` (integrity passed). Preparation test passed and both tool files analyzed cleanly. Debug Android build passed (`/tmp/work-invoice-review-build.log`), install -r succeeded. Device directory `files/work_review_workspaces/invoice-review-20260928` is separate from original `files/maintainiac_ui_lab/sqlite`. Initial exec-in transfer produced no file; verification caught that before launch. A subsequent staging copy was byte-verified; no existing file was overwritten or removed. Staging retained. Gradle stopped, no Gradle/Kotlin workers remained.

Physical S9 evidence: `/tmp/s9-isolated-work-money.png` shows Paid $440, Unpaid $855, Overdue $480. `/tmp/s9-isolated-unpaid-list.png` shows three unpaid records. `/tmp/s9-isolated-partial-list.png` shows only INV-4102 with total $500/balance $300; tapping opens exact INV-4102 (`/tmp/s9-isolated-partial-review.png`). Paid chip shows only INV-4101 total $240/balance $0 (`/tmp/s9-isolated-paid-list.png`); tap opens exact INV-4101 (`/tmp/s9-isolated-paid-review.png`), despite same customer/title as INV-4102. Force-stop/relaunch while no form was active retained the totals (`/tmp/s9-isolated-work-reopened-ready.png`). Current S9 is left on Work in this labeled review workspace.

Original installation re-read consistently and compared by every row of local_records/local_drafts/local_record_revisions/local_commands/local_change_outbox against the pre-review snapshot: unchanged, two original estimate drafts retained; quick_check ok. Post-check host snapshot `/var/folders/fy/sx7cyjf905g817cbs548x3y40000gn/T/s9-original-after-isolated-review-ie5b19vi`. No owner records deleted/reset/replaced.

New observed downstream defect: invoice review displays stored Due for both the paid invoice and overdue partial invoice, while list correctly derives Paid / Overdue · Partially paid from balances/dates. Fix that status consistency in the next bounded invoice-review pass without redesigning the review. Mac/iPhone populated list verification and production account enforcement remain unproven. No Mac screenshots, simulator or emulator used.

## September 28 — Invoice review collection-status consistency

Corrected the physically observed stale Due label without restructuring review. Added shared invoiceCollectionStatus projection and localized labels, reused by all-date query filters, invoice list and review heading. Paid/overdue semantic colors follow that projection. Draft precedence, local due-day boundary and explicit legacy Paid compatibility retained; no record/status/ledger migration or write. Review without financial permission does not calculate a ledger-derived label. Existing invoice layout and estimate review/templates unchanged.

Focused regression: 33 tests passed across invoice workspace, collection review, invoice status list, persisted list and overview statuses (`/tmp/invoice-collection-tests-final.log`). Added financial-read restriction regression: final five collection tests pass (`/tmp/invoice-collection-permission-tests.log`). First run had missing OperationalScope in the new test harness, corrected before the final run. Focused analysis clean (`/tmp/invoice-collection-analysis.log`, `/tmp/invoice-collection-final-analysis.log`). Android isolated-review build and normal macOS build passed; update install on S9 succeeded. Gradle stopped and no workers found. No Mac runtime claim for this build.

Physical S9 exact-record check: INV-4102 now displays Overdue · Partially paid, balance $300 (`/tmp/s9-collection-partial-fixed.png`); INV-4101 displays Paid, balance $0 (`/tmp/s9-collection-paid-fixed.png`). Work totals retained $440/$855/$480 (`/tmp/s9-collection-work.png`). S9 remains in the labeled isolated invoice review workspace; original installation is not the active test directory. Broader invoice-home convergence, iPhone/Mac rendered verification, remaining Work workflows and production permission enforcement remain unfinished.

## September 28 — Invoice review stale-route boundary

Found InvoiceDetailScreen used the passed record snapshot when current store lookup failed. Removed that fallback: resolve current stable ID and invoice kind, then apply current persisted-session creator/employee visibility before rendering details. Missing/inaccessible records render a generic localized unavailable state with back navigation. The route subscribes to OperationalScope so employee selection changes invalidate open content. No storage mutations, template changes or estimate layout changes.

Extended the disk-backed invoice-list regression: a fully populated hidden invoice argument cannot disclose title/number/actions; changing an open permitted review to another employee hides it, restoring permitted scope reveals the current record. This test passed. Existing invoice workspace, collection-status and deposit-flow tests: 26 passed. Focused analysis clean and diff whitespace check clean. Android isolated-review and normal macOS builds passed. This is one invoice-review read boundary, not a claim that all invoice actions, exports, other routes or Firebase grants are complete.

S9 update install -r succeeded in the same isolated workspace. Work Unpaid → Partially paid → INV-4102 still opens the correct review with Overdue · Partially paid and $300 balance (`/tmp/s9-invoice-access-allowed.png`). Read-boundary denial was exercised by the disk-backed regression, not by changing real account grants on the phone. Gradle stopped and worker check empty. No data clear/uninstall/deletion, no template or estimate-review redesign, and no Mac runtime claim.

## September 28 — Main invoice entry uses status lists

Main Invoices now opens the existing all-date status-list workflow, with search, draft access, a separate Invoice activity by date route, and New invoice in reserved lower-right space. Work-day entry continues directly to date activity. Date activity excludes ledger-paid invoices from overdue attention. Display preferences and financial-read restrictions apply to the new entry; this does not establish complete production authorization. Estimate review and templates unchanged.

Focused regression: 31 tests passed in /tmp/invoice-home-tests-final.log, final financial-permission test passed in /tmp/invoice-home-final-permission-test.log; analysis clean in /tmp/invoice-home-analysis-clean.log. Android isolated-review and normal macOS builds passed; S9 update install succeeded. Gradle workers stopped.

Physical S9 verification: /tmp/s9-current-invoice-check.png shows the default all-date home with five durable isolated records; /tmp/s9-invoice-home-partial.png shows Partially paid selecting only INV-4102; tapping opens exact INV-4102 with $300 balance and Overdue / Partially paid (/tmp/s9-invoice-home-exact-review.png). Invoice activity by date opens its distinct heading and two actual overdue entries (/tmp/s9-invoice-home-date-activity.png); the fully paid invoice is absent from attention. Supporting actions still consume substantial vertical room on the small phone; this is not final visual acceptance. Mac remains locked, so actual resized Mac and iPhone verification remain pending. No deletions, data clear, uninstall, or original-data replacement. S9 remains in the explicitly labeled isolated review workspace.

## September 28 — Compact invoice-home supporting actions

Continued the same invoice-home slice after physical inspection showed draft/date actions consuming two rows. Reused WorkDraftShortcut with an opt-in text-button label (other screens unchanged) and localized Date activity text. Plain-text actions now share one row at ordinary phone text sizes and wrap for accessibility. Draft routing and recovery unchanged.

Invoice-home regression verifies the actions share a row at 360 LP, retain at least 48-LP tap height, remain reachable at 320 LP / 2x text, and preserve status-to-exact-review and date navigation. Passed (/tmp/invoice-home-compact-accessibility.log). Three existing draft-shortcut/recovery tests passed (/tmp/invoice-home-compact-draft-regression.log). Focused analysis clean before final accessibility test addition; final analysis separately logged. Android and macOS builds passed. S9 install -r succeeded; /tmp/s9-invoice-home-compact.png physically shows Drafts and Date activity on one line and the first invoice's due date, total and balance now visible above New invoice without scrolling. This recovers approximately 56 LP of vertical space compared with the preceding screenshot. No Mac rendered or iPhone verification in this slice. Gradle stopped with explicit JDK path; worker check empty. No records deleted or reset.

## September 28 — Invoice-list financial-access changes

A targeted regression demonstrated that removing showFinancials while a Paid list remained open hid controls but retained the payment-based filtered result/count. The list now uses All invoices when financial access is absent, supplies no ledger entries to that query, and omits invoice status labels as well as money. This also covers a restricted direct route with a supplied financial filter. Existing creator/employee visibility remains in force.

Regression failed before the fix (/tmp/invoice-access-before.log), then six tests passed including home navigation, localized status strips and the permission transition (/tmp/invoice-access-after.log). Focused analysis clean (/tmp/invoice-access-analysis.log), Android build passed (/tmp/invoice-access-build.log). This source change has not yet been installed on S9; the compact-layout build remains installed. No live account grants changed.

Mac AX retry reports locked; prior unlock request remains pending. Physical iPhone SE 3 is available/paired according to devicectl, but no rendered iPhone check performed. Further invoice-workflow access audit identified the separate date-activity attention query grants reviewInvoices unconditionally and its filter does not consult canViewFinancials. That related route remains unfinished and must be checked before claiming invoice permission enforcement complete. No records deleted, reset or replaced.

Normal macOS build also passed (/tmp/invoice-access-macos.log). Gradle stopped; no Gradle/Kotlin workers remained. This is build evidence, not Mac rendered acceptance.

## September 28 — Invoice date-activity financial-read boundary

Continued the connected invoice date-activity route. Without canViewFinancials, its attention query no longer receives reviewInvoices capability; its attention projection is empty, so overdue panel and calendar attention markers cannot disclose payment state. The Open invoices financial grouping is suppressed. Closed-record preference no longer removes paid records for a non-financial reader. Ordinary dated/search results remain available. Invoice rows omit financial status from visible text and semantics and use a neutral accent instead of payment-state color. No record or ledger writes.

Added a restricted-reader regression with due/paid records on the selected date and another open invoice elsewhere. It checks ordinary records remain available while attention, open-balance grouping, amounts, status text and screen-reader status labels do not. Before-change test failed (/tmp/invoice-date-access-before.log). First after-change run exposed a test SemanticsHandle disposal issue, fixed by explicit disposal. Final 23 focused tests pass (/tmp/invoice-date-access-final.log), including navigation and widths 320/390/412/800/1440. Focused analysis clean (/tmp/invoice-date-access-analysis.log).

Remaining: dated workspace creator/employee query still has legacy fixture fallback and must be aligned with persisted-session visibility before claiming full date-route authorization. Neither these tests nor local widget permission parameters establish Firebase enforcement or complete account/action security. No estimate review or template changes.

Android and macOS builds passed (/tmp/invoice-date-access-android.log, /tmp/invoice-date-access-macos.log). S9 install -r succeeded with the same isolated review target, incorporating both list and date-access fixes. Launch command accepted; no new claim of rendered restricted-account verification. Gradle stopped and worker check empty. Original data not cleared or uninstalled.

## September 28 — Persisted invoice date scope

Date-activity record/search/calendar/attention projections now reuse visibleWorkOverviewRecords for a persisted session, matching the all-date list and review scope. Technician attention uses the session actorEmployeeId. Existing nonpersistent fixture behavior remains explicit; it is not a production authorization claim. Shared work attention matches stable creator/assignment IDs first and allows legacy display-name matching only for a known demo employee, never substituting the first demo employee for an unfamiliar real ID.

Extended the reopened-SQLite regression through the dated Invoice workspace as technician owner (not a demo-roster ID): own partial overdue attention appears, search finds own settled invoice, hidden other-creator record remains unavailable. It failed before the fix (/tmp/invoice-date-scope-before.log). All 27 invoice/persisted/attention tests passed after (/tmp/invoice-date-scope-after.log). Added an unknown-employee attention regression with an explicit overdue control record; all six attention tests passed (/tmp/invoice-date-scope-unknown.log). The initial new test used default fixtures that had no qualifying Work alert; corrected to explicit test records rather than weakening its positive control. Focused analysis clean before that final test addition; final analysis logged separately.

Android build passed (/tmp/invoice-date-scope-android.log). No user records, payment data, permissions, or estimate review/templates modified. Full account grants/actions/Firebase, iPhone verification and unlocked-Mac resized acceptance remain unfinished.

Final five-file analysis clean (/tmp/invoice-date-scope-final-analysis.log); macOS build passed (/tmp/invoice-date-scope-macos.log). S9 update install succeeded and launch command accepted in the same isolated review workspace. No claim that the non-demo employee scenario was exercised on the phone; that evidence is the reopened-SQLite test. Gradle stopped and no workers remained.

## September 28 — Invoice date-activity localization and wide title

Moved invoice date-activity search, headings, empty/error/permission copy, filing controls, invoice draft shortcut, row status and overdue reason into shared en/en_US/es/es_US/fr/fr_CA catalogs. Attention localization projects from the matched invoice customer, preserving stable attention IDs and original business text. Existing USD money formatting and other linked-screen/shared tooltip localization remain outside this completed text slice; no claim of entire-app translation completion or human language acceptance.

New six-case widget matrix covers three locales, 320 LP at 1.5x text/light theme and 1100 LP/dark theme. It exposed the existing shared scoped wide header dropping headerTitle. Corrected that no-workday-action row to render supplied title in its existing flexible middle space. No new breakpoint or title truncation. Compact/workday header geometry unchanged.

45 focused invoice, draft and localization tests passed (/tmp/invoice-date-l10n-final-tests.log). Analysis clean after removing an unnecessary test assertion (/tmp/invoice-date-l10n-final-analysis.log). Broader Work-home/Job/layout run: 24 passed, five operations-layout failures (/tmp/invoice-header-shared-regression.log). Temporarily tested the exact pre-change wide-header body, restoring current contents in finally: the same five tests fail (/tmp/invoice-header-baseline-layout.log), involving Expenses column keys, desktop navigation ListView expectation and source-layout assertion. These are pre-existing relative to this header change, not silently waived or fixed in the unrelated Expenses lane.

Android and macOS builds passed (/tmp/invoice-date-l10n-android.log, /tmp/invoice-date-l10n-macos.log). Latest localization/title change not installed on phones yet; no new physical visual acceptance claimed. Gradle stopped, worker check empty. No data deletion or record modifications. Mac remains awaiting unlock for genuine window-resize acceptance.

## September 28 — Installed invoice localization verification

Latest localization/title APK update installed successfully over wireless ADB; normal launch reached the labeled isolated workspace. Physical S9: Work -> Invoices displays five saved records and compact supporting actions (/tmp/s9-invoice-l10n-home.png). Search INV-4102 returns exactly that record, total $500 and balance $300 (/tmp/s9-invoice-l10n-search.png); tapping opens exact INV-4102 with matching state/balance (/tmp/s9-invoice-l10n-exact-review.png). Date activity route opens correctly with two overdue items (/tmp/s9-invoice-l10n-date.png). English device rendering only; Spanish/French have widget-matrix evidence, not physical-phone language acceptance. No business data written or removed.

Observed unfinished date-route layout: its older floating New invoice overlaps the dated records heading/content; Invoice drafts also remains a full-width filled action. Main all-date home has already resolved these behaviors. Keep the next correction in this connected invoice route, using a reserved lower action area and compact draft access rather than expanding to another workflow. Desktop/iPhone rendered acceptance still pending.

## September 28 — Invoice date-action placement

Corrected the physically observed date-activity creation-action overlap. Date activity and the all-date home now reuse the same reserved lower-right New invoice action; the dated screen no longer floats it over records or places a duplicate action near the header on wide windows. Its draft shortcut uses the existing optional text-button presentation, aligned to start. Removed the obsolete oversized scroll-bottom allowance used for the floating button. No data, navigation, create permission, or editor behavior changed.

28 focused invoice/home/localization tests passed (/tmp/invoice-date-action-tests.log), now asserting content bounds end before the creation control at 320/412/800/1440 LP and three-language small/large-text layouts. Focused analysis clean (/tmp/invoice-date-action-analysis.log). Physical acceptance and build results recorded below when complete.

Android and macOS builds passed (/tmp/invoice-date-action-android.log, /tmp/invoice-date-action-macos.log). S9 update install succeeded in the same isolated workspace. Physical /tmp/s9-date-action-fixed.png confirms compact Drafts and reserved lower-right creation action; /tmp/s9-date-action-scrolled.png shows the dated records region scrolling above it without overlay. Gradle stopped, worker check empty. No business data changed.

That scrolled inspection exposed a remaining date-route accuracy defect: fully paid ledger-backed INV-4101 appears under Open invoices with stored Due status and total $240. The all-date list and exact review already derive Paid/$0 correctly. The dated _openInvoices and row presentation still use stored status; next bounded correction must reuse invoiceCollectionStatus / invoice balance projection there, including closed-record preference, rather than alter payment records. Do not call the complete invoice date workflow accepted yet.

## September 28 — Invoice date-activity payment projection

Stayed in the same date-activity screen. Open-invoice membership and closed-record preference now use the existing authorized-ledger collection-state projection, matching all-date list/review. Date/search row labels, semantics and status colors use that projection as well. No payment or invoice records mutated. Financial-read guards retained.

New regression uses two stored-Due records, fully and partially paid: full payment excludes the record from Open invoices; search still retrieves it with Paid status; partial stays open and shows Partially paid; stored status/ledger remain unchanged. Six locale/width cases now expect the correct derived Overdue label for their past-due fixture. 34 focused tests passed (/tmp/invoice-date-balance-final-tests.log); five-file analysis clean (/tmp/invoice-date-balance-final-analysis.log). Android build passed (/tmp/invoice-date-balance-android.log), idle Gradle stopped and worker check empty. Installation and physical check pending below.

Android update install succeeded and macOS build passed (/tmp/invoice-date-balance-macos.log). Physical S9 date view now shows Open invoices 1, only INV-4103 Unpaid; fully settled INV-4101 is absent (/tmp/s9-date-balance-open-fixed.png). Searching INV-4101 on this same screen retrieves the original record with Paid status and its unchanged $240 invoice total (/tmp/s9-date-balance-paid-search.png). This proves corrected grouping without removing the record. No record-edit/delete actions used. iPhone and actual Mac resize acceptance remain pending; this is a bounded date-projection correction, not completion of the entire Work goal.

## September 28 — Invoice date membership and supporting group clarity

Previous goal turn made progress: corrected/physically verified ledger-derived paid/open state. Continued only Invoice date activity. Mac accessibility attempt again reports locked; no screenshots/unlock bypass.

Dated invoices previously disappeared from the selected-date group when also flagged in global attention. Replaced attention subtraction with complete non-draft date membership; calendar counts/markers use the same non-draft predicate. Attention remains actionable separately. Supporting open group remains nonduplicative but is now labeled Other unpaid invoices in all six catalogs, making its partial count explicit. No invoice/payment data writes.

Updated regression failed against old query (/tmp/invoice-date-membership-before.log) then passed after correction. It verifies overdue date membership, draft exclusion and matching calendar count. 28 focused invoice/date/localization tests pass (/tmp/invoice-date-membership-tests.log); analysis clean (/tmp/invoice-date-membership-analysis.log). Build/install/physical evidence follows when finished.

Android/macOS builds passed (/tmp/invoice-date-membership-android.log, /tmp/invoice-date-membership-macos.log); S9 update installed successfully. Idle Gradle stopped, worker check empty. On physical S9 selected September 20 using previous-day controls (/tmp/s9-date-membership-sept20.png). Dated list now shows INV-4102, count 1, Overdue / Partially paid, despite also appearing in attention; Other unpaid invoices count 1 contains INV-4103 (/tmp/s9-date-membership-records.png). Tapping the dated row opens exact INV-4102 with $300 remaining balance (/tmp/s9-date-membership-exact-review.png). No business records modified/deleted. Desktop resize and iPhone acceptance remain pending.

## September 28 — Invoice dated payment activity

Previous turn progressed with date-membership fix and S9 proof. Continued the same invoice date workflow. Investigation found that calendar/list membership consulted only WorkRecord dates and omitted linked payments. Added a read-only invoice_date_activity projection using the existing exact-invoice payment matcher (stable ID or legacy number, invoice link kind only). It includes existing creation/issue/due semantics and authorized receipt/application dates; drafts remain excluded, matching-day event kinds are deduplicated. Same-day creation and issue display Issued to avoid redundant copy.

Date rows now explain matching events with compact localized labels; current status/total remain separate. Calendar and list share the projection. No ledger is supplied without financial read, preventing payment-only row/count leakage. Applied funds are labeled Payment applied, never a second receipt. No record mutation or changes to payment commands.

31 tests passed including reopened SQLite records, exact routing, layouts and new payment-only access tests (/tmp/invoice-date-events-final-tests.log); six language/layout cases additionally assert the event label (/tmp/invoice-date-events-label-locales.log). Analysis clean (/tmp/invoice-date-events-final-analysis.log). New row context legitimately adds a line: ordinary 390-LP fixture is 90 LP tall and bounded below 96, replacing its old 72-LP no-context assertion; accessibility still reflows. Android build passed (/tmp/invoice-date-events-android.log); install/macOS build in progress. Physical outcome recorded below.

Interrupted-turn completion evidence: macOS build passed (/tmp/invoice-date-events-macos.log), S9 install Success and launched. September 1 selected on physical phone (/tmp/s9-date-events-sept1.png). Date list shows 4 non-draft invoices; paid and partial entries both show Issued / Payment received, ordinary invoices show Issued (/tmp/s9-date-events-rows.png). Show all 4 expands to all four rows, with Show only 3 below and New invoice remaining outside scrolling content (/tmp/s9-date-events-expanded.png). Original five saved records preserved; no business writes/deletions. Gradle stopped and current worker check empty. A payment-only date and applied-payment distinction have widget-test evidence; physical workspace records happen to receive payments on issue date, so no claim of physical payment-only acceptance.

## September 28 — Mac invoice navigation after screen unlock

The owner authorized shell input to dismiss the passwordless Mac screen lock. Sending Return with System Events restored CUA access; no credentials or security settings changed. This is specific observed behavior for this session, not a general password-lock bypass.

The current Mac process was relaunched to load the current build. Invoice home search clearing worked by keyboard (Tab then Space from the search field), restoring the Paid-filtered record without changing that filter. The clear icon was not separately exposed in the inspected AX tree. Invoice 2006 for Taylor Foster remained Paid, total $400 and balance $0. Selecting September 23 in Invoice activity showed one matching invoice with Payment received, while its issue date is September 16. This provides runtime payment-only-date membership evidence on Mac.

Used native Window menu controls to resize the actual app to a half-screen and then Top Left quarter arrangement. In the quarter arrangement, AX retained September 23, count 1, the payment-context row and New invoice action. Opening the row reached exact Invoice 2006; returning retained September 23 and its row. These are interaction/accessibility observations, not screenshot-based visual acceptance or precise app-content LP measurements. No Mac screenshots taken. Wider-window acceptance and latest S9 search-clear interaction remain pending.

## September 28 — Invoice search clear physical completion

Previous turn completed Mac navigation evidence (progress). This turn verified native Fill then Left-half window arrangements preserve the invoice date, count and row; restored half-width afterward. AX checks do not establish pixel appearance or exact content width. No Mac screenshot was taken.

Invoice home now uses a managed search controller and localized clear action, retaining selected status when text is cleared. Focused navigation, financial-access removal and reopened SQLite tests passed (3 tests, /tmp/invoice-home-clear-tests.log); focused analysis clean (/tmp/invoice-home-clear-analysis.log). Android and macOS builds passed (/tmp/invoice-home-clear-android.log, /tmp/invoice-home-clear-macos.log).

Launched latest installed debug workspace on wireless S9 Plus. Work Paid card correctly opens Payments received (both paid and partially paid records). Selected Paid explicitly, searched zzznomatch: zero records and visible clear button (/tmp/s9-clear-empty.png). Tapped clear and dismissed keyboard: Paid selection retained, empty search, exactly INV-4101 returned with total $240 and balance $0 (/tmp/s9-clear-restored.png). No records changed or deleted. This finishes physical search-clear verification for this invoice-list slice; broader Work outcome and iPhone acceptance remain incomplete.

## September 28 — Remaining pinned estimate section action

Previous goal turn produced physical invoice-search and Mac-resize evidence (progress). Began estimate editing audit, preserving review composition. Main estimate, photos/items and review actions already scroll; inspected DocumentSectionEditor revealed its Done/Save changes still lived in bottomNavigationBar. This shared primitive has exactly two production callers: estimate and invoice editors. Moved the action after section fields, within the same scroll and bounded form width. Existing flush, validation, reentry guard and error handling unchanged. Updated owning lifecycle instruction and test navigation helper to settle field reflow before scrolling to Done.

Baseline existing estimate suites passed 18 tests. New nested-section assertion failed all 8 width/scale/theme cases against old footer (/tmp/estimate-section-scroll-before.log). After change, 27 focused tests passed covering estimate scrolling, both document editors, retained section edits/review and failed flush/retry (/tmp/estimate-section-scroll-tests.log). Analysis clean (/tmp/estimate-section-scroll-analysis.log). Android and macOS debug builds passed (/tmp/estimate-section-scroll-android.log, /tmp/estimate-section-scroll-macos.log). Gradle stopped; worker check empty. S9 replacement install succeeded (/tmp/estimate-section-scroll-install.log); phone runtime scroll acceptance pending.

Relaunched current Mac build. Opened existing Kitchen faucet replacement draft, Avery Wilson, Estimate 2001, $150. Opened Estimate information and activated Done; returned to same editor, title/customer/total unchanged. AX runtime evidence verifies routing, not pixel layout acceptance; no Mac screenshots. No confirmed estimate changes or deletions.

Next estimate workflow gap: Client information still uses DropdownButtonFormField. Existing SavedClientsScreen has search and detail navigation but no selection-return contract, uses a private copied list; CustomerDetailScreen matches history by name and exposes creation paths needing scope review. Reuse candidate is current directory session (canViewCustomers/canManageCustomers), stable customer snapshot and draft codecs; do not duplicate persistence. Read-only 5.7 InvoiceClientInfoScreen currently wraps a party-information form titled Saved Clients; this limited inspection does not establish a reusable secure directory picker. No protected files changed. Client-selector correction not implemented yet; review layout untouched.

## September 28 — S9 estimate section scroll verified

Previous goal turn changed shared section action placement and passed tests/builds (progress). This turn launched the installed S9 build in its labeled isolated workspace. Opened Add Work > New Estimate > Estimate information. Done appears after the description, rather than across a fixed footer (/tmp/s9-estimate-scroll-fields.png). Focused description to open the physical keyboard: Done initially scrolled below view (/tmp/s9-estimate-scroll-keyboard.png). Swiped the form upward: description and Done moved together; Done remained fully tappable above keyboard (/tmp/s9-estimate-scroll-done-visible.png). Tapping Done returned to the same New estimate overview with Draft saved on this device (/tmp/s9-estimate-scroll-return.png). No fields entered, no confirmed record saved, no deletion; the normal new unfinished draft remains in the isolated workspace.

Client-selection follow-up investigation: DirectoryPersistenceSession loads customer data only with canViewCustomers and rejects saves without both view/manage. CustomerDetailScreen still exposes unscoped history based on display name, amounts and New estimate controls. Before routing estimate selection through it, use stable snapshot IDs plus authorized Work projections; do not introduce a picker that exposes other customers' same-name history or unrestricted financial totals. Preserve existing customer snapshot when merely backing out. Current customer editor already has durable recovery and exact confirmed-save handling to reuse.

## September 28 — Client history identity and access prerequisite

Previous turn completed physical estimate section-scroll evidence (progress). Continued the client-selection workflow by fixing its existing detail/history dependency before adding a selector. Added customerWorkHistory over already-authorized Work records: snapshot IDs override names, renamed clients retain their identified records, identical-name clients are separated; legacy name-only records match only an unambiguous saved directory name. No records rewritten or linked automatically. Customer detail now uses the shared visibleWorkOverviewRecords projection, derives displayed counts from actual visible rows, re-resolves rows before navigation, and removes reliance on stale linkedRecordCount values.

Directory view is checked before rendering passed-in customer data; with an active directory, details resolve the client by ID from that session or report unavailable. Edit is disabled without customer-manage access. New estimate is disabled without estimate-edit authority and rechecked on action; the existing editor accepts an initialCustomer snapshot and the active actor ID, preserving stable identity instead of passing name alone. Existing estimate review layout untouched. Granular module/financial grants, payments/attachment history, localization and the requested Saved clients/Add new selector remain unfinished; this is not a claim of end-to-end permissions completion.

Validation: 13 history/estimate customer/scroller tests passed (/tmp/customer-history-tests.log); 24 history/lifecycle/draft-recovery tests passed (/tmp/customer-history-regression.log); final 6 identity plus SQLite-backed directory deny/read-only tests passed (/tmp/customer-detail-access-final.log). Final focused analysis clean (/tmp/customer-history-final-analysis.log), diff check clean. Mac build after final route guard passed (/tmp/customer-history-final-macos.log). Android build running under exec session 21679 (/tmp/customer-history-android.log); do not restart without inspecting that handle. No new runtime installation yet; next finish build/cleanup and verify client details, then connect the compact selection flow.

Build completion: exec 21679 exited successfully; Android APK built in 22 seconds. Gradle daemon stopped afterward; worker check empty. Both platform builds are ready for runtime checks, not yet installed/launched for this customer-history change.

## September 28 — Estimate Saved clients / Add new flow

Previous turn fixed and tested client identity/history prerequisites (progress). Replaced the estimate customer dropdown with compact Saved clients and Add new text actions in the existing section editor. Saved clients opens the existing directory with search and simple alphabetical name rows. A selected row opens the existing client details; Use this client explicitly returns its stable identity. Back from details/directory cancels selection. The owning estimate re-resolves the returned ID from the current directory and captures/flushes its existing draft. Add new continues to use CustomerEditScreen and its existing durable confirmation choice; no parallel records or persistence introduced.

Directory listing now reads the active directory cache when present (rather than a stale copied list), checks view/manage grants, and shows an unavailable message without customer rows on denied view. Name rows use shared bounded width instead of multi-column customer cards. New selection/action/search/empty-state text added in English, Spanish and French catalogs (including regional variants). Customer detail widgets moved intact into customer_detail_sections.dart at a cohesive boundary; both source files remain below 500 lines. Review layout and templates untouched.

16 tests passed: explicit selection versus back cancellation at phone/desktop widths, row search, retained selected customer after section reopening, invoice/estimate section regressions, directory layout at enlarged text, SQLite-backed deny/read-only customer permissions and draft recovery (/tmp/client-selection-tests-final.log). Original grid-lane assertions were replaced with name-row order and shared 760-LP form bound, per requested list behavior. Focused analysis clean (/tmp/client-selection-final-analysis.log), diff check clean. macOS build passed (/tmp/client-selection-macos.log). Android build running session 50638 (/tmp/client-selection-android.log); inspect handle before any restart. No new runtime acceptance yet; next install and inspect this exact client selection flow on S9 and Mac. The broader phone contact/units/localization/financial-permission requirements remain open.

Android build completion: session 50638 exited successfully. Gradle stopped and worker check empty. S9 replacement installation is now live under exec session 71804, output /tmp/client-selection-install.log; poll that handle, do not restart merely because no output has appeared.

## Invoice landing and reusable jobs checkpoint

Owner's latest reusable-job request is now recorded in the Work lifecycle owning
blueprint, with the earlier September 19 handoff located. Current Work source
search and read-only 5.7 Dart search did not establish an implemented common-job
library. Add work presently has create actions only. Reusable jobs remain
unfinished; exact Add work placement is a proposal, not owner acceptance.

Invoice source now keeps the calendar below the content at all widths, suppresses
attention duplication while a status/search result is active, orders money cards
Unpaid / Partially paid / Overdue / Paid in full, and totals settled invoice face
values instead of receipt transactions. Focused analysis passed. Six money-card
locale/text-scale tests and 24 invoice-workspace tests passed. Test expectations
were scoped to invoice rows where summary labels/values now also appear, updated
for Paid in full, and scrolled to the bottom calendar before inspecting it.

Not yet delivered: full landing navigation regression, distinct zero-payment
Unpaid semantics versus existing outstanding balance query, actual invoice
approval permissions, reusable-job persistence/editor/tab, S24 new build and
runtime acceptance, and remaining broad Work goal. No user records were deleted
or reseeded in this checkpoint. No physical-device verification of this patch.

## Invoice in-place filter verification

Replaced obsolete two-screen navigation test with the required single invoice
landing flow: Drafts above summaries; paid filter changes content without a
route push; search clear retains filter; exact record opens; Back retains filter;
date mode returns in place and a day without records has no record section.
Restricted financial access can still use All invoices but receives no money
cards or payment status. The selected-day bar is hidden in all-date status views.
Calendar remains below content. All-date list honors the closed-record preference;
explicit Paid in full selection overrides that general preference.

Unpaid money card now uses a no-recorded-payments query, separate from existing
outstanding-balance projections. Partial balances no longer inflate that card.
Overdue still overlaps both categories intentionally. Tests: 25 combined invoice
workspace/navigation passed; 12 money/status/access/navigation passed; corrected
the navigation test to tap the actual InkWell and reran it without hit warnings.
Broader Work analysis found one existing estimate preview braces info at line 41;
no unrelated edit made.

Approval dependency inspection: WorkSessionPermissions currently has issue/share
permissions but no invoice approval grant or requirement policy. Estimate company
review methods assert estimate kind and cannot safely be presented as invoice
approval. InvoiceDraftWorkflow and WorkFinancialValidation already enforce issue
transitions at durable command boundaries. Approval must extend those boundaries,
record codec/revision and delivery, not just add a status widget. No new approval
capability or reusable-job flow is yet claimed implemented. No S24 build/install
of these edits has occurred.

## Internal invoice approval foundation and actions

Added persisted append-only invoice approval events, explicit approve/policy
session grants, content fingerprint validation, saved submission and approval
commands, issue/financial-ledger and PDF-delivery guards. Ordinary history
rewrites, removal of an existing requirement, unauthorized approvals, approval
with changed content, and issue before approval are rejected. Invoice edit/item
paths preserve history so superseded approvals remain evidence. Request approval
and authorized Approve invoice actions are wired; conditional Needs approval and
Approved landing filters operate in place. Owner development bootstrap can approve.

Read-only 5.7 invoice inspection found approved status/filter terminology but did
not establish an equivalent content-bound command authorization implementation;
no donor code copied. Existing UI Lab transaction/revision safeguards were reused.

A real SQLite test passed submission, denied approval, denied issuing, reopening,
authorized approval, immutable history, due-date invalidation, resubmission,
reapproval, issue and idempotent retry. 33 focused regression tests passed before
cohesive file extraction; 26 passed after extracting invoice sections and signature
model to keep files below 500 lines. Focused analysis clean. Unfinished: approval
UI tests/device evidence, localized approval controls, return-for-changes UI,
policy administration and Firebase. Reusable jobs remain pending. No S24 build
or install yet, no customer-record edits or deletions.

## Invoice approval actions and Android build

Request changes now requires a reason and retains it in the invoice approval
history; the creator sees the explanation and can resubmit. Approval labels use
the shared English/Spanish/French catalog. Fixed an incorrectly reused calendar
sentence label so the invoice filter reads exactly Needs approval.

SQLite-backed widget test passed request -> correction validation -> recorded
reason -> resubmit -> authorized approval, with actual saved events. Focused
analysis clean. Normal lib/main.dart Android debug build succeeded (24.8s,
/tmp/invoice-current-build.log). It emitted an existing plugin Kotlin migration
warning, not a build failure. Task Gradle daemon stopped after confirming no
active build; no other device installed as a substitute.

S24 currently missing from adb devices. S9 Plus and S25 Ultra listed. mDNS
reported no services. Owner's earlier 192.168.1.117:32795 endpoint refused the
connection. Asked for the current S24 Wireless debugging IP/port. This does not
establish that the phone lacks Wi-Fi; only the debugging connection is unavailable.
No latest-build installation or runtime acceptance on S24 yet. Broad Work goal
remains active, with policy UI, reusable jobs and other documented work unfinished.

## Cross-session approval verification and next invoice gap

New SQLite concurrency regression passed: employee cannot forge a supervisor
approval event; supervisor with an older session cannot approve after employee
changes service location; database retains latest content and original submission;
reopening requires resubmission before supervisor approval. This tests separate
actor identities and storage revisions, not just presentation-role changes.
Focused test analysis clean. Production permission refresh/revocation and Firebase
still are not established by these local-session tests.

Next invoice-form mismatch confirmed from source: InvoiceDraftInput has no simple
price field; buildConfirmedInvoice requires input.items.isNotEmpty; invoice editor
only totals items. Estimate already has service-price recovery and validation.
Owner's latest instruction is one form with optional items, not two mandatory
basic/detailed document types. Invoice needs a durable raw overall-price input,
reopen/recovery behavior, no silent replacement of existing itemized work, and
consistent customer document projection. No price-form edits in this checkpoint.
S24 debugging address question remains pending; no alternative device installed.

## Invoice one-price form

Invoice editor now offers Price for the work for a non-itemized entry. Raw price
and explicit item-editor mode persist in invoice draft payloads; closing/reopening
SQLite preserves incomplete input. Shared service-price calculation extracted
from the existing estimate implementation, retaining estimate behavior. Invoice
confirmation validates decimal input, creates an internal Service amount, and
uses summary customer output without an item table. Itemized work cannot be
silently overwritten by the overall price. Switching through the item editor
retains explicit item descriptions and detailed customer presentation. Clearing
an existing simple price cannot quietly reuse its old value. No template design
changes or estimate-review layout changes were made.

Evidence: 11 focused price/recovery/shared-estimate tests passed, 3 focused
invoice price preservation tests passed, and 25 invoice UI/workspace tests passed
(the validation-copy expectation updated to the new optional-item requirement).
Focused analysis clean. Android debug build succeeded in 22.6s, log
/tmp/invoice-simple-price-build.log. Gradle daemon stopped after verifying no
active build. Current adb still only S9 Plus and S25; no S24 install occurred.

Remaining UX check: on reopening a simple invoice, the item-entry overview may
count its internal service amount as one item; that should instead communicate
optional itemization. Test the switch/reopen form and basic-price edits physically
when S24 reconnects. Estimate's existing presentation selector still requires
reconciliation with the one-form owner correction. Broad Work remains unfinished.

## Reopened basic invoice UX and approval regression

Simple invoice overview now treats the persisted internal service amount as a
single overall price, not a user-entered item: Add items (optional) remains the
entry action. Price and optional-item labels now use the English/Spanish/French
catalog. Expanded widget regression saves, reopens, checks the exact price,
clears it, verifies required-price feedback, and saves a corrected amount.
Additional regression proves overall-price edits preserve approval history and
require fresh approval. Five focused tests passed and focused analysis clean.
This small UI follow-up is newer than /tmp/invoice-simple-price-build.log; no new
build or device installation claimed. S24 IP/port question remains unanswered;
continue independent invoice work without using a different phone as substitute.

## Invoice selected-card feedback and current build

Money-card selection now carries a check marker, outline, and semantic selected
state using the shared summary primitive. Invoice selection is preserved through
search clearing and cleared when returning to dated activity. Other summary-strip
consumers retain their default unselected rendering. Seven focused invoice
navigation/money-card tests passed; analysis of four changed files found no issues.
Android debug build succeeded (23.5s), log /tmp/invoice-selection-build.log.
S24 remains absent from adb devices; S9 and S25 are present. No installation or
physical acceptance claimed. Current owner endpoint question remains pending.
Reusable jobs is still a required labeled tab and persistent common-work library,
as documented in the owning Work lifecycle section, not an implemented feature.

## Invoice client selection consistency

Invoice Client information now uses Saved clients / Add new on one compact row.
The existing searchable saved-client directory and detail/history route is shared
with Estimates, with explicit Use this client selection. Internal selection naming
is generalized to selectForDocument; no duplicate directory was added. Selection
uses stable client ID rather than matching names, updates location for a changed
client, preserves work/prices, flushes draft input around navigation, and checks
directory access before and after selection. New-client creation relies on its
existing save rather than appending a second copy. A cohesive invoice client
selection part keeps the editor below 500 lines. No estimate review or PDF
layout changes.

Evidence: /tmp/invoice-client-regression.log has 33 passing focused workspace,
client selection, draft, and directory access tests. Expanded create-client
regressions at 360/1200 LP passed in /tmp/invoice-client-create-test.log, proving
single directory insertion and preserved invoice work/price. Nine-file analysis
is clean (/tmp/invoice-client-final-analysis.log). These are widget/storage test
evidence, not physical visual acceptance. S24 is absent from current mDNS; S9/S25
are present and were not substituted. No current build installed on S24.
Android debug build for this slice succeeded in 22.9s, recorded in
/tmp/invoice-client-build.log. Idle Gradle worker stopped after build completion.

## Invoice export command authorization

Moved customer-copy eligibility checks from only the screen delivery function
into shared Work export authorization. WorkExportAudit.assertCurrent now verifies
the durable record's integrity, identity, revision, issue/share authority and
approval, and compares full encoded saved content against any submitted copy.
PDF rendering uses that verified saved record; begin and later authorization
callbacks recheck the same copy. Alternate callers of the export command cannot
skip invoice approval by bypassing the screen helper. No new employee policy UI
or Firebase enforcement is claimed: profile access choices remain explicitly
unconnected to production account membership.

Eighteen focused tests passed (/tmp/invoice-export-regression.log): rejected
unapproved exports across share/save/print, denied issue permission, actor-level
approval requirement on older records, forged content with matching ID/revision,
stale concurrent edits, inactive session, audit outcomes, and legitimate approval
surviving issue plus partial/final payment and reopening. Five-file analysis clean
(/tmp/invoice-export-final-analysis.log). Device list still has S9/S25 only;
S24 installation and physical UI/runtime acceptance remain pending.
Android debug build succeeded in 22.7s (/tmp/invoice-export-build.log).
Idle Gradle build worker stopped after verifying no active build remained.

### Reusable jobs bounded implementation checkpoint

Add work now offers a Reusable jobs tab. Common work can be created, copied
from an existing job, edited, persisted, recovered and used for a new client.
Uses shared SQLite records, revisions, actor-scoped drafts and Work write queue;
backup pause blocks new writes without changing saved records. Explicit copying
excludes customer identity, schedule, assignment, approvals, receipt/stock and
payment links. Protected 5.7 store/actions were inspected read-only; no donor
source was copied. Owning requirements remain in work_lifecycle_blueprint.md.

Verification: 15 focused reusable/job/draft/Work layout regressions passed
(/tmp/reusable-job-regression.log); after adding pause coverage, all four
library tests passed (/tmp/reusable-job-pause-test.log). Extended 360/1200 LP
widget journeys create/edit common work, select a new customer and location,
save a real SQLite-backed job with the copied price, and verify the reusable
source is unchanged (/tmp/reusable-job-complete-flow.log, 2 passed). Final
eight-file analysis clean (/tmp/reusable-job-final-analysis.log). Android debug
APK built in 23.4s (/tmp/reusable-job-build.log). Idle Gradle daemon stopped and
Gradle/Kotlin process absence verified. S24 remains absent from ADB; no install
or physical acceptance claimed. Direct Jobs access, translations, reuse from
estimate/invoice/quote creation and full production authorization remain open.

### Reusable jobs access from Jobs

Jobs now exposes the same library as Add work using the shared tab component.
Selecting Reusable jobs hides booking controls/calendar; returning to Jobs
preserves its selected date. Both entry points use the same SQLite library and
new-client job editor, with no duplicate persistence. A legacy Jobs regression
expected an active section while its default fixture contained no other active
job; it now supplies an explicit separately dated active job instead of relying
on unrelated example data. Four create/edit/reuse/save journeys cover Add work
and Jobs at 360/1200 LP; tab switching also covers 320 LP/enlarged text. All 22
focused tests passed (/tmp/reusable-jobs-entry-final-tests.log), four-file
analysis clean (/tmp/reusable-jobs-entry-analysis.log), diff whitespace checks
clean, Android debug build passed in 22.5s (/tmp/reusable-jobs-entry-build.log).
Idle Gradle worker stopped and process absence verified. S24 mDNS still absent;
no device installation or owner visual acceptance claimed. The previous direct
Jobs access gap is closed in source/tests; remaining gaps above still apply.

### Work landing navigation and draft protection

Removed the general Work Drafts shortcut, preserving permitted Employee status
and document-specific conditional draft access. Existing draft data and recovery
records are untouched. Shell destinations now have independent navigators with
a shared ModuleLandingNavigation coordinator. Selecting/reselecting a module
unwinds detail routes through registered DraftNavigationGuard exits; cancellation
and failed flush prevent departure. Other PopScopes are never force-popped.
Native Back remains one route. Read-only 5.7 bottom navigation inspection found
section-root dispatch, but did not establish a compatible durable asynchronous
exit contract; reused UI-Lab draft/guard systems rather than copying donor code.

35 focused Work/shell/guard/draft tests passed before extending independent
navigators to all five shell modules (/tmp/work-module-navigation-tests.log).
After that extension, 11 shell, landing guard, expense setup and recovery
regressions passed (/tmp/shell-module-navigation-regression.log). Failure
injection verifies Keep editing and failed saves retain the form and raw input;
a successful save returns through multiple routes to landing. Stale layout
assertions now match the already documented 884 LP Work breakpoint/1184 LP bound;
menu tests scroll lazy content before accessing settings. Eight-file analysis
clean (/tmp/work-module-navigation-final-analysis.log), whitespace checks clean,
Android debug build passed in 22.8s (/tmp/work-module-navigation-build.log).
Idle Gradle daemon stopped and process absence verified. S24 still absent from
ADB; no installation or physical acceptance claimed. Bespoke exit guards still
need exhaustive workflow checks; overall Work goal remains unfinished.


## September 28 — Scheduling build delivered; Quotes next

Scheduling now uses the shared Work detail header and compact Scheduled jobs /
Needs scheduling strip. Selection changes the list in place. Empty record groups
are omitted; calendar and navigation remain available. Job creation no longer
performs a second store insertion after a durable editor save. Source evidence:
18 focused tests passed in /tmp/scheduling-status-final-tests.log; two-file
analysis clean in /tmp/scheduling-status-final-analysis.log; Android debug build
succeeded in /tmp/scheduling-status-build.log. No active Gradle/build worker
was found in the process check after deployment.

S24 rediscovered by mDNS. The older direct port refused connection; the current
ADB mDNS transport 2774 was verified as SM-S928U. Existing-package update via
adb install -r succeeded using build/app/outputs/flutter-apk/app-debug.apk
(September 28 16:37). No uninstall, clear, or record reset was performed. Launch
reported Status: ok and topResumedActivity was com.tameyourbiz.app with
com.maintainiac.ui_lab_2_1.MainActivity. UI hierarchy confirmed the app dashboard
was rendered. This proves installation and launch, not visual acceptance of all
changed Work screens.

Latest owner priority supersedes earlier Quotes-last sequence: Quotes is next.
Expenses has not been changed in this Work pass. Quote investigation confirms
WorkRecordKind currently has only estimate/job/invoice and Work navigation
explicitly displays an unconnected Quotes dialog. Do not present Quotes as done.

Reuse assessment started read-only: protected 5.7 invoice_record.dart and
invoice_ledger_store.dart implement Invoice/Estimate records with a Hive ledger;
the estimate picker imports those records into jobs. The inspected invoice and
job paths do not provide an independently implemented Quote workflow. No donor
code was copied or executed. UI-Lab already has SQLite transactions, immutable
number claims, revision checks, draft checkpoints, customer snapshots, signature
and approval provenance, shared price/items and document rendering to reuse.
Quotes must be a distinct stored kind with its own draft identity and numbering,
not estimates silently relabeled. Authorization, customer approval validation,
export authorization, dated projections, conversion and recovery dispatch must
all be inspected/extended together. Current estimate approval validation explicitly
rejects non-estimates, so merely exposing a Quote editor would fail or bypass
existing safeguards. Complete that bounded workflow before unrelated header work.
Overall goal remains active and unfinished.


## September 28 — Quote persistence foundation (not device-delivered)

Prior goal turn was progress: latest completed Scheduling/Invoice APK installed
and launched on verified S24. Current turn starts Quotes per newest owner priority.
Distinct quote enum, independent number claims and draft recovery domain added.
Shared EstimateDraftInput now retains documentKind with legacy estimate default;
openEstimateDraft accepts an explicit proposal kind and validates handoff/base
identity and creator grants. Confirmation rejects time-and-materials quote prices.
Existing Work records cannot change kind through save. Separate quote approval
grants/policy fields added rather than borrowing Estimate policy silently.

This is foundational implementation, NOT a complete Quote workflow. Existing
Quote shortcut remains unconnected. Quote dispatch branches explicitly fail
closed until its screens exist; unsupported customer decisions and exports are
blocked. Required NEXT work: connect Quote editor, landing and review using
shared client/pricing/draft primitives; replace every explicit 'Quote ... not
connected yet' branch; give ResumedQuoteDraft distinct routing (currently shared
ResumedEstimateDraft controller), then audited approval/signature/delivery,
conversions, attention/status projections and user-workflow testing. Do not
ship this intermediate foundation or claim Quotes finished. Quote lifecycle
currently reuses proposal stage/date/revision fields named estimate internally.

14 persistence/recovery/numbering tests passed (/tmp/quote-foundation-tests.log),
including 5 new quote tests covering restart, raw-input recovery, independent
numbering, wrong-kind rejection, fixed-price constraint, save permission and
required-approval bypass. 29 Work/approval regressions passed
(/tmp/quote-foundation-regression.log). Two old Work assertions were reconciled
with previously implemented owner directions (no general Drafts or money strip
on Work; Saved clients capitalization), not production behavior changes.
24-file focused analysis clean (/tmp/quote-foundation-focused-analysis.log).
Broader analysis before formatting had 36 pre-existing infos/warnings but no
remaining kind-exhaustiveness errors; not claimed globally clean. Android debug
build passed in 29.5s (/tmp/quote-foundation-build.log). It was NOT installed;
S24 retains the previous completed build. Idle Gradle daemon stopped after build;
process absence checked. Overall goal remains active; no visual acceptance or
complete Quote feature claimed.


### September 28 — Quote create, draft recovery, save and edit connected

This supersedes the previous foundation-only navigation checkpoint. Quote now
opens from Work, Add Work, dated Work rows, saved-document and recovery routes.
The landing screen has the shared header, conditional Drafts, in-place compact
status filters/search/date controls and a bottom calendar. One editor supports
fixed service price or optional itemized work, stable saved-client selection,
optional expiry, preserved raw inputs and ordinary SQLite confirmation. Review
and editing reread saved records. ResumedQuoteDraft is a distinct route with the
shared proposal controller. Estimate UI layout was not redesigned.

UI tests exercised create -> leave incomplete -> Save draft -> Quote drafts ->
resume -> select client -> save -> review -> edit -> save -> landing -> reopen
at 360 and 1200 LP, plus 320 LP with TextScaler 2. This caught and fixed stale
Quote Drafts visibility after returning from unfinished input. It also caught
an existing client Work history heading/New estimate action Row overflow;
that heading now wraps at the available logical width without truncation.
26 Quote/Work screen tests passed (/tmp/quote-recovery-ui-tests.log); 18 focused
Quote/Estimate persistence/recovery and customer access/history tests passed
(/tmp/quote-connected-regression.log). Focused 12-file analyzer clean
(/tmp/quote-connected-analysis.log). Android debug build passed in 22.8s
(/tmp/quote-connected-build.log). No full product or physical visual acceptance
is claimed. Gradle stopped with explicit JAVA_HOME and process absence verified.

Latest APK is built but NOT installed. S24 R5CX14WC8FA was absent from adb devices;
its mDNS service advertised 192.168.1.117:37389, which refused connection.
Previously used :45123 also refused. S9 and S25 remain connected; neither was
used in place of the requested S24. Asked owner asynchronously for the current
Wireless debugging IP/port. S24 retains the earlier completed Invoice/Scheduling
build. This is an ADB connection failure, not evidence that Wi-Fi is disabled.

Next within the same Quote workflow: audited supervisor/admin approval,
customer acceptance with or without signature, attributed ink signature,
delivery/export, conversion, and attention projection. Temporary Quote save
and export guards remain fail-closed; do not just remove them. Existing Estimate
company-review handlers use display actors and lack the full Quote session
validation required here; reuse models/revision infrastructure, but bind Quote
approval to saved content and actor authority with bypass tests. QuoteStatus
currently checks required approval before terminal statuses; resolve precedence
when enabling those transitions. Realistic durable isolated demo records and
S24 runtime checks still pending. Expenses layout unchanged; broad goal active.


### September 28 — Quote supervisor/admin approval connected

Previous turn classified as concrete progress: Quote UI, draft return refresh,
accessibility correction, tests and build. Continued the same Quote workflow.

Added quote_approval_content.dart and session-level quote_approval_validation.dart.
Supervisor decisions retain immutable existing history, acting employee ID,
content fingerprint and document revision. Decisions require canApproveQuotes;
raw approved-status injection, actor forgery, history removal, content changes
without a revision, retaining an obsolete approval, and inconsistent totals
are rejected. Required approval cannot be disabled. Submission and approval
must use unchanged saved content; Request changes needs a nonempty reason.
Shared EstimateCompanyReviewEvent adds optional contentFingerprint with backward
compatible codec; Estimate behavior was not promoted into Quote authority.
Quote grants added to explicit UI-Lab owner development authority, not Firebase.

Quote detail now supports Request approval, confirmed Approve for sending, and
Request changes for approval-required records. No customer approval/signature is
created by supervisor approval. Requests and decisions use the durable Work
session; errors retain the record. Changes requested has a distinct list status
and conditional filter. Closed/expired states take precedence over needs-approval.
The changes dialog owns its controller through route disposal.

36 focused Quote/Work/Estimate-review tests passed
(/tmp/quote-approval-regression.log), including two new direct-bypass tests and
three native-SQLite UI journeys at 320 LP/TextScaler2, 360 LP and 1200 LP. UI
journey includes request -> approve -> edit -> invalidated approval. Approval
history reload from a new session verified; this test is not described as a
full device restart. 12-file focused analyzer clean
(/tmp/quote-approval-analysis.log). Android debug build passed in 22.8s
(/tmp/quote-approval-build.log). Idle Gradle stopped; process absence checked.

S24 remains absent from connected ADB devices; S9 and S25 present. No new
owner IP/port supplied yet. This build not installed; latest device build is
still earlier Invoice/Scheduling. No alternative phone used. No data reset,
uninstall, screenshot, emulator, protected-5.7 write, or unrelated expense
layout edits. Goal remains active.

Next: finish Quote customer acceptance with/without signature (not merely an
approved enum), attributed signature capture, delivery/export and conversions.
Temporary Quote guard still rejects customer stage/delivery/signature writes,
and export still blocked. Existing estimate_signature_draft_workflow.dart has
estimate-specific domain and kind validation; preserve recovery identity and
actor/revision enforcement when reusing it. Customer acceptance validator is
currently Estimate-only. Quote internal company approval is now enabled and
must not be regressed by removing all approval checks with the temporary guard.
Role/policy UI and Firebase enforcement still pending. Latest source is not a
claim that the entire Work product or Quote lifecycle is complete.
