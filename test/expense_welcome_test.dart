import 'dart:io';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'support/storage/native_widget_pump.dart';
import 'package:ui_lab_2_1/src/data/storage/app_preferences_repository.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_welcome_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_entry_choice_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_choice_card.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('failed setup stays open and a retry saves the chosen values', (
    tester,
  ) async {
    final store = _FailingPreferences();
    final preferences = AppPreferencesController(storage: store);
    addTearDown(preferences.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ExpenseWelcomeScreen(preferences: preferences),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tap(tester, 'expense-setup-detailed');
    await tap(tester, 'expense-welcome-continue');
    await tap(tester, 'expense-setup-assisted');
    await tap(tester, 'expense-welcome-continue');
    expect(
      find.textContaining('Your choices could not be saved'),
      findsOneWidget,
    );
    expect(preferences.expenseSetupCompleted, isFalse);
    expect(preferences.receiptAssistanceEnabled, isFalse);
    store.fail = false;
    await tap(tester, 'expense-welcome-continue');
    expect(find.text('Open'), findsOneWidget);
    expect(preferences.expenseSetupCompleted, isTrue);
    expect(preferences.receiptDetailedReceipts, isTrue);
    expect(preferences.receiptAssistanceEnabled, isTrue);
  });
  testWidgets(
    'first Expenses tap opens setup, back cancels, completion is remembered',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final root = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('expense-welcome-'),
      ))!;
      final persistence = (await tester.runAsync(
        () => LocalPersistence.open(directory: root),
      ))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(persistence.close);
        await tester.runAsync(() => root.delete(recursive: true));
      });
      await tester.pumpWidget(
        UiLabApp(
          expenseRepository: persistence.expenses,
          receiptDraftRepository: persistence.receiptDrafts,
          draftStore: persistence.drafts,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Expenses'), findsNothing);
      await tap(tester, 'app-destination-expenses');
      expect(find.text('Welcome to Expenses'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, 'app-destination-expenses');
      await tap(tester, 'expense-setup-detailed');
      await tap(tester, 'expense-welcome-continue');
      expect(find.text('Help with your receipts'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('expense-welcome-continue')),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, 'expense-setup-manual');
      await tap(tester, 'expense-welcome-continue');
      expect(find.byKey(const ValueKey('expenses-add-fab')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('expense-spending-month')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('expense-spending-year')), findsNothing);
      await tap(tester, 'app-destination-dashboard');
      await tap(tester, 'app-destination-expenses');
      expect(find.text('Welcome to Expenses'), findsNothing);
      await tap(tester, 'expenses-add-fab');
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('receipt-every-item-choice'))
            .evaluate()
            .isNotEmpty,
      );
      expect(
        tester
            .widget<ReceiptChoiceCard>(
              find.byKey(const ValueKey('receipt-every-item-choice')),
            )
            .selected,
        isTrue,
      );
    },
  );

  for (final dark in [false, true]) {
    for (final width in [320.0, 1440.0]) {
      testWidgets('setup spacing and large text: $width dark $dark', (
        tester,
      ) async {
        final preferences = AppPreferencesController();
        addTearDown(preferences.dispose);
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: ExpenseWelcomeScreen(preferences: preferences),
          ),
        );
        final basic = tester.getRect(
          find.byKey(const ValueKey('expense-setup-basic')),
        );
        final detailed = tester.getRect(
          find.byKey(const ValueKey('expense-setup-detailed')),
        );
        expect(detailed.top - basic.bottom, 24);
        expect(basic.width, detailed.width);
        await tap(tester, 'expense-setup-basic');
        await tap(tester, 'expense-welcome-continue');
        await tap(tester, 'expense-setup-assisted');
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Welcome to Expenses'), findsOneWidget);
        expect(preferences.expenseSetupCompleted, isFalse);
        expect(preferences.receiptAssistanceEnabled, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test(
    'setup saves atomically, survives reopen, fails without changing choices',
    () async {
      final directory = await Directory.systemTemp.createTemp('expense-setup-');
      final file = File('${directory.path}/test.sqlite');
      var db = LocalDatabase.file(file);
      var preferences = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      await preferences.setThemeMode(ThemeMode.dark);
      await db.customStatement(
        "CREATE TRIGGER fail_setup BEFORE UPDATE ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      expect(
        await preferences.completeExpenseSetup(
          detailed: true,
          assistance: true,
        ),
        isFalse,
      );
      expect(preferences.expenseSetupCompleted, isFalse);
      expect(preferences.receiptDetailedReceipts, isFalse);
      expect(preferences.receiptAssistanceEnabled, isFalse);
      await db.customStatement('DROP TRIGGER fail_setup');
      expect(
        await preferences.completeExpenseSetup(
          detailed: true,
          assistance: true,
        ),
        isTrue,
      );
      preferences.dispose();
      await db.close();
      db = LocalDatabase.file(file);
      preferences = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      expect(preferences.expenseSetupCompleted, isTrue);
      expect(preferences.receiptDetailedReceipts, isTrue);
      expect(preferences.receiptAssistanceEnabled, isTrue);
      expect(preferences.themeMode, ThemeMode.dark);
      await preferences.rememberReceiptDetail(false);
      expect(preferences.receiptAssistanceEnabled, isTrue);
      expect(await db.select(db.localRecords).get(), isEmpty);
      expect(await db.select(db.localChangeOutbox).get(), isEmpty);
      preferences.dispose();
      await db.close();
      await directory.delete(recursive: true);
    },
  );

  testWidgets(
    'Continue remembers last receipt choice without changing assistance',
    (tester) async {
      final preferences = AppPreferencesController();
      await preferences.completeExpenseSetup(detailed: true, assistance: true);
      addTearDown(preferences.dispose);
      ExpenseEntryChoice? choice;
      await tester.pumpWidget(
        AppPreferencesScope(
          controller: preferences,
          child: MaterialApp(
            home: ExpenseEntryChoiceScreen(
              canAttachReceipt: true,
              onContinue: (value) async {
                choice = value;
                return null;
              },
            ),
          ),
        ),
      );
      await tap(tester, 'receipt-total-only-choice');
      expect(preferences.receiptDetailedReceipts, isTrue);
      await tap(tester, 'continue-expense-setup');
      expect(choice!.type, ExpenseReceiptType.basic);
      expect(preferences.receiptDetailedReceipts, isFalse);
      expect(preferences.receiptAssistanceEnabled, isTrue);
    },
  );
}

class _FailingPreferences extends Fake implements AppPreferencesRepository {
  bool fail = true;
  @override
  Map<String, String> get values => {};
  @override
  bool get usingDefaultsAfterRecovery => false;
  @override
  Future<Map<String, String>> saveMany(
    Map<String, String> changes, {
    LocalDraftCheckpoint? draftCheckpoint,
  }) async {
    if (fail) throw StateError('injected storage failure');
    return changes;
  }
}
