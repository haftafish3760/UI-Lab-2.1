import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'Work settings draft survives reopen; only successful Save applies and consumes it',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1100);
      tester.view.devicePixelRatio = 1;
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var preferences = (await tester.runAsync(
        () => LocalAppPreferencesStore.open(db),
      ))!;
      final toggle = find.byKey(const ValueKey('show-work-daily-summaries'));
      final save = find.byKey(const ValueKey('save-work-settings'));
      Future<void> open() async {
        await tester.pumpWidget(UiLabApp(preferencesStore: preferences));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Work').first);
        await tester.pumpAndSettle();
        expect(find.text('My Jobs'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('work-settings-button')));
        await tester.pumpAndSettle();
        await waitForNativeSave(tester, () => toggle.evaluate().isNotEmpty);
      }

      Future<void> savedInput() async {
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find.text('Draft saved on this device').evaluate().isNotEmpty,
        );
      }

      Future<List<dynamic>> drafts() => LocalDraftStore(db).list(
        organizationId: 'device',
        ownerId: 'device',
        domain: LocalAppPreferencesStore.workDisplayDraftDomain,
      );
      try {
        await open();
        expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
        await tester.tap(toggle);
        await savedInput();
        expect(preferences.values['workShowDailySummaries'], isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(() => harness.close(db));
        db = (await tester.runAsync(harness.open))!;
        preferences = (await tester.runAsync(
          () => LocalAppPreferencesStore.open(db),
        ))!;
        await open();
        expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
        await savedInput();
        await tester.runAsync(
          () => db.customStatement(
            "CREATE TRIGGER fail_work_choice BEFORE INSERT ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected'); END",
          ),
        );
        await tester.tap(save);
        await waitForNativeSave(
          tester,
          () => find
              .textContaining('Work settings were not applied.')
              .evaluate()
              .isNotEmpty,
        );
        expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
        expect(preferences.values['workShowDailySummaries'], isNull);
        expect(await tester.runAsync(drafts), hasLength(1));
        final controller = AppPreferencesScope.of(tester.element(toggle));
        expect(controller.canRetrySave, isFalse);
        expect(controller.saveError, isNull);
        await tester.runAsync(
          () => db.customStatement('DROP TRIGGER fail_work_choice'),
        );
        await tester.tap(save);
        await waitForNativeSave(tester, () => toggle.evaluate().isEmpty);
        expect(find.text('My Jobs'), findsNothing);
        expect(find.text('Work Calendar'), findsOneWidget);
        expect(preferences.values['workShowDailySummaries'], 'false');
        expect(await tester.runAsync(drafts), isEmpty);
        final reopened = (await tester.runAsync(
          () => LocalAppPreferencesStore.open(db),
        ))!;
        expect(reopened.values['workShowDailySummaries'], 'false');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(harness.dispose);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );
}
