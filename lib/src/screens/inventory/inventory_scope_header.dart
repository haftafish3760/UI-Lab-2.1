import 'package:flutter/material.dart';

import '../../shared/app_view_mode.dart';
import '../../shared/operational_header.dart';
import '../dashboard/dashboard_models.dart';

class InventoryScopeHeader extends StatelessWidget {
  const InventoryScopeHeader({
    required this.view,
    required this.onViewChanged,
    required this.selectedVehicleId,
    required this.onVehicleChanged,
    required this.onSettings,
    this.workspaceLabel = 'Materials',
    this.showBackButton = false,
    this.onBack,
    this.contextKey = const ValueKey('inventory-context-selector'),
    this.viewKey = const ValueKey('inventory-view-selector'),
    this.settingsKey = const ValueKey('inventory-settings-button'),
    super.key,
  });

  final AppViewMode view;
  final String? selectedVehicleId;
  final ValueChanged<AppViewMode> onViewChanged;
  final ValueChanged<String?> onVehicleChanged;
  final VoidCallback onSettings;
  final String workspaceLabel;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Key contextKey;
  final Key viewKey;
  final Key settingsKey;

  @override
  Widget build(BuildContext context) => OperationalHeader(
    view: view,
    onViewChanged: onViewChanged,
    selectedContext: _selectedOption,
    contextOptions: _options,
    onContextChanged: (option) =>
        onVehicleChanged(option.id == 'fleet' ? null : option.id),
    leadingIcon: showBackButton ? Icons.arrow_back_rounded : Icons.menu_rounded,
    leadingTooltip: showBackButton ? 'Back to Materials' : 'Open navigation',
    onLeading: showBackButton ? onBack : null,
    settingsTooltip: '$workspaceLabel settings',
    onSettings: onSettings,
    contextKey: contextKey,
    viewKey: viewKey,
    settingsKey: settingsKey,
    headerTitle: workspaceLabel,
  );

  List<OperationalHeaderContextOption> get _options {
    final vehicles = [
      for (final vehicle in demoVehicles)
        OperationalHeaderContextOption(
          id: vehicle.id,
          kind: OperationalContextKind.vehicle,
          title: vehicle.name,
          detail: '${vehicle.description} · stock location',
          icon: vehicle.icon,
        ),
    ];
    if (view == AppViewMode.technician) return vehicles;
    return [
      const OperationalHeaderContextOption(
        id: 'fleet',
        kind: OperationalContextKind.vehicle,
        title: 'Fleet Overview',
        titleKind: OperationalContextTitleKind.fleetOverview,
        detail: 'All authorized vehicle stock',
        icon: Icons.business_outlined,
      ),
      ...vehicles,
    ];
  }

  OperationalHeaderContextOption get _selectedOption {
    final options = _options;
    final id = selectedVehicleId ?? (view == AppViewMode.admin ? 'fleet' : '');
    return options.firstWhere(
      (option) => option.id == id,
      orElse: () => options.first,
    );
  }
}
