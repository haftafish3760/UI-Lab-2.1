import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/day_notes/stored_day_note.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';

void main() {
  for (final kind in ['note', 'workday']) {
    for (final admitted in [false, true]) {
      test(
        '$kind ${admitted ? 'drains admitted' : 'rejects new'} command on disposal',
        () async {
          final root = await Directory.systemTemp.createTemp('activity-drain-');
          var persistence = await LocalPersistence.open(directory: root);
          final notes = await openUiLabDayNotes(persistence.database);
          final work = await openUiLabWorkdaySession(persistence.database);
          final target = kind == 'note' ? notes : work;
          final note = StoredDayNote(
            id: 'retained-note',
            organizationId: notes.access.organizationId,
            employeeId: 'alex',
            date: '2030-01-01',
            timeMinutes: 480,
            text: 'Confirmed input',
            createdAt: DateTime.utc(2030),
          );
          try {
            if (!admitted) target.dispose();
            final pending = kind == 'note'
                ? notes.create(note)
                : work
                      .start(
                        id: 'retained-workday',
                        employeeId: 'alex',
                        vehicleId: 'transit-12',
                        odometerTenths: 100,
                        expectedOdometerRevision: 0,
                        at: DateTime.utc(2030),
                      )
                      .then((result) => result.committed);
            if (admitted) target.dispose();
            final committed = await pending;
            expect(committed, admitted);
            await persistence.close();
            persistence = await LocalPersistence.open(directory: root);
            final reopenedNotes = await openUiLabDayNotes(persistence.database);
            final reopenedWork = await openUiLabWorkdaySession(
              persistence.database,
            );
            expect(
              reopenedNotes.records.any((r) => r.id == note.id),
              kind == 'note' && admitted,
            );
            expect(
              reopenedWork.records.any(
                (r) => r.record.id == 'retained-workday',
              ),
              kind == 'workday' && admitted,
            );
            reopenedNotes.dispose();
            reopenedWork.dispose();
            await persistence.database.verifyIntegrity();
          } finally {
            if (kind == 'note') {
              work.dispose();
            } else {
              notes.dispose();
            }
            await persistence.close();
            await root.delete(recursive: true);
          }
        },
      );
    }
  }
}
