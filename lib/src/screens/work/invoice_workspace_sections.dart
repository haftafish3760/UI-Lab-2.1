part of 'invoice_workspace_screen.dart';

extension _InvoiceWorkspaceSections on _InvoiceWorkspaceScreenState {
  Widget _buildSections(OperationsWorkspaceLayout layout, String query) {
    if (_selectedFilter != null) {
      final filter = widget.permissions.canViewFinancials
          ? _selectedFilter!
          : WorkOverviewFilter.allInvoices;
      final records = workOverviewRecords(
        records: visibleWorkOverviewRecords(context).where(
          (record) =>
              filter != WorkOverviewFilter.allInvoices ||
              !widget.permissions.canViewFinancials ||
              _preferences.includeClosedRecords ||
              invoiceCollectionStatus(
                    record,
                    _store.financialEntries,
                    now: DateTime.now(),
                  ) !=
                  InvoiceCollectionStatus.paid,
        ),
        payments: _store.financialEntries,
        filter: filter,
        now: DateTime.now(),
        search: query,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            filter.localizedLabel(context.l10n),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final record in records)
            _InvoiceRecordRow(
              record: record,
              showStatus: _preferences.showStatusDetails,
              showFinancials: widget.permissions.canViewFinancials,
              onOpen: () => _openInvoice(record),
            ),
        ],
      );
    }
    if (query.isNotEmpty) {
      return OperationsLaneGrid(
        layout: layout,
        children: [
          _InvoiceListSection(
            key: const ValueKey('invoice-search-results'),
            title: context.l10n.workInvoiceMatches,
            icon: Icons.search_rounded,
            records: _searchResults,
            emptyMessage: context.l10n.workInvoiceNoMatches,
            headerColor: _semantic.successSurface,
            borderColor: _semantic.success,
            preferences: _preferences,
            showFinancials: widget.permissions.canViewFinancials,
            onOpen: _openInvoice,
          ),
        ],
      );
    }
    final dateInvoices = _visible(_dateInvoices, _showAllDateInvoices);
    final openInvoices = _visible(_openInvoices, _showAllOpenInvoices);
    return OperationsLaneGrid(
      layout: layout,
      children: [
        if (dateInvoices.isNotEmpty)
          _InvoiceListSection(
            key: const ValueKey('invoice-date-records'),
            dateLabelFor: (record) => _dateActivity(
              record,
              _selectedDay,
            ).map((event) => event.localizedLabel(context.l10n)).join(' · '),
            title: context.l10n.workInvoicesForDate,
            icon: Icons.receipt_long_outlined,
            records: dateInvoices,
            totalCount: _dateInvoices.length,
            emptyMessage: context.l10n.workInvoiceNoDateActivity,
            headerColor: _semantic.successSurface,
            borderColor: _semantic.success,
            preferences: _preferences,
            showFinancials: widget.permissions.canViewFinancials,
            onOpen: _openInvoice,
            footer: _toggleFooter(
              records: _dateInvoices,
              showingAll: _showAllDateInvoices,
              onPressed: () =>
                  setState(() => _showAllDateInvoices = !_showAllDateInvoices),
            ),
          ),
        if (_openInvoices.isNotEmpty)
          _InvoiceListSection(
            key: const ValueKey('invoice-open-records'),
            title: context.l10n.workOpenInvoices,
            icon: Icons.account_balance_wallet_outlined,
            records: openInvoices,
            totalCount: _openInvoices.length,
            emptyMessage: context.l10n.workInvoiceNoOpenBalance,
            headerColor: _semantic.currentSurface,
            borderColor: _semantic.current,
            rowAccent: _semantic.current,
            preferences: _preferences,
            showFinancials: widget.permissions.canViewFinancials,
            onOpen: _openInvoice,
            footer: _toggleFooter(
              records: _openInvoices,
              showingAll: _showAllOpenInvoices,
              onPressed: () =>
                  setState(() => _showAllOpenInvoices = !_showAllOpenInvoices),
            ),
          ),
      ],
    );
  }
}
