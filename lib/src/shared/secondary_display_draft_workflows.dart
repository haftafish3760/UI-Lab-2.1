import '../data/storage/draft_recovery_selection.dart';
import '../data/preferences/receipt_intake_display_preferences.dart';
import '../data/preferences/work_record_display_preferences.dart';
import '../data/storage/app_preference_keys.dart';
import '../data/storage/preference_draft_workflow.dart';
import 'app_preferences.dart';

extension SecondaryDisplayDraftWorkflows on AppPreferencesController {
  void validateReceiptDisplayHandoff(
    PreferenceDraftWorkflow<ReceiptIntakeDisplayPreferences> workflow,
  ) {
    final repository = storage;
    if (repository == null) {
      throw StateError('Durable preferences unavailable.');
    }
    workflow.validateHandoff(
      repository: repository,
      domain: AppPreferenceKeys.receiptDisplayDraftDomain,
      draftId: AppPreferenceKeys.receiptDisplayDraftId,
    );
  }

  void validateWorkListDisplayHandoff(
    PreferenceDraftWorkflow<WorkRecordDisplayPreferences> workflow, {
    required String workspaceId,
  }) {
    if (!AppPreferenceKeys.workListIds.contains(workspaceId)) {
      throw ArgumentError('Unsupported Work list preference.');
    }
    final repository = storage;
    if (repository == null) {
      throw StateError('Durable preferences unavailable.');
    }
    workflow.validateHandoff(
      repository: repository,
      domain: AppPreferenceKeys.workListDraftDomain,
      draftId: workspaceId,
    );
  }

  Future<PreferenceDraftWorkflow<ReceiptIntakeDisplayPreferences>?>
  openReceiptDisplayDraft({
    required ReceiptIntakeDisplayPreferences initial,
    DraftRecoverySelection? recoverySelection,
  }) async {
    final repository = storage;
    if (repository == null) return null;
    return PreferenceDraftWorkflow.open<ReceiptIntakeDisplayPreferences>(
      repository: repository,
      recoverySelection: recoverySelection,
      domain: AppPreferenceKeys.receiptDisplayDraftDomain,
      draftId: AppPreferenceKeys.receiptDisplayDraftId,
      initial: initial,
      encode: (input) => {
        'showReviewChecklist': input.showReviewChecklist,
        'showEvidenceReminders': input.showEvidenceReminders,
      },
      decode: (payload) => ReceiptIntakeDisplayPreferences(
        showReviewChecklist: payload['showReviewChecklist'] as bool,
        showEvidenceReminders: payload['showEvidenceReminders'] as bool,
      ),
      confirm: (input, checkpoint) => setReceiptDisplay(
        showReviewChecklist: input.showReviewChecklist,
        showEvidenceReminders: input.showEvidenceReminders,
        draftCheckpoint: checkpoint,
      ),
    );
  }

  Future<PreferenceDraftWorkflow<WorkRecordDisplayPreferences>?>
  openWorkListDisplayDraft({
    required String workspaceId,
    required WorkRecordDisplayPreferences initial,
    DraftRecoverySelection? recoverySelection,
  }) async {
    if (!AppPreferenceKeys.workListIds.contains(workspaceId)) {
      throw ArgumentError('Unsupported Work list preference.');
    }
    final repository = storage;
    if (repository == null) return null;
    return PreferenceDraftWorkflow.open<WorkRecordDisplayPreferences>(
      repository: repository,
      recoverySelection: recoverySelection,
      domain: AppPreferenceKeys.workListDraftDomain,
      draftId: workspaceId,
      initial: initial,
      encode: (input) => {
        'showStatusDetails': input.showStatusDetails,
        'showAssignments': input.showAssignments,
        'includeClosedRecords': input.includeClosedRecords,
      },
      decode: (payload) => WorkRecordDisplayPreferences(
        showStatusDetails: payload['showStatusDetails'] as bool,
        showAssignments: payload['showAssignments'] as bool,
        includeClosedRecords: payload['includeClosedRecords'] as bool,
      ),
      confirm: (input, checkpoint) => setWorkListChoices(workspaceId, {
        'showStatusDetails': input.showStatusDetails,
        'showAssignments': input.showAssignments,
        'includeClosedRecords': input.includeClosedRecords,
      }, draftCheckpoint: checkpoint),
    );
  }
}
