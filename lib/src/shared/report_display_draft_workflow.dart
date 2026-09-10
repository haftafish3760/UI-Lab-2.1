import '../data/storage/draft_recovery_selection.dart';
import '../data/preferences/report_display_preferences.dart';
import '../data/storage/app_preference_keys.dart';
import '../data/storage/local_draft_checkpoint.dart';
import '../data/storage/preference_draft_workflow.dart';
import 'app_preferences.dart';

Map<String, bool> _choices(ReportDisplayPreferences input) => {
  'showInvoicedRevenue': input.showInvoicedRevenue,
  'showMoneyCollected': input.showMoneyCollected,
  'showRecordedExpenses': input.showRecordedExpenses,
  'showEstimatedGrossProfit': input.showEstimatedGrossProfit,
  'showVehicleHealth': input.showVehicleHealth,
};

extension ReportDisplayDraftWorkflow on AppPreferencesController {
  void validateReportDisplayHandoff(
    PreferenceDraftWorkflow<ReportDisplayPreferences> workflow,
  ) {
    final repository = storage;
    if (repository == null) {
      throw StateError('Durable preferences unavailable.');
    }
    workflow.validateHandoff(
      repository: repository,
      domain: AppPreferenceKeys.reportDisplayDraftDomain,
      draftId: AppPreferenceKeys.reportDisplayDraftId,
    );
  }

  Future<bool> applyReportDisplay(
    ReportDisplayPreferences input, {
    LocalDraftCheckpoint? draftCheckpoint,
  }) => setReportDisplay(_choices(input), draftCheckpoint: draftCheckpoint);

  Future<PreferenceDraftWorkflow<ReportDisplayPreferences>?>
  openReportDisplayDraft({
    required ReportDisplayPreferences initial,
    DraftRecoverySelection? recoverySelection,
  }) async {
    final repository = storage;
    if (repository == null) return null;
    return PreferenceDraftWorkflow.open<ReportDisplayPreferences>(
      repository: repository,
      recoverySelection: recoverySelection,
      domain: AppPreferenceKeys.reportDisplayDraftDomain,
      draftId: AppPreferenceKeys.reportDisplayDraftId,
      initial: initial,
      encode: _choices,
      decode: (payload) => ReportDisplayPreferences(
        showInvoicedRevenue: payload['showInvoicedRevenue'] as bool,
        showMoneyCollected: payload['showMoneyCollected'] as bool,
        showRecordedExpenses: payload['showRecordedExpenses'] as bool,
        showEstimatedGrossProfit: payload['showEstimatedGrossProfit'] as bool,
        showVehicleHealth: payload['showVehicleHealth'] as bool,
      ),
      confirm: (input, checkpoint) =>
          applyReportDisplay(input, draftCheckpoint: checkpoint),
    );
  }
}
