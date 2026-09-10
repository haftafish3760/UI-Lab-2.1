import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/day_notes/sqlite_day_note_repository.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/day_notes/stored_day_note.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';

void main() {
  test(
    'note projection publishes after commit, filters scope and survives reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'day-note-session-',
      );
      var db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
      final access = DayNoteAccess(
        organizationId: 'company',
        actorEmployeeId: 'alex',
        permissionRevision: 'test',
        employeeIds: {'alex', 'jordan'},
        canCreate: true,
      );
      var session = await DayNotePersistenceSession.open(
        SqliteDayNoteRepository(db),
        access,
      );
      var store = PrototypeOperationsStore(dayNoteSession: session);
      final date = DateTime(2030, 1, 2);
      final note = StoredDayNote(
        id: 'note',
        organizationId: 'company',
        employeeId: 'alex',
        date: '2030-01-02',
        timeMinutes: 1439,
        text: 'Inspected panel',
        createdAt: DateTime.utc(2030, 1, 3, 5),
      );
      List<DayEntry> entries({String? employee = 'alex', DateTime? day}) =>
          store
              .dashboardDay(
                day: day ?? date,
                contextId: employee ?? 'company',
                employeeId: employee,
              )
              .entries
              .where((entry) => entry.sourceRecordId == note.id)
              .toList();
      try {
        await db.customStatement(
          "CREATE TRIGGER fail_note BEFORE INSERT ON local_records WHEN NEW.domain = 'activity/day-notes' BEGIN SELECT RAISE(ABORT, 'fail'); END",
        );
        final pending = session.create(note);
        expect(session.isSaving, isTrue);
        expect(entries(), isEmpty);
        expect(await pending, isFalse);
        expect(session.isSaving, isFalse);
        expect(entries(), isEmpty);
        await db.customStatement('DROP TRIGGER fail_note');
        expect(await session.create(note), isTrue);
        expect(session.error, isNull);
        expect(entries().single.time, '11:59 PM');
        expect(entries(employee: 'jordan'), isEmpty);
        expect(entries(day: DateTime(2030, 1, 3)), isEmpty);
        expect(entries(employee: null), hasLength(1));
        final projected = store.dashboardDay(
          day: date,
          contextId: 'alex',
          employeeId: 'alex',
        );
        store.updateDashboardDay(day: date, contextId: 'alex', data: projected);
        store.updateDashboardDay(
          day: date,
          contextId: 'jordan',
          data: projected,
        );
        expect(entries(), hasLength(1));
        expect(entries(employee: 'jordan'), isEmpty);
        expect(await session.create(note), isTrue);
        expect(entries(), hasLength(1));
        expect(await db.select(db.localCommands).get(), hasLength(1));
        store.dispose();
        session.dispose();
        await db.close();
        db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
        session = await DayNotePersistenceSession.open(
          SqliteDayNoteRepository(db),
          access,
        );
        store = PrototypeOperationsStore(dayNoteSession: session);
        expect(entries().single.title, note.text);
        expect(entries().single.sourceRecordId, note.id);
        expect(entries(employee: 'jordan'), isEmpty);
      } finally {
        store.dispose();
        session.dispose();
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
