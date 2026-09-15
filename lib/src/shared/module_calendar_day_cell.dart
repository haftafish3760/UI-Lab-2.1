import 'package:flutter/material.dart';

import '../../l10n/app_localizations_extension.dart';

import '../theme/app_semantic_colors.dart';
import 'calendar_panel_surface.dart';

enum CalendarRecordKind {
  record,
  dashboardEntry,
  workRecord,
  job,
  estimate,
  invoice,
  payment,
  expense,
  inventoryRecord;

  String localizedLabel(BuildContext context, int count) {
    final copy = context.l10n;
    final singular = count == 1;
    return switch (this) {
      CalendarRecordKind.record =>
        singular ? copy.calendarRecordSingular : copy.calendarRecordPlural,
      CalendarRecordKind.dashboardEntry =>
        singular
            ? copy.calendarDashboardEntrySingular
            : copy.calendarDashboardEntryPlural,
      CalendarRecordKind.workRecord =>
        singular
            ? copy.calendarWorkRecordSingular
            : copy.calendarWorkRecordPlural,
      CalendarRecordKind.job =>
        singular ? copy.calendarJobSingular : copy.calendarJobPlural,
      CalendarRecordKind.estimate =>
        singular ? copy.calendarEstimateSingular : copy.calendarEstimatePlural,
      CalendarRecordKind.invoice =>
        singular ? copy.calendarInvoiceSingular : copy.calendarInvoicePlural,
      CalendarRecordKind.payment =>
        singular ? copy.calendarPaymentSingular : copy.calendarPaymentPlural,
      CalendarRecordKind.expense =>
        singular ? copy.calendarExpenseSingular : copy.calendarExpensePlural,
      CalendarRecordKind.inventoryRecord =>
        singular
            ? copy.calendarInventoryRecordSingular
            : copy.calendarInventoryRecordPlural,
    };
  }
}

/// One accessible date cell used by every module calendar.
///
/// The date, record count, approval state, today state, and selection state
/// have separate visual locations so operational markers never cover the date.
class ModuleCalendarDayCell extends StatelessWidget {
  const ModuleCalendarDayCell({
    super.key,
    required this.day,
    required this.selected,
    required this.today,
    required this.outsideMonth,
    required this.entryCount,
    required this.needsApproval,
    required this.recordKind,
    required this.isLastColumn,
    required this.isLastRow,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final bool outsideMonth;
  final int entryCount;
  final bool needsApproval;
  final CalendarRecordKind recordKind;
  final bool isLastColumn;
  final bool isLastRow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final materialCopy = MaterialLocalizations.of(context);
    final copy = context.l10n;
    final suffix = '${day.year}-${day.month}-${day.day}';
    final countedLabel = recordKind.localizedLabel(context, entryCount);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${materialCopy.formatFullDate(day)}. '
          '${today ? '${copy.calendarTodayState} ' : ''}'
          '${outsideMonth ? '${copy.calendarOutsideMonthState} ' : ''}'
          '${needsApproval ? '${copy.calendarNeedsApprovalState} ' : ''}'
          '${entryCount == 0 ? copy.calendarNoRecords(countedLabel) : copy.calendarRecordCount(entryCount, countedLabel)}',
      child: KeyedSubtree(
        key: ValueKey('calendar-day-$suffix'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0xAA20F060),
                      blurRadius: 9,
                      spreadRadius: -1,
                    ),
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : today
                ? const [
                    BoxShadow(
                      color: Color(0xAA20F060),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ]
                : const [],
          ),
          child: Material(
            // Exact 5.7 Active overlays: theme fills must not mask the painter.
            color: selected
                ? const Color(0xFF29D86D)
                : today
                ? const Color(0x2E20F060)
                : outsideMonth
                ? const Color(0x55000000)
                : Colors.transparent,
            child: InkWell(
              key: ValueKey('work-calendar-day-$suffix'),
              onTap: onTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    right: isLastColumn
                        ? BorderSide.none
                        : BorderSide(
                            color: CalendarPanelSurface.gridLine(context),
                            width: 1.5,
                          ),
                    bottom: isLastRow
                        ? BorderSide.none
                        : BorderSide(
                            color: CalendarPanelSurface.gridLine(context),
                            width: 1.5,
                          ),
                  ),
                ),
                child: Stack(
                  children: [
                    PositionedDirectional(
                      top: 6,
                      start: 0,
                      end: 0,
                      child: Center(
                        child: KeyedSubtree(
                          key: ValueKey('calendar-day-number-$suffix'),
                          child: _DateNumber(
                            key: ValueKey('module-calendar-day-number-$suffix'),
                            day: day.day,
                            selected: selected,
                            today: today,
                            outsideMonth: outsideMonth,
                          ),
                        ),
                      ),
                    ),
                    if (!outsideMonth && entryCount > 0)
                      PositionedDirectional(
                        start: 7,
                        bottom: 7,
                        child: KeyedSubtree(
                          key: ValueKey('calendar-entry-count-$suffix'),
                          child: _CalendarEntryCount(
                            key: ValueKey(
                              'module-calendar-entry-count-$suffix',
                            ),
                            needsApproval: needsApproval,
                            count: entryCount,
                          ),
                        ),
                      ),
                    if (today)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: KeyedSubtree(
                            key: const ValueKey('calendar-today-indicator'),
                            child: const _TodayMarker(),
                          ),
                        ),
                      ),
                    if (selected)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            key: const ValueKey('calendar-selected-outline'),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF29D86D),
                                width: 2.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateNumber extends StatelessWidget {
  const _DateNumber({
    super.key,
    required this.day,
    required this.selected,
    required this.today,
    required this.outsideMonth,
  });

  final int day;
  final bool selected;
  final bool today;
  final bool outsideMonth;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? const Color(0xFF07100A)
        : today
        ? const Color(0xFF50FF7A)
        : outsideMonth
        ? const Color(0xB8F4F7F2)
        : Colors.white;
    return Text(
      '$day',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: foreground,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        height: 1,
        shadows: selected
            ? const [
                Shadow(
                  color: Color(0x88FFFFFF),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ]
            : const [
                Shadow(color: Color(0xEE000000), offset: Offset(0, 1)),
                Shadow(color: Color(0xEE000000), offset: Offset(1, 0)),
                Shadow(color: Color(0xCC000000), offset: Offset(-1, 0)),
                Shadow(color: Color(0xCC000000), offset: Offset(0, -1)),
                Shadow(color: Color(0xAA20F060), blurRadius: 7),
              ],
      ),
    );
  }
}

class _CalendarEntryCount extends StatelessWidget {
  const _CalendarEntryCount({
    required this.needsApproval,
    required this.count,
    super.key,
  });

  final bool needsApproval;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = _semanticColors(context);
    final foreground = needsApproval
        ? semantic.attention
        : colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 4,
          height: 4,
          child: DecoratedBox(
            key: const ValueKey('calendar-entry-count-dot'),
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$count',
          key: const ValueKey('calendar-entry-count-value'),
          style: TextStyle(
            color: foreground,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _TodayMarker extends StatelessWidget {
  const _TodayMarker();

  @override
  Widget build(BuildContext context) {
    final semantic = _semanticColors(context);
    return SizedBox(
      key: const ValueKey('work-calendar-today-marker'),
      width: 16,
      height: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: semantic.current,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

AppSemanticColors _semanticColors(BuildContext context) =>
    Theme.of(context).extension<AppSemanticColors>() ??
    (Theme.of(context).brightness == Brightness.dark
        ? AppSemanticColors.dark
        : AppSemanticColors.light);
