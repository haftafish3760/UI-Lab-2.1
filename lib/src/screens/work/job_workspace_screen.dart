import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_theme.dart';
import '../expenses/expense_models.dart';
import '../expenses/expense_permissions.dart';
import '../expenses/receipt_intake_screen.dart';
import 'job_workspace_models.dart';
import 'work_contact_models.dart';
import 'work_item_source_picker.dart';
import 'work_items_editor.dart';
import 'work_models.dart';
import 'work_scope_header.dart';

part 'job_workspace_sections.dart';
part 'job_workspace_action_sections.dart';
part 'job_customer_contact_sheet.dart';
part 'job_workspace_interactions.dart';
part 'job_actions_screen.dart';

class JobWorkspaceScreen extends StatefulWidget {
  const JobWorkspaceScreen({
    super.key,
    required this.workRecord,
    this.onWorkRecordUpdated,
    this.permissions = const JobWorkspacePermissions.development(),
  });

  final WorkRecord workRecord;
  final ValueChanged<WorkRecord>? onWorkRecordUpdated;
  final JobWorkspacePermissions permissions;

  @override
  State<JobWorkspaceScreen> createState() => _JobWorkspaceScreenState();
}

class _JobWorkspaceScreenState extends State<JobWorkspaceScreen> {
  late ActiveJobRecord _job;
  late WorkRecord _sourceRecord;
  var _initialized = false;

  DateTime get _jobDay =>
      DateUtils.dateOnly(_sourceRecord.scheduledStart ?? DateTime.now());

  @override
  void initState() {
    super.initState();
    _sourceRecord = widget.workRecord;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final store = PrototypeOperationsScope.maybeOf(context);
    final customer = _customerFor(store?.customers ?? const []);
    final linkedExpenses = store == null
        ? const <ExpenseRecord>[]
        : store.expenses
              .where(
                (expense) =>
                    _sourceRecord.linkedExpenseIds.contains(expense.id),
              )
              .toList();
    _job = activeJobForRecord(
      _sourceRecord,
      scheduledTime: _scheduledTimeLabel(context, _sourceRecord),
      customer: customer,
      linkedExpenses: linkedExpenses,
    );
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scope = OperationalScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final available = constraints.maxWidth - insets.horizontal;
        final layout = AppLayoutEngine.detailWorkspaceFor(
          available,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final compact = layout.columns == 1;
        return Scaffold(
          key: ValueKey('job-workspace-${_sourceRecord.id}'),
          floatingActionButton: compact && _hasPhoneActions
              ? FloatingActionButton.extended(
                  key: const ValueKey('job-actions-fab'),
                  onPressed: _openJobActions,
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Job actions'),
                )
              : null,
          body: ColoredBox(
            color: colors.surfaceContainerLowest,
            child: SingleChildScrollView(
              padding: insets.copyWith(top: 12, bottom: 32),
              child: Center(
                child: SizedBox(
                  width: layout.workspaceWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkScopeHeader(
                        view: scope.view,
                        selectedDay: _jobDay,
                        selectedEmployeeId: scope.selectedEmployeeId,
                        workspaceLabel: 'Job details',
                        showBackButton: true,
                        showDateDescription: false,
                        showEmployeeStrip: false,
                        onBack: () => Navigator.maybePop(context),
                        onViewChanged: scope.setView,
                        onEmployeeChanged: scope.selectEmployee,
                      ),
                      const SizedBox(height: 12),
                      _JobIdentity(job: _job),
                      SizedBox(height: layout.gap),
                      if (layout.columns == 1)
                        _singleColumn(layout.gap)
                      else
                        _twoColumns(layout),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _singleColumn(double gap) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _CustomerSection(
        job: _job,
        canContact: widget.permissions.canContactCustomer,
        onContact: _openCustomerContact,
      ),
      SizedBox(height: gap),
      _ScopeSection(job: _job),
      SizedBox(height: gap),
      _NotesSection(
        job: _job,
        canEdit: widget.permissions.canEditJob,
        onEdit: _editNotes,
      ),
      SizedBox(height: gap),
      if (widget.permissions.canViewEstimate)
        _EstimateSection(
          job: _job,
          canAdd: false,
          canViewCustomerPrice: canViewJobCustomerPrice(widget.permissions),
          onAdd: _editJobItems,
        ),
      if (widget.permissions.canViewEstimate) SizedBox(height: gap),
      _ReceiptsSection(
        job: _job,
        canLinkExpense: widget.permissions.canLinkExpenses,
        canAttach: widget.permissions.canAttachReceipts,
        onLinkExpense: _linkExistingExpense,
        onAttachReceipt: _attachReceipt,
        onAttachJobPhoto: _attachJobPhoto,
      ),
    ],
  );

  Widget _twoColumns(DetailWorkspaceLayout layout) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: layout.columnWidth,
        child: Column(
          children: [
            _CustomerSection(
              job: _job,
              canContact: widget.permissions.canContactCustomer,
              onContact: _openCustomerContact,
            ),
            SizedBox(height: layout.gap),
            _ScopeSection(job: _job),
            SizedBox(height: layout.gap),
            _NotesSection(
              job: _job,
              canEdit: widget.permissions.canEditJob,
              onEdit: _editNotes,
            ),
          ],
        ),
      ),
      SizedBox(width: layout.gap),
      SizedBox(
        width: layout.columnWidth,
        child: Column(
          children: [
            if (widget.permissions.canViewEstimate)
              _EstimateSection(
                job: _job,
                canAdd: widget.permissions.canAddMaterials,
                canViewCustomerPrice: canViewJobCustomerPrice(
                  widget.permissions,
                ),
                onAdd: _editJobItems,
              ),
            if (widget.permissions.canViewEstimate)
              SizedBox(height: layout.gap),
            _ReceiptsSection(
              job: _job,
              canLinkExpense: widget.permissions.canLinkExpenses,
              canAttach: widget.permissions.canAttachReceipts,
              onLinkExpense: _linkExistingExpense,
              onAttachReceipt: _attachReceipt,
              onAttachJobPhoto: _attachJobPhoto,
            ),
            SizedBox(height: layout.gap),
            _JobActions(
              job: _job,
              permissions: widget.permissions,
              onStatus: _setJobStatus,
              onReschedule: _rescheduleJob,
              onReassign: _reassignJob,
            ),
          ],
        ),
      ),
    ],
  );

  void _replaceJob(ActiveJobRecord job) => setState(() => _job = job);

  void _persistSource(WorkRecord record) {
    _sourceRecord = record;
    widget.onWorkRecordUpdated?.call(record);
  }

  WorkCustomerProfile? _customerFor(List<WorkCustomerProfile> customers) {
    final expected = _sourceRecord.client.trim().toLowerCase();
    for (final customer in customers) {
      if (customer.name.trim().toLowerCase() == expected) return customer;
    }
    return null;
  }

  String _scheduledTimeLabel(BuildContext context, WorkRecord record) {
    final start = record.scheduledStart;
    if (start == null) return 'Schedule not set';
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(start)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(start))}';
  }

  bool get _hasPhoneActions {
    final permissions = widget.permissions;
    return permissions.canAddMaterials ||
        permissions.canLinkExpenses ||
        permissions.canAttachReceipts ||
        permissions.canEditJob ||
        permissions.canChangeStatus;
  }
}
