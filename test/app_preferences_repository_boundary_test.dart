import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/app_preferences_repository.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';

class _AcknowledgedPreferences extends Fake
    implements AppPreferencesRepository {
  Completer<Map<String, String>> pending = Completer();
  Map<String, String>? proposed;
  int writes = 0;
  @override
  Future<Map<String, String>> readCurrentValues() async =>
      Map.unmodifiable(values);

  @override
  Map<String, String> get values => {'themeMode': 'light'};
  @override
  bool get usingDefaultsAfterRecovery => false;
  @override
  Future<Map<String, String>> saveMany(
    Map<String, String> changes, {
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    writes++;
    proposed = changes;
    return pending.future;
  }
}

void main() {
  test(
    'disposal rejects new writes but drains previously accepted input',
    () async {
      final repository = _AcknowledgedPreferences();
      final controller = AppPreferencesController(storage: repository);
      final accepted = controller.setThemeMode(ThemeMode.dark);
      controller.dispose();
      expect(await controller.setLanguage(AppLanguage.french), isFalse);
      expect(await controller.retrySave(), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(repository.writes, 1);
      expect(repository.proposed, {'themeMode': 'dark'});
      repository.pending.complete({'themeMode': 'dark'});
      expect(await accepted, isTrue);
      expect(repository.writes, 1);
    },
  );

  test(
    'disposed failed and preview controllers cannot retry or mutate',
    () async {
      final repository = _AcknowledgedPreferences();
      final controller = AppPreferencesController(storage: repository);
      final failed = controller.setThemeMode(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);
      repository.pending.completeError(StateError('write failed'));
      expect(await failed, isFalse);
      expect(controller.canRetrySave, isTrue);
      controller.dispose();
      expect(controller.canRetrySave, isFalse);
      expect(await controller.retrySave(), isFalse);
      expect(repository.writes, 1);
      final preview = AppPreferencesController();
      preview.dispose();
      expect(await preview.setThemeMode(ThemeMode.dark), isFalse);
      expect(preview.themeMode, ThemeMode.light);
    },
  );

  test(
    'preference controller waits for an interface acknowledgement without SQLite',
    () async {
      final repository = _AcknowledgedPreferences();
      final controller = AppPreferencesController(storage: repository);
      addTearDown(controller.dispose);
      final saving = controller.setThemeMode(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);
      expect(repository.proposed, {'themeMode': 'dark'});
      expect(controller.isSaving, isTrue);
      expect(controller.themeMode, ThemeMode.light);
      repository.pending.complete({'themeMode': 'dark'});
      expect(await saving, isTrue);
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isSaving, isFalse);
    },
  );

  test(
    'interface failure retains visible settings and retries the same proposal',
    () async {
      final repository = _AcknowledgedPreferences();
      final controller = AppPreferencesController(storage: repository);
      addTearDown(controller.dispose);
      final saving = controller.setMeasurementSystem(
        AppMeasurementSystem.metric,
      );
      await Future<void>.delayed(Duration.zero);
      repository.pending.completeError(StateError('write failed'));
      expect(await saving, isFalse);
      expect(controller.measurementSystem, AppMeasurementSystem.us);
      expect(controller.canRetrySave, isTrue);
      expect(controller.saveError, isNotNull);
      repository.pending = Completer();
      final retry = controller.retrySave();
      await Future<void>.delayed(Duration.zero);
      expect(repository.proposed, {'measurementSystem': 'metric'});
      repository.pending.complete({'measurementSystem': 'metric'});
      expect(await retry, isTrue);
      expect(controller.measurementSystem, AppMeasurementSystem.metric);
      expect(controller.canRetrySave, isFalse);
      expect(controller.saveError, isNull);
    },
  );
}
