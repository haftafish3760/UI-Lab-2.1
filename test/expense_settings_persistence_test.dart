import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expenses_settings_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  test(
    'all category receipt types survive SQLite and invalid settings retain the original',
    () async {
      final harness = await DatabaseHarness.create();
      try {
        final db = await harness.open();
        final store = await LocalAppPreferencesStore.open(db);
        final expected = ExpenseDisplayPreferences(
          showJobLinks: false,
          categoryMode: ExpenseCategoryDisplayMode.custom,
          customCategories: ExpenseCategory.values.take(10).toList(),
          receiptTypes: {
            for (final c in ExpenseCategory.values)
              c: ExpenseReceiptType.detailed,
          },
        );
        await store.save('expenseDisplay', jsonEncode(expected.toPayload()));
        await harness.close(db);
        final reopened = await harness.open();
        final restored = await LocalAppPreferencesStore.open(reopened);
        final saved = restored.values['expenseDisplay']!;
        expect(
          ExpenseDisplayPreferences.fromPayload(jsonDecode(saved)).toPayload(),
          expected.toPayload(),
        );
        for (final invalid in [
          {
            ...expected.toPayload(),
            'customCategories': ['fuel', 'fuel'],
          },
          {
            ...expected.toPayload(),
            'customCategories': ExpenseCategory.values
                .take(11)
                .map((e) => e.name)
                .toList(),
          },
          {
            ...expected.toPayload(),
            'receiptTypes': {'unknown': 'detailed'},
          },
          {
            ...expected.toPayload(),
            'receiptTypes': {'fuel': 'automatic'},
          },
        ]) {
          await expectLater(
            restored.save('expenseDisplay', jsonEncode(invalid)),
            throwsArgumentError,
          );
          expect(
            (await LocalAppPreferencesStore.open(
              reopened,
            )).values['expenseDisplay'],
            saved,
          );
        }
      } finally {
        await harness.dispose();
      }
    },
  );

  for (final viewport in [const Size(390, 844), const Size(1400, 1100)]) {
    testWidgets(
      'Expense settings recover nested choices at ${viewport.width}; failed Save preserves input',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        var db = (await tester.runAsync(harness.open))!;
        var preferences = (await tester.runAsync(
          () => LocalAppPreferencesStore.open(db),
        ))!;
        final toggle = find.widgetWithText(SwitchListTile, 'Show related jobs');
        final save = find.byKey(const ValueKey('save-expense-settings-button'));
        Future<void> tapVisible(Finder target) async {
          await tester.ensureVisible(target);
          await tester.pump();
          await tester.tap(target);
        }

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
                          builder: (_) => ExpensesSettingsScreen(
                            initial: readExpenseDisplayPreferences(
                              context,
                              const ExpenseDisplayPreferences.defaults(),
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
          await tapVisible(find.text('Open settings'));
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
          domain: LocalAppPreferencesStore.expenseDisplayDraftDomain,
        );
        try {
          await open();
          expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
          await tapVisible(toggle);
          await tapVisible(
            find.byKey(const ValueKey('expense-category-mode-custom')),
          );
          await tester.pump();
          await tapVisible(
            find.byKey(const ValueKey('choose-expense-categories-button')),
          );
          await tester.pumpAndSettle();
          await tapVisible(find.widgetWithText(FilterChip, 'Fuel'));
          await savedInput();
          // Back retains unconfirmed nested choices.
          Navigator.of(tester.element(find.byType(AlertDialog))).pop();
          await tester.pumpAndSettle();
          await tapVisible(
            find.byKey(const ValueKey('expense-receipt-type-settings')),
          );
          await tester.pumpAndSettle();
          final fuel = find.widgetWithText(ListTile, 'Fuel');
          await tester.ensureVisible(fuel);
          await tapVisible(
            find.descendant(
              of: fuel,
              matching: find.byType(DropdownButton<ExpenseReceiptType>),
            ),
          );
          await tester.pumpAndSettle();
          await tapVisible(find.text('Detailed').last);
          await savedInput();
          expect(preferences.values['expenseDisplay'], isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await tester.runAsync(() => harness.close(db));
          db = (await tester.runAsync(harness.open))!;
          preferences = (await tester.runAsync(
            () => LocalAppPreferencesStore.open(db),
          ))!;
          await open();
          expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
          await tapVisible(save);
          await tester.pump();
          expect(preferences.values['expenseDisplay'], isNull);
          expect(
            find.text(
              'Finish or cancel your unfinished choices before saving settings.',
            ),
            findsWidgets,
          );
          await tapVisible(find.text('Continue category choices'));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<FilterChip>(find.widgetWithText(FilterChip, 'Fuel'))
                .selected,
            isTrue,
          );
          await tapVisible(find.text('Use categories'));
          await tester.pumpAndSettle();
          await tapVisible(find.text('Continue receipt-type choices'));
          await tester.pumpAndSettle();
          final recoveredFuel = find.widgetWithText(ListTile, 'Fuel');
          await tester.ensureVisible(recoveredFuel);
          expect(
            tester
                .widget<DropdownButton<ExpenseReceiptType>>(
                  find.descendant(
                    of: recoveredFuel,
                    matching: find.byType(DropdownButton<ExpenseReceiptType>),
                  ),
                )
                .value,
            ExpenseReceiptType.detailed,
          );
          await tapVisible(find.text('Use receipt types'));
          await savedInput();
          expect(
            find.text(
              'Finish or cancel your unfinished choices before saving settings.',
            ),
            findsNothing,
          );
          expect(
            find.text(
              'Detailed receipts: 2 categories · Other categories: Simple',
            ),
            findsOneWidget,
          );
          await tester.runAsync(
            () => db.customStatement(
              "CREATE TRIGGER fail_work_choice BEFORE INSERT ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected'); END",
            ),
          );
          await tapVisible(save);
          await waitForNativeSave(
            tester,
            () => find
                .textContaining('Expense display settings were not applied.')
                .evaluate()
                .isNotEmpty,
          );
          expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
          expect(preferences.values['expenseDisplay'], isNull);
          expect(await tester.runAsync(drafts), hasLength(1));
          final controller = AppPreferencesScope.of(tester.element(toggle));
          expect(controller.canRetrySave, isFalse);
          expect(controller.saveError, isNull);
          await tester.runAsync(
            () => db.customStatement('DROP TRIGGER fail_work_choice'),
          );
          await tapVisible(save);
          await waitForNativeSave(tester, () => toggle.evaluate().isEmpty);
          expect(controller.expenseDisplay!['showJobLinks'], isFalse);
          expect(controller.expenseDisplay!['customCategories'], ['fuel']);
          expect(
            (controller.expenseDisplay!['receiptTypes'] as Map)['fuel'],
            'detailed',
          );
          expect(
            controller.workListChoice('estimates', 'showStatusDetails'),
            isTrue,
          );
          expect(
            controller.workListChoice('invoices', 'showStatusDetails'),
            isTrue,
          );
          expect(
            preferences.values['expenseDisplay'],
            contains('"showJobLinks":false'),
          );
          expect(await tester.runAsync(drafts), isEmpty);
          final reopened = (await tester.runAsync(
            () => LocalAppPreferencesStore.open(db),
          ))!;
          expect(
            reopened.values['expenseDisplay'],
            contains('"showJobLinks":false'),
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
}
