import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme/app_theme.dart';

class DashboardCalendar extends StatefulWidget {
  const DashboardCalendar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  State<DashboardCalendar> createState() => _DashboardCalendarState();
}

class _DashboardCalendarState extends State<DashboardCalendar> {
  late DateTime _focusedDay;
  var _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selected;
  }

  @override
  void didUpdateWidget(covariant DashboardCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDay(oldWidget.selected, widget.selected)) {
      _focusedDay = widget.selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        key: const ValueKey('dashboard-calendar'),
        decoration: BoxDecoration(
          color: colors.calendarSurface,
          border: Border.all(color: colors.border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _CalendarViewSelector(
              format: _format,
              onChanged: (format) => setState(() => _format = format),
            ),
            Align(
              child: SizedBox(
                width: constraints.maxWidth.floorToDouble(),
                child: TableCalendar<void>(
                  key: const ValueKey('calendar-grid'),
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2040, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _format,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.week: 'Week',
                  },
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  sixWeekMonthsEnforced: false,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  rowHeight: _rowHeightFor(constraints.maxWidth),
                  daysOfWeekHeight: 26,
                  selectedDayPredicate: (day) => _sameDay(day, widget.selected),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextFormatter: (day, locale) => _monthLabel(day),
                    titleTextStyle: TextStyle(
                      color: colors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left_rounded,
                      color: colors.ink,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.ink,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: _weekdayStyle(colors),
                    weekendStyle: _weekdayStyle(colors),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    cellMargin: EdgeInsets.zero,
                    cellPadding: EdgeInsets.zero,
                    tablePadding: EdgeInsets.zero,
                    tableBorder: TableBorder(
                      horizontalInside: _calendarBorder(colors),
                      verticalInside: _calendarBorder(colors),
                      top: _calendarBorder(colors),
                      bottom: _calendarBorder(colors),
                      left: _calendarBorder(colors),
                      right: _calendarBorder(colors),
                    ),
                    markersMaxCount: 0,
                    markerSize: 0,
                    todayDecoration: BoxDecoration(),
                    selectedDecoration: BoxDecoration(),
                    defaultDecoration: BoxDecoration(),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                    widget.onSelected(selectedDay);
                  },
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  calendarBuilders: CalendarBuilders<void>(
                    defaultBuilder: _dayBuilder,
                    todayBuilder: _dayBuilder,
                    selectedBuilder: _dayBuilder,
                    outsideBuilder: _outsideDayBuilder,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _dayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    return _CalendarDay(
      day: day,
      selected: _sameDay(day, widget.selected),
      current: _sameDay(day, DateTime.now()),
      inMonth: day.month == focusedDay.month,
      count: _countFor(day),
    );
  }

  Widget? _outsideDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return _CalendarDay(
      day: day,
      selected: _sameDay(day, widget.selected),
      current: _sameDay(day, DateTime.now()),
      inMonth: false,
      count: 0,
    );
  }

  double _rowHeightFor(double width) {
    if (_format == CalendarFormat.week) return 62;
    if (width >= 390) return 60;
    if (width >= 350) return 56;
    return 52;
  }
}

class _CalendarViewSelector extends StatelessWidget {
  const _CalendarViewSelector({required this.format, required this.onChanged});

  final CalendarFormat format;
  final ValueChanged<CalendarFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    final nextFormat = format == CalendarFormat.month
        ? CalendarFormat.week
        : CalendarFormat.month;
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        key: const ValueKey('calendar-view-selector'),
        onPressed: () => onChanged(nextFormat),
        style: TextButton.styleFrom(
          foregroundColor: colors.ink,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(
          nextFormat == CalendarFormat.week ? 'View week' : 'View month',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.selected,
    required this.current,
    required this.inMonth,
    required this.count,
  });

  final DateTime day;
  final bool selected;
  final bool current;
  final bool inMonth;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    final selectedInk =
        ThemeData.estimateBrightnessForColor(colors.plan) == Brightness.dark
        ? Colors.white
        : const Color(0xFF081018);
    final badgeInk =
        ThemeData.estimateBrightnessForColor(colors.entries) == Brightness.dark
        ? Colors.white
        : const Color(0xFF07130F);
    return Semantics(
      key: ValueKey('calendar-day-${day.year}-${day.month}-${day.day}'),
      label:
          '${day.month}/${day.day}/${day.year}, '
          '${count == 1 ? '1 entry' : '$count entries'}',
      selected: selected,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: selected
              ? colors.plan
              : current
              ? colors.entriesSurface
              : inMonth
              ? Colors.transparent
              : colors.surfaceMuted.withValues(alpha: .48),
          border: current && !selected
              ? Border.all(color: colors.entries, width: 1.2)
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Text(
                '${day.day}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? selectedInk
                      : current
                      ? colors.ink
                      : inMonth
                      ? colors.ink
                      : colors.inkMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (count > 0)
              PositionedDirectional(
                end: 3,
                bottom: 3,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: colors.entries,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: .8),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: TextStyle(
                      color: badgeInk,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _monthLabel(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.year}';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

BorderSide _calendarBorder(DashboardColors colors) =>
    BorderSide(color: colors.border.withValues(alpha: .72), width: .7);

TextStyle _weekdayStyle(DashboardColors colors) =>
    TextStyle(color: colors.inkMuted, fontWeight: FontWeight.w800);

int _countFor(DateTime day) {
  if (day.day == 1) return 7;
  if (day.day == 2) return 3;
  if (day.day == 4) return 2;
  if (day.day == 8) return 5;
  return 0;
}
