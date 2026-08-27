import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DashboardCalendar extends StatefulWidget {
  const DashboardCalendar({super.key, this.forceMonth = false});

  final bool forceMonth;

  @override
  State<DashboardCalendar> createState() => _DashboardCalendarState();
}

class _DashboardCalendarState extends State<DashboardCalendar> {
  static const _entryCounts = <int, int>{4: 1, 11: 2, 25: 3};
  var _focusedMonth = DateTime(2026, 8, 25);
  DateTime? _selectedDay = DateTime(2026, 8, 25);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            !widget.forceMonth && MediaQuery.sizeOf(context).width < 600;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF4A5153),
            border: Border.all(color: const Color(0xFF929B99), width: 1.2),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x240E2B23),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MonthHeader(
                  compact: compact,
                  label: _monthLabel(_focusedMonth),
                  onPrevious: () => _changeMonth(compact ? -7 : -1),
                  onNext: () => _changeMonth(compact ? 7 : 1),
                ),
                const _WeekdayHeader(),
                if (compact) _buildWeek() else _buildMonth(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: Color(0xFF79F49A),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Badges show records attached to each day.',
                              style: TextStyle(color: Color(0xFFE2E7E5)),
                            ),
                          ),
                        ],
                      ),
                      if (compact) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _openMonthView,
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: const Text('View full month'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFB8C6C2),
                              width: 1.2,
                            ),
                            minimumSize: const Size.fromHeight(48),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeek() {
    final weekStart = _focusedMonth.subtract(
      Duration(days: _focusedMonth.weekday % 7),
    );
    return SizedBox(
      height: 82,
      child: Row(
        children: [
          for (var index = 0; index < 7; index++)
            Expanded(child: _dayCell(weekStart.add(Duration(days: index)))),
        ],
      ),
    );
  }

  Widget _buildMonth() {
    final first = _firstDayForMonth(_focusedMonth);
    return GridView.builder(
      itemCount: 42,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 70,
      ),
      itemBuilder: (context, index) =>
          _dayCell(first.add(Duration(days: index))),
    );
  }

  Widget _dayCell(DateTime day) {
    return _DayCell(
      day: day,
      selected: _sameDay(day, _selectedDay),
      today: _sameDay(day, DateTime(2026, 8, 25)),
      outsideMonth: day.month != _focusedMonth.month,
      badge: day.month == 8 ? _entryCounts[day.day] : null,
      onTap: () => setState(() => _selectedDay = day),
    );
  }

  void _changeMonth(int amount) {
    setState(() {
      _focusedMonth = amount.abs() == 7
          ? _focusedMonth.add(Duration(days: amount))
          : DateTime(_focusedMonth.year, _focusedMonth.month + amount);
      _selectedDay = null;
    });
  }

  Future<void> _openMonthView() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: const Text('Calendar')),
          body: const SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: DashboardCalendar(forceMonth: true),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.compact,
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final bool compact;
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            tooltip: compact ? 'Previous week' : 'Previous month',
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: compact ? 'Next week' : 'Next month',
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFF929B99)),
        ),
      ),
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.outsideMonth,
    required this.badge,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final bool outsideMonth;
  final int? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${day.month}/${day.day}/${day.year}'
          '${badge == null ? '' : ', $badge entries'}',
      child: Material(
        color: selected
            ? AppColors.green
            : today
            ? const Color(0x3347D977)
            : outsideMonth
            ? const Color(0x22101517)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFF929B99)),
                bottom: BorderSide(color: Color(0xFF929B99)),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 7,
                  top: 7,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF07100A)
                          : outsideMonth
                          ? const Color(0xFFB7C0BE)
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
                if (badge case final count?)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: _EntryBadge(count: count),
                  ),
                if (today && !selected)
                  const Positioned(
                    left: 7,
                    bottom: 7,
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        color: Color(0xFF79F49A),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryBadge extends StatelessWidget {
  const _EntryBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF65B8FF),
        border: Border.all(color: const Color(0xFF07100A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Color(0xFF07100A),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

DateTime _firstDayForMonth(DateTime month) {
  final first = DateTime(month.year, month.month);
  return first.subtract(Duration(days: first.weekday % 7));
}

bool _sameDay(DateTime day, DateTime? other) =>
    other != null &&
    day.year == other.year &&
    day.month == other.month &&
    day.day == other.day;

String _monthLabel(DateTime month) {
  const names = [
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
  return '${names[month.month - 1]} ${month.year}';
}
