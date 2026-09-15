import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';
import 'dashboard_models.dart';

/// This changes viewed scope, never the signed-in actor or their grants.
class DashboardScopeSelector extends StatelessWidget {
  const DashboardScopeSelector({
    super.key,
    required this.selectedId,
    required this.onEmployee,
    required this.onCompany,
  });
  final String? selectedId;
  final ValueChanged<EmployeeStatus> onEmployee;
  final VoidCallback onCompany;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey('employee-status-strip'),
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _choice(
          context,
          'Company Overview',
          selectedId == null,
          onCompany,
          const ValueKey('dashboard-company-scope'),
        ),
        for (final employee in demoEmployees) ...[
          const SizedBox(width: 8),
          _choice(
            context,
            employee.name,
            employee.id == selectedId,
            () => onEmployee(employee),
            ValueKey('employee-${employee.id}'),
          ),
        ],
      ],
    ),
  );

  Widget _choice(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
    Key key,
  ) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: AppLayoutEngine.calendarMaximum / 2,
    ),
    child: FilterChip(
      key: key,
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    ),
  );
}
