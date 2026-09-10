import 'package:flutter/widgets.dart';
import '../data/storage/draft_recovery_hub.dart';
import '../data/prototype_operations_store.dart';
import '../data/expenses/recurring_payment_session.dart';
import '../data/receipts/receipt_submission_session.dart';
import '../data/work/work_primary_draft_recovery.dart';
import '../data/work/estimate_action_draft_recovery.dart';
import '../data/work/job_action_draft_recovery.dart';
import '../data/work/invoice_payment_draft_recovery.dart';
import '../data/work/directory_draft_recovery.dart';
import '../data/work/models/estimate_models.dart';
import '../data/work/job_material_permissions.dart';
import '../data/workday/workday_draft_recovery.dart';
import '../data/day_notes/day_note_draft_recovery.dart';
import '../data/expenses/expense_draft_recovery.dart';
import '../data/expenses/recurring_draft_recovery.dart';
import '../data/receipts/receipt_workflow_draft_recovery.dart';
import 'app_preferences.dart';
import 'app_view_mode.dart';
import 'application_draft_recovery.dart';
import 'preference_draft_recovery.dart';

/// Session composition owns provider instances. Rebuilding responsive widgets
/// must not replace catalog identities or invalidate selected saved input.
class ApplicationRecoveryHost extends StatefulWidget {
  const ApplicationRecoveryHost({
    required this.operations,
    required this.preferences,
    required this.receipts,
    required this.recurring,
    required this.view,
    required this.child,
    super.key,
  });
  final PrototypeOperationsStore operations;
  final AppPreferencesController preferences;
  final ReceiptSubmissionSession? receipts;
  final RecurringPaymentSession? recurring;
  final AppViewMode Function() view;
  final Widget child;
  @override
  State<ApplicationRecoveryHost> createState() =>
      _ApplicationRecoveryHostState();
}

class _ApplicationRecoveryHostState extends State<ApplicationRecoveryHost> {
  DraftRecoveryHub<Object>? _hub;
  @override
  void initState() {
    super.initState();
    _compose();
  }

  @override
  void didUpdateWidget(covariant ApplicationRecoveryHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.operations, widget.operations) ||
        !identical(oldWidget.preferences, widget.preferences) ||
        !identical(oldWidget.receipts, widget.receipts) ||
        !identical(oldWidget.recurring, widget.recurring)) {
      _hub?.invalidate();
      _compose();
    }
  }

  void _compose() {
    final operations = widget.operations;
    final work = operations.workSession;
    final directory = operations.directorySession;
    final workday = operations.workdaySession;
    final notes = operations.dayNoteSession;
    final receipts = widget.receipts;
    final recurring = widget.recurring;
    if (work == null ||
        directory == null ||
        workday == null ||
        notes == null ||
        receipts?.drafts == null ||
        recurring?.drafts == null ||
        widget.preferences.storage == null) {
      _hub = null;
      return;
    }
    _hub = createApplicationDraftRecovery(
      work: WorkPrimaryDraftRecovery(work),
      estimateActions: EstimateActionDraftRecovery(
        work,
        reviewPermissions: () => widget.view() == AppViewMode.admin
            ? const EstimatePermissions.development()
            : const EstimatePermissions.technicianDevelopment(),
        customers: () => directory.customers,
      ),
      jobActions: JobActionDraftRecovery(
        work,
        materialPermissions: () => const JobWorkspacePermissions.development(),
      ),
      invoicePayments: InvoicePaymentDraftRecovery(work),
      directory: DirectoryDraftRecovery(directory),
      workday: WorkdayDraftRecovery(workday),
      dayNotes: DayNoteDraftRecovery(notes),
      expenses: ExpenseDraftRecovery(recurring!.expenses),
      recurring: RecurringDraftRecovery(recurring),
      receipts: ReceiptWorkflowDraftRecovery(receipts!),
      preferences: PreferenceDraftRecovery(widget.preferences),
    );
  }

  @override
  void dispose() {
    _hub?.invalidate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ApplicationRecoveryScope(hub: _hub, child: widget.child);
}

class ApplicationRecoveryScope extends InheritedWidget {
  const ApplicationRecoveryScope({
    required this.hub,
    required super.child,
    super.key,
  });
  final DraftRecoveryHub<Object>? hub;
  static DraftRecoveryHub<Object>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ApplicationRecoveryScope>()
      ?.hub;
  @override
  bool updateShouldNotify(ApplicationRecoveryScope oldWidget) =>
      !identical(hub, oldWidget.hub);
}
