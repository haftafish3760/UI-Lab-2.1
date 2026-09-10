import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'recurring_payment_session.dart';
import 'recurring_expense_payment_coordinator.dart';

class RecurringPaymentDraftInput {
  const RecurringPaymentDraftInput({
    required this.templateId,
    required this.occurrenceId,
    required this.baseTemplateRevision,
    required this.baseRevision,
    required this.amount,
    required this.paidOn,
  });
  final String templateId, occurrenceId, amount;
  final int baseTemplateRevision, baseRevision;
  final DateTime paidOn;
  RecurringPaymentDraftInput withAmount(String value) =>
      RecurringPaymentDraftInput(
        templateId: templateId,
        occurrenceId: occurrenceId,
        baseTemplateRevision: baseTemplateRevision,
        baseRevision: baseRevision,
        amount: value,
        paidOn: paidOn,
      );
  static String? amountError(String value) {
    final amount = double.tryParse(value);
    return amount == null || !amount.isFinite || amount <= 0
        ? 'Enter an amount above zero.'
        : null;
  }

  double confirmedAmount() {
    final error = amountError(amount);
    if (error != null) throw StateError(error);
    return double.parse(amount.trim());
  }

  Map<String, Object?> toPayload() => {
    'templateId': templateId,
    'occurrenceId': occurrenceId,
    'baseTemplateRevision': baseTemplateRevision,
    'baseRevision': baseRevision,
    'amount': amount,
    'paidOn': paidOn.toIso8601String(),
  };
  factory RecurringPaymentDraftInput.fromPayload(Map<String, Object?> input) =>
      RecurringPaymentDraftInput(
        templateId: input['templateId'] as String,
        occurrenceId: input['occurrenceId'] as String,
        baseTemplateRevision: input['baseTemplateRevision'] as int,
        baseRevision: input['baseRevision'] as int,
        amount: input['amount'] as String,
        paidOn: DateTime.parse(input['paidOn'] as String),
      );
}

class RecurringPaymentDraftController
    extends DraftWorkflowController<RecurringPaymentDraftInput> {
  RecurringPaymentDraftController._(DraftAutosaveSession session, this._commit)
    : super(
        session,
        (input) => input.toPayload(),
        RecurringPaymentDraftInput.fromPayload,
      );
  final Future<RecurringExpensePaymentResult> Function(
    RecurringPaymentDraftInput,
    LocalDraftCheckpoint,
  )
  _commit;
  RecurringPaymentDraftInput get input => recoveredInput!;
  void updateAmount(String value) => updateInput(input.withAmount(value));
  Future<RecurringExpensePaymentResult> confirm() async {
    input.confirmedAmount();
    late RecurringExpensePaymentResult result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result.succeeded;
    });
    return result;
  }
}

extension RecurringPaymentDraftWorkflow on RecurringPaymentSession {
  Future<RecurringPaymentDraftController> openPaymentDraft({
    required String templateId,
    required String occurrenceId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    requireActiveDraftOwner();
    expenses.requireActiveDraftOwner();
    recurringExpenses.requireActiveDraftOwner();
    final template = recoverySelection == null
        ? recurringExpenses.recordById(templateId)
        : await recurringExpenses.readCurrentPlan(templateId);
    final occurrence = recoverySelection == null
        ? recurringExpenses.currentOccurrenceFor(templateId)
        : await recurringExpenses.readOpenOccurrence(occurrenceId);
    final repository = drafts;
    if (repository == null ||
        template == null ||
        occurrence == null ||
        occurrence.id != occurrenceId ||
        occurrence.templateId != templateId ||
        !recurringExpenses.canPayForEmployee(template.ownerEmployeeId) ||
        !expenses.canCreateForEmployee(template.ownerEmployeeId)) {
      throw StateError('Payment entry is unavailable.');
    }
    final draft = DraftAutosaveSession(
      store: repository,
      organizationId: recurringExpenses.organizationId,
      ownerId: recurringExpenses.actorEmployeeId,
      domain: 'expenses/planned-payment',
      draftId: 'pay-${recurringExpenses.actorEmployeeId}-$occurrenceId',
    );
    void validate(RecurringPaymentDraftInput input) {
      if (input.templateId != templateId ||
          input.occurrenceId != occurrenceId ||
          input.baseRevision < 1 ||
          input.baseTemplateRevision < 1) {
        throw StateError('Payment input identity mismatch.');
      }
    }

    try {
      await draft.initialize();
      requireActiveDraftOwner();
      expenses.requireActiveDraftOwner();
      recurringExpenses.requireActiveDraftOwner();
      recoverySelection?.verify(
        openedDomain: draft.domain,
        openedDraftId: draft.draftId,
        openedRevision: draft.savedRevision,
        hasInput: draft.input.isNotEmpty,
      );

      final controller = RecurringPaymentDraftController._(draft, (
        input,
        checkpoint,
      ) {
        validate(input);
        return markPaid(
          templateId: templateId,
          occurrenceId: occurrenceId,
          expectedTemplateRevision: input.baseTemplateRevision,
          expectedOccurrenceRevision: input.baseRevision,
          actualAmount: input.confirmedAmount(),
          paidOn: input.paidOn,
          draftCheckpoint: checkpoint,
        );
      });
      if (controller.recoveredInput == null) {
        controller.updateInput(
          RecurringPaymentDraftInput(
            templateId: templateId,
            occurrenceId: occurrenceId,
            baseTemplateRevision: recurringExpenses.revisionForId(templateId)!,
            baseRevision: recurringExpenses.occurrenceRevisionForId(
              occurrenceId,
            )!,
            amount: occurrence.expectedAmount.toStringAsFixed(2),
            paidOn: DateTime.now(),
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
