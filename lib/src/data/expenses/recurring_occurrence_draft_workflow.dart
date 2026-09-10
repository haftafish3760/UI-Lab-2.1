import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'expense_workflow_models.dart';
import 'recurring_expense_ui_controller.dart';

class RecurringOccurrenceDraftInput {
  const RecurringOccurrenceDraftInput({
    required this.occurrenceId,
    required this.templateId,
    required this.baseRevision,
    required this.baseTemplateRevision,
    required this.amount,
    required this.dueOn,
  });
  final String occurrenceId, templateId, amount;
  final int baseRevision, baseTemplateRevision;
  final DateTime dueOn;
  RecurringOccurrenceDraftInput withValues({
    required String amount,
    required DateTime dueOn,
  }) => RecurringOccurrenceDraftInput(
    occurrenceId: occurrenceId,
    templateId: templateId,
    baseRevision: baseRevision,
    baseTemplateRevision: baseTemplateRevision,
    amount: amount,
    dueOn: dueOn,
  );
  static String? amountError(String value) {
    final amount = double.tryParse(value);
    return amount == null || !amount.isFinite || amount <= 0
        ? 'Enter an amount above zero.'
        : null;
  }

  ScheduledExpenseOccurrence confirmedOccurrence(
    ScheduledExpenseOccurrence base,
  ) {
    if (base.id != occurrenceId || base.templateId != templateId) {
      throw StateError('Draft identity mismatch.');
    }
    final error = amountError(amount);
    if (error != null) throw StateError(error);
    return base.copyWith(
      dueOn: dueOn,
      expectedAmount: double.parse(amount.trim()),
    );
  }

  Map<String, Object?> toPayload() => {
    'occurrenceId': occurrenceId,
    'templateId': templateId,
    'baseRevision': baseRevision,
    'baseTemplateRevision': baseTemplateRevision,
    'amount': amount,
    'dueOn': dueOn.toIso8601String(),
  };
  factory RecurringOccurrenceDraftInput.fromPayload(
    Map<String, Object?> input,
  ) => RecurringOccurrenceDraftInput(
    occurrenceId: input['occurrenceId'] as String,
    templateId: input['templateId'] as String,
    baseRevision: input['baseRevision'] as int,
    baseTemplateRevision: input['baseTemplateRevision'] as int,
    amount: input['amount'] as String,
    dueOn: DateTime.parse(input['dueOn'] as String),
  );
}

class RecurringOccurrenceDraftController
    extends DraftWorkflowController<RecurringOccurrenceDraftInput> {
  RecurringOccurrenceDraftController._(
    DraftAutosaveSession session,
    this._commit,
    this._isStale,
  ) : super(
        session,
        (input) => input.toPayload(),
        RecurringOccurrenceDraftInput.fromPayload,
      );
  final Future<ScheduledExpenseOccurrence?> Function(
    RecurringOccurrenceDraftInput,
    LocalDraftCheckpoint,
  )
  _commit;
  final bool Function(RecurringOccurrenceDraftInput) _isStale;
  RecurringOccurrenceDraftInput get input => recoveredInput!;
  bool get isStale => _isStale(input);
  void updateValues({required String amount, required DateTime dueOn}) =>
      updateInput(input.withValues(amount: amount, dueOn: dueOn));
  Future<ScheduledExpenseOccurrence?> confirm() async {
    ScheduledExpenseOccurrence? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension RecurringOccurrenceDraftWorkflow on RecurringExpenseUiController {
  Future<RecurringOccurrenceDraftController> openOccurrenceDraft({
    required String templateId,
    required String occurrenceId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    requireActiveDraftOwner();
    final current = recoverySelection == null
        ? currentOccurrenceFor(templateId)
        : await readOpenOccurrence(occurrenceId);
    final repository = drafts;
    if (repository == null ||
        !canManage ||
        current == null ||
        current.id != occurrenceId ||
        current.templateId != templateId) {
      throw StateError('Payment editing is unavailable.');
    }
    final draft = DraftAutosaveSession(
      store: repository,
      organizationId: organizationId,
      ownerId: actorEmployeeId,
      domain: 'expenses/planned-occurrence',
      draftId: 'edit-$actorEmployeeId-$occurrenceId',
    );
    void validate(RecurringOccurrenceDraftInput input) {
      if (input.occurrenceId != occurrenceId ||
          input.templateId != templateId ||
          input.baseRevision < 1 ||
          input.baseTemplateRevision < 1) {
        throw StateError('Draft identity mismatch.');
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

      final controller = RecurringOccurrenceDraftController._(
        draft,
        (input, checkpoint) {
          validate(input);
          return updateOccurrence(
            input.confirmedOccurrence(current),
            draftCheckpoint: checkpoint,
            expectedTemplateRevision: input.baseTemplateRevision,
            expectedRevision: input.baseRevision,
          );
        },
        (input) =>
            revisionForId(templateId) != input.baseTemplateRevision ||
            occurrenceRevisionForId(occurrenceId) != input.baseRevision,
      );
      if (controller.recoveredInput == null) {
        controller.updateInput(
          RecurringOccurrenceDraftInput(
            occurrenceId: occurrenceId,
            templateId: templateId,
            baseRevision: occurrenceRevisionForId(occurrenceId)!,
            baseTemplateRevision: revisionForId(templateId)!,
            amount: current.expectedAmount.toStringAsFixed(2),
            dueOn: current.dueOn,
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
