part of 'invoice_workspace_screen.dart';

extension _InvoiceWorkspaceQueries on _InvoiceWorkspaceScreenState {
  List<WorkRecord> get _scopedInvoices =>
      (_store.workSession == null
              ? _store.workRecords
              : visibleWorkOverviewRecords(context))
          .where((record) {
            if (record.kind != WorkRecordKind.invoice) return false;
            if (widget.permissions.canViewFinancials &&
                !_preferences.includeClosedRecords &&
                invoiceCollectionStatus(
                      record,
                      _store.financialEntries,
                      now: DateTime.now(),
                    ) ==
                    InvoiceCollectionStatus.paid) {
              return false;
            }
            if (_store.workSession != null) return true;
            final employeeId =
                _employeeId ??
                (_view == AppViewMode.technician ? 'alex' : null);
            if (employeeId == null) return true;
            final legacy = demoEmployees
                .where((e) => e.id == employeeId)
                .firstOrNull;
            return record.createdByEmployeeId == employeeId ||
                record.assignedEmployeeIds.contains(employeeId) ||
                (legacy != null && record.assignee == legacy.name);
          })
          .toList();

  Set<InvoiceDateActivity> _dateActivity(WorkRecord record, DateTime day) =>
      invoiceDateActivity(
        record,
        day,
        widget.permissions.canViewFinancials
            ? _store.financialEntries
            : const [],
      );

  bool _invoiceOccursOn(WorkRecord record, DateTime day) =>
      _dateActivity(record, day).isNotEmpty;

  List<WorkRecord> get _dateInvoices {
    return _sort(
      _scopedInvoices.where((record) => _invoiceOccursOn(record, _selectedDay)),
    );
  }

  List<WorkRecord> get _openInvoices {
    if (!widget.permissions.canViewFinancials) return const [];
    final excluded = {
      ..._attentionItems.map((item) => item.sourceId),
      ..._dateInvoices.map((record) => record.id),
    };
    return _sort(
      _scopedInvoices.where(
        (record) =>
            record.status != WorkRecordStatus.draft &&
            invoiceCollectionStatus(
                  record,
                  _store.financialEntries,
                  now: DateTime.now(),
                ) !=
                InvoiceCollectionStatus.paid &&
            !excluded.contains(record.id),
      ),
    );
  }

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

  List<OperationalAttentionItem> get _attentionItems => _filterInvoiceAttention(
    _store.attentionCenter.itemsFor(_attentionQueryForDay(null)),
  );

  OperationalAttentionQuery _attentionQueryForDay(DateTime? day) =>
      OperationalAttentionQuery(
        panelId: 'invoice-home',
        module: OperationalAttentionModule.work,
        view: _view,
        access: OperationalAttentionAccess({
          if (widget.permissions.canViewFinancials)
            OperationalAttentionCapability.reviewInvoices,
        }),
        selectedEmployeeId: _view == AppViewMode.technician
            ? _store.workSession?.permissions.actorEmployeeId ?? _employeeId
            : _employeeId,
        selectedDay: day,
        resourceKinds: const {OperationalAttentionResourceKind.invoice},
      );

  List<OperationalAttentionItem> _attentionItemsForDay(DateTime day) =>
      _filterInvoiceAttention(
        _store.attentionCenter.itemsFor(_attentionQueryForDay(day)),
      );

  List<OperationalAttentionItem> _filterInvoiceAttention(
    List<OperationalAttentionItem> items,
  ) => !widget.permissions.canViewFinancials
      ? const []
      : items
            .where((item) {
              final invoice = _scopedInvoices
                  .where((r) => r.id == item.sourceId)
                  .firstOrNull;
              if (invoice == null) return false;
              return invoiceCollectionStatus(
                    invoice,
                    _store.financialEntries,
                    now: DateTime.now(),
                  ) !=
                  InvoiceCollectionStatus.paid;
            })
            .map((item) {
              final invoice = _scopedInvoices.firstWhere(
                (r) => r.id == item.sourceId,
              );
              return OperationalAttentionItem(
                id: item.id,
                module: item.module,
                resourceKind: item.resourceKind,
                sourceId: item.sourceId,
                title: item.title,
                reason: context.l10n.workInvoiceOverdueReason(invoice.client),
                isUrgent: item.isUrgent,
              );
            })
            .toList();

  List<WorkRecord> _sort(Iterable<WorkRecord> records) =>
      records.toList()..sort((a, b) {
        final first = a.createdOn ?? DateTime(1970);
        final second = b.createdOn ?? DateTime(1970);
        return second.compareTo(first);
      });
}
