import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/day_notes/stored_day_note.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'day recovery retains civil date and raw text without depending on current calendar selection',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var notes = await openUiLabDayNotes(db);
      final date = DateTime(2026, 9, 9);
      final workflow = await notes.openDraft(date: date, employeeId: 'jordan');
      workflow.update(text: '  Midnight\nunfinished  ', timeMinutes: 0);
      await workflow.session.close();
      final raw = workflow.session.input;
      notes.dispose();
      await harness.close(db);
      db = await harness.open();
      notes = await openUiLabDayNotes(db);
      addTearDown(notes.dispose);
      final recovery = DayNoteDraftRecovery(notes);
      final entry = (await recovery.list()).single;
      expect(entry.preview.availability, DraftRecoveryAvailability.recoverable);
      final resumed = await recovery.resume(entry);
      expect(resumed.session.input, raw);
      expect(resumed.session.savedRevision, entry.revision);
      await resumed.session.close();
      Future<Object> open(int revision) => notes.openDraft(
        date: date,
        employeeId: 'jordan',
        recoverySelection: DraftRecoverySelection(
          domain: entry.domain,
          draftId: entry.draftId,
          revision: revision,
        ),
      );
      await expectLater(
        open(entry.revision + 1),
        throwsA(isA<LocalRecordConflict>()),
      );
      await recovery.discard(entry);
      await expectLater(
        open(entry.revision),
        throwsA(isA<LocalRecordConflict>()),
      );
      expect(await recovery.list(), isEmpty);
      expect(notes.records, isEmpty);
    },
  );
  test(
    'already published identity and malformed date are preserved; inaccessible employee input stays hidden',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final notes = await openUiLabDayNotes(db);
      addTearDown(notes.dispose);
      final workflow = await notes.openDraft(
        date: DateTime(2026, 9, 9),
        employeeId: 'alex',
      );
      workflow.update(text: 'Unfinished input', timeMinutes: 1439);
      await workflow.session.close();
      final recovery = DayNoteDraftRecovery(notes);
      final entry = (await recovery.list()).single;
      expect(entry.preview.availability, DraftRecoveryAvailability.recoverable);
      await notes.repository.create(
        StoredDayNote(
          id: workflow.input.noteId,
          organizationId: notes.access.organizationId,
          employeeId: 'alex',
          date: '2026-09-09',
          timeMinutes: 1439,
          text: 'Recorded elsewhere',
          createdAt: DateTime.now().toUtc(),
        ),
        notes.access,
      );
      expect(notes.records, isEmpty);
      expect(
        (await recovery.list()).single.preview.availability,
        DraftRecoveryAvailability.conflict,
      );
      await expectLater(recovery.resume(entry), throwsStateError);
      for (final input in [
        (
          'invalid',
          <String, Object?>{...workflow.session.input, 'date': '2026-02-31'},
        ),
        (
          'hidden',
          <String, Object?>{
            ...workflow.session.input,
            'employeeId': 'outside-access',
          },
        ),
      ]) {
        await notes.drafts.save(
          organizationId: notes.access.organizationId,
          ownerId: notes.access.actorEmployeeId,
          domain: entry.domain,
          draftId: input.$1,
          expectedRevision: 0,
          payload: input.$2,
          occurredAt: DateTime.now(),
        );
      }
      final entries = await recovery.list();
      expect(entries, hasLength(2));
      expect(
        entries.singleWhere((e) => e.draftId == 'invalid').preview.availability,
        DraftRecoveryAvailability.unreadable,
      );
    },
  );
}
