import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/module_month_calendar.dart';
import 'dashboard_models.dart';

/// Dashboard projection of the one shared calendar system.
///
/// The dashboard owns its record counts and navigation target. The calendar
/// owns only month/week presentation and date selection.
class DashboardCalendar extends StatelessWidget {
  const DashboardCalendar({
    super.key,
    this.compact = false,
    this.selectedDay,
    this.onDaySelected,
    this.entryCountForDay,
    this.needsApprovalForDay,
    this.maximumWidth = AppLayoutEngine.singleMaximum,
  });

  final bool compact;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final int Function(DateTime day)? entryCountForDay;
  final bool Function(DateTime day)? needsApprovalForDay;
  final double maximumWidth;

  @override
  Widget build(BuildContext context) {
    return WorkMonthCalendar(
      selectedDay: selectedDay ?? dashboardToday,
      onDaySelected: onDaySelected ?? _ignoreDay,
      entryCountForDay: entryCountForDay,
      needsApprovalForDay: needsApprovalForDay,
      recordKind: CalendarRecordKind.dashboardEntry,
      initiallyWeek: false,
      maximumWidth: maximumWidth,
    );
  }

  static void _ignoreDay(DateTime _) {}
}
