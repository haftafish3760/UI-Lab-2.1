import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/work/directory_persistence_session.dart';
import '../../shared/section_card.dart';
import '../work/employee_status_screen.dart';
import '../work/work_scope_header.dart';

/// A compact, record-derived team view for the company Dashboard.
class DashboardEmployeeStatusSummary extends StatelessWidget {
  const DashboardEmployeeStatusSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final directory = store.directorySession;
    if (directory?.permissions.canViewEmployees != true) {
      return const SizedBox.shrink();
    }
    final profiles = directory!.employees
        .where((person) => person.active)
        .toList();
    final statuses = workEmployeeOptions(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SectionCard(
          key: const ValueKey('dashboard-employee-status'),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Employee status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('dashboard-all-employee-status'),
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const EmployeeStatusScreen(),
                        ),
                      ),
                      child: const Text('View all'),
                    ),
                  ],
                ),
              ),
              if (profiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('No active employees are saved.'),
                  ),
                )
              else
                for (final profile in profiles.take(3)) ...[
                  const Divider(height: 1),
                  ListTile(
                    key: ValueKey('dashboard-employee-${profile.id}'),
                    title: Text(profile.name),
                    subtitle: Text(
                      statuses
                              .where((item) => item.id == profile.id)
                              .firstOrNull
                              ?.status ??
                          'Status unavailable',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            EmployeeWorkStatusDetailScreen(employee: profile),
                      ),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
