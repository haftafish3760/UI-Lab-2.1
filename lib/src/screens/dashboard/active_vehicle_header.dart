import 'package:flutter/material.dart';

import '../../shared/app_view_mode.dart';
import '../../shared/operational_header.dart';
import '../../shared/operational_scope.dart';
import 'dashboard_models.dart';

class ActiveVehicleHeader extends StatelessWidget {
  const ActiveVehicleHeader({
    super.key,
    this.view = AppViewMode.technician,
    this.onViewChanged,
    this.activeEmployee,
    this.onEmployeeSelected,
    this.onCompanyOverview,
    this.onStartWorkday,
    this.onSettings,
    this.workdayActive = false,
    this.showPrimaryAction = true,
    this.leadingIcon = Icons.menu_rounded,
    this.leadingTooltip = 'Open navigation menu',
    this.onLeading,
    this.settingsTooltip = 'Dashboard settings',
  });

  final AppViewMode view;
  final ValueChanged<AppViewMode>? onViewChanged;
  final EmployeeStatus? activeEmployee;
  final ValueChanged<EmployeeStatus>? onEmployeeSelected;
  final VoidCallback? onCompanyOverview;
  final VoidCallback? onStartWorkday;
  final VoidCallback? onSettings;
  final bool workdayActive;
  final bool showPrimaryAction;
  final IconData leadingIcon;
  final String leadingTooltip;
  final VoidCallback? onLeading;
  final String settingsTooltip;

  static const _company = OperationalHeaderContextOption(
    id: 'company',
    kind: OperationalContextKind.employee,
    title: 'Company Overview',
    titleKind: OperationalContextTitleKind.companyOverview,
    detail: '3 active · 1 available',
    icon: Icons.business_outlined,
  );

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final options = _contextOptions(scope);
    return OperationalHeader(
      view: view,
      onViewChanged: onViewChanged ?? _noopView,
      selectedContext: _selectedContext(options, scope),
      contextOptions: options,
      onContextChanged: (option) => _selectContext(option, scope),
      showStartWorkday: showPrimaryAction,
      onStartWorkday: onStartWorkday ?? _noop,
      primaryActionLabel: workdayActive ? 'Open workday' : 'Start workday',
      primaryActionIcon: workdayActive
          ? Icons.timer_outlined
          : Icons.play_arrow_rounded,
      primaryActionKey: ValueKey(
        workdayActive ? 'open-workday-button' : 'start-workday-button',
      ),
      settingsTooltip: settingsTooltip,
      onSettings: onSettings ?? _noop,
      leadingIcon: leadingIcon,
      leadingTooltip: leadingTooltip,
      onLeading: onLeading,
      contextKey: view == AppViewMode.technician
          ? const ValueKey('active-vehicle-summary')
          : activeEmployee == null
          ? const ValueKey('company-overview-summary')
          : const ValueKey('active-employee-summary'),
      viewKey: const ValueKey('dashboard-view-selector'),
      settingsKey: const ValueKey('dashboard-settings-button'),
    );
  }

  List<OperationalHeaderContextOption> _contextOptions(
    OperationalScopeController scope,
  ) {
    if (view == AppViewMode.technician) {
      return [
        for (final vehicle in demoVehicles)
          OperationalHeaderContextOption(
            id: vehicle.id,
            kind: OperationalContextKind.activeVehicle,
            title:
                '${vehicle.name} · ${formatOdometerTenths(scope.confirmedOdometerTenthsFor(vehicle.id))} mi',
            detail:
                '${vehicle.description} · Odometer ${formatOdometerTenths(scope.confirmedOdometerTenthsFor(vehicle.id))} mi',
            icon: vehicle.icon,
          ),
      ];
    }
    return [
      _company,
      for (final employee in demoEmployees)
        OperationalHeaderContextOption(
          id: employee.id,
          kind: OperationalContextKind.employee,
          title: employee.name,
          detail: employee.status,
          icon: employee.icon,
          iconColor: employee.color,
        ),
    ];
  }

  OperationalHeaderContextOption _selectedContext(
    List<OperationalHeaderContextOption> options,
    OperationalScopeController scope,
  ) {
    if (view == AppViewMode.technician) {
      return options.firstWhere(
        (option) => option.id == scope.selectedVehicleId,
        orElse: () => options.first,
      );
    }
    final employeeId = activeEmployee?.id;
    if (employeeId == null) return _company;
    return options.firstWhere((option) => option.id == employeeId);
  }

  void _selectContext(
    OperationalHeaderContextOption option,
    OperationalScopeController scope,
  ) {
    if (view == AppViewMode.technician) {
      scope.selectVehicle(option.id);
      return;
    }
    if (option.id == _company.id) {
      onCompanyOverview?.call();
      return;
    }
    final employee = demoEmployees.firstWhere(
      (candidate) => candidate.id == option.id,
    );
    onEmployeeSelected?.call(employee);
  }

  static void _noop() {}
  static void _noopView(AppViewMode _) {}
}
