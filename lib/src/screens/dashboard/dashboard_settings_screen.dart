import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/operational_scope.dart';
import '../../shared/app_preferences.dart';
import '../../shared/section_card.dart';
import 'active_vehicle_header.dart';
import 'dashboard_models.dart';
import 'dashboard_workday_models.dart';
import '../../shared/account_scope.dart';
import '../account/account_screen.dart';

class DashboardSettingsScreen extends StatefulWidget {
  const DashboardSettingsScreen({required this.enabledActions, super.key});

  final Set<DashboardWorkdayAction> enabledActions;

  @override
  State<DashboardSettingsScreen> createState() =>
      _DashboardSettingsScreenState();
}

class _DashboardSettingsScreenState extends State<DashboardSettingsScreen> {
  late var _enabled = Set<DashboardWorkdayAction>.of(widget.enabledActions);

  bool _saving = false;
  Future<void> _setEnabled(Set<DashboardWorkdayAction> actions) async {
    if (_saving) return;
    setState(() => _saving = true);
    final next = {...actions, DashboardWorkdayAction.endDay};
    final saved = await AppPreferencesScope.of(
      context,
    ).setDashboardActions(next.map((action) => action.name).toSet());
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) _enabled = next;
    });
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Dashboard settings were not saved. Previous choices remain active.',
          ),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _setEnabled(next),
          ),
        ),
      );
    }
  }

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
                    if (AccountScope.maybeOf(context) case final gateway?) ...[
                      SectionCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.account_circle_outlined),
                          title: const Text('Your account'),
                          subtitle: const Text(
                            'Sign in or create an optional account',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AccountScreen(gateway: gateway),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                                  (spec.action ==
                                          DashboardWorkdayAction.endDay ||
                                      _saving)
                                  ? null
                                  : (value) => _setEnabled(
                                      value == true
                                          ? {..._enabled, spec.action}
                                          : ({..._enabled}
                                              ..remove(spec.action)),
                                    ),
                            ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => _setEnabled(
                                        Set.of(defaultDashboardWorkdayActions),
                                      ),
                                child: const Text('Restore defaults'),
                              ),
                              FilledButton.icon(
                                key: const ValueKey(
                                  'save-dashboard-settings-button',
                                ),
                                onPressed: _saving ? null : _save,
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

  void _save() {
    if (_saving) return;
    Navigator.of(context).pop({..._enabled, DashboardWorkdayAction.endDay});
  }
}
