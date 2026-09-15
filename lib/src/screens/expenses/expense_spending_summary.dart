import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';
import '../../theme/app_theme.dart';
import 'expense_models.dart';
import 'expense_period_range.dart';

/// Calendar periods in local business dates; input must already be authorized.
Map<String, int> expensePeriodTotals(
  List<ExpenseRecord> records,
  DateTime day, {
  int firstWeekday = DateTime.monday,
}) {
  final ranges = {
    for (final period in ['Day', 'Week', 'Month', 'Year'])
      period: expensePeriodRange(period, day, firstWeekday),
  };
  return {
    for (final period in ranges.keys)
      period: records
          .where((r) {
            final date = r.resolvedDate;
            return date != null &&
                !date.isBefore(ranges[period]!.start) &&
                date.isBefore(ranges[period]!.end);
          })
          .fold<int>(0, (sum, r) => sum + (r.amount * 100).round()),
  };
}

class ExpenseSpendingSummary extends StatelessWidget {
  const ExpenseSpendingSummary({
    required this.records,
    required this.date,
    this.firstWeekday = DateTime.monday,
    this.onOpen,
    super.key,
  });
  final List<ExpenseRecord> records;
  final DateTime date;
  final int firstWeekday;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final totals = expensePeriodTotals(
      records,
      date,
      firstWeekday: firstWeekday,
    );
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppLayoutEngine.summaryMetricColumnsFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final period in totals.keys)
              SizedBox(
                width: width,
                child: Material(
                  key: ValueKey('expense-spending-${period.toLowerCase()}'),
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  child: InkWell(
                    onTap: onOpen == null ? null : () => onOpen!(period),
                    borderRadius: BorderRadius.circular(AppRadii.control),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            period == 'Day'
                                ? 'Daily total'
                                : 'This ${period.toLowerCase()}',
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            expenseMoney(totals[period]! / 100),
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
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
