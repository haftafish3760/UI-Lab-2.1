import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/day_notes/sqlite_day_note_repository.dart';
import 'package:ui_lab_2_1/src/data/day_notes/stored_day_note.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_record_navigation.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/day_entry_details_screen.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final authorized in [true, false]) {
    testWidgets('note route resolves scoped source; authorized=$authorized', (
      tester,
    ) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('note-route-'),
      ))!;
      late LocalDatabase db;
      late DayNotePersistenceSession session;
      await tester.runAsync(() async {
        db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
        final repo = SqliteDayNoteRepository(db);
        final owner = DayNoteAccess(
          organizationId: 'company',
          actorEmployeeId: 'alex',
          permissionRevision: 'test',
          employeeIds: {'alex'},
          canCreate: true,
        );
        await repo.create(
          StoredDayNote(
            id: 'private-note',
            organizationId: 'company',
            employeeId: 'alex',
            date: '2029-01-02',
            timeMinutes: 720,
            text: 'Confirmed source text',
            createdAt: DateTime.utc(2029, 1, 2),
          ),
          owner,
        );
        session = await DayNotePersistenceSession.open(
          repo,
          authorized
              ? owner
              : DayNoteAccess(
                  organizationId: 'company',
                  actorEmployeeId: 'sam',
                  permissionRevision: 'test',
                  employeeIds: {'sam'},
                ),
        );
      });
      final store = PrototypeOperationsStore(dayNoteSession: session);
      try {
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => DashboardRecordNavigation.openEntry(
                      context,
                      const DayEntry(
                        id: 'untrusted-projection',
                        sourceRecordId: 'private-note',
                        time: '1:00 AM',
                        title: 'Forged caller text',
                        detail: 'forged detail',
                        kind: DayEntryKind.note,
                        color: Colors.red,
                      ),
                      date: DateTime(2000),
                      showOdometer: true,
                      onCreateJob: (_) {},
                    ),
                    child: const Text('Open source'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open source'));
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => authorized
              ? find.byType(DayEntryDetailsScreen).evaluate().isNotEmpty
              : find
                    .text('This day record is unavailable.')
                    .evaluate()
                    .isNotEmpty,
        );
        expect(find.text('Forged caller text'), findsNothing);
        if (authorized) {
          final details = tester.widget<DayEntryDetailsScreen>(
            find.byType(DayEntryDetailsScreen),
          );
          expect(details.entry.title, 'Confirmed source text');
          expect(details.entry.time, '12:00 PM');
          expect(details.date, DateTime(2029, 1, 2));
          expect(details.showOdometer, isFalse);
        } else {
          expect(find.byType(DayEntryDetailsScreen), findsNothing);
          expect(find.text('Confirmed source text'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        store.dispose();
        session.dispose();
        await tester.runAsync(db.close);
        await tester.runAsync(() => directory.delete(recursive: true));
      }
    });
  }
}
