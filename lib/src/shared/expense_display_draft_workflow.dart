import '../data/storage/draft_recovery_selection.dart';
import '../data/preferences/expense_display_draft_input.dart';
import '../data/preferences/expense_display_preferences.dart';
import '../data/storage/app_preference_keys.dart';
import '../data/storage/local_draft_checkpoint.dart';
import '../data/storage/preference_draft_workflow.dart';
import 'app_preferences.dart';

extension ExpenseDisplayDraftWorkflow on AppPreferencesController {
  void validateExpenseDisplayHandoff(
    PreferenceDraftWorkflow<ExpenseDisplayDraftInput> workflow,
  ) {
    final repository = storage;
    if (repository == null) {
      throw StateError('Durable preferences unavailable.');
    }
    workflow.validateHandoff(
      repository: repository,
      domain: AppPreferenceKeys.expenseDisplayDraftDomain,
      draftId: AppPreferenceKeys.expenseDisplayDraftId,
    );
  }

  Future<bool> applyExpenseDisplay(
    ExpenseDisplayPreferences preferences, {
    LocalDraftCheckpoint? draftCheckpoint,
  }) => setExpenseDisplay(
    preferences.toPayload(),
    draftCheckpoint: draftCheckpoint,
  );

  Future<PreferenceDraftWorkflow<ExpenseDisplayDraftInput>?>
  openExpenseDisplayDraft({
    required ExpenseDisplayPreferences initial,
    DraftRecoverySelection? recoverySelection,
  }) async {
    final repository = storage;
    if (repository == null) return null;
    return PreferenceDraftWorkflow.open<ExpenseDisplayDraftInput>(
      repository: repository,
      recoverySelection: recoverySelection,
      domain: AppPreferenceKeys.expenseDisplayDraftDomain,
      draftId: AppPreferenceKeys.expenseDisplayDraftId,
      initial: ExpenseDisplayDraftInput(preferences: initial),
      encode: (input) => input.toPayload(),
      decode: ExpenseDisplayDraftInput.fromPayload,
      confirm: (input, checkpoint) {
        if (input.hasUnfinishedChoices) {
          throw StateError(
            'Finish or cancel your unfinished choices before saving settings.',
          );
        }
        return applyExpenseDisplay(
          input.preferences,
          draftCheckpoint: checkpoint,
        );
      },
    );
  }
}
