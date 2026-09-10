import 'app_preference_keys.dart';

/// Only the owning workflow's confirmed keys are retained with its raw input.
/// Null distinguishes an unset preference from an explicitly stored value.
abstract final class PreferenceDraftBaseline {
  static const payloadKey = '_confirmedPreferenceValues';
  static Set<String> keys(String domain, String id) {
    if (domain == AppPreferenceKeys.workDisplayDraftDomain &&
        id == AppPreferenceKeys.workDisplayDraftId) {
      return {
        'workShowEmployeeCards',
        'workShowDailySummaries',
        'workIncludeCompletedWork',
      };
    }
    if (domain == AppPreferenceKeys.receiptDisplayDraftDomain &&
        id == AppPreferenceKeys.receiptDisplayDraftId) {
      return {'receiptShowReviewChecklist', 'receiptShowEvidenceReminders'};
    }
    if (domain == AppPreferenceKeys.reportDisplayDraftDomain &&
        id == AppPreferenceKeys.reportDisplayDraftId) {
      return {
        for (final choice in AppPreferenceKeys.reportDisplayChoices)
          'report.$choice',
      };
    }
    if (domain == AppPreferenceKeys.expenseDisplayDraftDomain &&
        id == AppPreferenceKeys.expenseDisplayDraftId) {
      return {'expenseDisplay'};
    }
    if (domain == AppPreferenceKeys.workListDraftDomain &&
        AppPreferenceKeys.workListIds.contains(id)) {
      return {
        for (final choice in AppPreferenceKeys.workListChoices)
          AppPreferenceKeys.workListKey(id, choice),
      };
    }
    throw const FormatException('Unknown preference workflow.');
  }

  static Map<String, String?> capture(
    Map<String, String> values,
    String domain,
    String id,
  ) => Map.unmodifiable({for (final key in keys(domain, id)) key: values[key]});
  static Map<String, String?> decode(Object? raw, String domain, String id) {
    if (raw is! Map) {
      throw const FormatException('Preference baseline unavailable.');
    }
    final values = raw.cast<String, String?>();
    final expected = keys(domain, id);
    if (values.length != expected.length ||
        !values.keys.every(expected.contains)) {
      throw const FormatException('Preference baseline is incomplete.');
    }
    return Map.unmodifiable(values);
  }
}
