part of 'work_screen.dart';

class WorkDayScreen extends StatefulWidget {
  const WorkDayScreen({required this.initialDay, super.key});

  final DateTime initialDay;

  @override
  State<WorkDayScreen> createState() => _WorkDayScreenState();
}

class _WorkDayScreenState extends State<WorkDayScreen> {
  late final DateTime _day = DateUtils.dateOnly(widget.initialDay);

  AppViewMode get _view => OperationalScope.of(context).view;
  String? get _employeeId => OperationalScope.of(context).selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final layout = AppLayoutEngine.workFor(
          constraints.maxWidth - insets.horizontal,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final usesInlineAdd = layout.columns > 1;
        final records = _recordsForCurrentScope();
        return Scaffold(
          key: const ValueKey('work-day-screen'),
          floatingActionButton: usesInlineAdd
              ? null
              : FloatingActionButton.extended(
                  key: const ValueKey('work-day-add-button'),
                  heroTag: 'work-day-add-button',
                  onPressed: _openAddWork,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add work'),
                ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkScopeHeader(
                          view: _view,
                          selectedDay: _day,
                          selectedEmployeeId: _employeeId,
                          workspaceLabel: 'Work Day',
                          showBackButton: true,
                          onBack: () => Navigator.of(context).pop(),
                          onViewChanged: OperationalScope.of(context).setView,
                          onEmployeeChanged: OperationalScope.of(
                            context,
                          ).selectEmployee,
                        ),
                        const SizedBox(height: 14),
                        _WorkDaySummary(
                          count: records.length,
                          showAdd: usesInlineAdd,
                          onAdd: _openAddWork,
                        ),
                        const SizedBox(height: 12),
                        _WorkDayLanes(
                          layout: layout,
                          view: _view,
                          records: records,
                          onOpenJob: _openJob,
                          onAssignJob: _assignJob,
                          onOpenEstimate: _openEstimate,
                          onOpenInvoice: _openInvoice,
                          onOpenAllEstimates: () =>
                              _openWorkspace(WorkRecordKind.estimate),
                          onOpenAllInvoices: () =>
                              _openWorkspace(WorkRecordKind.invoice),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<WorkRecord> _recordsForCurrentScope() {
    final records = PrototypeOperationsScope.of(
      context,
    ).workRecords.where((record) => record.occursOn(_day));
    if (_view == AppViewMode.technician) {
      final employee = dashboardEmployeeById(
        _employeeId ?? demoEmployees.first.id,
      );
      return records
          .where(
            (record) =>
                record.createdByEmployeeId == employee.id ||
                (record.assignedEmployeeIds.contains(employee.id) ||
                    record.assignee == employee.name),
          )
          .toList();
    }
    if (_employeeId == null) return records.toList();
    final employee = dashboardEmployeeById(_employeeId!);
    return records
        .where(
          (record) =>
              record.createdByEmployeeId == employee.id ||
              (record.assignedEmployeeIds.contains(employee.id) ||
                  record.assignee == employee.name),
        )
        .toList();
  }

  Future<void> _openAddWork() async {
    final invoicePermissions = invoicePermissionsForView(_view);
    final estimatePermissions = _view == AppViewMode.admin
        ? const EstimatePermissions.development()
        : const EstimatePermissions.technicianDevelopment();
    final action = await Navigator.of(context).push<_WorkAction>(
      MaterialPageRoute(
        builder: (_) => _WorkActionsScreen.day(
          day: _day,
          actions: [
            _WorkAction.createJob,
            if (estimatePermissions.canCreate) _WorkAction.createEstimate,
            if (invoicePermissions.canCreate) _WorkAction.createInvoice,
            if (invoicePermissions.canRecordPayment) _WorkAction.recordPayment,
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _WorkAction.createJob) {
      final job = await Navigator.of(context).push<WorkRecord>(
        MaterialPageRoute(builder: (_) => WorkJobEditor(initialDay: _day)),
      );
      if (mounted && job != null) {
        PrototypeOperationsScope.of(context).addWorkRecord(job);
      }
      return;
    }
    if (action == _WorkAction.createEstimate) {
      final estimate = await Navigator.of(context).push<WorkRecord>(
        MaterialPageRoute(
          builder: (_) => EstimateEditorScreen(
            initialDay: _day,
            createdByEmployeeId: _employeeId,
          ),
        ),
      );
      if (mounted && estimate != null) {
        PrototypeOperationsScope.of(context).addWorkRecord(estimate);
      }
      return;
    }
    if (action == _WorkAction.createInvoice) {
      if (!invoicePermissions.canCreate) return;
      final invoice = await Navigator.of(context).push<WorkRecord>(
        MaterialPageRoute(
          builder: (_) => InvoiceEditorScreen(
            initialDay: _day,
            createdByEmployeeId: _employeeId ?? demoEmployees.first.id,
          ),
        ),
      );
      if (mounted && invoice != null) {
        PrototypeOperationsScope.of(context).addWorkRecord(invoice);
      }
      return;
    }
    if (!invoicePermissions.canRecordPayment) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            PaymentsScreen(initialDay: _day, permissions: invoicePermissions),
      ),
    );
  }

  void _openWorkspace(WorkRecordKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (kind) {
          WorkRecordKind.job => JobListWorkspaceScreen(initialDay: _day),
          WorkRecordKind.estimate => EstimateWorkspaceScreen(initialDay: _day),
          WorkRecordKind.invoice => InvoiceWorkspaceScreen(
            initialDay: _day,
            permissions: invoicePermissionsForView(_view),
          ),
        },
      ),
    );
  }

  void _openJob(WorkRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JobWorkspaceScreen(
          workRecord: record,
          onWorkRecordUpdated: PrototypeOperationsScope.of(
            context,
          ).updateWorkRecord,
        ),
      ),
    );
  }

  Future<void> _openEstimate(WorkRecord record) async {
    final store = PrototypeOperationsScope.of(context);
    final permissions = _view == AppViewMode.admin
        ? const EstimatePermissions.development()
        : const EstimatePermissions.technicianDevelopment();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EstimateDetailScreen(
          initialRecord: record,
          onUpdated: store.updateWorkRecord,
          onCreateJob: (_) async {},
          permissions: permissions,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openInvoice(WorkRecord record) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(
          record: record,
          permissions: invoicePermissionsForView(_view),
        ),
      ),
    );
  }

  Future<void> _assignJob(WorkRecord record) async {
    final store = PrototypeOperationsScope.of(context);
    final saved = await showModalBottomSheet<WorkRecord>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          JobAssignmentEditorSheet(record: record, work: store.workSession),
    );
    if (!mounted || saved == null) return;
    if (store.workSession == null) await store.updateWorkRecord(saved);
  }
}

class _WorkDaySummary extends StatelessWidget {
  const _WorkDaySummary({
    required this.count,
    required this.showAdd,
    required this.onAdd,
  });

  final int count;
  final bool showAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '$count work ${count == 1 ? 'record' : 'records'} in this view',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      if (showAdd)
        FilledButton.icon(
          key: const ValueKey('work-day-inline-add-button'),
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add work'),
        ),
    ],
  );
}

class _WorkDayLanes extends StatelessWidget {
  const _WorkDayLanes({
    required this.layout,
    required this.view,
    required this.records,
    required this.onOpenJob,
    required this.onAssignJob,
    required this.onOpenEstimate,
    required this.onOpenInvoice,
    required this.onOpenAllEstimates,
    required this.onOpenAllInvoices,
  });

  final OperationsWorkspaceLayout layout;
  final AppViewMode view;
  final List<WorkRecord> records;
  final ValueChanged<WorkRecord> onOpenJob;
  final ValueChanged<WorkRecord> onAssignJob;
  final ValueChanged<WorkRecord> onOpenEstimate;
  final ValueChanged<WorkRecord> onOpenInvoice;
  final VoidCallback onOpenAllEstimates;
  final VoidCallback onOpenAllInvoices;

  @override
  Widget build(BuildContext context) {
    final jobs = records
        .where((record) => record.kind == WorkRecordKind.job)
        .toList();
    final estimates = records
        .where((record) => record.kind == WorkRecordKind.estimate)
        .toList();
    final invoices = records
        .where((record) => record.kind == WorkRecordKind.invoice)
        .toList();
    final panels = <Widget>[
      _JobQueuePanel(
        view: view,
        records: jobs,
        onOpen: onOpenJob,
        onAssign: onAssignJob,
      ),
      _DocumentQueuePanel(
        kind: WorkRecordKind.estimate,
        records: estimates,
        onOpenRecord: onOpenEstimate,
        onOpenAll: onOpenAllEstimates,
      ),
      _DocumentQueuePanel(
        kind: WorkRecordKind.invoice,
        records: invoices,
        onOpenRecord: onOpenInvoice,
        onOpenAll: onOpenAllInvoices,
      ),
    ];
    if (layout.columns == 1) {
      return Column(children: _spaced(panels, layout.gap));
    }
    if (layout.columns == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: layout.laneWidth, child: panels.first),
          SizedBox(width: layout.gap),
          SizedBox(
            width: layout.laneWidth,
            child: Column(
              children: _spaced(panels.skip(1).toList(), layout.gap),
            ),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < panels.length; index++) ...[
          if (index > 0) SizedBox(width: layout.gap),
          SizedBox(width: layout.laneWidth, child: panels[index]),
        ],
      ],
    );
  }

  List<Widget> _spaced(List<Widget> widgets, double gap) => [
    for (var index = 0; index < widgets.length; index++) ...[
      if (index > 0) SizedBox(height: gap),
      widgets[index],
    ],
  ];
}
