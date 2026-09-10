import 'dart:io';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';

void main() {
  test(
    'device preferences survive reopen and failed writes retain active values',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'local-preferences-',
      );
      final file = File('${directory.path}/preferences.sqlite');
      var db = LocalDatabase.file(file);
      var controller = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      expect(await controller.setThemeMode(ThemeMode.dark), isTrue);
      expect(await controller.setLanguage(AppLanguage.french), isTrue);
      expect(
        await controller.setMeasurementSystem(AppMeasurementSystem.metric),
        isTrue,
      );
      expect(
        await controller.setDashboardActions({'endDay', 'addNote'}),
        isTrue,
      );
      controller.dispose();
      await db.close();
      db = LocalDatabase.file(file);
      controller = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      expect(controller.dashboardActions, {'endDay', 'addNote'});
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.language, AppLanguage.french);
      expect(controller.measurementSystem, AppMeasurementSystem.metric);
      await db.customStatement(
        "CREATE TRIGGER fail_preference BEFORE UPDATE ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect(await controller.setThemeMode(ThemeMode.light), isFalse);
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.saveError, isNotNull);
      expect(
        (await LocalAppPreferencesStore.open(db)).values['themeMode'],
        'dark',
      );
      await db.customStatement('DROP TRIGGER fail_preference');
      expect(await controller.retrySave(), isTrue);
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.saveError, isNull);
      expect(await db.select(db.localRecords).get(), isEmpty);
      expect(await db.select(db.localChangeOutbox).get(), isEmpty);
      controller.dispose();
      await db.close();
      await directory.delete(recursive: true);
    },
  );
  test(
    'Work display choices and atomic reset retain other device preferences',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'work-preferences-',
      );
      final file = File('${directory.path}/preferences.sqlite');
      var db = LocalDatabase.file(file);
      var controller = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      expect(await controller.setThemeMode(ThemeMode.dark), isTrue);
      expect(
        await controller.setWorkDisplay(
          showEmployeeCards: false,
          showDailySummaries: false,
          includeCompletedWork: false,
        ),
        isTrue,
      );
      controller.dispose();
      await db.close();
      db = LocalDatabase.file(file);
      controller = AppPreferencesController(
        storage: await LocalAppPreferencesStore.open(db),
      );
      expect(controller.workShowEmployeeCards, isFalse);
      expect(controller.workShowDailySummaries, isFalse);
      expect(controller.workIncludeCompletedWork, isFalse);
      await db.customStatement(
        "CREATE TRIGGER fail_work_reset BEFORE UPDATE ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      expect(
        await controller.setWorkDisplay(
          showEmployeeCards: true,
          showDailySummaries: true,
          includeCompletedWork: true,
        ),
        isFalse,
      );
      expect(controller.workShowEmployeeCards, isFalse);
      expect(controller.workShowDailySummaries, isFalse);
      expect(controller.workIncludeCompletedWork, isFalse);
      final persisted = (await LocalAppPreferencesStore.open(db)).values;
      expect(persisted['workShowEmployeeCards'], 'false');
      expect(persisted['workShowDailySummaries'], 'false');
      expect(persisted['workIncludeCompletedWork'], 'false');
      await db.customStatement('DROP TRIGGER fail_work_reset');
      expect(await controller.retrySave(), isTrue);
      expect(controller.workShowEmployeeCards, isTrue);
      expect(controller.workShowDailySummaries, isTrue);
      expect(controller.workIncludeCompletedWork, isTrue);
      expect(controller.themeMode, ThemeMode.dark);
      expect(await db.select(db.localRecords).get(), isEmpty);
      expect(await db.select(db.localChangeOutbox).get(), isEmpty);
      controller.dispose();
      await db.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'preference confirmation rejects stale and unrelated draft tokens',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'preference-draft-cas-',
      );
      final db = LocalDatabase.file(
        File('${directory.path}/preferences.sqlite'),
      );
      final store = await LocalAppPreferencesStore.open(db);
      final drafts = LocalDraftStore(db);
      try {
        await store.save('workShowDailySummaries', 'true');
        for (final revision in [0, 1]) {
          await drafts.save(
            organizationId: 'device',
            ownerId: 'device',
            domain: LocalAppPreferencesStore.workDisplayDraftDomain,
            draftId: LocalAppPreferencesStore.workDisplayDraftId,
            expectedRevision: revision,
            payload: {'choice': revision},
            occurredAt: DateTime.now(),
          );
        }
        for (final domain in [
          LocalAppPreferencesStore.workDisplayDraftDomain,
          'work/job-editor',
        ]) {
          await expectLater(
            store.saveMany(
              {'workShowDailySummaries': 'false'},
              draftCheckpoint: LocalDraftCheckpoint(
                domain: domain,
                draftId: LocalAppPreferencesStore.workDisplayDraftId,
                revision: 1,
              ),
            ),
            throwsA(anyOf(isA<ArgumentError>(), isA<Exception>())),
          );
          expect(
            (await LocalAppPreferencesStore.open(
              db,
            )).values['workShowDailySummaries'],
            'true',
          );
        }
        final retained = await drafts.list(
          organizationId: 'device',
          ownerId: 'device',
          domain: LocalAppPreferencesStore.workDisplayDraftDomain,
        );
        expect(retained.single.revision, 2);
        expect(drafts.decode(retained.single), {'choice': 1});
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('independent preference writers preserve each others fields', () async {
    final directory = await Directory.systemTemp.createTemp(
      'local-preferences-merge-',
    );
    final db = LocalDatabase.file(File('${directory.path}/preferences.sqlite'));
    final first = await LocalAppPreferencesStore.open(db);
    final second = await LocalAppPreferencesStore.open(db);
    await first.save('themeMode', 'dark');
    await second.save('language', 'spanish');
    expect((await LocalAppPreferencesStore.open(db)).values, {
      'themeMode': 'dark',
      'language': 'spanish',
    });
    await expectLater(first.save('cloudConsent', 'true'), throwsArgumentError);
    await db.close();
    await directory.delete(recursive: true);
  });
  for (final damaged in [
    'not-json',
    '[1]',
    '{"themeMode":7}',
    '{"themeMode":"future"}',
  ]) {
    test(
      'unreadable preferences allow defaults and retain original bytes: $damaged',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'preference-recovery-',
        );
        final db = LocalDatabase.file(
          File('${directory.path}/preferences.sqlite'),
        );
        await db
            .into(db.localMetadata)
            .insert(
              LocalMetadataCompanion.insert(
                metadataKey: 'device.app-preferences.v1',
                value: damaged,
              ),
            );
        final controller = AppPreferencesController(
          storage: await LocalAppPreferencesStore.open(db),
        );
        expect(controller.themeMode, ThemeMode.light);
        expect(
          controller.saveError,
          contains('original saved values are retained'),
        );
        expect((await db.select(db.localMetadata).get()).single.value, damaged);
        await db.customStatement(
          "CREATE TRIGGER fail_recovery BEFORE UPDATE ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
        );
        expect(await controller.setThemeMode(ThemeMode.dark), isFalse);
        expect((await db.select(db.localMetadata).get()).single.value, damaged);
        await db.customStatement('DROP TRIGGER fail_recovery');
        expect(await controller.retrySave(), isTrue);
        final rows = await db.select(db.localMetadata).get();
        expect(rows, hasLength(2));
        expect(
          rows
              .singleWhere(
                (row) => row.metadataKey.startsWith(
                  'device.app-preferences.recovery.',
                ),
              )
              .value,
          damaged,
        );
        expect(
          (await LocalAppPreferencesStore.open(db)).values['themeMode'],
          'dark',
        );
        controller.dispose();
        await db.close();
        await directory.delete(recursive: true);
      },
    );
  }
}
