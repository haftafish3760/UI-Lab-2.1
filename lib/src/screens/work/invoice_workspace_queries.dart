part of 'invoice_workspace_screen.dart';

extension _InvoiceWorkspaceQueries on _InvoiceWorkspaceScreenState {
  List<WorkRecord> get _scopedInvoices => _store.workRecords.where((record) {
    if (record.kind != WorkRecordKind.invoice) return false;
    if (!_preferences.includeClosedRecords &&
        record.status == WorkRecordStatus.paid) {
      return false;
    }
    if (_view == AppViewMode.technician) {
      final employee = dashboardEmployeeById(
        _employeeId ?? demoEmployees.first.id,
      );
      return record.createdByEmployeeId == employee.id ||
          record.assignee == employee.name;
    }
    if (_employeeId == null) return true;
    final employee = dashboardEmployeeById(_employeeId!);
    return record.createdByEmployeeId == employee.id ||
        record.assignee == employee.name;
  }).toList();

  List<WorkRecord> get _dateInvoices {
    final attentionIds = _attentionItems.map((item) => item.sourceId).toSet();
    return _sort(
      _scopedInvoices.where(
        (record) =>
            record.status != WorkRecordStatus.draft &&
            record.occursOn(_selectedDay) &&
            !attentionIds.contains(record.id),
      ),
    );
  }

  List<WorkRecord> _invoicesForDay(DateTime day) => _sort(
    _scopedInvoices.where(
      (record) =>
          record.status != WorkRecordStatus.draft && record.occursOn(day),
    ),
  );

  List<WorkRecord> get _openInvoices {
    final excluded = {
      ..._attentionItems.map((item) => item.sourceId),
      ..._dateInvoices.map((record) => record.id),
    };
    return _sort(
      _scopedInvoices.where(
        (record) =>
            record.status != WorkRecordStatus.draft &&
            record.status != WorkRecordStatus.paid &&
            !excluded.contains(record.id),
      ),
    );
  }

  List<WorkRecord> get _draftInvoices => _sort(
    _scopedInvoices.where((record) => record.status == WorkRecordStatus.draft),
  );

  List<WorkRecord> get _searchResults {
    final query = _search.text.trim().toLowerCase();
    return _sort(
      _scopedInvoices.where(
        (record) =>
            record.number.toLowerCase().contains(query) ||
            record.title.toLowerCase().contains(query) ||
            record.client.toLowerCase().contains(query) ||
            record.sourceId?.toLowerCase().contains(query) == true,
      ),
    );
  }

  List<OperationalAttentionItem> get _attentionItems =>
      _store.attentionCenter.itemsFor(_attentionQueryForDay(null));

  OperationalAttentionQuery _attentionQueryForDay(DateTime? day) =>
      OperationalAttentionQuery(
        panelId: 'invoice-home',
        module: OperationalAttentionModule.work,
        view: _view,
        access: const OperationalAttentionAccess({
          OperationalAttentionCapability.reviewInvoices,
        }),
        selectedEmployeeId: _employeeId,
        selectedDay: day,
        resourceKinds: const {OperationalAttentionResourceKind.invoice},
      );

  List<OperationalAttentionItem> _attentionItemsForDay(DateTime day) =>
      _store.attentionCenter.itemsFor(_attentionQueryForDay(day));

  List<WorkRecord> _sort(Iterable<WorkRecord> records) =>
      records.toList()..sort((a, b) {
        final first = a.createdOn ?? DateTime(1970);
        final second = b.createdOn ?? DateTime(1970);
        return second.compareTo(first);
      });
}
