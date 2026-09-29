import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/quote_status.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/operational_summary_strip.dart';
import '../../shared/calendar_width_section.dart';
import '../../theme/operational_card_palette.dart';
import 'quote_detail_screen.dart';
import 'quote_editor_screen.dart';
import 'work_detail_header.dart';
import 'work_draft_shortcut.dart';
import 'work_models.dart';
import 'work_month_calendar.dart';
import 'work_overview_scope.dart';
import 'work_record_settings_screen.dart';
import 'work_selected_date_bar.dart';

class QuoteWorkspaceScreen extends StatefulWidget {
  const QuoteWorkspaceScreen({required this.initialDay, super.key});
  final DateTime initialDay;
  @override
  State<QuoteWorkspaceScreen> createState() => _QuoteWorkspaceScreenState();
}

class _QuoteWorkspaceScreenState extends State<QuoteWorkspaceScreen> {
  late DateTime _day = DateUtils.dateOnly(widget.initialDay);
  final _search = TextEditingController();
  QuoteStatus? _status;
  bool _allDates = false;
  int _draftRefresh = 0;
  var _fallback = const WorkRecordDisplayPreferences();
  WorkRecordDisplayPreferences get _preferences =>
      readWorkRecordDisplayPreferences(context, 'quotes', _fallback);
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _settings() async {
    final result = await Navigator.of(context)
        .push<WorkRecordDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => WorkRecordSettingsScreen(
              workspaceLabel: 'Quotes',
              workspaceId: 'quotes',
              initial: _preferences,
            ),
          ),
        );
    if (mounted && result != null) setState(() => _fallback = result);
  }

  Future<void> _create() async {
    final record = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(builder: (_) => QuoteEditorScreen(initialDay: _day)),
    );
    if (!mounted) return;
    setState(() => _draftRefresh++);
    if (record != null) await _open(record);
  }

  Future<void> _open(WorkRecord record) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => QuoteDetailScreen(recordId: record.id)),
    );
    if (mounted) setState(() => _draftRefresh++);
  }

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final records = visibleWorkOverviewRecords(
      context,
    ).where((r) => r.kind == WorkRecordKind.quote).toList();
    final query = _search.text.trim().toLowerCase();
    final shown =
        records
            .where(
              (r) => quoteMatchesFilters(
                r,
                today: DateTime.now(),
                selectedDay: _day,
                allDates: _allDates,
                includeClosedRecords: _preferences.includeClosedRecords,
                query: query,
                selectedStatus: _status,
              ),
            )
            .toList()
          ..sort(
            (a, b) => (b.createdOn ?? _day).compareTo(a.createdOn ?? _day),
          );
    final canCreate =
        store.workSession?.permissions.editableKinds.contains(
          WorkRecordKind.quote,
        ) ==
        true;
    final tone = OperationalCardPalette.plan;
    return Scaffold(
      key: const ValueKey('work-quote-workspace'),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              key: const ValueKey('new-quote'),
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('New quote'),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.workFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return SingleChildScrollView(
              padding: insets.copyWith(top: 10, bottom: 96),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: layout.workspaceWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkDetailHeader(
                        label: 'Quotes',
                        selectedDay: _day,
                        onBack: () => Navigator.of(context).pop(),
                        onSettings: _settings,
                      ),
                      WorkDraftShortcut(
                        key: ValueKey('quote-draft-shortcut-$_draftRefresh'),
                        kind: WorkRecordKind.quote,
                        buttonKey: const ValueKey('quote-drafts'),
                      ),
                      const SizedBox(height: 12),
                      OperationalSummaryStrip(
                        items: [
                          for (final status in [
                            QuoteStatus.needsApproval,
                            if (records.any(
                              (r) =>
                                  quoteStatus(r, DateTime.now()) ==
                                  QuoteStatus.changesRequested,
                            ))
                              QuoteStatus.changesRequested,
                            QuoteStatus.ready,
                            QuoteStatus.awaitingCustomer,
                            QuoteStatus.accepted,
                            QuoteStatus.declined,
                            QuoteStatus.expired,
                          ])
                            OperationalSummaryItem(
                              id: 'quote-${status.name}',
                              label: status.label,
                              value:
                                  '${records.where((r) => quoteStatus(r, DateTime.now()) == status).length}',
                              color: tone.start,
                              endColor: tone.end,
                              foreground: tone.foreground,
                              icon: Icons.description_outlined,
                              selected: _status == status,
                              onTap: () => setState(() {
                                _status = status;
                                _allDates = true;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      WorkSelectedDateBar(
                        selectedDay: _day,
                        onPrevious: () => setState(() {
                          _day = _day.subtract(const Duration(days: 1));
                          _allDates = false;
                        }),
                        onNext: () => setState(() {
                          _day = _day.add(const Duration(days: 1));
                          _allDates = false;
                        }),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Selected date'),
                            selected: !_allDates,
                            onSelected: (_) =>
                                setState(() => _allDates = false),
                          ),
                          ChoiceChip(
                            label: const Text('All dates'),
                            selected: _allDates,
                            onSelected: (_) => setState(() => _allDates = true),
                          ),
                          if (_status != null)
                            TextButton(
                              onPressed: () => setState(() => _status = null),
                              child: const Text('All quotes'),
                            ),
                        ],
                      ),
                      if (records.isNotEmpty)
                        TextField(
                          key: const ValueKey('quote-search'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Search customer, title or number',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => setState(_search.clear),
                                  ),
                          ),
                        ),
                      for (final quote in shown)
                        ListTile(
                          key: ValueKey('quote-row-${quote.id}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(quote.title),
                          subtitle: Text(
                            [
                              quote.client,
                              quote.number,
                              '\$${quote.total.toStringAsFixed(2)}',
                              if (_preferences.showStatusDetails)
                                quoteStatus(quote, DateTime.now()).label,
                              if (_preferences.showAssignments &&
                                  quote.assignee != null)
                                quote.assignee!,
                            ].join(' · '),
                          ),
                          onTap: () => _open(quote),
                        ),
                      const SizedBox(height: 12),
                      CalendarWidthSection(
                        child: WorkMonthCalendar(
                          selectedDay: _day,
                          entryCountForDay: (day) =>
                              records.where((r) => r.occursOn(day)).length,
                          onDaySelected: (day) => setState(() {
                            _day = day;
                            _allDates = false;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
