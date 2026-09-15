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
import 'estimate_detail_screen.dart';
import 'estimate_editor_screen.dart';
import 'estimate_models.dart';
import 'work_job_editor.dart';
import 'work_attention_list_screen.dart';
import 'work_document_day_screen.dart';
import 'work_models.dart';
import 'work_month_calendar.dart';
import 'work_record_settings_screen.dart';
import 'work_selected_date_bar.dart';
import 'work_scope_header.dart';

part 'estimate_workspace_widgets.dart';

part 'estimate_workspace_actions.dart';

class EstimateWorkspaceScreen extends StatefulWidget {
  const EstimateWorkspaceScreen({
    required this.initialDay,
    this.permissions = const EstimatePermissions.development(),
    super.key,
  });

  final DateTime initialDay;
  final EstimatePermissions permissions;

  @override
  State<EstimateWorkspaceScreen> createState() =>
      _EstimateWorkspaceScreenState();
}

class _EstimateWorkspaceScreenState extends State<EstimateWorkspaceScreen> {
  late var _selectedDay = DateUtils.dateOnly(widget.initialDay);
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  final _dateAnchorKey = GlobalKey();
  var _showAllDrafts = false;
  var _fixturePreferences = const WorkRecordDisplayPreferences();
  WorkRecordDisplayPreferences get _preferences =>
      readWorkRecordDisplayPreferences(
        context,
        'estimates',
        _fixturePreferences,
      );

  AppViewMode get _view => OperationalScope.of(context).view;
  String? get _employeeId => OperationalScope.of(context).selectedEmployeeId;
  PrototypeOperationsStore get _store => PrototypeOperationsScope.of(context);

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView) {
      return const Scaffold(
        key: ValueKey('work-estimate-workspace'),
        body: SafeArea(
          child: Center(
            child: Text('You do not have permission to view estimates.'),
          ),
        ),
      );
    }
    final attentionQuery = _attentionQueryForDay(_selectedDay);
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
      key: const ValueKey('work-estimate-workspace'),
      floatingActionButton: widget.permissions.canCreate && compactActions
          ? FloatingActionButton.extended(
              key: const ValueKey('new-estimate'),
              onPressed: _createEstimate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New estimate'),
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
            final query = _search.text.trim().toLowerCase();
            return ListView(
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
                            workspaceLabel: 'Estimates',
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
                          FilledButton.icon(
                            key: const ValueKey('open-work-drafts'),
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => const WorkDraftsScreen(
                                  kind: WorkRecordKind.estimate,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.edit_note_outlined),
                            label: const Text(
                              'Drafts — continue or delete an estimate',
                            ),
                          ),
                          if (widget.permissions.canCreate &&
                              !compactActions) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FilledButton.icon(
                                key: const ValueKey('new-estimate-inline'),
                                onPressed: _createEstimate,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('New estimate'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          KeyedSubtree(
                            key: _dateAnchorKey,
                            child: WorkSelectedDateBar(
                              key: const ValueKey('estimate-selected-date'),
                              selectedDay: _selectedDay,
                              onPrevious: () => _selectDay(
                                _selectedDay.subtract(const Duration(days: 1)),
                              ),
                              onNext: () => _selectDay(
                                _selectedDay.add(const Duration(days: 1)),
                              ),
                            ),
                          ),
                          if (showAttention) ...[
                            const SizedBox(height: 10),
                            OperationalAttentionPanel(
                              key: const ValueKey('estimate-attention'),
                              items: attentionItems,
                              rowKeyFor: (item) => ValueKey(
                                'estimate-attention-row-${item.sourceId}',
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
                            key: const ValueKey('estimate-search'),
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Search estimates',
                              hintText:
                                  'Customer, work, description, or estimate number',
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
                          _EstimateHomeSections(
                            layout: layout,
                            dateRecords: _recordsForSelectedDay,
                            drafts: _drafts,
                            searchResults: query.isEmpty
                                ? null
                                : _searchResults,
                            showAllDrafts: _showAllDrafts,
                            showStatusDetails: _preferences.showStatusDetails,
                            showTotals:
                                widget.permissions.canViewEstimateTotals,
                            canCreate: widget.permissions.canCreate,
                            onOpen: _openEstimate,
                            onToggleDrafts: () => setState(
                              () => _showAllDrafts = !_showAllDrafts,
                            ),
                          ),
                        ],
                      ),
                      followingContent: layout.columns == 1
                          ? null
                          : WorkMonthCalendar(
                              maximumWidth: layout.laneWidth,
                              selectedDay: _selectedDay,
                              onDaySelected: _openCalendarDay,
                              entryCountForDay: (day) => _scopedEstimates
                                  .where(
                                    (record) =>
                                        record.resolvedEstimateStage !=
                                            EstimateStage.draft &&
                                        record.occursOn(day),
                                  )
                                  .length,
                              needsApprovalForDay: (day) =>
                                  _scopedEstimates.any(
                                    (record) => record.occursOn(day),
                                  ) &&
                                  _attentionItemsForDay(day).isNotEmpty,
                              recordKind: CalendarRecordKind.estimate,
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
                      entryCountForDay: (day) => _scopedEstimates
                          .where(
                            (record) =>
                                record.resolvedEstimateStage !=
                                    EstimateStage.draft &&
                                record.occursOn(day),
                          )
                          .length,
                      needsApprovalForDay: (day) =>
                          _scopedEstimates.any(
                            (record) => record.occursOn(day),
                          ) &&
                          _attentionItemsForDay(day).isNotEmpty,
                      recordKind: CalendarRecordKind.estimate,
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

  List<WorkRecord> get _scopedEstimates => _store.workRecords.where((record) {
    if (record.kind != WorkRecordKind.estimate) return false;
    final employeeId =
        _employeeId ?? (_view == AppViewMode.technician ? 'alex' : null);
    if (employeeId == null) return true;
    final legacy = demoEmployees.where((e) => e.id == employeeId).firstOrNull;
    return record.createdByEmployeeId == employeeId ||
        record.assignedEmployeeIds.contains(employeeId) ||
        (legacy != null && record.assignee == legacy.name);
  }).toList();

  List<WorkRecord> _recordsForDay(DateTime day) => _sorted(
    _scopedEstimates.where(
      (record) =>
          record.resolvedEstimateStage != EstimateStage.draft &&
          record.occursOn(day),
    ),
  );

  List<WorkRecord> get _allRecordsForSelectedDay =>
      _recordsForDay(_selectedDay);

  List<WorkRecord> get _recordsForSelectedDay {
    final attentionIds = _attentionItemsForDay(
      _selectedDay,
    ).map((item) => item.sourceId).toSet();
    return _allRecordsForSelectedDay
        .where((record) => !attentionIds.contains(record.id))
        .toList();
  }

  OperationalAttentionAccess get _attentionAccess =>
      OperationalAttentionAccess({
        if (widget.permissions.canEditItems)
          OperationalAttentionCapability.reviewEstimates,
        if (widget.permissions.canApproveCompanyReview)
          OperationalAttentionCapability.approveEstimates,
      });

  OperationalAttentionQuery _attentionQueryForDay(DateTime day) =>
      OperationalAttentionQuery(
        panelId: 'estimate-home',
        module: OperationalAttentionModule.work,
        view: _view,
        access: _attentionAccess,
        selectedEmployeeId: _employeeId,
        selectedDay: day,
        resourceKinds: const {OperationalAttentionResourceKind.estimate},
      );

  List<OperationalAttentionItem> _attentionItemsForDay(DateTime day) =>
      _store.attentionCenter.itemsFor(_attentionQueryForDay(day));

  List<WorkRecord> get _drafts => _sorted(
    _scopedEstimates.where(
      (record) => record.resolvedEstimateStage == EstimateStage.draft,
    ),
  );

  List<WorkRecord> get _searchResults {
    final query = _search.text.trim().toLowerCase();
    return _sorted(
      _scopedEstimates.where(
        (record) =>
            record.number.toLowerCase().contains(query) ||
            record.client.toLowerCase().contains(query) ||
            record.title.toLowerCase().contains(query) ||
            record.detail.toLowerCase().contains(query),
      ),
    );
  }

  List<WorkRecord> _sorted(Iterable<WorkRecord> records) {
    final sorted = records.toList();
    sorted.sort((left, right) {
      final leftDate = left.estimateDates?.lastEditedOn ?? left.createdOn;
      final rightDate = right.estimateDates?.lastEditedOn ?? right.createdOn;
      return (rightDate ?? DateTime(0)).compareTo(leftDate ?? DateTime(0));
    });
    return sorted;
  }

  void _selectDay(DateTime day, {bool revealDate = false}) {
    setState(() => _selectedDay = DateUtils.dateOnly(day));
    if (!revealDate) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _dateAnchorKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: 0,
      );
    });
  }

  void _openCalendarDay(DateTime day) {
    final selected = DateUtils.dateOnly(day);
    _selectDay(selected);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkDocumentDayScreen(
          initialDay: selected,
          kind: WorkRecordKind.estimate,
          preferences: _preferences,
          showFinancials: widget.permissions.canViewEstimateTotals,
          recordsForDay: _recordsForDay,
          attentionItemsForDay: _attentionItemsForDay,
          onOpenRecord: _openEstimate,
          onDismissAttention: (date, items) => _store.attentionCenter.dismiss(
            _attentionQueryForDay(date),
            items,
          ),
        ),
      ),
    );
  }

  Future<void> _createEstimate() async {
    final record = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => EstimateEditorScreen(
          initialDay: _selectedDay,
          createdByEmployeeId: _employeeId,
        ),
      ),
    );
    if (mounted && record != null) {
      final saved = await _store.addWorkRecord(record);
      if (!mounted || !saved) {
        return;
      }
      setState(() => _selectedDay = DateUtils.dateOnly(record.createdOn!));
      await _openEstimate(record);
    }
  }

  Future<void> _openEstimate(WorkRecord record) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EstimateDetailScreen(
          initialRecord: record,
          onUpdated: _store.updateWorkRecord,
          onCreateJob: _planJob,
          permissions: widget.permissions,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _refresh(VoidCallback change) => setState(change);
}
