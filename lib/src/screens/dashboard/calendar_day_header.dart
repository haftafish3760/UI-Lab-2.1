import 'package:flutter/material.dart';

import '../../shared/app_view_mode.dart';
import '../../shared/operational_header.dart';
import '../../shared/operational_scope.dart';
import 'dashboard_models.dart';

class CalendarDayHeader extends StatelessWidget {
  const CalendarDayHeader({
    required this.scope,
    required this.employee,
    required this.onSettings,
    required this.onBack,
    super.key,
  });

  final OperationalScopeController scope;
  final EmployeeStatus? employee;
  final VoidCallback onSettings;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final options = _options;
    return OperationalHeader(
      view: scope.view,
      onViewChanged: scope.setView,
      selectedContext: _selectedOption(options),
      contextOptions: options,
      onContextChanged: (option) =>
          scope.selectEmployee(option.id == 'company' ? null : option.id),
      leadingIcon: Icons.arrow_back_rounded,
      leadingTooltip: 'Back to Dashboard',
      onLeading: onBack,
      settingsTooltip: 'Calendar day settings',
      onSettings: onSettings,
      contextKey: const ValueKey('calendar-day-context-selector'),
      viewKey: const ValueKey('dashboard-view-selector'),
      settingsKey: const ValueKey('dashboard-settings-button'),
    );
  }

  List<OperationalHeaderContextOption> get _options {
    if (scope.view == AppViewMode.technician) {
      final selected = employee ?? demoEmployees.first;
      final vehicle = dashboardVehicleById(scope.selectedVehicleId);
      return [
        OperationalHeaderContextOption(
          id: selected.id,
          kind: OperationalContextKind.employee,
          title: selected.name,
          detail:
              '${vehicle.name} · ${formatOdometerTenths(scope.confirmedOdometerTenthsFor(vehicle.id))} mi',
          icon: selected.icon,
          iconColor: selected.color,
        ),
      ];
    }
    return [
      const OperationalHeaderContextOption(
        id: 'company',
        kind: OperationalContextKind.employee,
        title: 'Company Overview',
        titleKind: OperationalContextTitleKind.companyOverview,
        detail: 'Authorized company activity',
        icon: Icons.business_outlined,
      ),
      for (final candidate in demoEmployees)
        OperationalHeaderContextOption(
          id: candidate.id,
          kind: OperationalContextKind.employee,
          title: candidate.name,
          detail: candidate.status,
          icon: candidate.icon,
          iconColor: candidate.color,
        ),
    ];
  }

  OperationalHeaderContextOption _selectedOption(
    List<OperationalHeaderContextOption> options,
  ) {
    final id = scope.view == AppViewMode.technician
        ? (employee ?? demoEmployees.first).id
        : employee?.id ?? 'company';
    return options.firstWhere((option) => option.id == id);
  }
}
