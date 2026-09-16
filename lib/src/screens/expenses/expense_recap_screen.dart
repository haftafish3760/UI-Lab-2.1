import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'expense_period_range.dart';
import 'expense_period_screen.dart';

/// A projection of authorized expense records, never a second ledger.
class ExpenseRecapScreen extends StatefulWidget {
  const ExpenseRecapScreen({
    required this.anchor,
    required this.firstWeekday,
    required this.permissions,
    super.key,
  });
  final DateTime anchor;
  final int firstWeekday;
  final ExpensePermissions permissions;
  @override
  State<ExpenseRecapScreen> createState() => _ExpenseRecapScreenState();
}

class _ExpenseRecapScreenState extends State<ExpenseRecapScreen> {
  String _period = 'Month';
  late DateTime _anchor = widget.anchor;

  @override
  Widget build(BuildContext context) {
    final permissions = widget.permissions;
    if (!permissions.canView || !permissions.canViewAmounts) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense recap')),
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
    final range = expensePeriodRange(_period, _anchor, widget.firstWeekday);
    final records = PrototypeOperationsScope.of(context).expenses
        .where(
          (record) =>
              expenseVisibleInPeriod(record, range, permissions, employeeId),
        )
        .toList();
    final summary = ExpenseAmountSummary(records);
    final categories = <ExpenseCategory, List<ExpenseRecord>>{};
    for (final record in records) {
      categories.putIfAbsent(record.category, () => []).add(record);
    }
    final dates = MaterialLocalizations.of(context);
    final lastDay = DateTime(
      range.end.year,
      range.end.month,
      range.end.day - 1,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Expense recap')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: AppLayoutEngine.formWorkspaceWidthFor(
                  constraints.maxWidth,
                ),
                child: ListView(
                  padding: insets,
                  children: [
                    Text(
                      scope.view == AppViewMode.technician
                          ? 'My expenses'
                          : employeeId == null
                          ? 'Company expenses'
                          : 'Selected employee’s expenses',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Choose a period'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final period in [
                                'Month',
                                'Quarter',
                                'Year to date',
                                'Year',
                              ])
                                ChoiceChip(
                                  label: Text(period),
                                  selected: _period == period,
                                  onSelected: (_) =>
                                      setState(() => _period = period),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                              '${dates.formatMediumDate(range.start)} – ${dates.formatMediumDate(lastDay)}',
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _anchor,
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2200),
                              );
                              if (mounted && date != null) {
                                setState(() => _anchor = date);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Recorded expenses'),
                          const SizedBox(height: 8),
                          Text(
                            expenseMoney(summary.displayAmount),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text('${records.length} expense records'),
                          if (summary.missingMessage case final message?)
                            Text(message),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const ValueKey('recap-view-entries'),
                            icon: const Icon(Icons.list_alt),
                            label: const Text('View expenses'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ExpensePeriodScreen(
                                  period: _period,
                                  anchor: _anchor,
                                  firstWeekday: widget.firstWeekday,
                                  permissions: permissions,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Spending by category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (records.isEmpty)
                      const Text('No expenses recorded for this period.'),
                    for (final category in categories.keys) ...[
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              expenseMoney(
                                ExpenseAmountSummary(
                                  categories[category]!,
                                ).displayAmount,
                              ),
                            ),
                            if (ExpenseAmountSummary(
                                  categories[category]!,
                                ).missingMessage
                                case final message?)
                              Text(message),
                          ],
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
