import 'recurring_expense_ui_controller.dart';
import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import 'recurring_payment_session.dart';
import 'recurring_plan_draft_input.dart';
import 'recurring_plan_draft_workflow.dart';
import 'recurring_occurrence_draft_workflow.dart';
import 'recurring_payment_draft_workflow.dart';

sealed class ResumedRecurringDraft {
  const ResumedRecurringDraft();
}

class ResumedRecurringPlan extends ResumedRecurringDraft {
  const ResumedRecurringPlan(this.controller);
  final RecurringPlanDraftController controller;
}

class ResumedRecurringOccurrence extends ResumedRecurringDraft {
  const ResumedRecurringOccurrence(this.controller);
  final RecurringOccurrenceDraftController controller;
}

class ResumedRecurringPayment extends ResumedRecurringDraft {
  const ResumedRecurringPayment(this.controller);
  final RecurringPaymentDraftController controller;
}

/// Recovery is a domain operation; no list cache, navigation or SQL is exposed.
class RecurringDraftRecovery {
  RecurringDraftRecovery(this._session) {
    final drafts = _session.drafts;
    if (drafts == null) throw StateError('Recurring storage is unavailable.');
    _catalog = DraftRecoveryCatalog(
      repository: drafts,
      organizationId: _recurring.organizationId,
      ownerId: _recurring.actorEmployeeId,
      handlers: [
        for (final kind in ['new', 'edit', 'occurrence', 'payment'])
          DraftRecoveryHandler(
            domain: 'expenses/planned-$kind',
            workflowLabel: kind == 'payment'
                ? 'Planned expense payment'
                : 'Planned expense',
            canList: () => kind == 'payment'
                ? _recurring.canPayForEmployee(_recurring.actorEmployeeId)
                : _recurring.canManageForEmployee(_recurring.actorEmployeeId),
            inspect: (raw) => _inspect(raw, kind),
            canDiscard: (_) async => true,
          ),
      ],
    );
  }
  final RecurringPaymentSession _session;
  RecurringExpenseUiController get _recurring => _session.recurringExpenses;
  late final DraftRecoveryCatalog _catalog;
  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);

  Future<DraftRecoveryPreview?> _inspect(
    Map<String, Object?> raw,
    String kind,
  ) async {
    late String templateId;
    String? occurrenceId, ownerId;
    int? templateRevision, occurrenceRevision;
    String title = 'Planned expense';
    try {
      if (kind == 'new' || kind == 'edit') {
        final input = RecurringPlanDraftInput.fromPayload(raw);
        templateId = input.recordId;
        ownerId = input.ownerId;
        templateRevision = input.baseRevision;
        title = input.title;
        if (ownerId.isEmpty ||
            (kind == 'new'
                ? templateRevision != null ||
                      ownerId != _recurring.actorEmployeeId
                : templateRevision == null || templateRevision < 1)) {
          throw const FormatException();
        }
      } else if (kind == 'occurrence') {
        final input = RecurringOccurrenceDraftInput.fromPayload(raw);
        templateId = input.templateId;
        occurrenceId = input.occurrenceId;
        templateRevision = input.baseTemplateRevision;
        occurrenceRevision = input.baseRevision;
      } else {
        final input = RecurringPaymentDraftInput.fromPayload(raw);
        templateId = input.templateId;
        occurrenceId = input.occurrenceId;
        templateRevision = input.baseTemplateRevision;
        occurrenceRevision = input.baseRevision;
      }
      if (templateId.isEmpty ||
          (occurrenceId != null &&
              (occurrenceId.isEmpty ||
                  templateRevision! < 1 ||
                  occurrenceRevision! < 1))) {
        throw const FormatException();
      }
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved planned input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    if (ownerId != null && !_recurring.canManageForEmployee(ownerId)) {
      return null;
    }
    final template = await _recurring.readCurrentTemplate(templateId);
    if (kind != 'new' && template == null) {
      return const DraftRecoveryPreview(
        title: 'Plan unavailable — saved input retained',
        availability: DraftRecoveryAvailability.parentUnavailable,
      );
    }
    if (template != null) {
      final owner = template.assignedEmployeeId;
      if (ownerId != null && ownerId != owner) return null;
      if (kind == 'payment'
          ? !_recurring.canPayForEmployee(owner) ||
                !_session.expenses.canCreateForEmployee(owner)
          : !_recurring.canManageForEmployee(owner)) {
        return null;
      }
    }
    var conflict = kind == 'new'
        ? template != null
        : template!.lifecycle.revision != templateRevision;
    if (occurrenceId != null) {
      final occurrence = await _recurring.readCurrentOccurrence(occurrenceId);
      if (occurrence == null ||
          occurrence.templateId != templateId ||
          !occurrence.isOpen ||
          !template!.isActive) {
        return const DraftRecoveryPreview(
          title: 'Payment unavailable — saved input retained',
          availability: DraftRecoveryAvailability.parentUnavailable,
        );
      }
      conflict =
          conflict || occurrence.lifecycle.revision != occurrenceRevision;
    }
    return DraftRecoveryPreview(
      title: title.trim().isEmpty ? 'Unnamed planned expense' : title,
      recordId: templateId,
      availability: conflict
          ? DraftRecoveryAvailability.conflict
          : DraftRecoveryAvailability.recoverable,
    );
  }

  Future<ResumedRecurringDraft> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError('This planned input requires review before resuming.');
    }
    final selected = DraftRecoverySelection(
      domain: current.domain,
      draftId: current.draftId,
      revision: current.revision,
    );
    final saved = await _session.drafts!.find(
      organizationId: _recurring.organizationId,
      ownerId: _recurring.actorEmployeeId,
      domain: current.domain,
      draftId: current.draftId,
    );
    if (saved == null) throw StateError('Saved input is unavailable.');
    final raw = _session.drafts!.decode(saved);
    switch (current.domain) {
      case 'expenses/planned-new':
      case 'expenses/planned-edit':
        return ResumedRecurringPlan(
          await _recurring.openPlannedDraft(
            existingRecordId: current.domain.endsWith('-edit')
                ? RecurringPlanDraftInput.fromPayload(raw).recordId
                : null,
            recoverySelection: selected,
          ),
        );
      case 'expenses/planned-occurrence':
        final input = RecurringOccurrenceDraftInput.fromPayload(raw);
        return ResumedRecurringOccurrence(
          await _recurring.openOccurrenceDraft(
            templateId: input.templateId,
            occurrenceId: input.occurrenceId,
            recoverySelection: selected,
          ),
        );
      case 'expenses/planned-payment':
        final input = RecurringPaymentDraftInput.fromPayload(raw);
        return ResumedRecurringPayment(
          await _session.openPaymentDraft(
            templateId: input.templateId,
            occurrenceId: input.occurrenceId,
            recoverySelection: selected,
          ),
        );
      default:
        throw StateError('Unknown recurring workflow.');
    }
  }
}
