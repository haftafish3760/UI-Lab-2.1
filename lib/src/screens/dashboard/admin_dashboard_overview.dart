import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/operations_workspace.dart';
import 'dashboard_models.dart';
import 'today_entries.dart';
import 'today_plan.dart';

/// Company scope uses the same Plan and Entries language as employee scope.
///
/// The data and callbacks come from the Dashboard's shared record projection;
/// this widget does not keep a second set of hard-coded company records.
class AdminDashboardOverview extends StatelessWidget {
  const AdminDashboardOverview({
    super.key,
    required this.layout,
    required this.date,
    required this.data,
    required this.showOdometer,
    required this.onOpenPlan,
    required this.onPlanAction,
    required this.onOpenEntry,
    this.leading,
  });

  final OperationsWorkspaceLayout layout;
  final DateTime date;
  final DashboardDayData data;
  final bool showOdometer;
  final ValueChanged<PlanItem> onOpenPlan;
  final void Function(PlanItem item, PlanAction action) onPlanAction;
  final ValueChanged<DayEntry> onOpenEntry;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return OperationsLaneGrid(
      key: ValueKey('admin-${layout.columns}-lane-overview'),
      layout: layout,
      children: [
        ?leading,
        KeyedSubtree(
          key: const ValueKey('admin-company-schedule'),
          child: TodayPlan(
            date: date,
            items: data.plan,
            onOpen: onOpenPlan,
            onAction: onPlanAction,
          ),
        ),
        KeyedSubtree(
          key: const ValueKey('admin-company-entries'),
          child: TodayEntries(
            date: date,
            entries: data.entries,
            showOdometer: showOdometer,
            onOpen: onOpenEntry,
          ),
        ),
      ],
    );
  }
}
