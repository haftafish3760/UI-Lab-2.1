import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_intake_settings_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'Receipt settings recover raw choices; failed Save preserves draft and active values',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1100);
      tester.view.devicePixelRatio = 1;
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var preferences = (await tester.runAsync(
        () => LocalAppPreferencesStore.open(db),
      ))!;
      final toggle = find.widgetWithText(
        SwitchListTile,
        'Show review checklist',
      );
      final save = find.byKey(
        const ValueKey('save-receipt-intake-settings-button'),
      );
      Future<void> open() async {
        final controller = AppPreferencesController(storage: preferences);
        await tester.pumpWidget(
          AppPreferencesScope(
            controller: controller,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReceiptIntakeSettingsScreen(
                          initial: readReceiptIntakeDisplayPreferences(
                            context,
                            const ReceiptIntakeDisplayPreferences(),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Open settings'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open settings'));
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
        domain: LocalAppPreferencesStore.receiptDisplayDraftDomain,
      );
      try {
        await open();
        expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
        await tester.tap(toggle);
        await savedInput();
        expect(preferences.values['receiptShowReviewChecklist'], isNull);
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
              .textContaining('Receipt display settings were not applied.')
              .evaluate()
              .isNotEmpty,
        );
        expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
        expect(preferences.values['receiptShowReviewChecklist'], isNull);
        expect(await tester.runAsync(drafts), hasLength(1));
        final controller = AppPreferencesScope.of(tester.element(toggle));
        expect(controller.canRetrySave, isFalse);
        expect(controller.saveError, isNull);
        await tester.runAsync(
          () => db.customStatement('DROP TRIGGER fail_work_choice'),
        );
        await tester.tap(save);
        await waitForNativeSave(tester, () => toggle.evaluate().isEmpty);
        expect(controller.receiptShowReviewChecklist, isFalse);
        expect(
          controller.workListChoice('estimates', 'showStatusDetails'),
          isTrue,
        );
        expect(
          controller.workListChoice('invoices', 'showStatusDetails'),
          isTrue,
        );
        expect(preferences.values['receiptShowReviewChecklist'], 'false');
        expect(await tester.runAsync(drafts), isEmpty);
        final reopened = (await tester.runAsync(
          () => LocalAppPreferencesStore.open(db),
        ))!;
        expect(reopened.values['receiptShowReviewChecklist'], 'false');
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
