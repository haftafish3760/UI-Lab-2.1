part of 'dashboard_screen.dart';

extension _DashboardAttentionActions on _DashboardScreenState {
  OperationalAttentionQuery _dashboardAttentionQuery(
    OperationalScopeController scope,
  ) => OperationalAttentionQuery(
    panelId: 'dashboard-home',
    module: OperationalAttentionModule.dashboard,
    view: scope.view,
    access: scope.view == AppViewMode.admin
        ? const OperationalAttentionAccess.adminDevelopment()
        : const OperationalAttentionAccess.technicianDevelopment(),
    selectedEmployeeId: scope.selectedEmployeeId,
    selectedVehicleId: scope.view == AppViewMode.technician
        ? scope.selectedVehicleId
        : null,
  );

  void _openAttentionList(OperationalAttentionQuery query) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DashboardAttentionScreen(query: query, onOpen: _openAttentionItem),
      ),
    );
  }

  void _openAttentionItem(OperationalAttentionItem item) {
    switch (item.resourceKind) {
      case OperationalAttentionResourceKind.expense:
        _openAttentionExpense(item.sourceId);
      case OperationalAttentionResourceKind.estimate:
        _openAttentionEstimate(item.sourceId);
      case OperationalAttentionResourceKind.job:
        _openAttentionJob(item.sourceId);
      case OperationalAttentionResourceKind.invoice:
        _openAttentionInvoice(item.sourceId);
      case OperationalAttentionResourceKind.inventoryStock:
        _openAttentionStock(item.sourceId);
    }
  }

  Future<void> _openAttentionExpense(String expenseId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(expenseId: expenseId),
      ),
    );
  }

  Future<void> _openAttentionEstimate(String recordId) async {
    final store = PrototypeOperationsScope.of(context);
    final record = store.workRecords
        .where((candidate) => candidate.id == recordId)
        .firstOrNull;
    if (record == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EstimateDetailScreen(
          initialRecord: record,
          onUpdated: store.updateWorkRecord,
          onCreateJob: _createJobFromAttentionEstimate,
          permissions: OperationalScope.of(context).view == AppViewMode.admin
              ? const EstimatePermissions.development()
              : const EstimatePermissions.technicianDevelopment(),
        ),
      ),
    );
  }

  void _openAttentionJob(String recordId) {
    final store = PrototypeOperationsScope.of(context);
    final record = store.workRecords
        .where((candidate) => candidate.id == recordId)
        .firstOrNull;
    if (record == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JobWorkspaceScreen(
          workRecord: record,
          onWorkRecordUpdated: store.updateWorkRecord,
        ),
      ),
    );
  }

  void _openAttentionInvoice(String recordId) {
    final store = PrototypeOperationsScope.of(context);
    final record = store.workRecords
        .where((candidate) => candidate.id == recordId)
        .firstOrNull;
    if (record == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvoiceDetailScreen(
          record: record,
          permissions: invoicePermissionsForView(
            OperationalScope.of(context).view,
          ),
        ),
      ),
    );
  }

  Future<void> _openAttentionStock(String recordId) async {
    final store = PrototypeOperationsScope.of(context);
    final record = store.inventoryStock
        .where((candidate) => candidate.id == recordId)
        .firstOrNull;
    if (record == null) return;
    final updated = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => StockCountScreen(record: record)));
    if (!mounted || updated == null) return;
    store.updateInventoryStock(updated);
  }

  Future<void> _createJobFromAttentionEstimate(WorkRecord estimate) async {
    final job = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => WorkJobEditor(
          sourceEstimate: estimate,
          initialDay:
              estimate.estimateDates?.proposedServiceOn ?? _selectedDate,
        ),
      ),
    );
    if (!mounted || job == null) return;
    final store = PrototypeOperationsScope.of(context);
    store.addWorkRecord(job);
    store.updateWorkRecord(
      estimate.withEstimateStage(EstimateStage.converted, DateTime.now()),
    );
  }
}
