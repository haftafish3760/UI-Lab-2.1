import '../../data/work/invoice_date_activity.dart';
import 'invoice_date_activity_localization.dart';
import '../../data/work/invoice_collection_status.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../data/work/work_overview_query.dart';
import 'work_overview_cards.dart';
import 'work_overview_localization.dart';
import 'work_overview_scope.dart';
import 'invoice_collection_localization.dart';
import 'work_draft_shortcut.dart';
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
import 'work_models.dart';
import 'work_month_calendar.dart';
import 'work_record_settings_screen.dart';
import 'work_scope_header.dart';
import 'work_selected_date_bar.dart';

part 'invoice_workspace_widgets.dart';
part 'invoice_home_view.dart';
part 'invoice_workspace_sections.dart';
part 'invoice_workspace_queries.dart';

class InvoiceWorkspaceScreen extends StatefulWidget {
  const InvoiceWorkspaceScreen({
    required this.initialDay,
    this.showDateActivity = false,
    this.permissions = const InvoicePermissions.development(),
    super.key,
  });

  final DateTime initialDay;
  final bool showDateActivity;
  final InvoicePermissions permissions;

  @override
  State<InvoiceWorkspaceScreen> createState() => _InvoiceWorkspaceScreenState();
}

class _InvoiceWorkspaceScreenState extends State<InvoiceWorkspaceScreen> {
  late var _selectedDay = DateUtils.dateOnly(widget.initialDay);
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  WorkOverviewFilter? _selectedFilter;
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView) {
      return Scaffold(
        key: const ValueKey('work-invoice-workspace'),
        body: SafeArea(
          child: Center(child: Text(context.l10n.workInvoiceAccessDenied)),
        ),
      );
    }
    final query = _search.text.trim().toLowerCase();
    final attentionQuery = _attentionQueryForDay(null);
    final attentionItems = _attentionItems;
    final showAttention = _store.attentionCenter.shouldShow(
      attentionQuery,
      attentionItems,
    );
    return Scaffold(
      key: const ValueKey('work-invoice-workspace'),
      floatingActionButton: _buildNewInvoiceAction(),
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
              key: const ValueKey('invoice-activity-content'),
              controller: _scrollController,
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
                            workspaceLabel: context.l10n.workInvoiceHeading,
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
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: WorkDraftShortcut(
                              kind: WorkRecordKind.invoice,
                              buttonKey: const ValueKey('open-work-drafts'),
                              textButtonLabel: context.l10n.workDraftsShort,
                            ),
                          ),
                          if (widget.permissions.canViewFinancials) ...[
                            WorkOverviewCards(
                              selectedFilter: _selectedFilter,
                              onSelected: (filter) => setState(() {
                                _selectedFilter = filter;
                                _search.clear();
                              }),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                key: const ValueKey('invoice-view-date'),
                                onPressed: () =>
                                    setState(() => _selectedFilter = null),
                                child: Text(
                                  context.l10n.workInvoiceActivityByDate,
                                ),
                              ),
                              for (final filter in [
                                WorkOverviewFilter.invoicesNeedingApproval,
                                WorkOverviewFilter.approvedInvoices,
                              ])
                                if (widget.permissions.canViewFinancials &&
                                    workOverviewRecords(
                                      records: visibleWorkOverviewRecords(
                                        context,
                                      ),
                                      payments: _store.financialEntries,
                                      filter: filter,
                                      now: DateTime.now(),
                                    ).isNotEmpty)
                                  TextButton(
                                    key: ValueKey(
                                      'invoice-filter-${filter.name}',
                                    ),
                                    onPressed: () => setState(() {
                                      _selectedFilter = filter;
                                      _search.clear();
                                    }),
                                    child: Text(
                                      filter.localizedLabel(context.l10n),
                                    ),
                                  ),
                              TextButton(
                                key: const ValueKey('invoice-view-all'),
                                onPressed: () => setState(
                                  () => _selectedFilter =
                                      WorkOverviewFilter.allInvoices,
                                ),
                                child: Text(context.l10n.workFilterAllInvoices),
                              ),
                            ],
                          ),
                          if (_selectedFilter == null)
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
                          if (showAttention &&
                              _selectedFilter == null &&
                              query.isEmpty) ...[
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
                              labelText: context.l10n.workSearchInvoices,
                              hintText: context.l10n.workSearchInvoicesHint,
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: query.isEmpty
                                  ? null
                                  : IconButton(
                                      key: const ValueKey(
                                        'clear-invoice-search',
                                      ),
                                      tooltip: context.l10n.catalogClear,
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
                    ),
                  ),
                ),
                ...[
                  SizedBox(height: layout.gap),
                  CalendarWidthSection(
                    child: WorkMonthCalendar(
                      maximumWidth: AppLayoutEngine.calendarMaximum,
                      selectedDay: _selectedDay,
                      onDaySelected: _openCalendarDay,
                      entryCountForDay: (day) => _scopedInvoices
                          .where((record) => _invoiceOccursOn(record, day))
                          .length,
                      needsApprovalForDay: (day) =>
                          _scopedInvoices.any(
                            (record) => _invoiceOccursOn(record, day),
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
      label: Text(
        showingAll
            ? context.l10n.workShowOnlyThree
            : context.l10n.attentionShowAll(records.length),
      ),
    );
  }

  void _selectDay(DateTime day) => setState(() {
    _selectedDay = DateUtils.dateOnly(day);
    _selectedFilter = null;
  });

  void _openCalendarDay(DateTime day) {
    _search.clear();
    _selectDay(day);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context)
        .push<WorkRecordDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => WorkRecordSettingsScreen(
              workspaceId: 'invoices',
              workspaceLabel: context.l10n.workInvoiceHeading,
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
        SnackBar(content: Text(context.l10n.workInvoiceUnavailable)),
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
          workspaceLabel: context.l10n.workInvoiceAttention,
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
    final saved =
        _store.workSession != null || await _store.addWorkRecord(invoice);
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
