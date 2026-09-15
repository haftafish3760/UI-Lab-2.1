import 'work_drafts_screen.dart';
import 'package:flutter/material.dart';
import '../../shared/calendar_width_section.dart';

import '../../data/operational_attention.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_attention_panel.dart';
import '../../shared/operational_scope.dart';
import '../../shared/operations_workspace.dart';
import '../../theme/app_semantic_colors.dart';
import '../dashboard/dashboard_models.dart';
import 'invoice_editor_screen.dart';
import 'invoice_detail_screen.dart';
import 'invoice_permissions.dart';
import 'work_attention_list_screen.dart';
import 'work_document_day_screen.dart';
import 'work_models.dart';
import 'work_month_calendar.dart';
import 'work_record_settings_screen.dart';
import 'work_scope_header.dart';
import 'work_selected_date_bar.dart';

part 'invoice_workspace_widgets.dart';
part 'invoice_workspace_queries.dart';

class InvoiceWorkspaceScreen extends StatefulWidget {
  const InvoiceWorkspaceScreen({
    required this.initialDay,
    this.permissions = const InvoicePermissions.development(),
    super.key,
  });

  final DateTime initialDay;
  final InvoicePermissions permissions;

  @override
  State<InvoiceWorkspaceScreen> createState() => _InvoiceWorkspaceScreenState();
}

class _InvoiceWorkspaceScreenState extends State<InvoiceWorkspaceScreen> {
  late var _selectedDay = DateUtils.dateOnly(widget.initialDay);
  final _search = TextEditingController();
  var _showAllDateInvoices = false;
  var _showAllOpenInvoices = false;
  var _fixturePreferences = const WorkRecordDisplayPreferences();
  WorkRecordDisplayPreferences get _preferences =>
      readWorkRecordDisplayPreferences(
        context,
        'invoices',
        _fixturePreferences,
      );

  PrototypeOperationsStore get _store => PrototypeOperationsScope.of(context);
  AppViewMode get _view => OperationalScope.of(context).view;
  String? get _employeeId => OperationalScope.of(context).selectedEmployeeId;
  AppSemanticColors get _semantic =>
      Theme.of(context).extension<AppSemanticColors>()!;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView) {
      return const Scaffold(
        key: ValueKey('work-invoice-workspace'),
        body: SafeArea(
          child: Center(
            child: Text('You do not have permission to view invoices.'),
          ),
        ),
      );
    }
    final query = _search.text.trim().toLowerCase();
    final attentionQuery = _attentionQueryForDay(null);
    final attentionItems = _store.attentionCenter.itemsFor(attentionQuery);
    final showAttention = _store.attentionCenter.shouldShow(
      attentionQuery,
      attentionItems,
    );
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pageInsets = AppLayoutEngine.pageInsetsFor(pageWidth);
    final compactActions =
        AppLayoutEngine.workFor(
          pageWidth - pageInsets.horizontal,
          textScaler: MediaQuery.textScalerOf(context),
        ).columns ==
        1;
    return Scaffold(
      key: const ValueKey('work-invoice-workspace'),
      floatingActionButton: widget.permissions.canCreate && compactActions
          ? FloatingActionButton.extended(
              key: const ValueKey('new-invoice'),
              onPressed: _createInvoice,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New invoice'),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final availableWidth = constraints.maxWidth - insets.horizontal;
            final layout = AppLayoutEngine.workFor(
              availableWidth,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 96),
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: insets.left,
                    right: insets.right,
                  ),
                  child: SizedBox(
                    width: availableWidth,
                    child: OperationsWorkspaceFrame(
                      layout: layout,
                      primaryContent: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WorkScopeHeader(
                            view: _view,
                            selectedDay: _selectedDay,
                            selectedEmployeeId: _employeeId,
                            workspaceLabel: 'Invoices',
                            showBackButton: true,
                            showDateContext: false,
                            showEmployeeStrip: false,
                            onBack: () => Navigator.of(context).pop(),
                            onViewChanged: OperationalScope.of(context).setView,
                            onEmployeeChanged: OperationalScope.of(
                              context,
                            ).selectEmployee,
                            onSettings: _openSettings,
                          ),
                          if (widget.permissions.canCreate &&
                              !compactActions) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FilledButton.icon(
                                key: const ValueKey('new-invoice-inline'),
                                onPressed: _createInvoice,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('New invoice'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            key: const ValueKey('open-work-drafts'),
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => const WorkDraftsScreen(
                                  kind: WorkRecordKind.invoice,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.edit_note_outlined),
                            label: const Text(
                              'Drafts — continue or delete an invoice',
                            ),
                          ),
                          WorkSelectedDateBar(
                            key: const ValueKey('invoice-selected-date'),
                            selectedDay: _selectedDay,
                            onPrevious: () => _selectDay(
                              _selectedDay.subtract(const Duration(days: 1)),
                            ),
                            onNext: () => _selectDay(
                              _selectedDay.add(const Duration(days: 1)),
                            ),
                          ),
                          if (showAttention) ...[
                            const SizedBox(height: 10),
                            OperationalAttentionPanel(
                              key: const ValueKey('invoice-attention'),
                              items: attentionItems,
                              rowKeyFor: (item) => ValueKey(
                                'invoice-attention-row-${item.sourceId}',
                              ),
                              onOpen: _openAttentionItem,
                              onOpenAll: () =>
                                  _openAttentionList(attentionItems),
                              onDismiss: () => _store.attentionCenter.dismiss(
                                attentionQuery,
                                attentionItems,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          TextField(
                            key: const ValueKey('invoice-search'),
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Search invoices',
                              hintText:
                                  'Customer, job, invoice number, or work title',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        _search.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSections(layout, query),
                        ],
                      ),
                      followingContent: layout.columns == 1
                          ? null
                          : WorkMonthCalendar(
                              maximumWidth: layout.laneWidth,
                              selectedDay: _selectedDay,
                              onDaySelected: _openCalendarDay,
                              entryCountForDay: (day) => _scopedInvoices
                                  .where((record) => record.occursOn(day))
                                  .length,
                              needsApprovalForDay: (day) =>
                                  _scopedInvoices.any(
                                    (record) => record.occursOn(day),
                                  ) &&
                                  _attentionItemsForDay(day).isNotEmpty,
                              recordKind: CalendarRecordKind.invoice,
                            ),
                    ),
                  ),
                ),
                if (layout.columns == 1) ...[
                  SizedBox(height: layout.gap),
                  CalendarWidthSection(
                    child: WorkMonthCalendar(
                      maximumWidth: AppLayoutEngine.calendarMaximum,
                      selectedDay: _selectedDay,
                      onDaySelected: _openCalendarDay,
                      entryCountForDay: (day) => _scopedInvoices
                          .where((record) => record.occursOn(day))
                          .length,
                      needsApprovalForDay: (day) =>
                          _scopedInvoices.any(
                            (record) => record.occursOn(day),
                          ) &&
                          _attentionItemsForDay(day).isNotEmpty,
                      recordKind: CalendarRecordKind.invoice,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSections(OperationsWorkspaceLayout layout, String query) {
    if (query.isNotEmpty) {
      return OperationsLaneGrid(
        layout: layout,
        children: [
          _InvoiceListSection(
            key: const ValueKey('invoice-search-results'),
            title: 'Invoice matches',
            icon: Icons.search_rounded,
            records: _searchResults,
            emptyMessage: 'No authorized invoices match that search.',
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
        _InvoiceListSection(
          key: const ValueKey('invoice-date-records'),
          title: 'Invoices for this date',
          icon: Icons.receipt_long_outlined,
          records: dateInvoices,
          totalCount: _dateInvoices.length,
          emptyMessage: 'No invoice activity is recorded for this date.',
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
            title: 'Open invoices',
            icon: Icons.account_balance_wallet_outlined,
            records: openInvoices,
            totalCount: _openInvoices.length,
            emptyMessage: 'No other invoices have an open balance.',
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

  List<WorkRecord> _visible(List<WorkRecord> records, bool showAll) =>
      showAll ? records : records.take(3).toList();

  Widget? _toggleFooter({
    required List<WorkRecord> records,
    required bool showingAll,
    required VoidCallback onPressed,
  }) {
    if (records.length <= 3) return null;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        showingAll
            ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded,
      ),
      label: Text(showingAll ? 'Show only 3' : 'Show all ${records.length}'),
    );
  }

  void _selectDay(DateTime day) =>
      setState(() => _selectedDay = DateUtils.dateOnly(day));

  void _openCalendarDay(DateTime day) {
    final selected = DateUtils.dateOnly(day);
    _selectDay(selected);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkDocumentDayScreen(
          initialDay: selected,
          kind: WorkRecordKind.invoice,
          preferences: _preferences,
          showFinancials: widget.permissions.canViewFinancials,
          recordsForDay: _invoicesForDay,
          attentionItemsForDay: _attentionItemsForDay,
          onOpenRecord: _openInvoice,
          onDismissAttention: (date, items) => _store.attentionCenter.dismiss(
            _attentionQueryForDay(date),
            items,
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context)
        .push<WorkRecordDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => WorkRecordSettingsScreen(
              workspaceId: 'invoices',
              workspaceLabel: 'Invoices',
              initial: _preferences,
            ),
          ),
        );
    if (mounted && updated != null) {
      setState(() => _fixturePreferences = updated);
    }
  }

  void _openAttentionItem(OperationalAttentionItem item) {
    final matches = _scopedInvoices.where(
      (record) => record.id == item.sourceId,
    );
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This invoice is no longer available.')),
      );
      return;
    }
    _openInvoice(matches.first);
  }

  void _openAttentionList(List<OperationalAttentionItem> items) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkAttentionListScreen(
          selectedDay: _selectedDay,
          items: items,
          onOpen: _openAttentionItem,
          workspaceLabel: 'Invoice attention',
          screenKey: const ValueKey('invoice-attention-list'),
          rowKeyPrefix: 'invoice-attention-list',
          onSettings: _openSettings,
        ),
      ),
    );
  }

  Future<void> _createInvoice() async {
    if (!widget.permissions.canCreate) return;
    final invoice = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorScreen(
          initialDay: _selectedDay,
          createdByEmployeeId: _employeeId ?? demoEmployees.first.id,
        ),
      ),
    );
    if (!mounted || invoice == null) return;
    final saved = await _store.addWorkRecord(invoice);
    if (mounted && saved) {
      await _openInvoice(invoice);
    }
  }

  Future<void> _openInvoice(WorkRecord record) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(
          record: record,
          permissions: widget.permissions,
        ),
      ),
    );
  }
}
