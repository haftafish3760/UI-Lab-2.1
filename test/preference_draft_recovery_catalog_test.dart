import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/app_preference_keys.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/preference_draft_recovery.dart';
import 'preference_selected_draft_recovery_test.dart' as fixtures;
import 'support/storage/database_harness.dart';

void main() {
  test(
    'disposed preferences cannot discover, resume or discard saved input',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final store = await LocalAppPreferencesStore.open(db);
      final preferences = AppPreferencesController(storage: store);
      final session = await fixtures.open(preferences, 'work');
      await session.close();
      final recovery = PreferenceDraftRecovery(preferences);
      final entry = (await recovery.list()).single;
      preferences.dispose();
      expect(await recovery.list(), isEmpty);
      expect(() => PreferenceDraftRecovery(preferences), throwsStateError);
      await expectLater(recovery.resume(entry), throwsA(anything));
      await expectLater(recovery.discard(entry), throwsA(anything));
      final replacement = AppPreferencesController(storage: store);
      addTearDown(replacement.dispose);
      final recovered = (await PreferenceDraftRecovery(
        replacement,
      ).list()).single;
      expect(recovered.draftId, entry.draftId);
      expect(recovered.revision, entry.revision);
    },
  );

  test(
    'discovery and typed resume preserve all seven drafts across reopen',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var store = await LocalAppPreferencesStore.open(db);
      var preferences = AppPreferencesController(storage: store);
      final originals = <String, Object>{};
      for (final kind in [
        'work',
        'receipt',
        'report',
        'expense',
        'jobs',
        'estimates',
        'invoices',
      ]) {
        final session = await fixtures.open(preferences, kind);
        await session.close();
        originals['${session.domain}/${session.draftId}'] = session.input;
      }
      preferences.dispose();
      await harness.close(db);
      db = await harness.open();
      store = await LocalAppPreferencesStore.open(db);
      preferences = AppPreferencesController(storage: store);
      addTearDown(preferences.dispose);
      final confirmed = Map<String, String>.of(store.values);
      final recovery = PreferenceDraftRecovery(preferences);
      final entries = await recovery.list();
      expect(entries, hasLength(7));
      for (final entry in entries) {
        expect(
          entry.preview.availability,
          DraftRecoveryAvailability.recoverable,
        );
        final resumed = await recovery.resume(entry);
        await resumed.close();
        final saved = (await store.drafts.find(
          organizationId: 'device',
          ownerId: 'device',
          domain: entry.domain,
          draftId: entry.draftId,
        ))!;
        expect(saved.revision, entry.revision);
        expect(
          store.drafts.decode(saved),
          originals['${entry.domain}/${entry.draftId}'],
        );
      }
      expect(store.values, confirmed);
      await recovery.discard(entries.first);
      await expectLater(recovery.resume(entries.first), throwsA(anything));
      expect(await recovery.list(), hasLength(6));
    },
  );

  test(
    'fresh metadata prevents a stale controller offering conflicting recovery',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final store = await LocalAppPreferencesStore.open(db);
      final preferences = AppPreferencesController(storage: store);
      addTearDown(preferences.dispose);
      final session = await fixtures.open(preferences, 'work');
      await session.close();
      final recovery = PreferenceDraftRecovery(preferences);
      final selected = (await recovery.list()).single;
      final other = await LocalAppPreferencesStore.open(db);
      await other.save('measurementSystem', 'us');
      expect(
        (await recovery.list()).single.preview.availability,
        DraftRecoveryAvailability.recoverable,
      );
      await other.save('workShowEmployeeCards', 'false');
      expect(store.values['workShowEmployeeCards'], isNull);
      expect(
        (await store.readCurrentValues())['workShowEmployeeCards'],
        'false',
      );
      expect(
        (await recovery.list()).single.preview.availability,
        DraftRecoveryAvailability.conflict,
      );
      await expectLater(recovery.resume(selected), throwsStateError);
      final saved = (await store.drafts.find(
        organizationId: 'device',
        ownerId: 'device',
        domain: session.domain,
        draftId: session.draftId,
      ))!;
      expect(saved.revision, session.savedRevision);
      expect(store.drafts.decode(saved), session.input);
    },
  );

  test(
    'legacy input stays unchanged and unknown or malformed drafts remain visible',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final store = await LocalAppPreferencesStore.open(await harness.open());
      final preferences = AppPreferencesController(storage: store);
      addTearDown(preferences.dispose);
      const raw = <String, Object?>{
        'showInvoicedRevenue': true,
        'showMoneyCollected': false,
        'showRecordedExpenses': true,
        'showEstimatedGrossProfit': false,
        'showVehicleHealth': true,
      };
      for (final id in [AppPreferenceKeys.reportDisplayDraftId, 'unknown']) {
        await store.drafts.save(
          organizationId: 'device',
          ownerId: 'device',
          domain: AppPreferenceKeys.reportDisplayDraftDomain,
          draftId: id,
          expectedRevision: 0,
          payload: raw,
          occurredAt: DateTime.now().toUtc(),
        );
      }
      await store.drafts.save(
        organizationId: 'device',
        ownerId: 'device',
        domain: AppPreferenceKeys.workDisplayDraftDomain,
        draftId: AppPreferenceKeys.workDisplayDraftId,
        expectedRevision: 0,
        payload: {'bad': true},
        occurredAt: DateTime.now().toUtc(),
      );
      final recovery = PreferenceDraftRecovery(preferences);
      final entries = await recovery.list();
      expect(entries, hasLength(3));
      expect(
        entries.where(
          (e) => e.preview.availability == DraftRecoveryAvailability.unreadable,
        ),
        hasLength(2),
      );
      final legacy = entries.singleWhere(
        (e) => e.preview.availability == DraftRecoveryAvailability.recoverable,
      );
      expect(legacy.preview.title, contains('review'));
      await (await recovery.resume(legacy)).close();
      final saved = (await store.drafts.find(
        organizationId: 'device',
        ownerId: 'device',
        domain: legacy.domain,
        draftId: legacy.draftId,
      ))!;
      expect(saved.revision, 1);
      expect(store.drafts.decode(saved), raw);
    },
  );
}
