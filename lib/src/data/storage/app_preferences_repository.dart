import 'draft_repository.dart';
import 'local_draft_checkpoint.dart';

/// Confirmed device preferences and atomic confirmation of their draft input.
/// Implementations publish values only after the write is acknowledged.
abstract interface class AppPreferencesRepository {
  Map<String, String> get values;
  bool get usingDefaultsAfterRecovery;
  DraftRepository get drafts;

  /// Fresh stored values without changing the published controller cache.
  Future<Map<String, String>> readCurrentValues();

  Future<Map<String, String>> saveMany(
    Map<String, String> changes, {
    LocalDraftCheckpoint? draftCheckpoint,
  });
}
