import '../data/preferences/work_display_preferences.dart';
import '../data/preferences/work_record_display_preferences.dart';
import '../data/preferences/receipt_intake_display_preferences.dart';
import '../data/preferences/report_display_preferences.dart';
import '../data/preferences/expense_display_preferences.dart';
import '../data/preferences/expense_display_draft_input.dart';
import '../data/storage/app_preference_keys.dart';
import '../data/storage/app_preferences_repository.dart';
import '../data/storage/draft_recovery_catalog.dart';
import '../data/storage/draft_recovery_selection.dart';
import '../data/storage/preference_draft_baseline.dart';
import '../data/storage/preference_draft_workflow.dart';
import 'app_preferences.dart';
import 'work_display_draft_workflow.dart';
import 'secondary_display_draft_workflows.dart';
import 'report_display_draft_workflow.dart';
import 'expense_display_draft_workflow.dart';

sealed class ResumedPreferenceDraft {
  const ResumedPreferenceDraft();
  Future<void> close();
}

class ResumedWorkPreferences extends ResumedPreferenceDraft {
  const ResumedWorkPreferences(this.workflow);
  final PreferenceDraftWorkflow<WorkDisplayPreferences> workflow;
  @override
  Future<void> close() => workflow.session.close();
}

class ResumedWorkListPreferences extends ResumedPreferenceDraft {
  const ResumedWorkListPreferences(this.workspaceId, this.workflow);
  final String workspaceId;
  final PreferenceDraftWorkflow<WorkRecordDisplayPreferences> workflow;
  @override
  Future<void> close() => workflow.session.close();
}

class ResumedReceiptPreferences extends ResumedPreferenceDraft {
  const ResumedReceiptPreferences(this.workflow);
  final PreferenceDraftWorkflow<ReceiptIntakeDisplayPreferences> workflow;
  @override
  Future<void> close() => workflow.session.close();
}

class ResumedReportPreferences extends ResumedPreferenceDraft {
  const ResumedReportPreferences(this.workflow);
  final PreferenceDraftWorkflow<ReportDisplayPreferences> workflow;
  @override
  Future<void> close() => workflow.session.close();
}

class ResumedExpensePreferences extends ResumedPreferenceDraft {
  const ResumedExpensePreferences(this.workflow);
  final PreferenceDraftWorkflow<ExpenseDisplayDraftInput> workflow;
  @override
  Future<void> close() => workflow.session.close();
}

/// Device preference recovery uses the same controller factories/codecs as
/// editing. It neither navigates nor applies settings while discovering input.
class PreferenceDraftRecovery {
  PreferenceDraftRecovery(this._preferences) {
    if (!_preferences.canRecoverDrafts) {
      throw StateError('Stored settings are unavailable.');
    }
    _catalog = DraftRecoveryCatalog(
      repository: _repository.drafts,
      organizationId: 'device',
      ownerId: 'device',
      handlers: handlers,
    );
  }
  final AppPreferencesController _preferences;
  AppPreferencesRepository get _repository => _preferences.storage!;
  late final DraftRecoveryCatalog _catalog;
  static const _labels = {
    AppPreferenceKeys.workDisplayDraftDomain: 'Work settings',
    AppPreferenceKeys.workListDraftDomain: 'Work list settings',
    AppPreferenceKeys.receiptDisplayDraftDomain: 'Receipt settings',
    AppPreferenceKeys.reportDisplayDraftDomain: 'Report settings',
    AppPreferenceKeys.expenseDisplayDraftDomain: 'Expense settings',
  };
  Iterable<DraftRecoveryHandler> get handlers => _labels.entries.map(
    (entry) => DraftRecoveryHandler.withSelection(
      domain: entry.key,
      workflowLabel: entry.value,
      canList: () => _preferences.canRecoverDrafts,
      inspectSelection: _inspect,
      canDiscard: (_) async => _preferences.canRecoverDrafts,
    ),
  );
  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);
  Future<DraftRecoveryPreview?> _inspect(
    DraftRecoverySelection selected,
    Map<String, Object?> raw,
  ) async {
    Map<String, String?>? baseline;
    try {
      PreferenceDraftBaseline.keys(selected.domain, selected.draftId);
      if (raw.containsKey(PreferenceDraftBaseline.payloadKey)) {
        baseline = PreferenceDraftBaseline.decode(
          raw[PreferenceDraftBaseline.payloadKey],
          selected.domain,
          selected.draftId,
        );
      }
      // Strict selection opening validates the existing codec without seeding or
      // recapturing input. Close immediately; discovery never confirms it.
      final decoded = await _open(selected);
      await decoded.close();
    } on FormatException {
      return const DraftRecoveryPreview(
        title: 'Saved settings input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    } on TypeError {
      return const DraftRecoveryPreview(
        title: 'Saved settings input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    final current = await _repository.readCurrentValues();
    final conflict =
        baseline != null &&
        baseline.entries.any((entry) => current[entry.key] != entry.value);
    return DraftRecoveryPreview(
      title: baseline == null
          ? 'Saved settings — review choices before saving'
          : _labels[selected.domain]!,
      availability: conflict
          ? DraftRecoveryAvailability.conflict
          : DraftRecoveryAvailability.recoverable,
    );
  }

  Future<ResumedPreferenceDraft> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError('Saved settings require review before resuming.');
    }
    final resumed = await _open(
      DraftRecoverySelection(
        domain: current.domain,
        draftId: current.draftId,
        revision: current.revision,
      ),
    );
    if (!_preferences.canRecoverDrafts) {
      await resumed.close();
      throw StateError('Settings recovery is unavailable.');
    }
    return resumed;
  }

  Future<ResumedPreferenceDraft> _open(DraftRecoverySelection selected) async {
    if (!_preferences.canRecoverDrafts) {
      throw StateError('Settings recovery is unavailable.');
    }
    switch (selected.domain) {
      case AppPreferenceKeys.workDisplayDraftDomain:
        return ResumedWorkPreferences(
          (await _preferences.openWorkDisplayDraft(
            initial: const WorkDisplayPreferences(),
            recoverySelection: selected,
          ))!,
        );
      case AppPreferenceKeys.workListDraftDomain:
        return ResumedWorkListPreferences(
          selected.draftId,
          (await _preferences.openWorkListDisplayDraft(
            workspaceId: selected.draftId,
            initial: const WorkRecordDisplayPreferences(),
            recoverySelection: selected,
          ))!,
        );
      case AppPreferenceKeys.receiptDisplayDraftDomain:
        return ResumedReceiptPreferences(
          (await _preferences.openReceiptDisplayDraft(
            initial: const ReceiptIntakeDisplayPreferences(),
            recoverySelection: selected,
          ))!,
        );
      case AppPreferenceKeys.reportDisplayDraftDomain:
        return ResumedReportPreferences(
          (await _preferences.openReportDisplayDraft(
            initial: const ReportDisplayPreferences.defaults(),
            recoverySelection: selected,
          ))!,
        );
      case AppPreferenceKeys.expenseDisplayDraftDomain:
        return ResumedExpensePreferences(
          (await _preferences.openExpenseDisplayDraft(
            initial: const ExpenseDisplayPreferences.defaults(),
            recoverySelection: selected,
          ))!,
        );
      default:
        throw const FormatException('Unsupported preference recovery.');
    }
  }
}
