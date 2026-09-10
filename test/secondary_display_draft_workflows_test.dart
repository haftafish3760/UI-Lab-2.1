import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/preferences/receipt_intake_display_preferences.dart';
import 'package:ui_lab_2_1/src/data/preferences/work_record_display_preferences.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/secondary_display_draft_workflows.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'receipt and Work-list choices reopen independently and only their own confirmation applies',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var controller = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      var receipt = (await controller.openReceiptDisplayDraft(
        initial: const ReceiptIntakeDisplayPreferences(),
      ))!;
      var jobs = (await controller.openWorkListDisplayDraft(
        workspaceId: 'jobs',
        initial: const WorkRecordDisplayPreferences(),
      ))!;
      var invoices = (await controller.openWorkListDisplayDraft(
        workspaceId: 'invoices',
        initial: const WorkRecordDisplayPreferences(),
      ))!;
      receipt.updateInput(
        const ReceiptIntakeDisplayPreferences(showEvidenceReminders: false),
      );
      jobs.updateInput(
        const WorkRecordDisplayPreferences(showAssignments: false),
      );
      invoices.updateInput(
        const WorkRecordDisplayPreferences(includeClosedRecords: false),
      );
      await receipt.session.flush();
      await jobs.session.flush();
      await invoices.session.flush();
      expect(await jobs.confirm(), isTrue);
      expect(controller.workListChoice('jobs', 'showAssignments'), isFalse);
      expect(
        controller.workListChoice('invoices', 'includeClosedRecords'),
        isTrue,
      );
      expect(controller.receiptShowEvidenceReminders, isTrue);
      await receipt.session.close();
      await jobs.session.close();
      await invoices.session.close();
      controller.dispose();
      await harness.close(db);
      db = await harness.open();
      controller = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      addTearDown(controller.dispose);
      receipt = (await controller.openReceiptDisplayDraft(
        initial: const ReceiptIntakeDisplayPreferences(),
      ))!;
      invoices = (await controller.openWorkListDisplayDraft(
        workspaceId: 'invoices',
        initial: const WorkRecordDisplayPreferences(),
      ))!;
      expect(receipt.input.showEvidenceReminders, isFalse);
      expect(invoices.input.includeClosedRecords, isFalse);
      expect(controller.workListChoice('jobs', 'showAssignments'), isFalse);
      expect(await receipt.confirm(), isTrue);
      expect(await invoices.confirm(), isTrue);
      expect(controller.receiptShowEvidenceReminders, isFalse);
      expect(
        controller.workListChoice('invoices', 'includeClosedRecords'),
        isFalse,
      );
      expect(controller.workListChoice('jobs', 'showAssignments'), isFalse);
      expect(() => invoices.confirm(), throwsStateError);
      await receipt.session.close();
      await invoices.session.close();
      await expectLater(
        controller.openWorkListDisplayDraft(
          workspaceId: 'unknown',
          initial: const WorkRecordDisplayPreferences(),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'stale receipt settings editor cannot confirm or consume newer draft choices',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final controller = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(await harness.open()),
      );
      addTearDown(controller.dispose);
      final old = (await controller.openReceiptDisplayDraft(
        initial: const ReceiptIntakeDisplayPreferences(),
      ))!;
      await old.session.flush();
      final latest = (await controller.openReceiptDisplayDraft(
        initial: const ReceiptIntakeDisplayPreferences(),
      ))!;
      latest.updateInput(
        const ReceiptIntakeDisplayPreferences(
          showReviewChecklist: false,
          showEvidenceReminders: false,
        ),
      );
      await latest.session.flush();
      expect(await old.confirm(), isFalse);
      expect(controller.receiptShowReviewChecklist, isTrue);
      expect(controller.receiptShowEvidenceReminders, isTrue);
      expect(await latest.confirm(), isTrue);
      expect(controller.receiptShowReviewChecklist, isFalse);
      expect(controller.receiptShowEvidenceReminders, isFalse);
      await old.session.close();
      await latest.session.close();
    },
  );
}
