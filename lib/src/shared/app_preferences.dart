import 'dart:convert';
import '../data/storage/local_draft_checkpoint.dart';
import '../data/storage/app_preferences_repository.dart';
import '../data/storage/app_preference_keys.dart';
import '../data/storage/serialized_async_actions.dart';
import 'package:flutter/material.dart';

enum AppLanguage {
  english(Locale('en', 'US')),
  spanish(Locale('es', 'US')),
  french(Locale('fr', 'CA'));

  const AppLanguage(this.locale);

  final Locale locale;
}

enum AppMeasurementSystem { us, metric }

class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController({
    this.storage,
    ThemeMode initialThemeMode = ThemeMode.light,
    AppLanguage initialLanguage = AppLanguage.english,
    AppMeasurementSystem initialMeasurementSystem = AppMeasurementSystem.us,
  }) : _themeMode = initialThemeMode,
       _language = initialLanguage,
       _measurementSystem = initialMeasurementSystem {
    final saved = storage?.values;
    if (saved != null) _apply(saved);
    if (storage?.usingDefaultsAfterRecovery == true) {
      _saveError =
          'Saved device preferences could not be read. Default appearance, language and measurements are active; the original saved values are retained.';
    }
  }
  final AppPreferencesRepository? storage;
  final _writes = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _writes.pauseAndDrain();
  bool _disposed = false;
  bool get canRecoverDrafts => !_disposed && storage != null;
  bool _saving = false;
  String? _saveError;
  bool get isSaving => _saving;
  String? get saveError => _saveError;
  bool get canRetrySave => !_disposed && _failedChange != null;
  Map<String, String>? _failedChange;
  bool _receiptShowReviewChecklist = true;
  bool _receiptShowEvidenceReminders = true;
  bool get receiptShowReviewChecklist => _receiptShowReviewChecklist;
  bool get receiptShowEvidenceReminders => _receiptShowEvidenceReminders;
  Future<bool> setReceiptDisplay({
    required bool showReviewChecklist,
    required bool showEvidenceReminders,
    LocalDraftCheckpoint? draftCheckpoint,
  }) => _saveMany({
    'receiptShowReviewChecklist': showReviewChecklist.toString(),
    'receiptShowEvidenceReminders': showEvidenceReminders.toString(),
  }, draftCheckpoint: draftCheckpoint);
  final _reportDisplay = <String, bool>{};
  bool reportDisplayChoice(String choice) {
    if (!AppPreferenceKeys.reportDisplayChoices.contains(choice)) {
      throw ArgumentError('Unsupported report display preference.');
    }
    return _reportDisplay[choice] ?? true;
  }

  Future<bool> setReportDisplay(
    Map<String, bool> choices, {
    LocalDraftCheckpoint? draftCheckpoint,
  }) => _saveMany({
    for (final entry in choices.entries)
      'report.${entry.key}': entry.value.toString(),
  }, draftCheckpoint: draftCheckpoint);
  String? _expenseDisplay;
  Map<String, Object?>? get expenseDisplay => _expenseDisplay == null
      ? null
      : (jsonDecode(_expenseDisplay!) as Map).cast<String, Object?>();
  Future<bool> setExpenseDisplay(
    Map<String, Object?> choices, {
    LocalDraftCheckpoint? draftCheckpoint,
  }) => _saveMany({
    'expenseDisplay': jsonEncode(choices),
  }, draftCheckpoint: draftCheckpoint);
  final _workDisplay = <String, bool>{};
  bool get workShowEmployeeCards =>
      _workDisplay['workShowEmployeeCards'] ?? true;
  bool get workShowDailySummaries =>
      _workDisplay['workShowDailySummaries'] ?? true;
  bool get workIncludeCompletedWork =>
      _workDisplay['workIncludeCompletedWork'] ?? true;
  Future<bool> setWorkDisplay({
    bool? showEmployeeCards,
    bool? showDailySummaries,
    bool? includeCompletedWork,
    LocalDraftCheckpoint? draftCheckpoint,
  }) => _saveMany({
    if (showEmployeeCards != null)
      'workShowEmployeeCards': showEmployeeCards.toString(),
    if (showDailySummaries != null)
      'workShowDailySummaries': showDailySummaries.toString(),
    if (includeCompletedWork != null)
      'workIncludeCompletedWork': includeCompletedWork.toString(),
  }, draftCheckpoint: draftCheckpoint);
  final _workListValues = <String, bool>{};
  bool workListChoice(String workspace, String choice) =>
      _workListValues[AppPreferenceKeys.workListKey(workspace, choice)] ?? true;
  Future<bool> setWorkListChoices(
    String workspace,
    Map<String, bool> choices, {
    LocalDraftCheckpoint? draftCheckpoint,
  }) => _saveMany({
    for (final entry in choices.entries)
      AppPreferenceKeys.workListKey(workspace, entry.key): entry.value
          .toString(),
  }, draftCheckpoint: draftCheckpoint);
  Set<String>? _dashboardActions;
  Set<String>? get dashboardActions =>
      _dashboardActions == null ? null : Set.unmodifiable(_dashboardActions!);
  Future<bool> setDashboardActions(Set<String> actions) =>
      _save('dashboardActions', jsonEncode(actions.toList()..sort()));
  void _apply(Map<String, String> values) {
    if (values['expenseDisplay'] case final String value) {
      _expenseDisplay = value;
    }
    for (final entry in values.entries) {
      if (entry.key.startsWith('report.')) {
        _reportDisplay[entry.key.substring(7)] = entry.value == 'true';
      }
    }
    if (values['receiptShowReviewChecklist'] case final String value) {
      _receiptShowReviewChecklist = value == 'true';
    }
    if (values['receiptShowEvidenceReminders'] case final String value) {
      _receiptShowEvidenceReminders = value == 'true';
    }
    for (final entry in values.entries) {
      if (entry.key.startsWith('workList.')) {
        _workListValues[entry.key] = entry.value == 'true';
      }
    }
    for (final key in [
      'workShowEmployeeCards',
      'workShowDailySummaries',
      'workIncludeCompletedWork',
    ]) {
      if (values[key] case final String value) {
        _workDisplay[key] = value == 'true';
      }
    }
    if (values['dashboardActions'] case final String value) {
      _dashboardActions = (jsonDecode(value) as List).cast<String>().toSet();
    }
    if (values['themeMode'] case final String value) {
      _themeMode = ThemeMode.values.byName(value);
    }
    if (values['language'] case final String value) {
      _language = AppLanguage.values.byName(value);
    }
    if (values['measurementSystem'] case final String value) {
      _measurementSystem = AppMeasurementSystem.values.byName(value);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> _save(String key, String value) => _saveMany({key: value});

  Future<bool> _saveMany(
    Map<String, String> changes, {
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    // Reject stale presentation callbacks at admission. Already accepted writes
    // still drain normally before the owning installation closes.
    if (_disposed) return Future.value(false);
    final proposed = Map<String, String>.unmodifiable(changes);
    if (storage == null) {
      _apply(proposed);
      _notify();
      return Future.value(true);
    }
    return _writes.run(() async {
      _saving = true;
      _saveError = null;
      _notify();
      try {
        final saved =
            await storage?.saveMany(
              proposed,
              draftCheckpoint: draftCheckpoint,
            ) ??
            proposed;
        _apply(saved);
        _failedChange = null;
        return true;
      } on Object {
        // Draft-backed forms own their retry/discard workflow. Do not offer
        // their stale checkpoint from unrelated global appearance settings.
        _failedChange = draftCheckpoint == null ? proposed : null;
        _saveError = draftCheckpoint == null
            ? 'This preference was not saved. Your previous setting is still active.'
            : null;
        return false;
      } finally {
        _saving = false;
        _notify();
      }
    });
  }

  Future<bool> retrySave() {
    if (_disposed) return Future.value(false);
    final failed = _failedChange;
    return failed == null ? Future.value(true) : _saveMany(failed);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  ThemeMode _themeMode;
  AppLanguage _language;
  AppMeasurementSystem _measurementSystem;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  AppMeasurementSystem get measurementSystem => _measurementSystem;

  Future<bool> setThemeMode(ThemeMode value) => _save('themeMode', value.name);
  Future<bool> setLanguage(AppLanguage value) => _save('language', value.name);
  Future<bool> setMeasurementSystem(AppMeasurementSystem value) =>
      _save('measurementSystem', value.name);
}

class AppPreferencesScope extends InheritedNotifier<AppPreferencesController> {
  const AppPreferencesScope({
    required AppPreferencesController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppPreferencesController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppPreferencesScope>()
      ?.notifier;

  static AppPreferencesController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(scope != null, 'AppPreferencesScope is missing above this route.');
    return scope!.notifier!;
  }
}
