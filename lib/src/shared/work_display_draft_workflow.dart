import '../data/storage/draft_recovery_selection.dart';
import '../data/preferences/work_display_preferences.dart';
import '../data/storage/app_preference_keys.dart';
import '../data/storage/preference_draft_workflow.dart';
import 'app_preferences.dart';

extension WorkDisplayDraftWorkflow on AppPreferencesController {
  void validateWorkDisplayHandoff(
    PreferenceDraftWorkflow<WorkDisplayPreferences> workflow,
  ) {
    final repository = storage;
    if (repository == null) {
      throw StateError('Durable preferences are unavailable.');
    }
    workflow.validateHandoff(
      repository: repository,
      domain: AppPreferenceKeys.workDisplayDraftDomain,
      draftId: AppPreferenceKeys.workDisplayDraftId,
    );
  }

  Future<PreferenceDraftWorkflow<WorkDisplayPreferences>?>
  openWorkDisplayDraft({
    required WorkDisplayPreferences initial,
    DraftRecoverySelection? recoverySelection,
  }) async {
    final repository = storage;
    if (repository == null) return null;
    return PreferenceDraftWorkflow.open<WorkDisplayPreferences>(
      repository: repository,
      recoverySelection: recoverySelection,
      domain: AppPreferenceKeys.workDisplayDraftDomain,
      draftId: AppPreferenceKeys.workDisplayDraftId,
      initial: initial,
      encode: (input) => {
        'showEmployeeCards': input.showEmployeeCards,
        'showDailySummaries': input.showDailySummaries,
        'includeCompletedWork': input.includeCompletedWork,
      },
      decode: (payload) => WorkDisplayPreferences(
        showEmployeeCards: payload['showEmployeeCards'] as bool,
        showDailySummaries: payload['showDailySummaries'] as bool,
        includeCompletedWork: payload['includeCompletedWork'] as bool,
      ),
      confirm: (input, checkpoint) => setWorkDisplay(
        showEmployeeCards: input.showEmployeeCards,
        showDailySummaries: input.showDailySummaries,
        includeCompletedWork: input.includeCompletedWork,
        draftCheckpoint: checkpoint,
      ),
    );
  }
}
