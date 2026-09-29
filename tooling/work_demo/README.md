# Editable connected Work demonstration

Run explicitly from the repository root:

```sh
flutter test tooling/work_demo/create_estimate_workspace_test.dart
```

This developer-only tool reads `estimate_scenarios.json` and creates a **new**
installation beneath `output/work-demo/`. It has no option to overwrite an
existing installation. Failed or successful output is retained; it never resets
or deletes user data. The JSON is not an application asset or startup fixture.

Three fictional clients, four estimates, two quotes, two scheduled jobs, four
invoices, two payments and two reusable common jobs exercise normal draft
confirmation, customer approval without a signature, fictional signature capture,
job conversion and direct invoice conversion. The invoices include a draft,
overdue unpaid work, a partial payment and payment in full. Businesses represented
include plumbing, cleaning, delivery, photography, IT support and inspections. One
estimate belongs to an employee whose attempted approval and signing actions
must be rejected. The tool closes and reopens the database, checks the records,
and verifies database integrity before publishing `review-workspace-id`.

The output is compatible with the existing isolated launcher documented in
[`tool/work_review_workspace.md`](../../tool/work_review_workspace.md). Use the
printed `WORK_REVIEW_WORKSPACE` value for both the target directory and build
define. Transfer the closed installation to a **new** device workspace and
verify the transferred bytes. Do not overwrite another workspace, uninstall,
clear application data, or use `loadRequestedWorkExamples` to populate it.

All demonstration records are editable saved records. Nothing is recreated on
launch. The signature and verbal approval are explicitly fictional and do not
represent any real customer's consent. Never send messages to the sample
contacts. The launcher visibly identifies the test workspace and disables
notifications.

These checks exercise domain workflows, not taps on a physical phone. Device
layout, keyboard, native sharing, and production account authorization remain
separate verification requirements. The permissions here are the existing
UI-Lab development authority, not a production employer/employee login system.

Rendered widget checks can read a prepared workspace at phone and desktop widths:

```sh
flutter test tooling/work_demo/review_saved_workspace_test.dart \
  --dart-define=DEMO_REVIEW_PATH=/absolute/path/to/output/work-demo/new-workspace
```

This checks populated invoice, quote and schedule screens and scrolling without
capturing screenshots. It is not physical-device or owner visual acceptance.
The workspace is preserved after the checks; no deletion/reset is performed.
