import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import '../dashboard/dashboard_models.dart';
import 'expense_detail_screen.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'expense_record_card.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';

enum _CategoryPeriod { sevenDays, thisMonth, ninetyDays }

class ExpenseCategoryScreen extends StatefulWidget {
  const ExpenseCategoryScreen({
    required this.category,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final ExpenseCategory category;
  final ExpensePermissions permissions;

  @override
  State<ExpenseCategoryScreen> createState() => _ExpenseCategoryScreenState();
}

class _ExpenseCategoryScreenState extends State<ExpenseCategoryScreen> {
  var _period = _CategoryPeriod.thisMonth;

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView) {
      return const Scaffold(
        key: ValueKey('expense-category-screen'),
        body: SafeArea(
          child: Center(
            child: Text('You do not have permission to view expenses.'),
          ),
        ),
      );
    }
    final scope = OperationalScope.of(context);
    final records =
        PrototypeOperationsScope.of(context).expenses.where((item) {
          if (item.category != widget.category || !_withinPeriod(item)) {
            return false;
          }
          if (scope.view == AppViewMode.admin &&
              scope.selectedEmployeeId == null) {
            return true;
          }
          final owner = dashboardEmployeeById(
            scope.selectedEmployeeId ?? 'alex',
          ).name;
          return item.owner == owner;
        }).toList()..sort(
          (a, b) => (b.resolvedDate ?? dashboardToday).compareTo(
            a.resolvedDate ?? dashboardToday,
          ),
        );
    final total = records.fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      key: const ValueKey('expense-category-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return ListView(
              padding: insets.copyWith(top: 10, bottom: 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExpensesScopeHeader(
                          view: scope.view,
                          selectedEmployeeId: scope.selectedEmployeeId,
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                          onSettings: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ExpensesSettingsScreen(),
                            ),
                          ),
                          showSettings: widget.permissions.canConfigureDisplay,
                          workspaceLabel: widget.category.label,
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          operationalDateLabel(context, dashboardToday),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<_CategoryPeriod>(
                          segments: const [
                            ButtonSegment(
                              value: _CategoryPeriod.sevenDays,
                              label: Text('7 days'),
                            ),
                            ButtonSegment(
                              value: _CategoryPeriod.thisMonth,
                              label: Text('This month'),
                            ),
                            ButtonSegment(
                              value: _CategoryPeriod.ninetyDays,
                              label: Text('90 days'),
                            ),
                          ],
                          selected: {_period},
                          onSelectionChanged: (value) =>
                              setState(() => _period = value.single),
                        ),
                        const SizedBox(height: 12),
                        SectionCard(
                          child: Row(
                            children: [
                              Icon(widget.category.icon),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.category.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (widget.permissions.canViewAmounts)
                                Text(
                                  expenseMoney(total),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (
                          var index = 0;
                          index < records.length;
                          index++
                        ) ...[
                          ExpenseRecordCard(
                            expense: records[index],
                            showOwner: true,
                            showAmount: widget.permissions.canViewAmounts,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ExpenseDetailScreen(
                                  expenseId: records[index].id,
                                  permissions: widget.permissions,
                                ),
                              ),
                            ),
                          ),
                          if (index != records.length - 1)
                            const SizedBox(height: 8),
                        ],
                        if (records.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No expenses in this category for this period.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _withinPeriod(ExpenseRecord record) {
    final date = record.resolvedDate;
    if (date == null) return false;
    final today = DateUtils.dateOnly(DateTime.now());
    return switch (_period) {
      _CategoryPeriod.sevenDays => !date.isBefore(
        today.subtract(const Duration(days: 6)),
      ),
      _CategoryPeriod.ninetyDays => !date.isBefore(
        today.subtract(const Duration(days: 89)),
      ),
      _CategoryPeriod.thisMonth =>
        date.year == today.year && date.month == today.month,
    };
  }
}
