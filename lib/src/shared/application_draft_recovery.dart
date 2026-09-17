import '../data/storage/draft_recovery_hub.dart';
import '../data/work/work_primary_draft_recovery.dart';
import '../data/work/estimate_action_draft_recovery.dart';
import '../data/work/job_action_draft_recovery.dart';
import '../data/work/invoice_payment_draft_recovery.dart';
import '../data/work/directory_draft_recovery.dart';
import '../data/workday/workday_draft_recovery.dart';
import '../data/day_notes/day_note_draft_recovery.dart';
import '../data/expenses/expense_draft_recovery.dart';
import '../data/expenses/recurring_draft_recovery.dart';
import '../data/receipts/receipt_workflow_draft_recovery.dart';
import 'preference_draft_recovery.dart';

/// Application composition requires every supported provider explicitly. Screens
/// receive this service; provider construction and identities belong to session
/// composition, not to responsive layouts. Resumed objects retain their concrete
/// typed workflow/controller classes for presentation dispatch.
DraftRecoveryHub<Object> createApplicationDraftRecovery({
  required WorkPrimaryDraftRecovery work,
  required EstimateActionDraftRecovery estimateActions,
  required JobActionDraftRecovery jobActions,
  required InvoicePaymentDraftRecovery invoicePayments,
  required DirectoryDraftRecovery directory,
  required WorkdayDraftRecovery workday,
  required DayNoteDraftRecovery dayNotes,
  required ExpenseDraftRecovery expenses,
  required RecurringDraftRecovery recurring,
  required ReceiptWorkflowDraftRecovery receipts,
  required PreferenceDraftRecovery preferences,
}) => DraftRecoveryHub<Object>([
  DraftRecoveryProvider<Object>(
    id: 'expenseSetup',
    label: 'Expense setup',
    list: expenses.setup.list,
    resume: expenses.setup.resume,
    discard: expenses.setup.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'work',
    label: 'Work',
    list: work.list,
    resume: work.resume,
    discard: work.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'estimateActions',
    label: 'Estimate actions',
    list: estimateActions.list,
    resume: estimateActions.resume,
    discard: estimateActions.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'jobActions',
    label: 'Job actions',
    list: jobActions.list,
    resume: jobActions.resume,
    discard: jobActions.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'invoicePayments',
    label: 'Invoice payments',
    list: invoicePayments.list,
    resume: invoicePayments.resume,
    discard: invoicePayments.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'directory',
    label: 'Directory',
    list: directory.list,
    resume: directory.resume,
    discard: directory.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'workday',
    label: 'Workday',
    list: workday.list,
    resume: workday.resume,
    discard: workday.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'dayNotes',
    label: 'Day notes',
    list: dayNotes.list,
    resume: dayNotes.resume,
    discard: dayNotes.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'expenses',
    label: 'Expenses',
    list: expenses.list,
    resume: expenses.resume,
    discard: expenses.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'recurring',
    label: 'Planned expenses',
    list: recurring.list,
    resume: recurring.resume,
    discard: recurring.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'receipts',
    label: 'Receipts',
    list: receipts.list,
    resume: receipts.resume,
    discard: receipts.discard,
  ),
  DraftRecoveryProvider<Object>(
    id: 'preferences',
    label: 'Settings',
    list: preferences.list,
    resume: preferences.resume,
    discard: preferences.discard,
  ),
]);
