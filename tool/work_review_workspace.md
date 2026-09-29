# Isolated Work review target

`work_review_main.dart` is an explicitly selected debug entry point, not an
import of normal `lib/main.dart`. It requires a prepared database in application
support at `work_review_workspaces/<WORK_REVIEW_WORKSPACE>`, with an exactly
matching `review-workspace-id` file. It refuses release/profile, seed-enabled,
missing or invalid configurations rather than falling back to normal storage.
The entire application is visibly marked TEST WORKSPACE. Notifications are
disabled for this review target. Existing Work development permissions remain
development permissions, not verified Firebase account authority.

Prepare externally supplied fictional invoices on the host with:

```sh
flutter test tool/prepare_work_review_workspace_test.dart \
  --dart-define=REVIEW_INPUT=/absolute/path/to/external.json \
  --dart-define=REVIEW_OUTPUT=/absolute/path/to/new-directory \
  --dart-define=REVIEW_ID=unique-review-id
```

The input is a JSON array of objects containing id, number, title, client,
detail, status, issuedOn, dueOn, totalCents and paidCents. Contents are never
stored in source or application assets. Preparation refuses any existing output
destination; no cleanup, replacement or reset is performed. Use normal repository
commands and verify database integrity before closing and publishing the marker.
Transfer both prepared files to a new device directory, then verify their bytes
before launching. Do not copy over an existing review workspace.

```sh
flutter build apk --debug --no-pub -t tool/work_review_main.dart \
  --dart-define=WORK_REVIEW_WORKSPACE=unique-review-id
```

An update installation preserves the normal app database. This target reads and
edits only the selected review installation; its records survive reopening and
are not recreated on startup. Reinstalling a build using `lib/main.dart` returns
to normal startup and the original installation. Do not uninstall or clear app
data to switch targets. Keep review directories and staging files unless the
owner explicitly authorizes deletion. The test target is not a customer-facing
workspace switcher, backup system or production sample-data mechanism.
