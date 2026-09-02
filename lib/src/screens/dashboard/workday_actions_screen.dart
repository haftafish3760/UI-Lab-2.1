import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/operational_scope.dart';
import 'active_vehicle_header.dart';
import 'dashboard_models.dart';
import 'dashboard_workday_models.dart';

class WorkdayActionsScreen extends StatelessWidget {
  const WorkdayActionsScreen({
    required this.session,
    required this.enabledActions,
    super.key,
  });

  final DashboardWorkdaySession session;
  final Set<DashboardWorkdayAction> enabledActions;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final employee = _employeeFor(scope.selectedEmployeeId);
    final actions = [
      for (final spec in dashboardWorkdayActions)
        if (enabledActions.contains(spec.action))
          spec.forStatus(session.status),
      workdaySettingsAction,
    ];
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final available = math.max(
            0,
            constraints.maxWidth - insets.horizontal,
          );
          final workspaceWidth = math.min(1180.0, available.toDouble());
          return SingleChildScrollView(
            padding: insets.copyWith(top: 12, bottom: 28),
            child: Center(
              child: SizedBox(
                width: workspaceWidth,
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
                      onLeading: () => Navigator.of(context).pop(),
                      onSettings: () => Navigator.of(
                        context,
                      ).pop(DashboardWorkdayAction.configureActions),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Workday actions',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _ActionGrid(actions: actions),
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
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<DashboardWorkdayActionSpec> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = AppLayoutEngine.workShortcutsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      );
      final gridWidth = math.min(
        layout.columns * layout.tileWidth + (layout.columns - 1) * layout.gap,
        constraints.maxWidth,
      );
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: gridWidth,
          child: Wrap(
            spacing: layout.gap,
            runSpacing: layout.gap,
            children: [
              for (final action in actions)
                SizedBox(
                  width: layout.tileWidth,
                  child: _ActionTile(
                    spec: action,
                    iconExtent: layout.iconExtent,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.spec, required this.iconExtent});

  final DashboardWorkdayActionSpec spec;
  final double iconExtent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('workday-action-${spec.action.name}'),
        onTap: () => Navigator.of(context).pop(spec.action),
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: spec.description,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconExtent,
                height: iconExtent,
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: .13),
                  border: Border.all(color: spec.color.withValues(alpha: .45)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(spec.icon, color: spec.color, size: 27),
              ),
              const SizedBox(height: 6),
              Text(
                spec.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
