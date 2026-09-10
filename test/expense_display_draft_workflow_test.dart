import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/preferences/expense_display_draft_input.dart';
import 'package:ui_lab_2_1/src/data/preferences/expense_display_preferences.dart';
import 'package:ui_lab_2_1/src/data/storage/app_preference_keys.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/expense_display_draft_workflow.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'unfinished expense choices survive reopen; completion is blocked until resolved and confirmed atomically',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var repository = await LocalAppPreferencesStore.open(db);
      var controller = AppPreferencesController(storage: repository);
      var workflow = (await controller.openExpenseDisplayDraft(
        initial: const ExpenseDisplayPreferences.defaults(),
      ))!;
      final categories = {ExpenseCategory.fuel, ExpenseCategory.tools};
      final receipts = {ExpenseCategory.tools: ExpenseReceiptType.detailed};
      final input = ExpenseDisplayDraftInput(
        preferences: const ExpenseDisplayPreferences.defaults(),
        pendingCategories: categories,
        pendingReceiptTypes: receipts,
      );
      categories.clear();
      receipts.clear();
      workflow.updateInput(input);
      await expectLater(workflow.confirm(), throwsStateError);
      expect(controller.expenseDisplay, isNull);
      expect(workflow.input.pendingCategories, {
        ExpenseCategory.fuel,
        ExpenseCategory.tools,
      });
      expect(workflow.input.pendingReceiptTypes, {
        ExpenseCategory.tools: ExpenseReceiptType.detailed,
      });
      final legacy = workflow.session.input;
      await workflow.session.close();
      controller.dispose();
      await harness.close(db);
      db = await harness.open();
      repository = await LocalAppPreferencesStore.open(db);
      controller = AppPreferencesController(storage: repository);
      addTearDown(controller.dispose);
      workflow = (await controller.openExpenseDisplayDraft(
        initial: const ExpenseDisplayPreferences.defaults(),
      ))!;
      expect(workflow.session.input, legacy);
      final restored = workflow.input;
      final accepted = ExpenseDisplayPreferences(
        showJobLinks: false,
        categoryMode: ExpenseCategoryDisplayMode.custom,
        customCategories: restored.pendingCategories!.toList(),
        receiptTypes: Map.of(restored.pendingReceiptTypes!),
      );
      workflow.updateInput(ExpenseDisplayDraftInput(preferences: accepted));
      await db.customStatement(
        "CREATE TRIGGER reject_expense_preferences BEFORE INSERT ON local_metadata WHEN NEW.metadata_key = 'device.app-preferences.v1' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isFalse);
      expect(controller.expenseDisplay, isNull);
      expect(workflow.input.preferences.toPayload(), accepted.toPayload());
      await db.customStatement('DROP TRIGGER reject_expense_preferences');
      expect(await workflow.confirm(), isTrue);
      expect(controller.expenseDisplay, accepted.toPayload());
      expect(() => workflow.confirm(), throwsStateError);
      expect(
        await repository.drafts.find(
          organizationId: 'device',
          domain: AppPreferenceKeys.expenseDisplayDraftDomain,
          draftId: AppPreferenceKeys.expenseDisplayDraftId,
          ownerId: 'device',
        ),
        isNull,
      );
      await workflow.session.close();
    },
  );

  test(
    'invalid legacy pending choices remain byte-for-byte recoverable instead of being overwritten',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final repository = await LocalAppPreferencesStore.open(
        await harness.open(),
      );
      final payload = {
        'preferences': const ExpenseDisplayPreferences.defaults().toPayload(),
        'pendingCategories': ['fuel', 'fuel'],
        'pendingReceiptTypes': null,
      };
      await repository.drafts.save(
        organizationId: 'device',
        domain: AppPreferenceKeys.expenseDisplayDraftDomain,
        draftId: AppPreferenceKeys.expenseDisplayDraftId,
        ownerId: 'device',
        expectedRevision: 0,
        payload: payload,
        occurredAt: DateTime.utc(2026, 9, 10),
      );
      Future<SavedDraft?> saved() => repository.drafts.find(
        organizationId: 'device',
        domain: AppPreferenceKeys.expenseDisplayDraftDomain,
        draftId: AppPreferenceKeys.expenseDisplayDraftId,
        ownerId: 'device',
      );
      final before = (await saved())!;
      final controller = AppPreferencesController(storage: repository);
      addTearDown(controller.dispose);
      await expectLater(
        controller.openExpenseDisplayDraft(
          initial: const ExpenseDisplayPreferences.defaults(),
        ),
        throwsFormatException,
      );
      final after = (await saved())!;
      expect(after.payload, before.payload);
      expect(after.revision, before.revision);
      expect(repository.values, isEmpty);
    },
  );
}
