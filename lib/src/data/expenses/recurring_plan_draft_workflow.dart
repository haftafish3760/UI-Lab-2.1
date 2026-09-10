import '../storage/draft_autosave_session.dart';
import '../storage/draft_recovery_query.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_identity.dart';
import 'expense_workflow_models.dart';
import 'recurring_expense_ui_controller.dart';
import 'recurring_plan_draft_input.dart';

class RecurringPlanDraftController
    extends DraftWorkflowController<RecurringPlanDraftInput> {
  RecurringPlanDraftController._(
    DraftAutosaveSession session,
    this._commit,
    this._isStale,
  ) : super(
        session,
        (input) => input.toPayload(),
        RecurringPlanDraftInput.fromPayload,
      );
  final Future<ScheduledExpenseRecord?> Function(
    RecurringPlanDraftInput,
    LocalDraftCheckpoint,
  )
  _commit;
  final bool Function(RecurringPlanDraftInput) _isStale;
  RecurringPlanDraftInput get input => recoveredInput!;
  bool get isStale => _isStale(input);
  Future<ScheduledExpenseRecord?> confirm() async {
    ScheduledExpenseRecord? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension RecurringPlanDraftWorkflow on RecurringExpenseUiController {
  DraftRecoveryQuery get plannedDraftRecovery {
    if (!canManage || drafts == null) {
      throw StateError('Planned expense editing is unavailable.');
    }
    return DraftRecoveryQuery(
      canList: () => canManage,
      repository: drafts!,
      organizationId: organizationId,
      ownerId: actorEmployeeId,
      domain: 'expenses/planned-new',
      parentField: 'baseRevision',
      labelField: 'title',
      emptyLabel: 'Unnamed planned expense',
    );
  }

  Future<RecurringPlanDraftController> openPlannedDraft({
    String? existingRecordId,
    String? recoveryDraftId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    requireActiveDraftOwner();
    if (!canManage || drafts == null) {
      throw StateError('Planned expense editing is unavailable.');
    }
    final current = existingRecordId == null
        ? null
        : recoverySelection == null
        ? recordById(existingRecordId)
        : await readCurrentPlan(existingRecordId);
    if (existingRecordId != null &&
        (current == null || recoveryDraftId != null)) {
      throw StateError('Planned expense is unavailable.');
    }
    final draft = DraftAutosaveSession(
      store: drafts!,
      organizationId: organizationId,
      ownerId: actorEmployeeId,
      domain: existingRecordId == null
          ? 'expenses/planned-new'
          : 'expenses/planned-edit',
      draftId: existingRecordId == null
          ? recoverySelection?.draftId ??
                recoveryDraftId ??
                newLocalRecordIdentity('planned-input')
          : 'edit-$actorEmployeeId-$existingRecordId',
    );
    void validate(RecurringPlanDraftInput input) {
      if (input.recordId.isEmpty ||
          (existingRecordId == null
              ? input.baseRevision != null || input.ownerId != actorEmployeeId
              : input.recordId != existingRecordId ||
                    input.baseRevision == null ||
                    input.baseRevision! < 1 ||
                    input.ownerId != current!.ownerEmployeeId)) {
        throw StateError('The saved edit does not match this record.');
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
      final controller = RecurringPlanDraftController._(
        draft,
        (input, checkpoint) {
          validate(input);
          final record = input.confirmedRecord();
          return existingRecordId == null
              ? create(record, draftCheckpoint: checkpoint)
              : update(
                  record,
                  draftCheckpoint: checkpoint,
                  expectedRevision: input.baseRevision,
                );
        },
        (input) =>
            existingRecordId != null &&
            revisionForId(existingRecordId) != input.baseRevision,
      );
      if (recoveryDraftId != null && controller.recoveredInput == null) {
        throw StateError('Selected expense recovery is unavailable.');
      }
      if (controller.recoveredInput == null) {
        controller.updateInput(
          RecurringPlanDraftInput.initial(
            record: current,
            baseRevision: existingRecordId == null
                ? null
                : revisionForId(existingRecordId),
            ownerId: actorEmployeeId,
            ownerLabel: actorEmployeeLabel,
          ),
        );
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
