import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/screens/work/work_settings_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/work_display_draft_workflow.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final differentStore in [false, true]) {
    testWidgets(
      'Work settings selected recovery different store: $differentStore',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final db = (await tester.runAsync(harness.open))!;
        final repository = (await tester.runAsync(
          () => LocalAppPreferencesStore.open(db),
        ))!;
        final owner = AppPreferencesController(storage: repository);
        final replacement = AppPreferencesController(
          storage: (await tester.runAsync(
            () => LocalAppPreferencesStore.open(db),
          ))!,
        );
        final workflow = (await tester.runAsync(
          () => owner.openWorkDisplayDraft(
            initial: const WorkDisplayPreferences(showDailySummaries: false),
          ),
        ))!;
        try {
          await tester.pumpWidget(
            AppPreferencesScope(
              controller: differentStore ? replacement : owner,
              child: MaterialApp(
                home: WorkSettingsScreen(
                  initial: const WorkDisplayPreferences(),
                  recoveredWorkflow: workflow,
                ),
              ),
            ),
          );
          final toggle = find.byKey(
            const ValueKey('show-work-daily-summaries'),
          );
          if (differentStore) {
            await waitForNativeSave(
              tester,
              () => find
                  .textContaining('could not be opened')
                  .evaluate()
                  .isNotEmpty,
            );
            expect(toggle, findsNothing);
          } else {
            await waitForNativeSave(tester, () => toggle.evaluate().isNotEmpty);
            expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
            await tester.tap(toggle);
            await waitForNativeSave(
              tester,
              () =>
                  find.text('Draft saved on this device').evaluate().isNotEmpty,
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          expect(repository.values, isEmpty);
          final reopened = (await tester.runAsync(
            () => owner.openWorkDisplayDraft(
              initial: const WorkDisplayPreferences(),
            ),
          ))!;
          expect(reopened.input.showDailySummaries, !differentStore);
          await finishNativeOperation(tester, reopened.session.close);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          owner.dispose();
          replacement.dispose();
          await tester.runAsync(harness.dispose);
        }
      },
    );
  }
}
