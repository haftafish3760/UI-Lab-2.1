import 'package:flutter/material.dart';
import '../../../l10n/app_localizations_extension.dart';

import '../../shared/app_view_mode.dart';
import '../../shared/operational_header.dart';
import '../../shared/operational_scope.dart';
import '../../theme/app_theme.dart';
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
    this.ownerPresentation = false,
    this.onVehicleChanged,
    this.ownerTitle,
    this.dashboardWide = false,
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
  final bool ownerPresentation;
  final ValueChanged<String>? onVehicleChanged;
  final String? ownerTitle;
  final bool dashboardWide;

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
      dashboardWide: dashboardWide,
      ownerPresentation: ownerPresentation,
      headerTitle: ownerPresentation
          ? (ownerTitle ?? context.l10n.navDashboard)
          : null,
      contextReading:
          ownerPresentation &&
              (!dashboardWide || view == AppViewMode.technician)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dashboardOdometerLabel.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.onHeaderMuted,
                    fontSize: 11,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _odometerLabel(scope, scope.selectedVehicleId),
                  key: const ValueKey('dashboard-header-odometer'),
                  style: const TextStyle(
                    color: Color(0xFF6AD39B),
                    fontSize: 19,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : null,
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
    if ((ownerPresentation && !dashboardWide) ||
        view == AppViewMode.technician) {
      return [
        for (final vehicle in demoVehicles)
          OperationalHeaderContextOption(
            id: vehicle.id,
            kind: OperationalContextKind.activeVehicle,
            title: ownerPresentation
                ? vehicle.name
                : '${vehicle.name} · ${_odometerLabel(scope, vehicle.id)}',
            detail: ownerPresentation
                ? vehicle.description
                : '${vehicle.description} · Odometer ${_odometerLabel(scope, vehicle.id)}',
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
    if ((ownerPresentation && !dashboardWide) ||
        view == AppViewMode.technician) {
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
    if ((ownerPresentation && !dashboardWide) ||
        view == AppViewMode.technician) {
      scope.selectVehicle(option.id);
      onVehicleChanged?.call(option.id);
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

String _odometerLabel(OperationalScopeController scope, String vehicleId) {
  final session = scope.workdaySession;
  if (session != null) {
    final odometer = session.odometerFor(vehicleId);
    if (odometer == null) return 'Unavailable';
    if (odometer.revision == 0) return 'Not recorded';
    return '${formatOdometerTenths(odometer.readingTenths)} mi';
  }
  return '${formatOdometerTenths(scope.confirmedOdometerTenthsFor(vehicleId))} mi';
}
