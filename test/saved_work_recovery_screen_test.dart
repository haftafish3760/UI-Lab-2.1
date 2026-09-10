import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/preferences/work_display_preferences.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_hub.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/work_display_draft_workflow.dart';
import 'package:ui_lab_2_1/src/shared/preference_draft_recovery.dart';
import 'package:ui_lab_2_1/src/shell/saved_work_recovery_screen.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final (width, failRelease) in [
    (390.0, false),
    (1400.0, false),
    (390.0, true),
  ]) {
    testWidgets(
      'saved work retains until confirmed discard at $width release failure=$failRelease',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final db = (await tester.runAsync(harness.open))!;
        final repository = (await tester.runAsync(
          () => LocalAppPreferencesStore.open(db),
        ))!;
        final owner = AppPreferencesController(storage: repository);
        final draft = (await tester.runAsync(
          () => owner.openWorkDisplayDraft(
            initial: const WorkDisplayPreferences(showDailySummaries: false),
          ),
        ))!;
        await finishNativeOperation(tester, draft.session.close);
        final recovery = PreferenceDraftRecovery(owner);
        final hub = DraftRecoveryHub<Object>([
          DraftRecoveryProvider(
            id: 'preferences',
            label: 'Settings',
            list: recovery.list,
            resume: recovery.resume,
            discard: recovery.discard,
          ),
        ]);
        var opened = 0;
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1100),
                  textScaler: TextScaler.linear(1.6),
                ),
                child: SavedWorkRecoveryScreen(
                  hub: hub,
                  onResume: (_, workflow) async {
                    expect(
                      (workflow as ResumedWorkPreferences)
                          .workflow
                          .input
                          .showDailySummaries,
                      isFalse,
                    );
                    if (failRelease) {
                      await db.customStatement(
                        "CREATE TRIGGER reject_recovery_save BEFORE UPDATE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
                      );
                      workflow.workflow.updateInput(
                        const WorkDisplayPreferences(showDailySummaries: true),
                      );
                    }
                    opened++;
                  },
                ),
              ),
            ),
          );
          await waitForNativeSave(
            tester,
            () => find.text('Continue').evaluate().isNotEmpty,
          );
          await tester.tap(find.text('Continue'));
          await waitForNativeSave(
            tester,
            () =>
                opened == 1 &&
                find.text('Ready to continue').evaluate().isNotEmpty &&
                tester
                        .widget<TextButton>(
                          find.widgetWithText(TextButton, 'Continue'),
                        )
                        .onPressed !=
                    null &&
                find.byType(LinearProgressIndicator).evaluate().isEmpty,
          );
          await tester.pumpAndSettle();
          if (failRelease) {
            expect(
              find.textContaining('Some recent changes could not be saved'),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            await tester.runAsync(
              () => db.customStatement('DROP TRIGGER reject_recovery_save'),
            );
            final retained = (await tester.runAsync(
              () => owner.openWorkDisplayDraft(
                initial: const WorkDisplayPreferences(),
              ),
            ))!;
            expect(retained.input.showDailySummaries, isFalse);
            await finishNativeOperation(tester, retained.session.close);
            return;
          }
          await tester.tap(find.text('Discard input'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Keep input'));
          await tester.pumpAndSettle();
          expect((await tester.runAsync(recovery.list))!, hasLength(1));
          await tester.tap(find.text('Discard input'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(TextButton, 'Discard input').last,
          );
          await waitForNativeSave(
            tester,
            () => find.text('No unfinished work found.').evaluate().isNotEmpty,
          );
          expect((await tester.runAsync(recovery.list))!, isEmpty);
          expect(repository.values, isEmpty);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          owner.dispose();
          await tester.runAsync(harness.dispose);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      },
    );
  }
}
