import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'active_vehicle_header.dart';
import 'dashboard_models.dart';
import 'dashboard_workday_models.dart';

class DashboardSettingsScreen extends StatefulWidget {
  const DashboardSettingsScreen({required this.enabledActions, super.key});

  final Set<DashboardWorkdayAction> enabledActions;

  @override
  State<DashboardSettingsScreen> createState() =>
      _DashboardSettingsScreenState();
}

class _DashboardSettingsScreenState extends State<DashboardSettingsScreen> {
  late var _enabled = Set<DashboardWorkdayAction>.of(widget.enabledActions);

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final employee = _employeeFor(scope.selectedEmployeeId);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final available = math.max(
            0,
            constraints.maxWidth - insets.horizontal,
          );
          final workspace = math.min(920.0, available.toDouble());
          return SingleChildScrollView(
            padding: insets.copyWith(top: 12, bottom: 28),
            child: Center(
              child: SizedBox(
                width: workspace,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ActiveVehicleHeader(
                      view: scope.view,
                      onViewChanged: scope.setView,
                      activeEmployee: employee,
                      onEmployeeSelected: (selected) =>
                          scope.selectEmployee(selected.id),
                      onCompanyOverview: () => scope.selectEmployee(null),
                      showPrimaryAction: false,
                      leadingIcon: Icons.arrow_back_rounded,
                      leadingTooltip: 'Back to Dashboard',
                      onLeading: _save,
                      onSettings: _save,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Dashboard settings',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'These choices affect only the Dashboard. They do not change employee permissions.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Active workday actions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Choose the labeled actions shown when the workday Actions button is opened.',
                          ),
                          const SizedBox(height: 10),
                          for (final spec in dashboardWorkdayActions)
                            CheckboxListTile(
                              key: ValueKey(
                                'dashboard-action-setting-${spec.action.name}',
                              ),
                              contentPadding: EdgeInsets.zero,
                              secondary: Icon(spec.icon, color: spec.color),
                              title: Text(spec.label),
                              subtitle: Text(
                                spec.action == DashboardWorkdayAction.endDay
                                    ? 'Required so an active day can always be reviewed and closed.'
                                    : spec.description,
                              ),
                              value: _enabled.contains(spec.action),
                              onChanged:
                                  spec.action == DashboardWorkdayAction.endDay
                                  ? null
                                  : (value) => setState(() {
                                      if (value == true) {
                                        _enabled.add(spec.action);
                                      } else {
                                        _enabled.remove(spec.action);
                                      }
                                    }),
                            ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              TextButton(
                                onPressed: () => setState(
                                  () => _enabled = Set.of(
                                    defaultDashboardWorkdayActions,
                                  ),
                                ),
                                child: const Text('Restore defaults'),
                              ),
                              FilledButton.icon(
                                key: const ValueKey(
                                  'save-dashboard-settings-button',
                                ),
                                onPressed: _save,
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Save Dashboard settings'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  EmployeeStatus? _employeeFor(String? id) {
    if (id == null) return null;
    for (final employee in demoEmployees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  void _save() =>
      Navigator.of(context).pop({..._enabled, DashboardWorkdayAction.endDay});
}
