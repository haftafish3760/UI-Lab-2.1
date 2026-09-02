import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/operational_attention.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_attention_panel.dart';
import '../../shared/operational_scope.dart';
import '../../shared/operations_workspace.dart';
import 'active_vehicle_header.dart';
import 'active_workday_overview.dart';
import 'dashboard_add_actions_screen.dart';
import 'dashboard_attention_screen.dart';
import 'dashboard_backdrop.dart';
import 'dashboard_calendar.dart';
import 'dashboard_date_heading.dart';
import 'dashboard_day_screen.dart';
import 'dashboard_models.dart';
import 'dashboard_record_navigation.dart';
import 'dashboard_settings_screen.dart';
import 'dashboard_workday_models.dart';
import 'employee_status_strip.dart';
import '../expenses/expense_editor_screen.dart';
import '../expenses/expense_detail_screen.dart';
import '../expenses/expense_models.dart';
import '../expenses/expense_permissions.dart';
import '../expenses/receipt_intake_screen.dart';
import '../inventory/stock_count_screen.dart';
import '../work/estimate_detail_screen.dart';
import '../work/estimate_editor_screen.dart';
import '../work/estimate_models.dart';
import '../work/invoice_detail_screen.dart';
import '../work/invoice_editor_screen.dart';
import '../work/invoice_permissions.dart';
import '../work/job_workspace_screen.dart';
import '../work/work_job_editor.dart';
import '../work/work_models.dart';
import 'today_entries.dart';
import 'today_plan.dart';
import 'start_workday_screen.dart';
import 'workday_actions_screen.dart';

part 'dashboard_screen_actions.dart';
part 'dashboard_attention_actions.dart';
part 'dashboard_projection_actions.dart';
part 'dashboard_end_workday_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _permissions = DashboardPermissions.development();

  var _selectedDate = dashboardToday;
  DashboardWorkdaySession? _workday;
  var _enabledWorkdayActions = Set<DashboardWorkdayAction>.of(
    defaultDashboardWorkdayActions,
  );

  DashboardDayData _dayDataFor(DateTime day, EmployeeStatus? employee) {
    final scope = OperationalScope.of(context);
    return PrototypeOperationsScope.of(context).dashboardDay(
      day: day,
      contextId: _dashboardContextId(scope),
      employeeId: employee?.id,
    );
  }

  DashboardDayData _dayData(EmployeeStatus? employee) =>
      _dayDataFor(_selectedDate, employee);

  void _saveDay(DateTime day, DashboardDayData data) {
    final scope = OperationalScope.of(context);
    PrototypeOperationsScope.of(context).updateDashboardDay(
      day: day,
      contextId: _dashboardContextId(scope),
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final store = PrototypeOperationsScope.of(context);
    final employee = _employeeFor(scope.selectedEmployeeId);
    final attentionQuery = _dashboardAttentionQuery(scope);
    final attentionItems = store.attentionCenter.itemsFor(attentionQuery);
    final showAttention = store.attentionCenter.shouldShow(
      attentionQuery,
      attentionItems,
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: DashboardBackdrop(
        child: _DashboardBody(
          view: scope.view,
          selectedDate: _selectedDate,
          employee: employee,
          data: _dayData(employee),
          showOdometer: false,
          onViewChanged: scope.setView,
          onDateSelected: _openCalendarDay,
          onEmployeeSelected: (value) => scope.selectEmployee(value.id),
          onCompanyOverview: () => scope.selectEmployee(null),
          workday:
              scope.view == AppViewMode.technician &&
                  sameDashboardDay(_selectedDate, dashboardToday)
              ? _workday
              : null,
          onStartWorkday: _startWorkday,
          onSettings: _openDashboardSettings,
          onReturnToToday: () => setState(() => _selectedDate = dashboardToday),
          attentionItems: attentionItems,
          showAttention: showAttention,
          onOpenAttention: _openAttentionItem,
          onOpenAllAttention: () => _openAttentionList(attentionQuery),
          onDismissAttention: () =>
              store.attentionCenter.dismiss(attentionQuery, attentionItems),
          onOpenPlan: _openPlan,
          onPlanAction: _handlePlanAction,
          onOpenEntry: _openEntry,
          entryCountForDay: (day) => _dayDataFor(day, employee).entries.length,
          needsApprovalForDay: (day) => _dayDataFor(day, employee).entries.any(
            (entry) => entry.reviewStatus == DayEntryReviewStatus.needsApproval,
          ),
        ),
      ),
      floatingActionButton:
          _workday != null && sameDashboardDay(_selectedDate, dashboardToday)
          ? FloatingActionButton.extended(
              key: const ValueKey('dashboard-workday-actions-fab'),
              heroTag: 'dashboard-workday-actions-fab',
              onPressed: _openWorkdayActions,
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Actions'),
            )
          : _canAdd
          ? FloatingActionButton.extended(
              key: const ValueKey('dashboard-add-button'),
              heroTag: 'dashboard-add-fab',
              onPressed: _showAddActions,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }

  bool get _canAdd => _availableAddActions.isNotEmpty;

  List<DashboardAddAction> get _availableAddActions => [
    if (_permissions.canAddSchedule && _permissions.canCreateJob)
      DashboardAddAction.schedule,
    if (_permissions.canCreateEstimate) DashboardAddAction.estimate,
    if (_permissions.canCreateInvoice) DashboardAddAction.invoice,
    if (_permissions.canRecordExpense) ...[
      DashboardAddAction.expense,
      DashboardAddAction.fuel,
    ],
    if (_permissions.canAddReceipt) DashboardAddAction.receipt,
    if (_permissions.canAddHistoricalEntry &&
        !_selectedDate.isAfter(dashboardToday))
      DashboardAddAction.dayRecord,
  ];

  EmployeeStatus? _employeeFor(String? id) {
    if (id == null) return null;
    for (final employee in demoEmployees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  void _openPlan(PlanItem item) {
    if (!_permissions.canViewSchedule) return;
    DashboardRecordNavigation.openPlan(
      context,
      item,
      onCreateJob: _createJobFromAttentionEstimate,
    );
  }

  Future<void> _openEntry(DayEntry entry) async {
    if (!_permissions.canViewEntryDetails) return;
    await DashboardRecordNavigation.openEntry(
      context,
      entry,
      date: _selectedDate,
      showOdometer: false,
      onCreateJob: _createJobFromAttentionEstimate,
    );
  }

  void _openCalendarDay(DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DashboardDayScreen(initialDay: day),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.view,
    required this.selectedDate,
    required this.employee,
    required this.data,
    required this.showOdometer,
    required this.onViewChanged,
    required this.onDateSelected,
    required this.onEmployeeSelected,
    required this.onCompanyOverview,
    required this.workday,
    required this.onStartWorkday,
    required this.onSettings,
    required this.onReturnToToday,
    required this.attentionItems,
    required this.showAttention,
    required this.onOpenAttention,
    required this.onOpenAllAttention,
    required this.onDismissAttention,
    required this.onOpenPlan,
    required this.onPlanAction,
    required this.onOpenEntry,
    required this.entryCountForDay,
    required this.needsApprovalForDay,
  });

  final AppViewMode view;
  final DateTime selectedDate;
  final EmployeeStatus? employee;
  final DashboardDayData data;
  final bool showOdometer;
  final ValueChanged<AppViewMode> onViewChanged;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<EmployeeStatus> onEmployeeSelected;
  final VoidCallback onCompanyOverview;
  final DashboardWorkdaySession? workday;
  final VoidCallback onStartWorkday;
  final VoidCallback onSettings;
  final VoidCallback onReturnToToday;
  final List<OperationalAttentionItem> attentionItems;
  final bool showAttention;
  final ValueChanged<OperationalAttentionItem> onOpenAttention;
  final VoidCallback onOpenAllAttention;
  final VoidCallback onDismissAttention;
  final ValueChanged<PlanItem> onOpenPlan;
  final void Function(PlanItem item, PlanAction action) onPlanAction;
  final ValueChanged<DayEntry> onOpenEntry;
  final int Function(DateTime day) entryCountForDay;
  final bool Function(DateTime day) needsApprovalForDay;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        final pageInsets = AppLayoutEngine.pageInsetsFor(
          bodyConstraints.maxWidth,
        );
        final availableWidth = math.max(
          0,
          bodyConstraints.maxWidth - pageInsets.horizontal,
        );
        final layout = AppLayoutEngine.dashboardOperationsFor(
          availableWidth.toDouble(),
          textScaler: scaler,
        );
        final type = AppLayoutEngine.typographyFor(layout.workspaceWidth);
        final attentionPanel = OperationalAttentionPanel(
          key: const ValueKey('dashboard-needs-attention'),
          items: attentionItems,
          rowKeyFor: (item) => ValueKey('dashboard-attention-${item.sourceId}'),
          onOpen: onOpenAttention,
          onOpenAll: onOpenAllAttention,
          onDismiss: onDismissAttention,
        );
        final employeeStrip = view == AppViewMode.admin
            ? EmployeeStatusStrip(
                employees: demoEmployees,
                selectedId: employee?.id,
                onSelected: onEmployeeSelected,
              )
            : null;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: pageInsets.copyWith(top: 12, bottom: 92),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: availableWidth.toDouble(),
                  child: OperationsWorkspaceFrame(
                    layout: layout,
                    primaryContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ActiveVehicleHeader(
                          view: view,
                          onViewChanged: onViewChanged,
                          activeEmployee: employee,
                          onEmployeeSelected: onEmployeeSelected,
                          onCompanyOverview: onCompanyOverview,
                          onStartWorkday: onStartWorkday,
                          onSettings: onSettings,
                          showPrimaryAction:
                              view == AppViewMode.technician && workday == null,
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            width: layout.laneWidth,
                            child: DashboardDateHeading(
                              type: type,
                              date: selectedDate,
                              onReturnToToday: onReturnToToday,
                            ),
                          ),
                        ),
                        if (employeeStrip != null) ...[
                          const SizedBox(height: 12),
                          employeeStrip,
                        ],
                        const SizedBox(height: 12),
                        if (workday != null) ...[
                          ActiveWorkdayOverview(session: workday!),
                          const SizedBox(height: 12),
                        ],
                        _DashboardLanes(
                          layout: layout,
                          date: selectedDate,
                          data: data,
                          showOdometer: showOdometer,
                          onOpenPlan: onOpenPlan,
                          onPlanAction: onPlanAction,
                          onOpenEntry: onOpenEntry,
                          attention: showAttention ? attentionPanel : null,
                          companyOverview:
                              view == AppViewMode.admin && employee == null,
                          calendar: DashboardCalendar(
                            compact: layout.columns == 1,
                            maximumWidth: layout.laneWidth,
                            selectedDay: selectedDate,
                            onDaySelected: onDateSelected,
                            entryCountForDay: entryCountForDay,
                            needsApprovalForDay: needsApprovalForDay,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardLanes extends StatelessWidget {
  const _DashboardLanes({
    required this.layout,
    required this.date,
    required this.data,
    required this.showOdometer,
    required this.onOpenPlan,
    required this.onPlanAction,
    required this.onOpenEntry,
    required this.attention,
    required this.calendar,
    required this.companyOverview,
  });

  final OperationsWorkspaceLayout layout;
  final DateTime date;
  final DashboardDayData data;
  final bool showOdometer;
  final ValueChanged<PlanItem> onOpenPlan;
  final void Function(PlanItem item, PlanAction action) onPlanAction;
  final ValueChanged<DayEntry> onOpenEntry;
  final Widget? attention;
  final Widget calendar;
  final bool companyOverview;

  Widget get plan => KeyedSubtree(
    key: companyOverview
        ? const ValueKey('admin-company-schedule')
        : const ValueKey('dashboard-technician-schedule'),
    child: TodayPlan(
      date: date,
      items: data.plan,
      onOpen: onOpenPlan,
      onAction: onPlanAction,
    ),
  );
  Widget get entries => KeyedSubtree(
    key: companyOverview
        ? const ValueKey('admin-company-entries')
        : const ValueKey('dashboard-technician-entries'),
    child: TodayEntries(
      date: date,
      entries: data.entries,
      showOdometer: showOdometer,
      onOpen: onOpenEntry,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final priorityLane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (attention case final panel?) ...[
          panel,
          SizedBox(height: layout.gap),
        ],
        plan,
      ],
    );
    final calendarLane = KeyedSubtree(
      key: companyOverview
          ? const ValueKey('admin-company-calendar')
          : const ValueKey('dashboard-technician-calendar'),
      child: calendar,
    );
    final lanes = switch (layout.columns) {
      1 => [priorityLane, entries, calendarLane],
      2 => [
        priorityLane,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            entries,
            SizedBox(height: layout.gap),
            calendarLane,
          ],
        ),
      ],
      _ => [priorityLane, entries, calendarLane],
    };
    return KeyedSubtree(
      key: ValueKey('dashboard-${layout.columns}-lane-row'),
      child: OperationsLaneGrid(layout: layout, children: lanes),
    );
  }
}
