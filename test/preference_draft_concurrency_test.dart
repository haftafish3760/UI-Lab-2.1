import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/data/storage/preference_draft_baseline.dart';
import 'package:ui_lab_2_1/src/data/preferences/work_display_preferences.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/work_display_draft_workflow.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'direct changes to the same settings cannot be overwritten by a reopened older draft',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var repository = await LocalAppPreferencesStore.open(db);
      var controller = AppPreferencesController(storage: repository);
      var draft = (await controller.openWorkDisplayDraft(
        initial: const WorkDisplayPreferences(),
      ))!;
      draft.updateInput(
        const WorkDisplayPreferences(showDailySummaries: false),
      );
      await draft.session.flush();
      final raw = draft.session.input;
      final revision = draft.session.savedRevision;
      final other = await LocalAppPreferencesStore.open(db);
      await other.save('workShowEmployeeCards', 'false');
      expect(await draft.confirm(), isFalse);
      expect(draft.session.input, raw);
      expect(draft.session.savedRevision, revision);
      expect(
        (await LocalAppPreferencesStore.open(
          db,
        )).values['workShowEmployeeCards'],
        'false',
      );
      await draft.session.close();
      controller.dispose();
      await harness.close(db);
      db = await harness.open();
      repository = await LocalAppPreferencesStore.open(db);
      controller = AppPreferencesController(storage: repository);
      addTearDown(controller.dispose);
      draft = (await controller.openWorkDisplayDraft(
        initial: const WorkDisplayPreferences(showEmployeeCards: false),
      ))!;
      expect(draft.session.input, raw);
      expect(await draft.confirm(), isFalse);
      expect(repository.values['workShowEmployeeCards'], 'false');
      expect(repository.values.containsKey('workShowDailySummaries'), isFalse);
      expect(draft.session.savedRevision, revision);
      await draft.session.close();
    },
  );
  test(
    'unrelated direct writes survive a valid draft confirmation and are excluded from its baseline',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = await LocalAppPreferencesStore.open(db);
      await repository.save('measurementSystem', 'metric');
      final controller = AppPreferencesController(storage: repository);
      addTearDown(controller.dispose);
      final draft = (await controller.openWorkDisplayDraft(
        initial: const WorkDisplayPreferences(showDailySummaries: false),
      ))!;
      await draft.session.flush();
      final baseline =
          draft.session.input[PreferenceDraftBaseline.payloadKey] as Map;
      expect(
        baseline.keys,
        unorderedEquals([
          'workShowEmployeeCards',
          'workShowDailySummaries',
          'workIncludeCompletedWork',
        ]),
      );
      final other = await LocalAppPreferencesStore.open(db);
      await other.save('measurementSystem', 'us');
      expect(await draft.confirm(), isTrue);
      expect(repository.values['measurementSystem'], 'us');
      expect(repository.values['workShowDailySummaries'], 'false');
      await draft.session.close();
    },
  );
  test(
    'an old repository cache cannot bless a stale baseline as current when a draft opens later',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = await LocalAppPreferencesStore.open(db);
      final controller = AppPreferencesController(storage: repository);
      addTearDown(controller.dispose);
      await (await LocalAppPreferencesStore.open(
        db,
      )).save('workShowDailySummaries', 'false');
      final draft = (await controller.openWorkDisplayDraft(
        initial: const WorkDisplayPreferences(),
      ))!;
      expect(await draft.confirm(), isFalse);
      expect(
        (await LocalAppPreferencesStore.open(
          db,
        )).values['workShowDailySummaries'],
        'false',
      );
      await draft.session.close();
    },
  );
}
