import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import 'expense_draft_input.dart';
import 'expense_draft_workflow.dart';
import 'expense_ui_repository_controller.dart';

/// Discovers owned manual/correction input independently of list filters and UI.
class ExpenseDraftRecovery {
  ExpenseDraftRecovery(this._expenses) {
    final drafts = _expenses.drafts;
    if (drafts == null) throw StateError('Expense storage is unavailable.');
    _catalog = DraftRecoveryCatalog(
      repository: drafts,
      organizationId: _expenses.organizationId,
      ownerId: _expenses.actorEmployeeId,
      handlers: [
        for (final edit in [false, true])
          DraftRecoveryHandler(
            domain: edit ? 'expenses/edit-entry' : 'expenses/manual-entry',
            workflowLabel: edit ? 'Expense correction' : 'New expense',
            canList: () => edit
                ? _expenses.canEditForEmployee(_expenses.actorEmployeeId)
                : _expenses.canCreateForEmployee(_expenses.actorEmployeeId),
            inspect: (raw) => _inspect(raw, edit),
            canDiscard: (_) async => true,
          ),
      ],
    );
  }
  final ExpenseUiRepositoryController _expenses;
  late final DraftRecoveryCatalog _catalog;
  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);

  Future<DraftRecoveryPreview?> _inspect(
    Map<String, Object?> raw,
    bool edit,
  ) async {
    late ExpenseDraftInput input;
    try {
      input = ExpenseDraftInput.fromPayload(raw);
      if (input.expenseId.trim().isEmpty ||
          input.ownerId.trim().isEmpty ||
          input.receiptSourceId != null ||
          input.receiptSourceRevision != null ||
          (edit
              ? input.baseRevision == null ||
                    input.baseRevision! < 1 ||
                    input.baseRecord?.id != input.expenseId ||
                    input.baseRecord?.paidByEmployeeId != input.ownerId
              : input.baseRevision != null || input.baseRecord != null)) {
        throw const FormatException('Invalid expense draft context.');
      }
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved expense input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    if (!(edit
        ? _expenses.canEditForEmployee(input.ownerId)
        : _expenses.canCreateForEmployee(input.ownerId))) {
      return null;
    }
    final current = await _expenses.readCurrentExpense(input.expenseId);
    if (edit && (current == null || current.isDeleted)) {
      return const DraftRecoveryPreview(
        title: 'Expense unavailable — saved input retained',
        availability: DraftRecoveryAvailability.parentUnavailable,
      );
    }
    if (current != null && current.paidByEmployeeId != input.ownerId) {
      return null;
    }
    final conflict = edit
        ? current!.revision != input.baseRevision
        : current != null;
    return DraftRecoveryPreview(
      title: input.vendor.trim().isEmpty ? 'Unnamed expense' : input.vendor,
      recordId: input.expenseId,
      availability: conflict
          ? DraftRecoveryAvailability.conflict
          : DraftRecoveryAvailability.recoverable,
    );
  }

  Future<ExpenseDraftController> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError('This expense requires review before resuming.');
    }
    final saved = await _expenses.drafts!.find(
      organizationId: _expenses.organizationId,
      ownerId: _expenses.actorEmployeeId,
      domain: current.domain,
      draftId: current.draftId,
    );
    if (saved == null) throw StateError('Saved expense input is unavailable.');
    final input = ExpenseDraftInput.fromPayload(
      _expenses.drafts!.decode(saved),
    );
    return _expenses.openExpenseDraft(
      initial: input,
      existingRecordId: current.domain == 'expenses/edit-entry'
          ? input.expenseId
          : null,
      recoverySelection: DraftRecoverySelection(
        domain: current.domain,
        draftId: current.draftId,
        revision: current.revision,
      ),
    );
  }
}
