import '../../data/work/invoice_collection_status.dart';
import 'invoice_collection_localization.dart';
import '../../data/preferences/work_record_display_preferences.dart';
import 'package:intl/intl.dart';
import '../../shared/section_card.dart';
import '../../data/work/invoice_payment_balance.dart';
import 'work_invoice_filter_strip.dart';
import '../../../l10n/app_localizations_extension.dart';
import 'work_overview_localization.dart';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/work_overview_query.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/operational_scope.dart';
import 'work_models.dart';
import 'work_overview_scope.dart';
import 'work_scope_header.dart';

class WorkOverviewListScreen extends StatefulWidget {
  const WorkOverviewListScreen({
    required this.initialFilter,
    required this.onOpen,
    this.onSettings,
    this.supportingActions,
    this.bottomAction,
    this.showFinancials = true,
    this.preferences = const WorkRecordDisplayPreferences(),
    super.key,
  });
  final WorkOverviewFilter initialFilter;
  final ValueChanged<WorkRecord> onOpen;
  final VoidCallback? onSettings;
  final Widget? supportingActions;
  final Widget? bottomAction;
  final bool showFinancials;
  final WorkRecordDisplayPreferences preferences;

  @override
  State<WorkOverviewListScreen> createState() => _WorkOverviewListScreenState();
}

class _WorkOverviewListScreenState extends State<WorkOverviewListScreen> {
  late WorkOverviewFilter _filter = widget.initialFilter;
  final _searchController = TextEditingController();
  String get _search => _searchController.text;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final scope = OperationalScope.of(context);
    final invoiceList = invoiceListFilters.contains(widget.initialFilter);
    // Removing financial access must also stop payment-derived filtering and
    // counts, including a previously selected or directly supplied filter.
    final effectiveFilter = invoiceList && !widget.showFinancials
        ? WorkOverviewFilter.allInvoices
        : _filter;
    final records = workOverviewRecords(
      records: visibleWorkOverviewRecords(context).where(
        (record) =>
            !invoiceList ||
            !widget.showFinancials ||
            effectiveFilter != WorkOverviewFilter.allInvoices ||
            widget.preferences.includeClosedRecords ||
            invoiceCollectionStatus(
                  record,
                  store.financialEntries,
                  now: DateTime.now(),
                ) !=
                InvoiceCollectionStatus.paid,
      ),
      payments: widget.showFinancials ? store.financialEntries : const [],
      filter: effectiveFilter,
      now: DateTime.now(),
      search: _search,
    );
    return Scaffold(
      key: const ValueKey('work-overview-list'),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 32),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkScopeHeader(
                          view: scope.view,
                          selectedDay: DateTime.now(),
                          selectedEmployeeId: scope.selectedEmployeeId,
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                          workspaceLabel: invoiceList
                              ? context.l10n.workInvoiceHeading
                              : context.l10n.workRecordsHeading,
                          showBackButton: true,
                          showDateContext: false,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                          onSettings: widget.onSettings,
                        ),
                        const SizedBox(height: 16),
                        if (invoiceList && widget.showFinancials)
                          WorkInvoiceFilterStrip(
                            selected: _filter,
                            onSelected: (value) =>
                                setState(() => _filter = value),
                          )
                        else if (!invoiceList)
                          DropdownButtonFormField<WorkOverviewFilter>(
                            initialValue: _filter,
                            isExpanded: true,
                            itemHeight: null,
                            decoration: InputDecoration(
                              labelText: context.l10n.workShowRecords,
                            ),
                            items: [
                              for (final value in WorkOverviewFilter.values)
                                DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value.localizedLabel(context.l10n),
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _filter = value);
                              }
                            },
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: context.l10n.workSearchRecords,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: invoiceList && _search.isNotEmpty
                                ? IconButton(
                                    key: const ValueKey('clear-invoice-search'),
                                    tooltip: context.l10n.catalogClear,
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () =>
                                        setState(_searchController.clear),
                                  )
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        if (widget.supportingActions != null) ...[
                          widget.supportingActions!,
                          const SizedBox(height: 12),
                        ],
                        Text(
                          context.l10n.workRecordCount(records.length),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (records.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(context.l10n.workNoMatchingRecords),
                          ),
                        for (final record in records)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _recordSurface(
                              invoiceList: invoiceList,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                key: ValueKey(
                                  'work-overview-record-${record.id}',
                                ),
                                title: Text(
                                  '${record.client}\n${record.title}',
                                ),
                                subtitle: Text(
                                  '${record.number}${widget.preferences.showStatusDetails && (!invoiceList || widget.showFinancials) ? ' · ${record.kind == WorkRecordKind.estimate ? record.resolvedEstimateStage.localizedLabel(context.l10n) : (invoiceList && widget.showFinancials ? _invoiceStatus(context, record) : record.status.localizedLabel(context.l10n))}' : ''}\n${_recordDates(context, record)}${invoiceList && widget.preferences.showAssignments && record.assignee != null && record.assignee!.isNotEmpty ? '\n${record.assignee}' : ''}${invoiceList && widget.showFinancials ? _invoiceAmounts(context, record) : ''}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  final current =
                                      visibleWorkOverviewRecords(context)
                                          .where(
                                            (candidate) =>
                                                candidate.id == record.id,
                                          )
                                          .firstOrNull;
                                  if (current == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context.l10n.workRecordUnavailable,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  widget.onOpen(current);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.bottomAction case final action?) action,
              ],
            );
          },
        ),
      ),
    );
  }
}

String _recordDates(BuildContext context, WorkRecord record) {
  final localizations = MaterialLocalizations.of(context);
  String date(DateTime value) => localizations.formatMediumDate(value);
  if (record.kind == WorkRecordKind.job) {
    final start = record.scheduledStart;
    final end = record.scheduledEnd;
    if (record.status == WorkRecordStatus.completed &&
        record.completedOn != null) {
      return context.l10n.workCompletedDate(date(record.completedOn!));
    }
    if (start != null) {
      return end != null && !DateUtils.isSameDay(start, end)
          ? context.l10n.workScheduledDate('${date(start)} – ${date(end)}')
          : context.l10n.workScheduledDate(date(start));
    }
    return context.l10n.workNotScheduled;
  }
  if (record.kind == WorkRecordKind.invoice && record.dueOn != null) {
    return context.l10n.workDueDate(date(record.dueOn!));
  }
  final created = record.createdOn;
  return created == null
      ? context.l10n.workCreatedDateMissing
      : context.l10n.workCreatedDate(date(created));
}

String _invoiceAmounts(BuildContext context, WorkRecord record) {
  final payments = PrototypeOperationsScope.of(context).financialEntries;
  final money = NumberFormat.simpleCurrency(
    locale: Localizations.localeOf(context).toLanguageTag(),
    name: 'USD',
  );
  final l10n = context.l10n;
  return '\n${l10n.workInvoiceTotal}: ${money.format(record.total)}'
      '\n${l10n.workInvoiceBalance}: ${money.format(invoiceBalanceCents(record, payments) / 100)}';
}

Widget _recordSurface({required bool invoiceList, required Widget child}) =>
    invoiceList
    ? Column(children: [child, const Divider(height: 1)])
    : SectionCard(padding: EdgeInsets.zero, child: child);

String _invoiceStatus(BuildContext context, WorkRecord record) =>
    invoiceCollectionStatus(
      record,
      PrototypeOperationsScope.of(context).financialEntries,
      now: DateTime.now(),
    ).localizedLabel(context.l10n);
