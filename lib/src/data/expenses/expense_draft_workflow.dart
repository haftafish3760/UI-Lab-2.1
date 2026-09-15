import '../storage/draft_autosave_session.dart';
import '../storage/draft_recovery_query.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_identity.dart';
import 'expense_draft_input.dart';
import 'expense_editor_record_codec.dart';
import 'expense_ui_repository_controller.dart';
import 'expense_workflow_models.dart';

class ExpenseDraftController
    extends DraftWorkflowController<ExpenseDraftInput> {
  ExpenseDraftController._(DraftAutosaveSession session, this._commit)
    : super(
        session,
        (input) => input.toPayload(),
        ExpenseDraftInput.fromPayload,
      );
  final Future<ExpenseRecord?> Function(ExpenseDraftInput, LocalDraftCheckpoint)
  _commit;
  ExpenseDraftInput get input => recoveredInput!;
  Future<ExpenseRecord?> confirm() async {
    ExpenseRecord? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension ExpenseDraftWorkflow on ExpenseUiRepositoryController {
  DraftRecoveryQuery get manualDraftRecovery {
    if (drafts == null || !canCreateForEmployee(actorEmployeeId)) {
      throw StateError('Expense creation is unavailable.');
    }
    return DraftRecoveryQuery(
      canList: () => canCreateForEmployee(actorEmployeeId),
      repository: drafts!,
      organizationId: organizationId,
      ownerId: actorEmployeeId,
      domain: 'expenses/manual-entry',
      parentField: 'baseRevision',
      labelField: 'vendor',
      emptyLabel: 'Unnamed expense',
    );
  }

  Future<ExpenseDraftController> openExpenseDraft({
    required ExpenseDraftInput initial,
    String? existingRecordId,
    String? recoveryDraftId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    requireActiveDraftOwner();
    final selectedParent = recoverySelection == null || existingRecordId == null
        ? null
        : await readCurrentExpense(existingRecordId);
    final current = existingRecordId == null
        ? null
        : recoverySelection == null
        ? recordById(existingRecordId)
        : selectedParent?.isDeleted == false
        ? selectedParent!.record
        : null;
    if (drafts == null ||
        (existingRecordId == null
            ? !canCreateForEmployee(actorEmployeeId)
            : current == null ||
                  !canEditForEmployee(current.paidByEmployeeId ?? ''))) {
      throw StateError('Expense editing is unavailable.');
    }
    if (existingRecordId != null && recoveryDraftId != null) {
      throw StateError('Invalid recovery target.');
    }
    final draft = DraftAutosaveSession(
      store: drafts!,
      organizationId: organizationId,
      ownerId: actorEmployeeId,
      domain: current == null ? 'expenses/manual-entry' : 'expenses/edit-entry',
      draftId: current == null
          ? recoverySelection?.draftId ??
                recoveryDraftId ??
                newLocalRecordIdentity('expense-input')
          : 'edit-$actorEmployeeId-$existingRecordId',
    );
    void validate(ExpenseDraftInput input) {
      if (input.expenseId.isEmpty ||
          input.receiptSourceId != null ||
          input.receiptSourceRevision != null ||
          (current == null
              ? input.baseRecord != null || input.baseRevision != null
              : input.expenseId != current.id ||
                    input.baseRecord?.id != current.id ||
                    input.baseRevision == null ||
                    input.baseRevision! < 1 ||
                    input.baseRecord?.paidByEmployeeId !=
                        current.paidByEmployeeId)) {
        throw StateError('The saved expense does not match this workflow.');
      }
    }

    try {
      await draft.initialize();
      requireActiveDraftOwner();
      recoverySelection?.verify(
        openedDomain: draft.domain,
        openedDraftId: draft.draftId,
        openedRevision: draft.savedRevision,
        hasInput: draft.input.isNotEmpty,
      );
      final controller = ExpenseDraftController._(draft, (input, checkpoint) {
        validate(input);
        final record = input.confirmedRecord();
        return current == null
            ? create(
                record: record,
                paidByEmployeeId: input.ownerId,
                occurredAtUtc: DateTime.now().toUtc(),
                draftCheckpoint: checkpoint,
              )
            : update(
                record: record,
                occurredAtUtc: DateTime.now().toUtc(),
                expectedRevision: input.baseRevision,
                draftCheckpoint: checkpoint,
                auditNote: input.correctionReason.trim().isEmpty
                    ? null
                    : input.correctionReason.trim(),
              );
      });
      if (recoveryDraftId != null && controller.recoveredInput == null) {
        throw StateError('Selected expense recovery is unavailable.');
      }
      if (controller.recoveredInput == null) {
        final seed = initial.toPayload();
        seed.addAll({
          'expenseId': current?.id ?? newLocalRecordIdentity('EXP'),
          'receiptSourceId': null,
          'receiptSourceRevision': null,
          'baseRecord': current == null
              ? null
              : encodeExpenseEditorRecord(current),
          'baseRevision': current == null ? null : revisionForId(current.id),
        });
        if (current != null) {
          seed.addAll({
            'receiptImageCount': current.receiptImageCount,
            'vendor': current.vendor,
            'amount': current.amount?.toStringAsFixed(2) ?? '',
            'subtotal': current.resolvedReceiptSubtotal.toStringAsFixed(2),
            'salesTax': current.salesTax.toStringAsFixed(2),
            'job': current.job ?? '',
            'ownerId': current.paidByEmployeeId,
            'ownerLabel': current.owner,
            'jobId': current.jobId,
            'date': current.resolvedDate!.toIso8601String(),
            'category': current.category.name,
            'receiptType': current.receiptType.name,
            'prepareMaterialsReview': current.prepareMaterialsReview,
            'lines': current.lineItems.map(encodeExpenseEditorLine).toList(),
          });
        }
        final input = ExpenseDraftInput.fromPayload(seed);
        validate(input);
        controller.updateInput(input);
      } else {
        validate(controller.input);
      }
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
