import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_day_screen.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_persistence_session.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final calendar in [false, true]) {
    testWidgets(
      '${calendar ? 'Calendar Day' : 'Dashboard'} description survives Back/reopen and atomic confirmation failure',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1100);
        tester.view.devicePixelRatio = 1;
        final directory = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('day-note-editor-'),
        ))!;
        late LocalDatabase db;
        late DayNotePersistenceSession notes;
        Future<void> mount() async {
          await tester.runAsync(() async {
            db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
            notes = await openUiLabDayNotes(db);
          });
          await tester.pumpWidget(
            UiLabApp(dayNoteSession: notes, draftStore: LocalDraftStore(db)),
          );
          await tester.pumpAndSettle();
          if (calendar) {
            Navigator.of(tester.element(find.byType(DashboardScreen))).push(
              MaterialPageRoute<void>(
                builder: (_) => DashboardDayScreen(
                  initialDay: dashboardToday.subtract(const Duration(days: 1)),
                ),
              ),
            );
            await tester.pumpAndSettle();
          }
        }

        Future<void> open() async {
          await tester.tap(
            find.byKey(
              ValueKey(
                calendar ? 'calendar-day-add-button' : 'dashboard-add-button',
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            calendar
                ? find.text('Add a day record')
                : find.byKey(const ValueKey('add-entry-action')),
          );
          await tester.pump();
          await waitForNativeSave(
            tester,
            () => find.text('Draft saved on this device').evaluate().isNotEmpty,
          );
        }

        const text = '  Inspected panel\nNeeds follow-up  ';
        try {
          await mount();
          await open();
          final field = find.byKey(const ValueKey('day-note-description'));
          await tester.tap(find.textContaining('Record time:'));
          await tester.pumpAndSettle();
          Navigator.of(
            tester.element(find.byType(TimePickerDialog)),
          ).pop(const TimeOfDay(hour: 13, minute: 47));
          await tester.pumpAndSettle();
          await tester.enterText(field, text);
          await tester.pump();
          await waitForNativeSave(
            tester,
            () => find.text('Draft saved on this device').evaluate().isNotEmpty,
          );
          await tester.tap(find.text('Keep unfinished'));
          await tester.pump();
          await waitForNativeSave(tester, () => field.evaluate().isEmpty);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          notes.dispose();
          await tester.runAsync(db.close);
          await mount();
          await open();
          expect(tester.widget<TextField>(field).controller!.text, text);
          await tester.runAsync(
            () => db.customStatement(
              "CREATE TRIGGER fail_note_draft BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'fail'); END",
            ),
          );
          await tester.tap(find.byKey(const ValueKey('save-day-note')));
          await tester.pump();
          await waitForNativeSave(
            tester,
            () => notes.error != null && !notes.isSaving,
          );
          expect(tester.widget<TextField>(field).controller!.text, text);
          expect(notes.records, isEmpty);
          await tester.runAsync(
            () => db.customStatement('DROP TRIGGER fail_note_draft'),
          );
          await tester.tap(find.byKey(const ValueKey('save-day-note')));
          await tester.pump();
          await waitForNativeSave(tester, () => field.evaluate().isEmpty);
          expect(notes.records.single.text, text);
          expect(notes.records.single.timeMinutes, 827);
          final selectedDay = calendar
              ? dashboardToday.subtract(const Duration(days: 1))
              : dashboardToday;
          expect(
            notes.records.single.date,
            '${selectedDay.year.toString().padLeft(4, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}',
          );
          expect(find.text(text), findsOneWidget);
          expect(
            await tester.runAsync(() => db.select(db.localDrafts).get()),
            isEmpty,
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          notes.dispose();
          await tester.runAsync(db.close);
          await mount();
          expect(find.text(text), findsOneWidget);
          expect(notes.records, hasLength(1));
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          notes.dispose();
          await tester.runAsync(db.close);
          await tester.runAsync(() => directory.delete(recursive: true));
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      },
    );
  }
}
