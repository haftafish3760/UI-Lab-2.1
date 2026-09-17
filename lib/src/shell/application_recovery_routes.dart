import 'package:flutter/material.dart';
import '../data/expenses/expense_entry_setup_workflow.dart';
import '../screens/expenses/expense_entry_flow.dart';
import '../data/prototype_operations_store.dart';
import '../data/day_notes/day_note_draft_workflow.dart';
import '../data/expenses/expense_draft_workflow.dart';
import '../data/expenses/recurring_draft_recovery.dart';
import '../data/receipts/receipt_workflow_draft_recovery.dart';
import '../data/work/work_primary_draft_recovery.dart';
import '../data/work/estimate_action_draft_recovery.dart';
import '../data/work/job_action_draft_recovery.dart';
import '../data/work/directory_draft_recovery.dart';
import '../data/work/invoice_payment_draft_workflow.dart';
import '../data/work/job_material_permissions.dart';
import '../data/work/models/estimate_models.dart';
import '../data/workday/workday_draft_recovery.dart';
import '../shared/application_recovery_release.dart';
import '../shared/preference_draft_recovery.dart';
import '../screens/work/work_primary_recovery_routes.dart';
import '../screens/work/estimate_action_recovery_routes.dart';
import '../screens/work/job_details_recovery_routes.dart';
import '../screens/work/job_materials_recovery_route.dart';
import '../screens/work/invoice_payment_recovery_route.dart';
import '../screens/dashboard/workday_recovery_routes.dart';
import '../screens/dashboard/day_note_recovery_route.dart';
import '../screens/expenses/expense_permissions.dart';
import '../screens/expenses/expense_recovery_routes.dart';
import 'directory_recovery_routes.dart';
import 'preference_recovery_routes.dart';

/// Application presentation boundary. It owns every recovered result until its
/// editor returns, including failures before navigation. Callers supply current
/// capabilities; dispatch never invents role grants or interprets stored payloads.
Future<void> openApplicationRecovery(
  BuildContext context,
  Object workflow, {
  required ExpensePermissions expensePermissions,
  required EstimatePermissions estimatePermissions,
  required JobWorkspacePermissions materialPermissions,
  required DateTime selectedDay,
  required String Function(String employeeId) employeeLabel,
}) async {
  try {
    if (!context.mounted) return;
    switch (workflow) {
      case ExpenseEntrySetupWorkflow():
        await openExpenseEntryFlow(
          context,
          expenseDate: workflow.input.date,
          permissions: expensePermissions,
          recoveredSetup: workflow,
          onConfirm: PrototypeOperationsScope.of(context).addExpense,
        );
      case ResumedWorkDraft():
        await openPrimaryWorkRecovery(context, workflow);
      case ResumedEstimateAction():
        await openEstimateActionRecovery(
          context,
          workflow,
          reviewPermissions: estimatePermissions,
        );
      case ResumedJobMaterials(:final controller):
        await openJobMaterialsRecovery(
          context,
          controller,
          permissions: materialPermissions,
        );
      case ResumedJobAction():
        await openJobDetailsRecovery(context, workflow);
      case InvoicePaymentDraftController():
        await openInvoicePaymentRecovery(context, workflow);
      case ResumedDirectoryDraft():
        await openDirectoryRecovery(
          context,
          workflow,
          selectedDay: selectedDay,
        );
      case ResumedWorkdayDraft():
        await openWorkdayRecovery(context, workflow);
      case DayNoteDraftController():
        final notes = PrototypeOperationsScope.of(context).dayNoteSession;
        if (notes == null) throw StateError('Day note recovery unavailable.');
        await openDayNoteRecovery(
          context,
          workflow,
          session: notes,
          employeeLabel: employeeLabel(workflow.input.employeeId),
        );
      case ExpenseDraftController() ||
          ResumedRecurringDraft() ||
          ResumedReceiptWorkflow():
        await openExpenseRecovery(
          context,
          workflow,
          permissions: expensePermissions,
        );
      case ResumedPreferenceDraft():
        await openPreferenceRecovery(context, workflow);
      default:
        throw ArgumentError('Unsupported application recovery workflow.');
    }
  } finally {
    await releaseApplicationRecovery(workflow);
  }
}
