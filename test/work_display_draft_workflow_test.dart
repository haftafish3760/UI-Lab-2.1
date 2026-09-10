import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/preferences/work_display_preferences.dart';
import 'package:ui_lab_2_1/src/data/storage/app_preference_keys.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/work_display_draft_workflow.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'Work display draft survives rollback/reopen and applies only on confirmed commit',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var controller = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      var workflow = (await controller.openWorkDisplayDraft(
        initial: const WorkDisplayPreferences(),
      ))!;
      workflow.updateInput(
        const WorkDisplayPreferences(
          showEmployeeCards: false,
          includeCompletedWork: false,
        ),
      );
      await db.customStatement(
        "CREATE TRIGGER reject_preferences BEFORE INSERT ON local_metadata WHEN NEW.metadata_key = 'device.app-preferences.v1' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isFalse);
      expect(controller.workShowEmployeeCards, isTrue);
      expect(controller.workIncludeCompletedWork, isTrue);
      await workflow.session.close();
      controller.dispose();
      await harness.close(db);
      db = await harness.open();
      controller = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      addTearDown(controller.dispose);
      workflow = (await controller.openWorkDisplayDraft(
        initial: const WorkDisplayPreferences(),
      ))!;
      expect(workflow.input.showEmployeeCards, isFalse);
      expect(workflow.input.includeCompletedWork, isFalse);
      expect(workflow.input.showDailySummaries, isTrue);
      await db.customStatement('DROP TRIGGER reject_preferences');
      expect(await workflow.confirm(), isTrue);
      expect(controller.workShowEmployeeCards, isFalse);
      expect(controller.workIncludeCompletedWork, isFalse);
      expect(() => workflow.confirm(), throwsStateError);
      expect(
        await controller.storage!.drafts.find(
          organizationId: 'device',
          domain: AppPreferenceKeys.workDisplayDraftDomain,
          draftId: AppPreferenceKeys.workDisplayDraftId,
          ownerId: 'device',
        ),
        isNull,
      );
      await workflow.session.close();
    },
  );

  test(
    'unreadable legacy preference draft is retained instead of replaced by initial choices',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final repository = await LocalAppPreferencesStore.open(
        await harness.open(),
      );
      final payload = {
        'showEmployeeCards': 'unsupported',
        'showDailySummaries': false,
        'includeCompletedWork': false,
      };
      await repository.drafts.save(
        organizationId: 'device',
        domain: AppPreferenceKeys.workDisplayDraftDomain,
        draftId: AppPreferenceKeys.workDisplayDraftId,
        ownerId: 'device',
        expectedRevision: 0,
        payload: payload,
        occurredAt: DateTime.utc(2026, 9, 10),
      );
      final controller = AppPreferencesController(storage: repository);
      addTearDown(controller.dispose);
      await expectLater(
        controller.openWorkDisplayDraft(
          initial: const WorkDisplayPreferences(),
        ),
        throwsA(isA<TypeError>()),
      );
      final retained = await repository.drafts.find(
        organizationId: 'device',
        domain: AppPreferenceKeys.workDisplayDraftDomain,
        draftId: AppPreferenceKeys.workDisplayDraftId,
        ownerId: 'device',
      );
      expect(retained, isNotNull);
      expect(repository.drafts.decode(retained!), payload);
      expect(retained.revision, 1);
      expect(controller.workShowEmployeeCards, isTrue);
      expect(repository.values, isEmpty);
    },
  );
}
