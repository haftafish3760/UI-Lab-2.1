import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_ui_lab_bootstrap.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'note recovery preserves raw text, calendar time and first failed confirmation time',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var notes = await openUiLabDayNotes(database);
      final day = DateTime.utc(2026, 9, 9, 23, 59);
      var workflow = await notes.openDraft(date: day, employeeId: 'alex');
      await expectLater(
        workflow.confirm(),
        throwsA(isA<DayNoteInputValidation>()),
      );
      workflow.update(text: '  Exact unfinished\ntext  ', timeMinutes: 0);
      final id = workflow.input.noteId;
      final draftId = workflow.session.draftId;
      await database.customStatement(
        "CREATE TRIGGER reject_note BEFORE INSERT ON local_records WHEN NEW.domain = 'activity/day-notes' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect(await workflow.confirm(), isFalse);
      final firstAttempt = workflow.input.createdAt;
      expect(firstAttempt!.isUtc, isTrue);
      expect(notes.records, isEmpty);
      await workflow.session.close();
      notes.dispose();
      await harness.close(database);
      database = await harness.open();
      notes = await openUiLabDayNotes(database);
      addTearDown(notes.dispose);
      workflow = await notes.openDraft(date: day, employeeId: 'alex');
      expect(workflow.session.draftId, draftId);
      expect(workflow.input.noteId, id);
      expect(workflow.input.createdAt, firstAttempt);
      expect(workflow.input.text, '  Exact unfinished\ntext  ');
      expect(workflow.input.date, '2026-09-09');
      expect(workflow.input.timeMinutes, 0);
      await database.customStatement('DROP TRIGGER reject_note');
      expect(await workflow.confirm(), isTrue);
      expect(notes.records.single.createdAt, firstAttempt);
      expect(notes.records.single.text, '  Exact unfinished\ntext  ');
      expect(notes.records.single.timeMinutes, 0);
      await expectLater(workflow.confirm(), throwsStateError);
      expect(
        await notes.drafts.find(
          organizationId: notes.access.organizationId,
          ownerId: notes.access.actorEmployeeId,
          domain: 'activity/day-note-input',
          draftId: draftId,
        ),
        isNull,
      );
      await workflow.session.close();
    },
  );

  test(
    'legacy note input is recovered without rewrite; malformed context is preserved',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final notes = await openUiLabDayNotes(await harness.open());
      addTearDown(notes.dispose);
      final key = 'new-${notes.access.actorEmployeeId}-alex-2026-09-09';
      final payload = <String, Object?>{
        'noteId': 'legacy-note',
        'employeeId': 'alex',
        'date': '2026-09-09',
        'timeMinutes': 1439,
        'text': 'Legacy unfinished',
        'createdAt': null,
      };
      await notes.drafts.save(
        organizationId: notes.access.organizationId,
        ownerId: notes.access.actorEmployeeId,
        domain: 'activity/day-note-input',
        draftId: key,
        expectedRevision: 0,
        payload: payload,
        occurredAt: DateTime.utc(2026, 9, 9),
      );
      final workflow = await notes.openDraft(
        date: DateTime(2026, 9, 9),
        employeeId: 'alex',
      );
      expect(workflow.input.toPayload(), payload);
      expect(workflow.session.savedRevision, 1);
      await workflow.session.close();
      await notes.drafts.save(
        organizationId: notes.access.organizationId,
        ownerId: notes.access.actorEmployeeId,
        domain: 'activity/day-note-input',
        draftId: key,
        expectedRevision: 1,
        payload: {...payload, 'employeeId': 'jordan'},
        occurredAt: DateTime.utc(2026, 9, 9),
      );
      await expectLater(
        notes.openDraft(date: DateTime(2026, 9, 9), employeeId: 'alex'),
        throwsStateError,
      );
      final retained = await notes.drafts.find(
        organizationId: notes.access.organizationId,
        ownerId: notes.access.actorEmployeeId,
        domain: 'activity/day-note-input',
        draftId: key,
      );
      expect(retained!.revision, 2);
      expect(notes.drafts.decode(retained)['employeeId'], 'jordan');
      await expectLater(
        notes.openDraft(date: DateTime(2026, 9, 9), employeeId: 'unknown'),
        throwsStateError,
      );
    },
  );
}
