part of 'work_screen.dart';

extension _WorkScreenActions on _WorkScreenState {
  Future<void> _showWorkActions() async {
    final action = await Navigator.of(context).push<_WorkAction>(
      MaterialPageRoute(
        builder: (_) => _WorkActionsScreen.home(
          day: _selectedDay,
          actions: [
            if (_estimatePermissions.canCreate) _WorkAction.createEstimate,
            if (_invoicePermissions.canCreate) _WorkAction.createInvoice,
            _WorkAction.createJob,
            if (_invoicePermissions.canRecordPayment) _WorkAction.recordPayment,
            _WorkAction.addContact,
          ],
        ),
      ),
    );
    if (action != null && mounted) await _handleAction(action);
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<WorkDisplayPreferences>(
      MaterialPageRoute(
        builder: (_) => WorkSettingsScreen(initial: _preferences),
      ),
    );
    if (updated != null && mounted) {
      _updateState(() => _fixturePreferences = updated);
    }
  }

  Future<void> _handleAction(_WorkAction action) async {
    switch (action) {
      case _WorkAction.createEstimate:
        final record = await Navigator.of(context).push<WorkRecord>(
          MaterialPageRoute(
            builder: (_) => EstimateEditorScreen(
              initialDay: _selectedDay,
              createdByEmployeeId: _selectedEmployeeId,
            ),
          ),
        );
        if (mounted && record != null) {
          final saved = await PrototypeOperationsScope.of(
            context,
          ).addWorkRecord(record);
          if (mounted && saved) {
            await openSavedWorkDocument(context, record);
          }
        }
      case _WorkAction.createInvoice:
        if (!_invoicePermissions.canCreate) return;
        final invoice = await Navigator.of(context).push<WorkRecord>(
          MaterialPageRoute(
            builder: (_) => InvoiceEditorScreen(
              initialDay: _selectedDay,
              createdByEmployeeId:
                  _selectedEmployeeId ?? demoEmployees.first.id,
            ),
          ),
        );
        if (invoice != null && mounted) {
          final saved = await PrototypeOperationsScope.of(
            context,
          ).addWorkRecord(invoice);
          if (mounted && saved) {
            await openSavedWorkDocument(context, invoice);
          }
        }
      case _WorkAction.createJob:
        await _createJob();
      case _WorkAction.recordPayment:
        _openPayments();
      case _WorkAction.addContact:
        await _addCustomer();
    }
  }

  Future<void> _createJob() async {
    final job = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => WorkJobEditor(initialDay: _selectedDay),
      ),
    );
    if (job != null && mounted) {
      PrototypeOperationsScope.of(context).addWorkRecord(job);
    }
  }

  void _openWorkDay(DateTime day) {
    _updateState(() => _selectedDay = DateUtils.dateOnly(day));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WorkDayScreen(initialDay: day)),
    );
  }

  void _handleDestination(WorkDestination destination) {
    switch (destination) {
      case WorkDestination.jobs:
        _openRecordWorkspace(WorkRecordKind.job);
      case WorkDestination.estimates:
        _openRecordWorkspace(WorkRecordKind.estimate);
      case WorkDestination.invoices:
        _openRecordWorkspace(WorkRecordKind.invoice);
      case WorkDestination.companyInfo:
        _openCompanyProfile();
      case WorkDestination.customers:
        _openSavedClients();
      case WorkDestination.payments:
        _openPayments();
      case WorkDestination.scheduling:
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => WorkScheduleScreen(initialDay: _selectedDay),
          ),
        );
      case WorkDestination.quotes:
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(destination.label),
            content: const Text(
              'Quotes are not connected in this build. Estimates remain a separate workspace.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Work'),
              ),
            ],
          ),
        );
    }
  }

  void _openCompanyProfile() {
    final store = PrototypeOperationsScope.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanyProfileScreen(
          initialProfile: store.companyProfile,
          selectedDay: _selectedDay,
          onSaved: store.updateCompanyProfile,
        ),
      ),
    );
  }

  void _openSavedClients() {
    final store = PrototypeOperationsScope.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedClientsScreen(
          initialClients: store.customers,
          selectedDay: _selectedDay,
          onClientsChanged: store.replaceCustomers,
        ),
      ),
    );
  }

  void _openPayments() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PaymentsScreen(permissions: _invoicePermissions),
    ),
  );

  Future<void> _addCustomer() async {
    final created = await Navigator.of(context).push<WorkCustomerProfile>(
      MaterialPageRoute(
        builder: (_) => CustomerEditScreen(selectedDay: _selectedDay),
      ),
    );
    if (!mounted || created == null) return;
    final store = PrototypeOperationsScope.of(context);
    if (store.directorySession == null) {
      store.replaceCustomers([...store.customers, created]);
    }
  }

  void _openRecordWorkspace(WorkRecordKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (kind) {
          WorkRecordKind.job => JobListWorkspaceScreen(
            initialDay: _selectedDay,
          ),
          WorkRecordKind.estimate => EstimateWorkspaceScreen(
            initialDay: _selectedDay,
            permissions: _estimatePermissions,
          ),
          WorkRecordKind.invoice => InvoiceWorkspaceScreen(
            initialDay: _selectedDay,
            permissions: _invoicePermissions,
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

  void _openRecord(WorkRecord record) {
    switch (record.kind) {
      case WorkRecordKind.job:
        _openJob(record);
      case WorkRecordKind.estimate:
        _openEstimate(record);
      case WorkRecordKind.invoice:
        _openInvoice(record);
    }
  }

  void _openAttentionItem(OperationalAttentionItem item) {
    final matches = _records.where((record) => record.id == item.sourceId);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This Work record is no longer available.'),
        ),
      );
      return;
    }
    _openRecord(matches.first);
  }

  void _openAttentionList(List<OperationalAttentionItem> items) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkAttentionListScreen(
          selectedDay: _selectedDay,
          items: items,
          onOpen: _openAttentionItem,
        ),
      ),
    );
  }

  Future<void> _openEstimate(WorkRecord record) async {
    final store = PrototypeOperationsScope.of(context);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EstimateDetailScreen(
          initialRecord: record,
          onUpdated: store.updateWorkRecord,
          onCreateJob: _createJobFromEstimate,
          permissions: _estimatePermissions,
        ),
      ),
    );
    if (mounted) _updateState(() {});
  }

  EstimatePermissions get _estimatePermissions =>
      (PrototypeOperationsScope.of(
            context,
          ).workSession?.permissions.canManageOtherCreators ??
          (_view == AppViewMode.admin))
      ? const EstimatePermissions.development()
      : const EstimatePermissions.technicianDevelopment();

  InvoicePermissions get _invoicePermissions =>
      invoicePermissionsForView(_view);

  void _openInvoice(WorkRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvoiceDetailScreen(
          record: record,
          permissions: _invoicePermissions,
        ),
      ),
    );
  }

  Future<void> _createJobFromEstimate(WorkRecord estimate) async {
    final job = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => WorkJobEditor(
          sourceEstimate: estimate,
          initialDay: estimate.estimateDates?.proposedServiceOn ?? _selectedDay,
        ),
      ),
    );
    if (!mounted || job == null) return;
    final store = PrototypeOperationsScope.of(context);
    if (store.workSession == null) {
      store.addWorkRecord(job);
      store.updateWorkRecord(
        estimate.withEstimateStage(EstimateStage.converted, DateTime.now()),
      );
    }
    _updateState(() {});
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
