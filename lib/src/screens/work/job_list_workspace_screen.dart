import 'package:flutter/material.dart';

import '../../data/operational_attention.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_attention_panel.dart';
import '../../shared/operational_scope.dart';
import '../../shared/operations_workspace.dart';
import '../../theme/app_semantic_colors.dart';
import '../dashboard/dashboard_models.dart';
import 'job_workspace_screen.dart';
import 'job_workspace_models.dart';
import 'work_job_editor.dart';
import 'work_models.dart';
import 'work_month_calendar.dart';
import 'work_attention_list_screen.dart';
import 'work_record_settings_screen.dart';
import 'work_scope_header.dart';
import 'work_selected_date_bar.dart';

part 'job_day_screen.dart';
part 'job_list_workspace_widgets.dart';

class JobListWorkspaceScreen extends StatefulWidget {
  const JobListWorkspaceScreen({
    required this.initialDay,
    this.permissions = const JobWorkspacePermissions.development(),
    super.key,
  });

  final DateTime initialDay;
  final JobWorkspacePermissions permissions;

  @override
  State<JobListWorkspaceScreen> createState() => _JobListWorkspaceScreenState();
}

class _JobListWorkspaceScreenState extends State<JobListWorkspaceScreen> {
  late var _selectedDay = DateUtils.dateOnly(widget.initialDay);
  final _search = TextEditingController();
  var _showAllDateJobs = false;
  var _showAllActiveJobs = false;
  var _fixturePreferences = const WorkRecordDisplayPreferences();
  WorkRecordDisplayPreferences get _preferences =>
      readWorkRecordDisplayPreferences(context, 'jobs', _fixturePreferences);

  PrototypeOperationsStore get _store => PrototypeOperationsScope.of(context);
  AppViewMode get _view => OperationalScope.of(context).view;
  String? get _employeeId => OperationalScope.of(context).selectedEmployeeId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pageInsets = AppLayoutEngine.pageInsetsFor(pageWidth);
    final compactActions =
        AppLayoutEngine.workFor(
          pageWidth - pageInsets.horizontal,
          textScaler: MediaQuery.textScalerOf(context),
        ).columns ==
        1;
    return Scaffold(
      key: const ValueKey('work-job-workspace'),
      floatingActionButton: compactActions
          ? FloatingActionButton.extended(
              key: const ValueKey('new-job'),
              onPressed: _createJob,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New job'),
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
            final attentionCenter = _store.attentionCenter;
            final attentionQuery = _attentionQueryForDay(_selectedDay);
            final attentionItems = attentionCenter.itemsFor(attentionQuery);
            final showAttention = attentionCenter.shouldShow(
              attentionQuery,
              attentionItems,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
              children: [
                SizedBox(
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
                          workspaceLabel: 'Jobs',
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
                        WorkSelectedDateBar(
                          key: const ValueKey('job-selected-date'),
                          selectedDay: _selectedDay,
                          onPrevious: () => _selectDay(
                            _selectedDay.subtract(const Duration(days: 1)),
                          ),
                          onNext: () => _selectDay(
                            _selectedDay.add(const Duration(days: 1)),
                          ),
                        ),
                        if (!compactActions) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FilledButton.icon(
                              key: const ValueKey('new-job-inline'),
                              onPressed: _createJob,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('New job'),
                            ),
                          ),
                        ],
                        if (showAttention) ...[
                          const SizedBox(height: 10),
                          OperationsLaneGrid(
                            key: const ValueKey('job-attention'),
                            layout: layout,
                            children: [
                              OperationalAttentionPanel(
                                items: attentionItems,
                                rowKeyFor: (item) =>
                                    ValueKey('job-attention-${item.sourceId}'),
                                onOpen: _openAttentionItem,
                                onOpenAll: () =>
                                    _openAttentionList(attentionItems),
                                onDismiss: () => attentionCenter.dismiss(
                                  attentionQuery,
                                  attentionItems,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey('job-search'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Search jobs',
                            hintText: 'Customer, work, or job number',
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
                    followingContent: WorkMonthCalendar(
                      maximumWidth: layout.laneWidth,
                      selectedDay: _selectedDay,
                      onDaySelected: _openDay,
                      entryCountForDay: (day) => _scopedJobs
                          .where((record) => record.occursOn(day))
                          .length,
                      needsApprovalForDay: (day) =>
                          _attentionItemsForDay(day).isNotEmpty,
                      recordKind: CalendarRecordKind.job,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AppSemanticColors get _semantic =>
      Theme.of(context).extension<AppSemanticColors>()!;

  Widget _buildSections(OperationsWorkspaceLayout layout, String query) {
    if (query.isNotEmpty) {
      return OperationsLaneGrid(
        layout: layout,
        children: [
          _JobListSection(
            key: const ValueKey('job-search-results'),
            title: 'Job matches',
            icon: Icons.search_rounded,
            records: _searchResults,
            emptyMessage: 'No authorized jobs match that search.',
            headerColor: _semantic.currentSurface,
            borderColor: _semantic.current,
            selectedDay: _selectedDay,
            preferences: _preferences,
            onOpen: _openJob,
          ),
        ],
      );
    }
    final dateJobs = _showAllDateJobs
        ? _jobsForSelectedDay
        : _jobsForSelectedDay.take(3).toList();
    final activeJobs = _showAllActiveJobs
        ? _activeJobs
        : _activeJobs.take(3).toList();
    return OperationsLaneGrid(
      layout: layout,
      children: [
        _JobListSection(
          key: const ValueKey('job-date-records'),
          title: 'Jobs for this date',
          icon: Icons.event_available_outlined,
          records: dateJobs,
          totalCount: _jobsForSelectedDay.length,
          emptyMessage: 'No jobs are scheduled for this date.',
          headerColor: _semantic.plannedSurface,
          borderColor: _semantic.planned,
          selectedDay: _selectedDay,
          preferences: _preferences,
          onOpen: _openJob,
          footer: _toggleFooter(
            records: _jobsForSelectedDay,
            showingAll: _showAllDateJobs,
            onPressed: () =>
                setState(() => _showAllDateJobs = !_showAllDateJobs),
          ),
        ),
        _JobListSection(
          key: const ValueKey('job-active-records'),
          title: 'Active jobs',
          icon: Icons.handyman_outlined,
          records: activeJobs,
          totalCount: _activeJobs.length,
          emptyMessage: 'No other jobs are currently active.',
          headerColor: _semantic.currentSurface,
          borderColor: _semantic.current,
          rowAccent: _semantic.current,
          selectedDay: _selectedDay,
          preferences: _preferences,
          onOpen: _openJob,
          footer: _toggleFooter(
            records: _activeJobs,
            showingAll: _showAllActiveJobs,
            onPressed: () =>
                setState(() => _showAllActiveJobs = !_showAllActiveJobs),
          ),
        ),
      ],
    );
  }

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

  List<WorkRecord> get _scopedJobs => _store.workRecords.where((record) {
    if (record.kind != WorkRecordKind.job) return false;
    if (!_preferences.includeClosedRecords &&
        record.status == WorkRecordStatus.completed) {
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

  List<OperationalAttentionItem> _attentionItemsForDay(DateTime day) =>
      _store.attentionCenter.itemsFor(_attentionQueryForDay(day));

  Set<String> get _attentionJobIds => {
    for (final item in _attentionItemsForDay(_selectedDay)) item.sourceId,
  };

  List<WorkRecord> _jobsForDay(DateTime day) {
    final attentionIds = {
      for (final item in _attentionItemsForDay(day)) item.sourceId,
    };
    return _sortJobs(
      _scopedJobs
          .where((record) => record.occursOn(day))
          .where((record) => !attentionIds.contains(record.id)),
    );
  }

  List<WorkRecord> get _jobsForSelectedDay => _jobsForDay(_selectedDay);

  List<WorkRecord> _allJobsForDay(DateTime day) =>
      _sortJobs(_scopedJobs.where((record) => record.occursOn(day)));

  List<WorkRecord> get _activeJobs {
    const activeStates = {
      WorkRecordStatus.enRoute,
      WorkRecordStatus.arrived,
      WorkRecordStatus.inProgress,
      WorkRecordStatus.paused,
      WorkRecordStatus.needsReturnVisit,
    };
    final datedIds = {
      ..._attentionJobIds,
      ..._jobsForSelectedDay.map((record) => record.id),
    };
    return _sortJobs(
      _scopedJobs.where(
        (record) =>
            activeStates.contains(record.status) &&
            !datedIds.contains(record.id),
      ),
    );
  }

  List<WorkRecord> get _searchResults {
    final query = _search.text.trim().toLowerCase();
    return _sortJobs(
      _scopedJobs.where(
        (record) =>
            record.number.toLowerCase().contains(query) ||
            record.title.toLowerCase().contains(query) ||
            record.client.toLowerCase().contains(query) ||
            record.detail.toLowerCase().contains(query),
      ),
    );
  }

  OperationalAttentionQuery _attentionQueryForDay(DateTime day) =>
      OperationalAttentionQuery(
        panelId: 'job-workspace',
        module: OperationalAttentionModule.work,
        view: _view,
        access: _view == AppViewMode.admin
            ? const OperationalAttentionAccess.adminDevelopment()
            : const OperationalAttentionAccess.technicianDevelopment(),
        selectedEmployeeId: _employeeId,
        selectedDay: DateUtils.dateOnly(day),
        resourceKinds: const {OperationalAttentionResourceKind.job},
      );

  List<WorkRecord> _sortJobs(Iterable<WorkRecord> records) =>
      records.toList()..sort((a, b) {
        final first = a.scheduledStart ?? a.createdOn ?? DateTime(1970);
        final second = b.scheduledStart ?? b.createdOn ?? DateTime(1970);
        return first.compareTo(second);
      });

  void _selectDay(DateTime day) =>
      setState(() => _selectedDay = DateUtils.dateOnly(day));

  void _openDay(DateTime day) {
    final selected = DateUtils.dateOnly(day);
    _selectDay(selected);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => JobDayScreen(
          initialDay: selected,
          preferences: _preferences,
          recordsForDay: _allJobsForDay,
          attentionItemsForDay: _attentionItemsForDay,
          onOpenRecord: _openJob,
          onDismissAttention: (date, items) => _store.attentionCenter.dismiss(
            _attentionQueryForDay(date),
            items,
          ),
        ),
      ),
    );
  }

  Future<void> _createJob() async {
    final job = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => WorkJobEditor(initialDay: _selectedDay),
      ),
    );
    if (mounted && job != null) _store.addWorkRecord(job);
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context)
        .push<WorkRecordDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => WorkRecordSettingsScreen(
              workspaceId: 'jobs',
              workspaceLabel: 'Jobs',
              initial: _preferences,
            ),
          ),
        );
    if (mounted && updated != null) {
      setState(() => _fixturePreferences = updated);
    }
  }

  Future<void> _openJob(WorkRecord record) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => JobWorkspaceScreen(
          workRecord: record,
          onWorkRecordUpdated: _store.updateWorkRecord,
          permissions: widget.permissions,
        ),
      ),
    );
  }

  Future<void> _openAttentionItem(OperationalAttentionItem item) async {
    final matches = _scopedJobs.where((record) => record.id == item.sourceId);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This job is no longer available.')),
      );
      return;
    }
    await _openJob(matches.first);
  }

  void _openAttentionList(List<OperationalAttentionItem> items) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkAttentionListScreen(
          selectedDay: _selectedDay,
          items: items,
          onOpen: _openAttentionItem,
          workspaceLabel: 'Job attention',
          screenKey: const ValueKey('job-attention-list'),
          rowKeyPrefix: 'job-attention-list',
          onSettings: _openSettings,
        ),
      ),
    );
  }
}
