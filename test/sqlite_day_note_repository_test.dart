import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/day_notes/stored_day_note.dart';
import 'package:ui_lab_2_1/src/data/day_notes/sqlite_day_note_repository.dart';

void main() {
  late Directory directory;
  late LocalDatabase db;
  late SqliteDayNoteRepository repo;
  final access = DayNoteAccess(
    organizationId: 'company',
    actorEmployeeId: 'alex',
    permissionRevision: 'test',
    employeeIds: {'alex'},
    canCreate: true,
  );
  final note = StoredDayNote(
    id: 'note',
    organizationId: 'company',
    employeeId: 'alex',
    date: '2030-01-02',
    timeMinutes: 1439,
    text: '  Inspected panel\n${'detail ' * 70}',
    createdAt: DateTime.utc(2030, 1, 3, 5),
  );
  const checkpoint = LocalDraftCheckpoint(
    domain: SqliteDayNoteRepository.draftDomain,
    draftId: 'draft',
    revision: 1,
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('day-note-');
    db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
    repo = SqliteDayNoteRepository(db);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });
  Future<void> saveDraft({String? text}) async {
    await LocalDraftStore(db).save(
      organizationId: 'company',
      domain: checkpoint.domain,
      draftId: checkpoint.draftId,
      ownerId: 'alex',
      expectedRevision: 0,
      payload: {
        'noteId': note.id,
        'employeeId': 'alex',
        'date': note.date,
        'timeMinutes': note.timeMinutes,
        'text': text ?? note.text,
      },
      occurredAt: note.createdAt,
    );
  }

  test(
    'confirmation rollback preserves raw input; reopen and retry never duplicates',
    () async {
      await saveDraft();
      await db.customStatement(
        "CREATE TRIGGER fail_draft BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'fail'); END",
      );
      await expectLater(
        repo.create(note, access, draft: checkpoint),
        throwsA(anything),
      );
      expect(await repo.read(access), isEmpty);
      expect(await db.select(db.localCommands).get(), isEmpty);
      expect(await db.select(db.localDrafts).get(), hasLength(1));
      await db.customStatement('DROP TRIGGER fail_draft');
      await repo.create(note, access, draft: checkpoint);
      await db.close();
      db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
      repo = SqliteDayNoteRepository(db);
      final retained = (await repo.read(access)).single;
      expect(retained.toJson(), note.toJson());
      expect(retained.text.length, greaterThan(240));
      await repo.create(note, access, draft: checkpoint);
      expect(await db.select(db.localCommands).get(), hasLength(1));
      expect(await db.select(db.localDrafts).get(), isEmpty);
      await saveDraft();
      await expectLater(
        repo.create(note, access, draft: checkpoint),
        throwsA(anything),
      );
      expect(await db.select(db.localDrafts).get(), hasLength(1));
    },
  );
  test(
    'different confirmation text and unauthorized scope cannot consume a draft',
    () async {
      await saveDraft(text: 'different raw text');
      await expectLater(
        repo.create(note, access, draft: checkpoint),
        throwsA(anything),
      );
      expect(await repo.read(access), isEmpty);
      await repo.create(note, access);
      for (final denied in [
        DayNoteAccess(
          organizationId: 'other',
          actorEmployeeId: 'alex',
          permissionRevision: 'test',
          employeeIds: {'alex'},
          canCreate: true,
        ),
        DayNoteAccess(
          organizationId: 'company',
          actorEmployeeId: 'sam',
          permissionRevision: 'test',
          employeeIds: {'sam'},
          canCreate: true,
        ),
      ]) {
        expect(await repo.read(denied), isEmpty);
        await expectLater(repo.create(note, denied), throwsStateError);
      }
      expect(await db.select(db.localDrafts).get(), hasLength(1));
    },
  );
  test('invalid calendar dates, clock values and empty text are rejected', () {
    for (final changes in [
      {'date': '2030-02-30'},
      {'date': '2030-1-2'},
      {'timeMinutes': -1},
      {'timeMinutes': 1440},
      {'text': '  '},
    ]) {
      expect(
        () => StoredDayNote.fromJson({...note.toJson(), ...changes}),
        throwsArgumentError,
      );
    }
  });
}
