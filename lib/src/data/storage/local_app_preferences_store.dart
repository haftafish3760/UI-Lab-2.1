import 'preference_draft_baseline.dart';
import 'app_preference_keys.dart';
import 'app_preferences_repository.dart';
import 'draft_repository.dart';
import 'dart:convert';
import 'expense_display_preference_codec.dart';
import 'local_draft_checkpoint.dart';
import 'local_draft_store.dart';
import 'local_record_command.dart';
import 'local_database.dart';
import 'serialized_async_actions.dart';
import 'local_record_identity.dart';

/// Device presentation preferences only; no business data or cloud consent.
class LocalAppPreferencesStore implements AppPreferencesRepository {
  LocalAppPreferencesStore._(
    this.database,
    this._values, {
    this.usingDefaultsAfterRecovery = false,
  });
  @override
  bool usingDefaultsAfterRecovery;
  final LocalDatabase database;
  @override
  DraftRepository get drafts => LocalDraftStore(database);
  Map<String, String> _values;
  @override
  Map<String, String> get values => Map.unmodifiable(_values);
  final _writes = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _writes.pauseAndDrain();
  @override
  Future<Map<String, String>> readCurrentValues() async =>
      Map.unmodifiable(await _read(database));

  static const _key = 'device.app-preferences.v1';
  static const workDisplayDraftDomain =
      AppPreferenceKeys.workDisplayDraftDomain;
  static const workDisplayDraftId = AppPreferenceKeys.workDisplayDraftId;
  static const receiptDisplayDraftDomain =
      AppPreferenceKeys.receiptDisplayDraftDomain;
  static const receiptDisplayDraftId = AppPreferenceKeys.receiptDisplayDraftId;
  static const reportDisplayDraftDomain =
      AppPreferenceKeys.reportDisplayDraftDomain;
  static const reportDisplayDraftId = AppPreferenceKeys.reportDisplayDraftId;
  static const reportDisplayChoices = AppPreferenceKeys.reportDisplayChoices;
  static const expenseDisplayDraftDomain =
      AppPreferenceKeys.expenseDisplayDraftDomain;
  static const expenseDisplayDraftId = AppPreferenceKeys.expenseDisplayDraftId;
  static const workListDraftDomain = AppPreferenceKeys.workListDraftDomain;
  static const workListIds = AppPreferenceKeys.workListIds;
  static const workListChoices = AppPreferenceKeys.workListChoices;
  static String workListKey(String workspace, String choice) =>
      AppPreferenceKeys.workListKey(workspace, choice);

  static const _allowed = {
    'receiptShowReviewChecklist': {'true', 'false'},
    'receiptShowEvidenceReminders': {'true', 'false'},
    'themeMode': {'system', 'light', 'dark'},
    'workShowEmployeeCards': {'true', 'false'},
    'workShowDailySummaries': {'true', 'false'},
    'workIncludeCompletedWork': {'true', 'false'},
    'language': {'english', 'spanish', 'french'},
    'measurementSystem': {'us', 'metric'},
  };
  static const dashboardActionNames = {
    'pauseOrResume',
    'endDay',
    'addStop',
    'addFuel',
    'addExpense',
    'addReceipt',
    'addNote',
    'createEstimate',
    'configureActions',
  };
  static bool _valid(String key, String value) {
    if (key == 'expenseDisplay') {
      try {
        return validExpenseDisplayPreferences(jsonDecode(value));
      } on FormatException {
        return false;
      }
    }
    if (key.startsWith('report.')) {
      return reportDisplayChoices.contains(key.substring(7)) &&
          const {'true', 'false'}.contains(value);
    }
    if (key.startsWith('workList.')) {
      final parts = key.split('.');
      return parts.length == 3 &&
          workListIds.contains(parts[1]) &&
          workListChoices.contains(parts[2]) &&
          const {'true', 'false'}.contains(value);
    }
    if (key != 'dashboardActions') {
      return _allowed[key]?.contains(value) == true;
    }
    try {
      final actions = jsonDecode(value);
      return actions is List &&
          actions.contains('endDay') &&
          actions.toSet().length == actions.length &&
          actions.every(
            (action) =>
                action is String && dashboardActionNames.contains(action),
          );
    } on FormatException {
      return false;
    }
  }

  static Future<LocalAppPreferencesStore> open(LocalDatabase database) async {
    try {
      return LocalAppPreferencesStore._(database, await _read(database));
    } on FormatException {
      return LocalAppPreferencesStore._(
        database,
        {},
        usingDefaultsAfterRecovery: true,
      );
    }
  }

  static Future<Map<String, String>> _read(LocalDatabase database) async {
    final row = await (database.select(
      database.localMetadata,
    )..where((row) => row.metadataKey.equals(_key))).getSingleOrNull();
    if (row == null) return {};
    final decoded = jsonDecode(row.value);
    if (decoded is! Map) {
      throw const FormatException('Invalid saved preferences.');
    }
    final values = <String, String>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String ||
          entry.value is! String ||
          !_valid(entry.key as String, entry.value as String)) {
        throw const FormatException('Unsupported saved device preference.');
      }
      values[entry.key as String] = entry.value as String;
    }
    return values;
  }

  Future<Map<String, String>> save(String key, String value) =>
      saveMany({key: value});

  @override
  Future<Map<String, String>> saveMany(
    Map<String, String> changes, {
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    final proposed = Map<String, String>.unmodifiable(changes);
    return _writes.run(() async {
      if (proposed.isEmpty ||
          proposed.entries.any((entry) => !_valid(entry.key, entry.value))) {
        throw ArgumentError('Unsupported device preference.');
      }
      final committed = await database.transaction(() async {
        Map<String, String?>? expectedValues;
        final draft = draftCheckpoint;
        if (draft != null) {
          Set<String> allowed;
          try {
            allowed = PreferenceDraftBaseline.keys(draft.domain, draft.draftId);
          } on FormatException {
            throw ArgumentError('This draft cannot confirm these preferences.');
          }
          if (!proposed.keys.every(allowed.contains)) {
            throw ArgumentError('This draft cannot confirm these preferences.');
          }
          final saved = await drafts.find(
            organizationId: 'device',
            ownerId: 'device',
            domain: draft.domain,
            draftId: draft.draftId,
          );
          if (saved == null || saved.revision != draft.revision) {
            throw const LocalRecordConflict(
              'Settings input changed. Its draft was preserved.',
            );
          }
          expectedValues = PreferenceDraftBaseline.decode(
            drafts.decode(saved)[PreferenceDraftBaseline.payloadKey],
            draft.domain,
            draft.draftId,
          );
          if (!await LocalDraftStore(database).consumeIfUnchanged(
            organizationId: 'device',
            domain: draft.domain,
            draftId: draft.draftId,
            ownerId: 'device',
            expectedRevision: draft.revision,
          )) {
            throw const LocalRecordConflict(
              'Settings input changed. Its saved draft was preserved.',
            );
          }
        }
        Map<String, String> previous;
        try {
          previous = await _read(database);
        } on FormatException {
          // Preserve exact bytes before an explicit preference change replaces
          // unreadable metadata. Archive and replacement commit together.
          final damaged = await (database.select(
            database.localMetadata,
          )..where((row) => row.metadataKey.equals(_key))).getSingle();
          await database
              .into(database.localMetadata)
              .insert(
                LocalMetadataCompanion.insert(
                  metadataKey:
                      'device.app-preferences.recovery.${newLocalRecordIdentity('snapshot')}',
                  value: damaged.value,
                ),
              );
          previous = {};
        }
        if (expectedValues != null &&
            proposed.keys.any(
              (key) =>
                  !expectedValues!.containsKey(key) ||
                  expectedValues[key] != previous[key],
            )) {
          throw const LocalRecordConflict(
            'These settings changed since editing began. Your draft was preserved.',
          );
        }
        final next = {...previous, ...proposed};
        await database
            .into(database.localMetadata)
            .insertOnConflictUpdate(
              LocalMetadataCompanion.insert(
                metadataKey: _key,
                value: jsonEncode(next),
              ),
            );
        return next;
      });
      _values = committed;
      usingDefaultsAfterRecovery = false;
      return values;
    });
  }
}
