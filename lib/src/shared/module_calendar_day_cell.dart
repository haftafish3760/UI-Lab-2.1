import 'package:flutter/material.dart';

import '../../l10n/app_localizations_extension.dart';
import '../layout/app_layout_engine.dart';
import '../theme/app_semantic_colors.dart';

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
    final colors = Theme.of(context).colorScheme;
    final semantic = _semanticColors(context);
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
        child: Material(
          color: outsideMonth
              ? colors.surfaceContainerHigh
              : selected
              ? semantic.currentSurface
              : colors.surface,
          child: InkWell(
            key: ValueKey('work-calendar-day-$suffix'),
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  right: isLastColumn
                      ? BorderSide.none
                      : BorderSide(color: colors.outline, width: 1.2),
                  bottom: isLastRow
                      ? BorderSide.none
                      : BorderSide(color: colors.outline, width: 1.2),
                ),
              ),
              child: Stack(
                children: [
                  PositionedDirectional(
                    top: 6,
                    end: 6,
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
                  if (!outsideMonth && entryCount > 0)
                    PositionedDirectional(
                      start: 7,
                      bottom: 7,
                      child: KeyedSubtree(
                        key: ValueKey('calendar-entry-count-$suffix'),
                        child: _CalendarEntryCount(
                          key: ValueKey('module-calendar-entry-count-$suffix'),
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
                              color: semantic.current,
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
    final colors = Theme.of(context).colorScheme;
    final semantic = _semanticColors(context);
    final extent = AppLayoutEngine.calendarDateNumberExtentFor(
      MediaQuery.textScalerOf(context),
    );
    final foreground = selected
        ? colors.onPrimary
        : today
        ? semantic.current
        : outsideMonth
        ? colors.onSurfaceVariant.withValues(alpha: .48)
        : colors.onSurface;
    return Container(
      width: extent,
      height: extent,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? semantic.current
            : today
            ? semantic.currentSurface
            : colors.surfaceContainerLow,
        border: Border.all(
          color: selected
              ? semantic.current
              : today
              ? semantic.current
              : colors.outline,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$day',
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: selected || today ? FontWeight.w700 : FontWeight.w600,
          height: 1,
        ),
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
