import 'package:flutter/material.dart';

import '../../l10n/app_localizations_extension.dart';
import '../layout/app_layout_engine.dart';
import 'module_calendar_day_cell.dart';
import 'calendar_panel_surface.dart';

export 'module_calendar_day_cell.dart' show CalendarRecordKind;

class WorkMonthCalendar extends StatefulWidget {
  const WorkMonthCalendar({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.entryCountForDay,
    this.needsApprovalForDay,
    this.recordKind = CalendarRecordKind.record,
    this.initiallyWeek = false,
    this.maximumWidth = AppLayoutEngine.singleMaximum,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final int Function(DateTime day)? entryCountForDay;
  final bool Function(DateTime day)? needsApprovalForDay;
  final CalendarRecordKind recordKind;
  final bool initiallyWeek;
  final double maximumWidth;

  @override
  State<WorkMonthCalendar> createState() => _WorkMonthCalendarState();
}

class _WorkMonthCalendarState extends State<WorkMonthCalendar> {
  late DateTime _focusedMonth;
  late DateTime _focusedDay;
  late var _showWeek = widget.initiallyWeek;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDay;
    _focusedMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  @override
  void didUpdateWidget(covariant WorkMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDay(widget.selectedDay, oldWidget.selectedDay)) {
      _focusedDay = widget.selectedDay;
      _focusedMonth = DateTime(
        widget.selectedDay.year,
        widget.selectedDay.month,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          key: const ValueKey('shared-calendar-width-frame'),
          width: widget.maximumWidth
              .clamp(0.0, constraints.maxWidth)
              .toDouble(),
          child: LayoutBuilder(builder: _buildCalendar),
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, BoxConstraints constraints) {
    final rowHeight = AppLayoutEngine.monthCalendarRowHeightFor(
      MediaQuery.textScalerOf(context),
    );
    final dayWidth = constraints.maxWidth / 7;
    final first = _showWeek
        ? _firstVisibleDay(_focusedDay)
        : _firstVisibleDay(_focusedMonth);
    final itemCount = _showWeek ? 7 : 42;
    final colors = Theme.of(context).colorScheme;
    final materialCopy = MaterialLocalizations.of(context);
    return DecoratedBox(
      key: const ValueKey('work-5-7-calendar'),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: CalendarPanelSurface.gridLine(context),
          width: 1.5,
        ),
      ),
      child: CalendarPanelSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CalendarHeader(
              label: _showWeek
                  ? _weekLabel(materialCopy, first)
                  : materialCopy.formatMonthYear(_focusedMonth),
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onTitle: _pickMonth,
              showingWeek: _showWeek,
              onToggleView: () => setState(() => _showWeek = !_showWeek),
            ),
            const _WeekdayHeader(),
            AnimatedSize(
              key: const ValueKey('calendar-period-grid-transition'),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: KeyedSubtree(
                key: _showWeek
                    ? const ValueKey('inline-week-grid')
                    : const ValueKey('inline-month-grid'),
                child: GridView.builder(
                  key: const ValueKey('work-5-7-calendar-grid'),
                  itemCount: itemCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: dayWidth / rowHeight,
                  ),
                  itemBuilder: (context, index) {
                    final day = first.add(Duration(days: index));
                    final outsideMonth =
                        !_showWeek && day.month != _focusedMonth.month;
                    final entryCount = outsideMonth
                        ? 0
                        : widget.entryCountForDay?.call(day) ?? 0;
                    return ModuleCalendarDayCell(
                      day: day,
                      selected: _sameDay(day, widget.selectedDay),
                      today: _sameDay(day, DateTime.now()),
                      outsideMonth: outsideMonth,
                      entryCount: entryCount,
                      needsApproval:
                          !outsideMonth &&
                          (widget.needsApprovalForDay?.call(day) ?? false),
                      recordKind: widget.recordKind,
                      isLastColumn: index % 7 == 6,
                      isLastRow: index >= itemCount - 7,
                      onTap: () {
                        setState(() {
                          _focusedDay = day;
                          _focusedMonth = DateTime(day.year, day.month);
                        });
                        widget.onDaySelected(day);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeMonth(int amount) {
    setState(() {
      if (_showWeek) {
        final next = _focusedDay.add(Duration(days: amount * 7));
        _focusedDay = next;
        _focusedMonth = DateTime(next.year, next.month);
      } else {
        final nextMonth = DateTime(
          _focusedMonth.year,
          _focusedMonth.month + amount,
        );
        final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final focusedDate = _focusedDay.day > lastDay
            ? lastDay
            : _focusedDay.day;
        _focusedMonth = nextMonth;
        _focusedDay = DateTime(nextMonth.year, nextMonth.month, focusedDate);
      }
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDay,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
      helpText: context.l10n.calendarChooseWorkDate,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _focusedDay = picked;
      _focusedMonth = DateTime(picked.year, picked.month);
    });
    widget.onDaySelected(picked);
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onTitle,
    required this.showingWeek,
    required this.onToggleView,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTitle;
  final bool showingWeek;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final copy = context.l10n;
    return ColoredBox(
      color: colors.surfaceContainerHigh,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: showingWeek
                  ? copy.calendarPreviousWeek
                  : copy.calendarPreviousMonth,
              color: colors.onSurface,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: TextButton(
                onPressed: onTitle,
                style: TextButton.styleFrom(foregroundColor: colors.onSurface),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('calendar-view-toggle'),
              onPressed: onToggleView,
              child: Text(
                showingWeek ? copy.calendarMonthView : copy.calendarWeekView,
              ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: showingWeek
                  ? copy.calendarNextWeek
                  : copy.calendarNextMonth,
              color: colors.onSurface,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final copy = context.l10n;
    final labels = [
      copy.calendarMondayShort,
      copy.calendarTuesdayShort,
      copy.calendarWednesdayShort,
      copy.calendarThursdayShort,
      copy.calendarFridayShort,
      copy.calendarSaturdayShort,
      copy.calendarSundayShort,
    ];
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.symmetric(
          horizontal: BorderSide(color: colors.outline, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

DateTime _firstVisibleDay(DateTime month) {
  final first = DateTime(month.year, month.month, month.day);
  return first.subtract(Duration(days: first.weekday - DateTime.monday));
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _weekLabel(MaterialLocalizations copy, DateTime first) {
  final last = first.add(const Duration(days: 6));
  return '${copy.formatShortMonthDay(first)} – ${copy.formatShortDate(last)}';
}
