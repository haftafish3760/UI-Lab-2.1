import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/prototype_operations_store.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_scope.dart';
import 'dashboard_review_section.dart';
import '../expenses/report_sources_screen.dart';
import 'dashboard_models.dart';

/// Reads existing scoped reports; missing attribution is never a zero profit.
class AdminEmployeeOverview extends StatelessWidget {
  const AdminEmployeeOverview({
    required this.employee,
    required this.date,
    super.key,
  });

  final EmployeeStatus employee;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    if (scope.view != AppViewMode.admin ||
        scope.selectedEmployeeId != employee.id) {
      return const SizedBox.shrink();
    }
    final summary = PrototypeOperationsScope.of(context).reportSummary(
      fromInclusive: DateTime(date.year, date.month),
      toExclusive: DateTime(date.year, date.month + 1),
      employeeId: employee.id,
      employeeName: employee.name,
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final period = DateFormat.yMMMM(locale).format(date);
    final money = NumberFormat.simpleCurrency(name: 'USD', locale: locale);
    return DashboardReviewSection(
      key: const ValueKey('admin-employee-overview'),
      title: '${employee.name} · $period',
      icon: Icons.person_outline,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Monthly results. The schedule above follows the selected day.',
        ),
        _records(
          context,
          'Completed jobs',
          '${summary.completedJobs.length}',
          summary.completedJobs,
          period,
        ),
        _records(
          context,
          'Recorded expenses',
          money.format(summary.financial.recordedExpenseCents / 100),
          summary.recordedExpenses,
          period,
        ),
        const Divider(),
        const Text(
          'Employee contribution · Incomplete',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Revenue from their work, labor cost, and shared job costs still need '
          'confirmed allocations. Payments collected by this employee are not '
          'attributed yet. These missing amounts are not treated as zero.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Expenses here are recorded under this employee. Buying supplies '
          'for a crew does not make the entire purchase their personal job cost.',
        ),
      ],
    );
  }

  Widget _records(
    BuildContext context,
    String label,
    String value,
    List<PrototypeReportSource> sources,
    String period,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      final scope = OperationalScope.of(context);
      if (scope.view != AppViewMode.admin ||
          scope.selectedEmployeeId != employee.id) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReportSourcesScreen(
            title: '${employee.name} · $label',
            basis: '$period · recorded employee association',
            sources: sources,
          ),
        ),
      );
    },
  );
}
