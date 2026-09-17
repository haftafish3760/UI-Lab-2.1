import '../data/storage/draft_recovery_hub.dart';
import '../data/expenses/expense_entry_setup_workflow.dart';
import 'draft_recovery_controller.dart';
import '../data/work/work_primary_draft_recovery.dart';
import '../data/work/estimate_action_draft_recovery.dart';
import '../data/work/job_action_draft_recovery.dart';
import '../data/work/directory_draft_recovery.dart';
import '../data/workday/workday_draft_recovery.dart';
import '../data/expenses/recurring_draft_recovery.dart';
import '../data/receipts/receipt_workflow_draft_recovery.dart';
import '../data/expenses/expense_draft_workflow.dart';
import '../data/work/invoice_payment_draft_workflow.dart';
import '../data/day_notes/day_note_draft_workflow.dart';
import 'preference_draft_recovery.dart';

/// Releases a recovery result that never reached its editor (for example when
/// the recovery view disappears during opening). Closing flushes pending input;
/// it never confirms a business record or discards a saved draft.
Future<void> releaseApplicationRecovery(Object workflow) => switch (workflow) {
  ExpenseEntrySetupWorkflow() => workflow.session.close(),
  ResumedEstimateDraft(:final controller) => controller.session.close(),
  ResumedInvoiceDraft(:final controller) => controller.session.close(),
  ResumedJobDraft(:final controller) => controller.session.close(),
  ResumedEstimateSignature(:final controller) => controller.session.close(),
  ResumedEstimateDelivery(:final controller) => controller.session.close(),
  ResumedEstimateItems(:final controller) => controller.session.close(),
  ResumedEstimateReview(:final controller) => controller.session.close(),
  ResumedJobNotes(:final controller) => controller.session.close(),
  ResumedJobSchedule(:final controller) => controller.session.close(),
  ResumedJobAssignment(:final controller) => controller.session.close(),
  ResumedJobMaterials(:final controller) => controller.session.close(),
  ResumedCompanyDraft(:final controller) => controller.session.close(),
  ResumedCustomerDraft(:final controller) => controller.session.close(),
  ResumedEmployeeDraft(:final controller) => controller.session.close(),
  ResumedVehicleDraft(:final controller) => controller.session.close(),
  ResumedWorkdayStart(:final controller) => controller.session.close(),
  ResumedWorkdayEnd(:final controller) => controller.session.close(),
  ResumedRecurringPlan(:final controller) => controller.session.close(),
  ResumedRecurringOccurrence(:final controller) => controller.session.close(),
  ResumedRecurringPayment(:final controller) => controller.session.close(),
  ResumedReceiptReview(:final controller) => controller.session.close(),
  ResumedReceiptEvidence(:final controller) => controller.session.close(),
  ExpenseDraftController() => workflow.session.close(),
  InvoicePaymentDraftController() => workflow.session.close(),
  DayNoteDraftController() => workflow.session.close(),
  ResumedPreferenceDraft() => workflow.close(),
  _ => Future<void>.error(ArgumentError('Unsupported recovery workflow.')),
};

/// The caller owns disposal; presentation code need not know workflow subtypes
/// to safely release a result that arrives after the view has gone away.
DraftRecoveryController<Object> createApplicationRecoveryController(
  DraftRecoveryHub<Object> hub,
) => DraftRecoveryController(hub, releaseUnclaimed: releaseApplicationRecovery);
