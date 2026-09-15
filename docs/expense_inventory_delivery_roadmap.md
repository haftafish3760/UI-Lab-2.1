# Expense and inventory delivery roadmap — September 14

Current owner corrections govern this task. This is a delivery sequence with
acceptance gates, not a claim that the Expense or Inventory app is finished.
Owning rules remain Receipt/material intake, Operations §9, storage, UI
foundation and Work lifecycle. D38 authorizes the inventory migration.

Latest owner priority: finish Expenses UI/UX one screen at a time, beginning
with the home screen on phone and widescreen, then receipt entry/capture/review.
Work follows after Expenses. OCR, device capability and inventory engine work
remain deferred during this layout pass. Operations section 9 owns the home
layout, spending periods, calendar behavior and permission boundaries. Receipt
flow uses protected 5.7 Active as a structural reference. PDF remains owned by
the other model. A passed test is not visual acceptance or production readiness.

Expenses home checkpoint: shared navigation placement, four spending periods,
direct entry actions, bounded record/calendar lanes, and visible company scope
are implemented. Small phone and short desktop at 2x text pass focused widget
checks; refund/year-boundary and denied-route/amount checks are included. Native
Windows verification uses an isolated build copy because the running app locks
its SQLite native asset. Visual acceptance and replacing the running build remain
pending while the owner's computer is locked. Fresh dependency resolution also
exposed the existing build_runner/analyzer versus SDK-pinned meta conflict; the
verification copy uses the workspace's existing resolved package configuration.

Permission completion limit: the lab's Technician/Admin switch still uses
explicit development grants. The checks exercise denied read/amount/create/
receipt/editor boundaries, but do not prove a production employee/position policy.
That integration must bind the signed-in employee and permitted record scope to
AuthorizedExpenseService, including named employees/team scope and historical
calendar routes. Position labels alone must never grant access.

OCR/device-workload checkpoint: Android debug build succeeds; static analysis
is clean; 12 focused workload, image-budget, consent, retry, stale-result,
restored-path and accessibility tests pass. No app was installed or launched by
this task. iOS source target is now 15.5 to satisfy the native reader dependency;
Mac compilation and physical-device validation remain pending. Native engine
accuracy, cold/warm 5–10-second timing and sustained thermal/memory acceptance
are not established. The broader Expense suite has two unresolved failures:
receipt save retry after an injected SQLite failure (also fails in isolation),
and calendar navigation expecting a missing calendar widget. These are not
claimed as pre-existing or as passing. Raw recognized text is not yet durable
or connected to expense/item proposals; see the owning intake blueprint.

| Stage | Deliverable and location | Completion evidence / remaining work |
| --- | --- | --- |
| 1. Independent generator | Separate native Flutter Android/iOS app at `C:\Users\noneya\Documents\Receipt Generator`; fictional stores, generic supplies, image preview, native image/answer sharing, saved examples | Web implementation and staging deleted; port 4318 has no listener. Nine native tests pass; Flutter analysis clean; Android debug APK built. No installation/launch. iOS source included; Mac build and physical-device acceptance pending. No PDF dependency or work. |
| 2. Independent test corpus | Receipt image inputs separated from answer JSON; freeze/version training, development and held-out evaluation sets | Arithmetic checks do not prove OCR. Real camera images, image degradation, negative lines, ambiguous matches, missing sections and complete reconciliation required. Never import parser/catalog rules into generator. |
| 3. Expense entry | Business-only, optional category selector, meaningful new-entry/draft routes; section-level containers without a single enclosing card | Inspect 5.7 pre-photo entry as reference; user accepts its general initial flow, not its entire logic or personal classification. New UI not implemented here. |
| 4. Capture and preview | Native camera/photo picker, contextual permissions; replace post-photo preview and long-receipt stitching | Preserve originals, add/replace/reorder/remove/zoom; denied permission, interrupted capture, empty selection, duplicates, missing middle, glare and unreadable output. No hand-built camera stack. |
| 5. Review and data saving | Manual fields and add/edit/remove item flow; optional reading assistance; actual compression preview | Assistance on first Expenses entry and changeable settings, per-use overrides, no inferred commits. Preserve local save and owner-selected approximate 1 MB/750 KB/500 KB/250 KB choices. |
| 6. Durable contractor stock | Item, location, quantity, purchase history, pending commitments, reminders | SQLite command/ledger atomicity, retry/restart, permission and correction evidence. User sees On hand, Pending and Available separately. Catalog installation never creates owned stock. |
| 7. Related Work | Select existing Job/Estimate/Invoice; use cost/stock to prepare an Estimate; opt-in pending material quantities | Coordinate stable-ID contract with the other model. Reserving is not consuming; cancellation/revision/release and overcommitment need explicit rules and tests. No concurrent edits to the other model's Work/PDF implementation. |
| 8. Core pack review | Core, Standard, Professional, Complete; plumbing/electrical/HVAC Core bundled offline | Review actual frequent-use families with evidence, aliases, units and pack sizes. “Top 25%” is a usefulness target, not permission to pick an arbitrary quarter. Identify missing/incorrectly tiered items. Include cleaning/handyman/custom-item paths. |
| 9. Optional Firebase backup | Separate business-app cloud setup under D32–D34, with local-only operation preserved | Confirm actual project identity, access rules, upload/restore and deletion behavior. Configuration file alone is not working backup. Do not wire Firebase into the test generator. |

PDF generation for Expenses/Invoices belongs exclusively to the owner's other
Codex model. This task does not create, adapt, test, or replace that PDF system.
Only record receipt evidence and stable record IDs needed by its future consumer.

Inventory/reading assistance are opt-in. Low-stock reminders require an explicit
item/location threshold and enabled reminders; unknown counts are not zero.
Turning a feature off preserves existing records and permits viewing/correction.
The product is contractor/service inventory, not a warehouse management suite.

Platform references reviewed for permission planning:
[Android photo picker/minimal permission](https://developer.android.com/privacy-and-security/minimize-permission-requests),
[Android camera intents](https://developer.android.com/media/camera/camera-intents),
[Apple capture authorization](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media).
These guide the later native capture slice; this generator does not use a camera.
