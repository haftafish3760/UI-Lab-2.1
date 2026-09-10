import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'Dashboard choices survive reopen; failed toggle preserves active setting',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1100);
      tester.view.devicePixelRatio = 1;
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var preferences = (await tester.runAsync(
        () => LocalAppPreferencesStore.open(db),
      ))!;
      final checkbox = find.byKey(
        const ValueKey('dashboard-action-setting-pauseOrResume'),
      );
      Future<void> open() async {
        await tester.pumpWidget(UiLabApp(preferencesStore: preferences));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('dashboard-settings-button')),
        );
        await tester.pumpAndSettle();
      }

      try {
        await open();
        expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);
        await tester.tap(checkbox);
        await waitForNativeSave(
          tester,
          () => tester.widget<CheckboxListTile>(checkbox).value == false,
        );
        // No explicit settings Save: simulate route/app disposal after acknowledgment.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(() => harness.close(db));
        db = (await tester.runAsync(harness.open))!;
        preferences = (await tester.runAsync(
          () => LocalAppPreferencesStore.open(db),
        ))!;
        await open();
        expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);
        await tester.runAsync(
          () => db.customStatement(
            "CREATE TRIGGER fail_dashboard_setting BEFORE UPDATE ON local_metadata BEGIN SELECT RAISE(ABORT, 'fail'); END",
          ),
        );
        await tester.tap(checkbox);
        await waitForNativeSave(
          tester,
          () => find
              .textContaining('Dashboard settings were not saved.')
              .evaluate()
              .isNotEmpty,
        );
        expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);
        await tester.runAsync(
          () => db.customStatement('DROP TRIGGER fail_dashboard_setting'),
        );
        await tester.tap(find.text('Retry'));
        await waitForNativeSave(
          tester,
          () => tester.widget<CheckboxListTile>(checkbox).value == true,
        );
        expect(
          tester
              .widget<CheckboxListTile>(
                find.byKey(const ValueKey('dashboard-action-setting-endDay')),
              )
              .onChanged,
          isNull,
        );
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
