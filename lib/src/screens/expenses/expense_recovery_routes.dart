import 'package:flutter/material.dart';
import '../../data/expenses/expense_draft_workflow.dart';
import '../../data/expenses/recurring_draft_recovery.dart';
import '../../data/expenses/recurring_expense_ui_controller.dart';
import '../../data/receipts/receipt_workflow_draft_recovery.dart';
import '../../data/storage/draft_autosave_session.dart';
import 'expense_editor_screen.dart';
import 'expense_permissions.dart';
import 'receipt_evidence_review_screen.dart';
import 'scheduled_expense_editor_screen.dart';
import 'scheduled_expense_occurrence_editor_screen.dart';
import 'scheduled_payment_draft_dialog.dart';

/// Presentation dispatch only. The recovery service has already authorized and
/// reopened the exact workflow; each editor retains its own current action gates.
/// Capability checking does not take ownership of a workflow.
bool supportsExpenseRecovery(Object workflow) =>
    workflow is ExpenseDraftController ||
    workflow is ResumedRecurringDraft ||
    workflow is ResumedReceiptWorkflow;

Future<void> openExpenseRecovery(
  BuildContext context,
  Object workflow, {
  required ExpensePermissions permissions,
}) async {
  final session = _session(workflow);
  if (session == null) throw ArgumentError('Unsupported expense recovery.');
  try {
    if (!context.mounted) return;
    Widget? editor;
    switch (workflow) {
      case ExpenseDraftController():
        final input = workflow.input;
        editor = ExpenseEditorScreen(
          expenseDate: input.date,
          existing: input.baseRecord,
          existingRecordIsOwn: input.ownerId == permissions.actorEmployeeId,
          permissions: permissions,
          recoveredExpenseWorkflow: workflow,
        );
      case ResumedReceiptReview(:final controller):
        editor = ExpenseEditorScreen(
          expenseDate: controller.input.date,
          receiptDraftId: controller.source.draftId,
          purpose: ExpenseEditorPurpose.receiptReview,
          existingRecordIsOwn:
              controller.source.ownerEmployeeId == permissions.actorEmployeeId,
          permissions: permissions,
          recoveredReceiptWorkflow: controller,
        );
      case ResumedReceiptEvidence(:final controller):
        editor = ReceiptEvidenceReviewScreen(
          evidence: const [],
          permissions: permissions,
          receiptDraftId: controller.source.draftId,
          receiptRevision: controller.source.lifecycle.revision,
          recoveredWorkflow: controller,
        );
      case ResumedRecurringDraft():
        final recurring = RecurringExpenseUiScope.maybeOf(context);
        if (recurring == null) {
          throw StateError('Planned expense session unavailable.');
        }
        switch (workflow) {
          case ResumedRecurringPlan(:final controller):
            final input = controller.input;
            final current = input.baseRevision == null
                ? null
                : await recurring.readCurrentPlan(input.recordId);
            if (input.baseRevision != null && current == null) {
              throw StateError('Planned expense is no longer available.');
            }
            editor = ScheduledExpenseEditorScreen(
              initial: current,
              permissions: permissions,
              recoveredWorkflow: controller,
            );
          case ResumedRecurringOccurrence(:final controller):
            final current = await recurring.readOpenOccurrence(
              controller.input.occurrenceId,
            );
            if (current == null) throw StateError('Payment is no longer open.');
            editor = ScheduledExpenseOccurrenceEditorScreen(
              occurrence: current,
              permissions: permissions,
              recoveredWorkflow: controller,
            );
          case ResumedRecurringPayment(:final controller):
            final template = await recurring.readCurrentPlan(
              controller.input.templateId,
            );
            final occurrence = await recurring.readOpenOccurrence(
              controller.input.occurrenceId,
            );
            if (template == null || occurrence == null) {
              throw StateError('Payment is no longer available.');
            }
            if (!context.mounted) return;
            if (!permissions.canView ||
                !permissions.canViewAmounts ||
                !permissions.canCreate) {
              throw StateError('Payment viewing is unavailable.');
            }
            await showScheduledPaymentDraftDialog(
              context,
              template: template,
              occurrence: occurrence,
              recoveredWorkflow: controller,
            );
            return;
        }
    }
    if (!context.mounted) return;
    if (editor == null) throw StateError('Recovery editor is unavailable.');
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => editor!));
  } finally {
    // Covers route failures and disappearance before mounting as well as normal
    // editor closure. Closing never consumes the saved draft.
    await session.close();
  }
}

DraftAutosaveSession? _session(Object workflow) => switch (workflow) {
  ExpenseDraftController() => workflow.session,
  ResumedReceiptReview(:final controller) => controller.session,
  ResumedReceiptEvidence(:final controller) => controller.session,
  ResumedRecurringPlan(:final controller) => controller.session,
  ResumedRecurringOccurrence(:final controller) => controller.session,
  ResumedRecurringPayment(:final controller) => controller.session,
  _ => null,
};
