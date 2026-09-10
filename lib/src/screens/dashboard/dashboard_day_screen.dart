import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../work/estimate_models.dart';
import '../work/work_job_editor.dart';
import '../work/work_models.dart';
import 'calendar_approval_screen.dart';
import 'calendar_day_header.dart';
import 'calendar_day_overview.dart';
import 'dashboard_day_settings_screen.dart';
import 'dashboard_models.dart';
import 'dashboard_record_navigation.dart';
import 'today_entries.dart';
import 'today_plan.dart';

part 'dashboard_day_record_actions.dart';

class DashboardDayScreen extends StatefulWidget {
  const DashboardDayScreen({required this.initialDay, super.key});

  final DateTime initialDay;

  @override
  State<DashboardDayScreen> createState() => _DashboardDayScreenState();
}

class _DashboardDayScreenState extends State<DashboardDayScreen> {
  static const _permissions = DashboardPermissions.development();
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    _day = DateUtils.dateOnly(widget.initialDay);
  }

  bool get _isToday => sameDashboardDay(_day, dashboardToday);
  bool get _isPast => _day.isBefore(dashboardToday) && !_isToday;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final employee = _employeeFor(scope.selectedEmployeeId);
    final companyScope = scope.view == AppViewMode.admin && employee == null;
    final contextId = _contextId(scope);
    final store = PrototypeOperationsScope.of(context);
    final data = store.dashboardDay(
      day: _day,
      contextId: contextId,
      employeeId: employee?.id,
    );
    final financialSummary = store.financialSummary(
      fromInclusive: _day,
      toExclusive: DateTime(_day.year, _day.month, _day.day + 1),
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      floatingActionButton: _dayFab(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final available = math.max(
              0,
              constraints.maxWidth - insets.horizontal,
            );
            final layout = AppLayoutEngine.workFor(
              available.toDouble(),
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: insets.copyWith(top: 12, bottom: 92),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalendarDayHeader(
                          scope: scope,
                          employee: employee,
                          onBack: () => Navigator.of(context).pop(),
                          onSettings: _openSettings,
                        ),
                        const SizedBox(height: 14),
                        _DayNavigation(
                          day: _day,
                          onPrevious: () => _shiftDay(-1),
                          onNext: () => _shiftDay(1),
                        ),
                        const SizedBox(height: 14),
                        if (data.entries.any(
                          (entry) =>
                              entry.reviewStatus ==
                              DayEntryReviewStatus.needsApproval,
                        )) ...[
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: SizedBox(
                              width: layout.laneWidth,
                              child: CalendarDayApprovals(
                                entries: data.entries,
                                onOpen: (entry) =>
                                    _reviewEntry(entry, contextId),
                              ),
                            ),
                          ),
                          SizedBox(height: layout.gap),
                        ],
                        _DayWorkspace(
                          columns: layout.columns,
                          laneWidth: layout.laneWidth,
                          gap: layout.gap,
                          children: [
                            CalendarDayMetricStrip(
                              companyScope: companyScope,
                              data: data,
                              vehicleName: dashboardVehicleById(
                                scope.selectedVehicleId,
                              ).name,
                              onVehicleDetails: () =>
                                  _showVehicleDetails(scope),
                            ),
                            if (!_isPast)
                              TodayPlan(
                                date: _day,
                                items: data.plan,
                                onOpen: _openPlan,
                                onAction: _handleDayPlanAction,
                                allowedActions: _isToday
                                    ? const {
                                        PlanAction.viewDetails,
                                        PlanAction.markArrived,
                                        PlanAction.reschedule,
                                        PlanAction.markComplete,
                                      }
                                    : const {
                                        PlanAction.viewDetails,
                                        PlanAction.reschedule,
                                      },
                              ),
                            if (!_day.isAfter(dashboardToday))
                              TodayEntries(
                                date: _day,
                                entries: data.entries,
                                showOdometer: true,
                                onOpen: (entry) => _openEntry(entry, contextId),
                              ),
                            if (!_day.isAfter(dashboardToday))
                              CalendarDayRecap(
                                companyScope: companyScope,
                                data: data,
                                financialSummary: financialSummary,
                                canViewCompanyFinancials:
                                    _permissions.canViewCompanyFinancials,
                                pendingApprovals: data.entries
                                    .where(
                                      (entry) =>
                                          entry.reviewStatus ==
                                          DayEntryReviewStatus.needsApproval,
                                    )
                                    .length,
                              ),
                          ],
                        ),
                      ],
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

  Widget? _dayFab() {
    final allowed = _isPast
        ? _permissions.canAddHistoricalEntry
        : _permissions.canAddSchedule;
    if (!allowed) return null;
    return FloatingActionButton.extended(
      key: const ValueKey('calendar-day-add-button'),
      onPressed: _showAddActions,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        _isPast
            ? 'Add entry'
            : _isToday
            ? 'Add'
            : 'Plan work',
      ),
    );
  }

  Future<void> _showAddActions() async {
    final action = await showModalBottomSheet<_DayAddAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isPast)
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Plan work'),
                subtitle: Text(operationalDateLabel(context, _day)),
                onTap: () => Navigator.pop(context, _DayAddAction.plan),
              ),
            if (!_day.isAfter(dashboardToday))
              ListTile(
                leading: const Icon(Icons.note_add_outlined),
                title: const Text('Add a day record'),
                subtitle: const Text(
                  'Work note, expense, trip, or other entry',
                ),
                onTap: () => Navigator.pop(context, _DayAddAction.entry),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _DayAddAction.plan) {
      await _createScheduledJob();
      return;
    }
    if (await DashboardRecordNavigation.openStoredDayNoteEditor(
      context,
      _day,
    )) {
      return;
    }
    if (!mounted) return;
    final title = await _askForTitle('Add a day record');
    if (!mounted || title == null) return;
    final scope = OperationalScope.of(context);
    final employee = _employeeFor(scope.selectedEmployeeId);
    final contextId = _contextId(scope);
    final store = PrototypeOperationsScope.of(context);
    final current = store.dashboardDay(
      day: _day,
      contextId: contextId,
      employeeId: employee?.id,
    );
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.now());
    store.updateDashboardDay(
      day: _day,
      contextId: contextId,
      data: DashboardDayData(
        plan: current.plan,
        entries: [
          ...current.entries,
          DayEntry(
            id: 'day-record-${DateTime.now().microsecondsSinceEpoch}',
            time: time,
            title: title,
            detail: 'Manually added day record',
            kind: DayEntryKind.note,
            color: const Color(0xFF65727A),
          ),
        ],
      ),
    );
  }

  Future<String?> _askForTitle(String title) async {
    var value = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Description'),
          onChanged: (next) => value = next,
          onSubmitted: (next) {
            final trimmed = next.trim();
            if (trimmed.isNotEmpty) Navigator.pop(context, trimmed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) Navigator.pop(context, trimmed);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DashboardDaySettingsScreen(day: _day),
    ),
  );

  Future<void> _showVehicleDetails(OperationalScopeController scope) async {
    final vehicle = dashboardVehicleById(scope.selectedVehicleId);
    final confirmed = scope.confirmedOdometerTenthsFor(vehicle.id);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vehicle.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicle.description),
            const SizedBox(height: 14),
            Text(
              'Latest confirmed odometer · '
              '${formatOdometerTenths(confirmed)} mi',
            ),
            const SizedBox(height: 6),
            const Text(
              'Distance is unavailable because this day does not have both '
              'a starting and an ending odometer record.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shiftDay(int amount) => setState(
    () => _day = DateUtils.dateOnly(_day.add(Duration(days: amount))),
  );

  EmployeeStatus? _employeeFor(String? id) {
    if (id == null) return null;
    for (final employee in demoEmployees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  String _contextId(OperationalScopeController scope) {
    return scope.view == AppViewMode.admin
        ? scope.selectedEmployeeId ?? 'company'
        : scope.selectedEmployeeId ?? 'technician';
  }
}

class _DayWorkspace extends StatelessWidget {
  const _DayWorkspace({
    required this.columns,
    required this.laneWidth,
    required this.gap,
    required this.children,
  });

  final int columns;
  final double laneWidth;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) SizedBox(height: gap),
          ],
        ],
      );
    }
    return Wrap(
      key: ValueKey('calendar-day-$columns-column-layout'),
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final child in children) SizedBox(width: laneWidth, child: child),
      ],
    );
  }
}

class _DayNavigation extends StatelessWidget {
  const _DayNavigation({
    required this.day,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime day;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: onPrevious,
        tooltip: 'Previous day',
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: Text(
          operationalDateLabel(context, day),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      IconButton(
        onPressed: onNext,
        tooltip: 'Next day',
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );
}

enum _DayAddAction { plan, entry }
