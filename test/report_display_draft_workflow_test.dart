import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/preferences/report_display_preferences.dart';
import 'package:ui_lab_2_1/src/data/storage/app_preference_keys.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/report_display_draft_workflow.dart';

import 'package:ui_lab_2_1/src/data/storage/preference_draft_baseline.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'legacy report choices survive failed confirmation and reopen without changing other preferences',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var repository = await LocalAppPreferencesStore.open(db);
      await repository.save('measurementSystem', 'metric');
      const choices = {
        'showInvoicedRevenue': false,
        'showMoneyCollected': true,
        'showRecordedExpenses': false,
        'showEstimatedGrossProfit': true,
        'showVehicleHealth': false,
      };
      await repository.drafts.save(
        organizationId: 'device',
        domain: AppPreferenceKeys.reportDisplayDraftDomain,
        draftId: AppPreferenceKeys.reportDisplayDraftId,
        ownerId: 'device',
        expectedRevision: 0,
        payload: choices,
        occurredAt: DateTime.utc(2026, 9, 10),
      );
      var controller = AppPreferencesController(storage: repository);
      var workflow = (await controller.openReportDisplayDraft(
        initial: const ReportDisplayPreferences.defaults(),
      ))!;
      expect(workflow.session.input, choices);
      await db.customStatement(
        "CREATE TRIGGER reject_reports BEFORE UPDATE ON local_metadata WHEN NEW.metadata_key = 'device.app-preferences.v1' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isFalse);
      expect(controller.reportDisplayChoice('showInvoicedRevenue'), isTrue);
      await workflow.session.close();
      controller.dispose();
      await harness.close(db);
      db = await harness.open();
      repository = await LocalAppPreferencesStore.open(db);
      controller = AppPreferencesController(storage: repository);
      addTearDown(controller.dispose);
      workflow = (await controller.openReportDisplayDraft(
        initial: const ReportDisplayPreferences.defaults(),
      ))!;
      final restored = Map<String, Object?>.from(workflow.session.input);
      expect(restored.remove(PreferenceDraftBaseline.payloadKey), isNotNull);
      expect(restored, choices);
      await db.customStatement('DROP TRIGGER reject_reports');
      expect(await workflow.confirm(), isTrue);
      for (final entry in choices.entries) {
        expect(controller.reportDisplayChoice(entry.key), entry.value);
      }
      expect(repository.values['measurementSystem'], 'metric');
      expect(() => workflow.confirm(), throwsStateError);
      expect(
        await repository.drafts.find(
          organizationId: 'device',
          domain: AppPreferenceKeys.reportDisplayDraftDomain,
          draftId: AppPreferenceKeys.reportDisplayDraftId,
          ownerId: 'device',
        ),
        isNull,
      );
      await workflow.session.close();
    },
  );

  test(
    'incomplete legacy report payload is retained instead of silently defaulted',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final repository = await LocalAppPreferencesStore.open(
        await harness.open(),
      );
      const payload = {'showInvoicedRevenue': false};
      await repository.drafts.save(
        organizationId: 'device',
        domain: AppPreferenceKeys.reportDisplayDraftDomain,
        draftId: AppPreferenceKeys.reportDisplayDraftId,
        ownerId: 'device',
        expectedRevision: 0,
        payload: payload,
        occurredAt: DateTime.utc(2026, 9, 10),
      );
      final controller = AppPreferencesController(storage: repository);
      addTearDown(controller.dispose);
      await expectLater(
        controller.openReportDisplayDraft(
          initial: const ReportDisplayPreferences.defaults(),
        ),
        throwsA(isA<TypeError>()),
      );
      final retained = (await repository.drafts.find(
        organizationId: 'device',
        domain: AppPreferenceKeys.reportDisplayDraftDomain,
        draftId: AppPreferenceKeys.reportDisplayDraftId,
        ownerId: 'device',
      ))!;
      expect(repository.drafts.decode(retained), payload);
      expect(retained.revision, 1);
      expect(repository.values, isEmpty);
    },
  );
}
