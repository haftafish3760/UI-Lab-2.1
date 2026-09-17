import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/workday/stored_workday_record.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'Dashboard reloads paused workday and failed End remains editable',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1100);
      tester.view.devicePixelRatio = 1;
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('dashboard-workday-'),
      ))!;
      late LocalDatabase db;
      late WorkdayPersistenceSession session;
      Future<void> mount() async {
        await tester.runAsync(() async {
          db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
          session = await openUiLabWorkdaySession(db);
        });
        await tester.pumpWidget(
          UiLabApp(workdaySession: session, draftStore: LocalDraftStore(db)),
        );
        await tester.pumpAndSettle();
      }

      Future<void> action(String key) async {
        await tester.tap(
          find.byKey(const ValueKey('dashboard-inline-actions')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('workday-action-$key')));
        await tester.pump();
      }

      Future<void> expandEntries() async {
        final button = find.byKey(const ValueKey('entries-expand-button'));
        if (find
            .descendant(of: button, matching: find.textContaining('Show all'))
            .evaluate()
            .isNotEmpty) {
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
        }
      }

      try {
        await mount();
        final start = find.byKey(const ValueKey('start-workday-button'));
        await tester.ensureVisible(start);
        await tester.tap(start);
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find.text('Draft saved on this device').evaluate().isNotEmpty,
        );
        await tester.enterText(
          find.byKey(const ValueKey('start-day-odometer-field')),
          '1234.5',
        );
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find.text('Draft saved on this device').evaluate().isNotEmpty,
        );
        final confirm = find.byKey(
          const ValueKey('confirm-start-workday-button'),
        );
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('active-workday-overview'))
              .evaluate()
              .isNotEmpty,
        );
        await expandEntries();
        expect(find.text('Workday started'), findsOneWidget);
        await action('pauseOrResume');
        await waitForNativeSave(
          tester,
          () =>
              session.activeFor('alex')?.record.status ==
                  StoredWorkdayStatus.paused &&
              !session.isSaving,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        session.dispose();
        await tester.runAsync(db.close);
        await mount();
        expect(find.text('Paused'), findsOneWidget);
        await expandEntries();
        expect(find.text('Workday started'), findsOneWidget);
        await action('endDay');
        await waitForNativeSave(
          tester,
          () => find.text('Draft saved on this device').evaluate().isNotEmpty,
        );
        final ending = find.byKey(const ValueKey('ending-odometer-field'));
        await tester.enterText(ending, '1240.');
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find.text('Draft saved on this device').evaluate().isNotEmpty,
        );
        await tester.tap(find.text('Keep workday open'));
        await tester.pump();
        await waitForNativeSave(tester, () => ending.evaluate().isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        session.dispose();
        await tester.runAsync(db.close);
        await mount();
        await action('endDay');
        await waitForNativeSave(
          tester,
          () => find.text('Draft saved on this device').evaluate().isNotEmpty,
        );
        expect(tester.widget<TextField>(ending).controller!.text, '1240.');
        await tester.enterText(ending, '1240.0');
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find.text('Draft saved on this device').evaluate().isNotEmpty,
        );
        await tester.runAsync(
          () => db.customStatement(
            "CREATE TRIGGER fail_end BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'fail'); END",
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('confirm-end-workday-button')),
        );
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => session.error != null && !session.isSaving,
        );
        expect(tester.widget<TextField>(ending).controller!.text, '1240.0');
        expect(
          session.activeFor('alex')!.record.status,
          StoredWorkdayStatus.paused,
        );
        await tester.runAsync(
          () => db.customStatement('DROP TRIGGER fail_end'),
        );
        await tester.tap(
          find.byKey(const ValueKey('confirm-end-workday-button')),
        );
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('ending-odometer-field'))
              .evaluate()
              .isEmpty,
        );
        expect(session.activeFor('alex'), isNull);
        await expandEntries();
        expect(find.text('Workday ended'), findsOneWidget);
        expect(session.odometerFor('transit-12')!.readingTenths, 12400);
        expect(
          await tester.runAsync(() => db.select(db.localDrafts).get()),
          isEmpty,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        session.dispose();
        await tester.runAsync(db.close);
        await mount();
        expect(session.activeFor('alex'), isNull);
        await expandEntries();
        expect(find.text('Workday ended'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('active-workday-overview')),
          findsNothing,
        );
        expect(session.odometerFor('transit-12')!.readingTenths, 12400);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        session.dispose();
        await tester.runAsync(db.close);
        await tester.runAsync(() => directory.delete(recursive: true));
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );
}
