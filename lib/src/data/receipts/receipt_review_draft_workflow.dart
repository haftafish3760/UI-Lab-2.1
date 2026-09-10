import '../storage/draft_recovery_selection.dart';
import '../expenses/expense_draft_input.dart';
import '../expenses/expense_workflow_models.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_identity.dart';
import 'receipt_draft_record.dart';
import 'receipt_submission_session.dart';

class ReceiptReviewDraftController
    extends DraftWorkflowController<ExpenseDraftInput> {
  ReceiptReviewDraftController._(
    DraftAutosaveSession session,
    this.source,
    this.recoveryAvailable,
    this._commit,
  ) : super(
        session,
        (input) => input.toPayload(),
        ExpenseDraftInput.fromPayload,
      );
  final StoredReceiptDraft source;
  final bool recoveryAvailable;
  final Future<ExpenseRecord?> Function(ExpenseDraftInput, LocalDraftCheckpoint)
  _commit;
  ExpenseDraftInput get input {
    if (!recoveryAvailable) {
      throw StateError('Saved receipt review is unavailable.');
    }
    return recoveredInput!;
  }

  bool get isStale => input.receiptSourceRevision != source.lifecycle.revision;
  @override
  void updateInput(ExpenseDraftInput input) {
    if (!recoveryAvailable) {
      throw StateError('Saved review cannot be replaced.');
    }
    _validateReceiptReview(input, source.draftId);
    super.updateInput(input);
  }

  Future<ExpenseRecord?> confirm() async {
    if (!recoveryAvailable) {
      throw StateError('Saved review cannot be confirmed.');
    }
    ExpenseRecord? result;
    await session.confirm((checkpoint) async {
      _validateReceiptReview(input, source.draftId);
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

void _validateReceiptReview(ExpenseDraftInput input, String receiptId) {
  if (input.receiptSourceId != receiptId ||
      input.receiptSourceRevision == null ||
      input.receiptSourceRevision! < 1 ||
      input.expenseId.isEmpty ||
      input.baseRecord != null ||
      input.baseRevision != null) {
    throw StateError('The saved review belongs to a different receipt.');
  }
}

extension ReceiptReviewDraftWorkflow on ReceiptSubmissionSession {
  Future<ReceiptReviewDraftController> openReviewDraft({
    required String receiptId,
    required ExpenseDraftInput initial,
    DraftRecoverySelection? recoverySelection,
  }) async {
    final source = recoverySelection == null
        ? receipts.recordById(receiptId)
        : (await receipts.findById(draftId: receiptId)).record;
    final permissions = receiptPermissions;
    if (drafts == null ||
        source == null ||
        source.organizationId != permissions.organizationId ||
        permissions.readAccess == null ||
        !permissions.canTarget(source) ||
        !(permissions.owns(source)
            ? permissions.canSubmitOwn
            : permissions.canSubmitTeam) ||
        !expenses.canCreateForEmployee(expenses.actorEmployeeId)) {
      throw StateError('Receipt review is unavailable.');
    }
    final draft = DraftAutosaveSession(
      store: drafts!,
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      domain: 'expenses/receipt-review',
      draftId: 'review-${permissions.actorEmployeeId}-$receiptId',
    );
    try {
      await draft.initialize();
      recoverySelection?.verify(
        openedDomain: draft.domain,
        openedDraftId: draft.draftId,
        openedRevision: draft.savedRevision,
        hasInput: draft.input.isNotEmpty,
      );

      ExpenseDraftInput? recovered;
      bool available = true;
      try {
        recovered = ExpenseDraftInput.fromPayload(
          draft.input.isEmpty
              ? {
                  ...initial.toPayload(),
                  'expenseId': newLocalRecordIdentity('EXP'),
                  'receiptSourceId': receiptId,
                  'receiptSourceRevision': source.lifecycle.revision,
                  'receiptImageCount': source.activeEvidence.length,
                  'jobId': source.linkedJobId,
                  'baseRecord': null,
                  'baseRevision': null,
                }
              : draft.input,
        );
        _validateReceiptReview(recovered, receiptId);
      } on Object {
        available = false;
      }
      final controller = ReceiptReviewDraftController._(
        draft,
        source,
        available,
        (input, checkpoint) async {
          final record = input.confirmedRecord();
          final result = await submit(
            draftId: receiptId,
            expectedReceiptRevision: input.receiptSourceRevision!,
            reviewedRecord: record,
            paidByEmployeeId: record.paidByEmployeeId!,
            occurredAtUtc: DateTime.now().toUtc(),
            draftCheckpoint: checkpoint,
          );
          return result.succeeded ? result.expense : null;
        },
      );
      if (available && draft.input.isEmpty) controller.updateInput(recovered!);
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
