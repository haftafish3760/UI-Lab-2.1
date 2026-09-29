import '../work/quote_detail_screen.dart';
import 'dart:math' as math;
import '../../shared/screen_layout_configuration.dart';
import '../../shared/screen_layout_edit_controls.dart';
import '../../shared/screen_widget_board.dart';
import '../../shell/app_menu_scope.dart';
import 'admin_widget_catalog.dart';
import 'admin_business_widgets.dart';
import '../expenses/reports_screen.dart';
import '../../data/workday/workday_persistence_session.dart';
import '../../data/workday/workday_read_models.dart';
import '../../data/workday/stored_workday_record.dart';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations_extension.dart';

import '../../data/operational_attention.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/app_preferences.dart';
import '../../theme/app_theme.dart';
import '../../shared/operational_scope.dart';
import '../../shared/operations_workspace.dart';
import 'active_vehicle_header.dart';
import 'dashboard_view_selector.dart';
import 'admin_dashboard_overview.dart';
import 'admin_employee_overview.dart';
import '../../shared/calendar_width_section.dart';
import 'active_workday_overview.dart';
import 'dashboard_add_actions_screen.dart';
import 'dashboard_attention_screen.dart';
import 'dashboard_backdrop.dart';
import 'dashboard_calendar.dart';
import 'dashboard_date_heading.dart';
import 'dashboard_employee_status_summary.dart';
import 'dashboard_day_screen.dart';
import 'dashboard_models.dart';
import 'dashboard_record_navigation.dart';
import 'dashboard_settings_screen.dart';
import 'dashboard_summary_strip.dart';
import '../work/payments_screen.dart';
import '../expenses/expenses_screen.dart';
import 'dashboard_workday_models.dart';
import 'dashboard_end_workday_dialog.dart';
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
part 'dashboard_plan_actions.dart';
part 'dashboard_manual_entry_actions.dart';
part 'dashboard_body_layout.dart';
part 'admin_dashboard_workspace.dart';
part 'dashboard_command_bar.dart';
part 'dashboard_attention_actions.dart';
part 'dashboard_projection_actions.dart';

part 'dashboard_workday_persistence.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _permissions = DashboardPermissions.development();

  var _selectedDate = dashboardToday;
  DashboardWorkdaySession? _fixtureWorkday;
  var _fixtureEnabledWorkdayActions = Set<DashboardWorkdayAction>.of(
    defaultDashboardWorkdayActions,
  );

  Set<DashboardWorkdayAction> get _enabledWorkdayActions {
    final names = AppPreferencesScope.maybeOf(context)?.dashboardActions;
    return names == null
        ? _fixtureEnabledWorkdayActions
        : names.map(DashboardWorkdayAction.values.byName).toSet();
  }

  set _enabledWorkdayActions(Set<DashboardWorkdayAction> actions) =>
      _fixtureEnabledWorkdayActions = actions;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            AppLayoutEngine.dashboardOperationsFor(
              constraints.maxWidth -
                  AppLayoutEngine.pageInsetsFor(
                    constraints.maxWidth,
                  ).horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            ).columns >
            1;
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
              onReturnToToday: () =>
                  setState(() => _selectedDate = dashboardToday),
              attentionItems: attentionItems,
              onOpenAllAttention: () => _openAttentionList(attentionQuery),
              onOpenAttention: _openAttentionItem,
              onOpenPlan: _openPlan,
              onPlanAction: _handlePlanAction,
              onOpenEntry: _openEntry,
              entryCountForDay: (day) =>
                  _dayDataFor(day, employee).entries.length,
              needsApprovalForDay: (day) =>
                  _dayDataFor(day, employee).entries.any(
                    (entry) =>
                        entry.reviewStatus ==
                        DayEntryReviewStatus.needsApproval,
                  ),
              onOpenActions:
                  scope.view == AppViewMode.technician && _workday != null
                  ? _openWorkdayActions
                  : _canAdd
                  ? _showAddActions
                  : null,
              onEndWorkday: () async {
                final stored = _storedActiveWorkday;
                if (stored != null) {
                  await _endStoredWorkday(stored);
                } else {
                  await _endWorkday();
                }
              },
            ),
          ),
          floatingActionButton: wide
              ? null
              : _workday != null &&
                    sameDashboardDay(_selectedDate, dashboardToday)
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
      },
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
