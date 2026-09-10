# Local-storage regression harness

This directory provides reusable test infrastructure for UI Lab's SQLite/Drift
adapters and editor workflows. Every database case owns a temporary directory;
tests must never point it at application-support data or the protected 5.7 tree.

## Run or share

The repeatable suite runner is documented in
[`tooling/storage_qa/README.md`](../../../tooling/storage_qa/README.md).
It records selected commands, source fingerprints, machine logs and explicit
pass/failure evidence. Use that report with these helpers when handing off a run.

Share the repository revision (including `pubspec.lock`), these helpers, and the
relevant test files. From that checkout, run `flutter pub get`, then for example:

```sh
flutter test test/local_database_durability_test.dart test/local_database_interruption_test.dart test/draft_autosave_session_test.dart
flutter test test/invoice_editor_draft_recovery_test.dart test/invoice_item_draft_recovery_test.dart test/invoice_editor_confirmation_test.dart
```

`database_harness.dart` creates isolated files and tracks connections. Register
`harness.dispose` as teardown; use `harness.close(database)` before reopening the
same file to test restoration instead of merely reading an in-memory cache.
The helper imports UI Lab's `LocalDatabase`; reuse with a different application
requires adapting that import/database factory, not copying business fixtures
or pointing tests at a production database.

`native_widget_pump.dart` advances both Flutter's fake widget clock and real
native SQLite I/O until a supplied observable condition holds. It has a bounded
attempt limit and asserts completion. Do not substitute a fixed sleep or disable
the assertion to make a failing workflow pass.

`crash_writer.dart` is the child-process fixture used by the interruption tests.
It signals when an uncommitted write is active so the parent can terminate it
and inspect the reopened database. This proves process-interruption behavior,
not battery removal, filesystem hardware guarantees, or every mobile lifecycle.

## Evidence boundaries

- Database tests cover file reopen, stale revisions, atomic failure, replay,
  scoped reads, corruption refusal, capacity failure and process interruption.
- Domain tests verify preserved business values and cache behavior after failed
  writes. They do not establish production authentication or cloud security.
- Editor tests exercise actual widgets with isolated native SQLite, including
  incomplete input, Back, reopening, explicit discard, stale edits and retry.
- Imported source links and private-cost retention have independent line-item
  regression coverage. Stock movements are outside this recovery harness.
- Current native evidence comes from macOS. Run and document applicable Windows,
  Android and iOS cases independently; a host test is not device acceptance.

For a new workflow, add assertions about what the user can recover and what
confirmed records must remain unchanged. Verify interrupted and failed paths as
well as successful saves. Keep fixtures synthetic and compare complete relevant
values/source identities, rather than treating a row count or a green legacy
suite as proof of durability.

The interruption suite also runs `draft_replacement_crash_writer.dart` in an
isolated child process. It acknowledges a replacement draft, begins another
consume/create transaction, and waits for the parent to send SIGKILL. The parent
verifies recovery of the acknowledged input, rollback of the uncommitted revision
marker, rejection of stale-editor writes/deletion, and continued revision safety.
The helper refuses paths outside the disposable database-harness directory.
This verifies host process termination; it does not simulate loss of device power.
