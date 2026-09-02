import 'package:flutter/material.dart';

import '../../shared/app_view_mode.dart';
import '../../shared/operational_header.dart';
import '../dashboard/dashboard_models.dart';
import '../dashboard/employee_status_strip.dart';

class ExpensesScopeHeader extends StatelessWidget {
  const ExpensesScopeHeader({
    required this.view,
    required this.selectedEmployeeId,
    required this.onViewChanged,
    required this.onEmployeeChanged,
    required this.onSettings,
    this.workspaceLabel = 'Expenses',
    this.showBackButton = false,
    this.onBack,
    this.showEmployeeStrip = true,
    this.showSettings = true,
    this.contextKey = const ValueKey('expenses-context-selector'),
    this.viewKey = const ValueKey('expenses-view-selector'),
    this.settingsKey = const ValueKey('expenses-settings-button'),
    super.key,
  });

  final AppViewMode view;
  final String? selectedEmployeeId;
  final ValueChanged<AppViewMode> onViewChanged;
  final ValueChanged<String?> onEmployeeChanged;
  final VoidCallback onSettings;
  final String workspaceLabel;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showEmployeeStrip;
  final bool showSettings;
  final Key contextKey;
  final Key viewKey;
  final Key settingsKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OperationalHeader(
        view: view,
        onViewChanged: onViewChanged,
        selectedContext: _selectedOption,
        contextOptions: _options,
        onContextChanged: (option) =>
            onEmployeeChanged(option.id == 'company' ? null : option.id),
        leadingIcon: showBackButton
            ? Icons.arrow_back_rounded
            : Icons.menu_rounded,
        leadingTooltip: showBackButton ? 'Back to Expenses' : 'Open navigation',
        onLeading: showBackButton ? onBack : null,
        settingsTooltip: '$workspaceLabel settings',
        onSettings: onSettings,
        showSettings: showSettings,
        contextKey: contextKey,
        viewKey: viewKey,
        settingsKey: settingsKey,
        headerTitle: workspaceLabel,
      ),
      if (view == AppViewMode.admin && showEmployeeStrip) ...[
        const SizedBox(height: 14),
        EmployeeStatusStrip(
          employees: demoEmployees,
          selectedId: selectedEmployeeId,
          onSelected: (employee) => onEmployeeChanged(employee.id),
        ),
      ],
    ],
  );

  List<OperationalHeaderContextOption> get _options {
    final employees = [
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
    if (view == AppViewMode.technician) return [employees.first];
    return [
      const OperationalHeaderContextOption(
        id: 'company',
        kind: OperationalContextKind.employee,
        title: 'Company Overview',
        titleKind: OperationalContextTitleKind.companyOverview,
        detail: 'Authorized company expenses',
        icon: Icons.business_outlined,
      ),
      ...employees,
    ];
  }

  OperationalHeaderContextOption get _selectedOption {
    final options = _options;
    final id = view == AppViewMode.technician
        ? demoEmployees.first.id
        : selectedEmployeeId ?? 'company';
    return options.firstWhere((option) => option.id == id);
  }
}
