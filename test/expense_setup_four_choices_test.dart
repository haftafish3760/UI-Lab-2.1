import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_welcome_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_entry_choice_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_choice_card.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_intake_screen.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';

Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'direct new receipt also asks instead of silently choosing Basic',
    (tester) async {
      final prefs = AppPreferencesController();
      addTearDown(prefs.dispose);
      await prefs.completeExpenseSetup(
        detailPreference: ReceiptDetailPreference.mixed,
        assistance: false,
      );
      await tester.pumpWidget(
        AppPreferencesScope(
          controller: prefs,
          child: MaterialApp(
            home: ReceiptIntakeScreen(expenseDate: DateTime(2030)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('expense-entry-choice-screen')),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<ReceiptChoiceCard>(find.byType(ReceiptChoiceCard))
            .every((card) => card.selected == false),
        isTrue,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('continue-expense-setup')),
            )
            .onPressed,
        isNull,
      );
    },
  );
  for (final reduceMotion in [false, true]) {
    testWidgets(
      'four choices start empty; back retains choice; motion $reduceMotion',
      (tester) async {
        final prefs = AppPreferencesController();
        addTearDown(prefs.dispose);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
            home: ExpenseWelcomeScreen(preferences: prefs),
          ),
        );
        expect(
          tester
              .widgetList<ReceiptChoiceCard>(find.byType(ReceiptChoiceCard))
              .length,
          4,
        );
        expect(
          tester
              .widgetList<ReceiptChoiceCard>(find.byType(ReceiptChoiceCard))
              .every((card) => card.selected == false),
          isTrue,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('expense-welcome-continue')),
              )
              .onPressed,
          isNull,
        );
        await tap(tester, 'expense-setup-not-sure');
        await tester.ensureVisible(
          find.byKey(const ValueKey('expense-welcome-continue')),
        );
        await tester.tap(
          find.byKey(const ValueKey('expense-welcome-continue')),
        );
        await tester.pump();
        final switcher = tester.widget<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        );
        expect(
          switcher.duration,
          reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        );
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ReceiptChoiceCard>(
                find.byKey(const ValueKey('expense-setup-not-sure')),
              )
              .selected,
          isTrue,
        );
        expect(prefs.expenseSetupCompleted, isFalse);
        expect(prefs.receiptDetailPreference, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final preference in ReceiptDetailPreference.values) {
    test('preference ${preference.name} survives database reopen', () async {
      final root = await Directory.systemTemp.createTemp(
        'four-receipt-choices-',
      );
      final file = File('${root.path}/test.sqlite');
      var db = LocalDatabase.file(file);
      var prefs = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      expect(
        await prefs.completeExpenseSetup(
          detailPreference: preference,
          assistance: false,
        ),
        isTrue,
      );
      await prefs.rememberReceiptDetail(true);
      prefs.dispose();
      await db.close();
      db = LocalDatabase.file(file);
      prefs = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      expect(prefs.receiptDetailPreference, preference);
      expect(
        prefs.chooseReceiptDetailEachTime,
        preference == ReceiptDetailPreference.mixed ||
            preference == ReceiptDetailPreference.notSureYet,
      );
      expect(prefs.expenseSetupCompleted, isTrue);
      prefs.dispose();
      await db.close();
      await root.delete(recursive: true);
    });
  }
  for (final preference in [
    ReceiptDetailPreference.mixed,
    ReceiptDetailPreference.notSureYet,
  ]) {
    testWidgets(
      '${preference.name} asks again despite the last receipt choice',
      (tester) async {
        final prefs = AppPreferencesController();
        addTearDown(prefs.dispose);
        await prefs.completeExpenseSetup(
          detailPreference: preference,
          assistance: false,
        );
        await prefs.rememberReceiptDetail(true);
        for (var receipt = 0; receipt < 2; receipt++) {
          await tester.pumpWidget(
            AppPreferencesScope(
              controller: prefs,
              child: MaterialApp(
                home: ExpenseEntryChoiceScreen(
                  key: ValueKey(receipt),
                  canAttachReceipt: true,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .widgetList<ReceiptChoiceCard>(find.byType(ReceiptChoiceCard))
                .every((card) => card.selected == false),
            isTrue,
          );
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const ValueKey('continue-expense-setup')),
                )
                .onPressed,
            isNull,
          );
          await tap(tester, 'receipt-every-item-choice');
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const ValueKey('continue-expense-setup')),
                )
                .onPressed,
            isNotNull,
          );
        }
      },
    );
  }
}
