import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_scope.dart';
import 'expense_detail_screen.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'expense_period_range.dart';
import 'expense_record_card.dart';

bool expenseVisibleInPeriod(
  ExpenseRecord record,
  DateTimeRange range,
  ExpensePermissions permissions,
  String? employeeId,
) {
  if (!permissions.canView || !permissions.canViewAmounts) {
    return false;
  }
  if (!permissions.canReviewCompanyExpenses &&
      record.paidByEmployeeId != permissions.actorEmployeeId) {
    return false;
  }
  if (employeeId != null && record.paidByEmployeeId != employeeId) {
    return false;
  }
  final date = record.resolvedDate;
  return date != null &&
      !date.isBefore(range.start) &&
      date.isBefore(range.end);
}

class ExpensePeriodScreen extends StatelessWidget {
  const ExpensePeriodScreen({
    required this.period,
    required this.anchor,
    required this.firstWeekday,
    required this.permissions,
    super.key,
  });

  final String period;
  final DateTime anchor;
  final int firstWeekday;
  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) {
    if (!permissions.canView || !permissions.canViewAmounts) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expenses')),
        body: const Center(
          child: Text('You do not have permission to view spending.'),
        ),
      );
    }
    final scope = OperationalScope.of(context);
    final employeeId =
        scope.selectedEmployeeId ??
        (scope.view == AppViewMode.technician
            ? permissions.actorEmployeeId
            : null);
    final range = expensePeriodRange(period, anchor, firstWeekday);
    final records =
        PrototypeOperationsScope.of(context).expenses
            .where(
              (record) => expenseVisibleInPeriod(
                record,
                range,
                permissions,
                employeeId,
              ),
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.resolvedDate!.compareTo(b.resolvedDate!);
            return byDate != 0 ? byDate : a.id.compareTo(b.id);
          });
    final summary = ExpenseAmountSummary(records);
    final dates = MaterialLocalizations.of(context);
    final lastDay = DateTime(
      range.end.year,
      range.end.month,
      range.end.day - 1,
    );
    return Scaffold(
      appBar: AppBar(title: Text('$period expenses')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: layout.columnWidth,
                child: ListView(
                  padding: insets,
                  children: [
                    Text(
                      '${dates.formatMediumDate(range.start)} – ${dates.formatMediumDate(lastDay)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${records.length} expense records • ${expenseMoney(summary.displayAmount)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (summary.missingMessage case final message?)
                      Text(message),
                    const SizedBox(height: 16),
                    if (records.isEmpty)
                      const Text('No expense records for this period.'),
                    for (final record in records) ...[
                      Text(dates.formatMediumDate(record.resolvedDate!)),
                      ExpenseRecordCard(
                        expense: record,
                        showOwner: permissions.canReviewCompanyExpenses,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ExpenseDetailScreen(
                              expenseId: record.id,
                              permissions: permissions,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
