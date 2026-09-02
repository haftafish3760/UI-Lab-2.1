import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_header.dart';
import '../dashboard/dashboard_models.dart';
import '../dashboard/employee_status_strip.dart';

class WorkScopeHeader extends StatelessWidget {
  const WorkScopeHeader({
    required this.view,
    required this.selectedDay,
    required this.selectedEmployeeId,
    required this.onViewChanged,
    required this.onEmployeeChanged,
    this.workspaceLabel = 'Work',
    this.showBackButton = false,
    this.onBack,
    this.onSettings,
    this.showDateContext = true,
    this.showDateDescription = true,
    this.showEmployeeStrip = true,
    super.key,
  });

  final AppViewMode view;
  final DateTime selectedDay;
  final String? selectedEmployeeId;
  final ValueChanged<AppViewMode> onViewChanged;
  final ValueChanged<String?> onEmployeeChanged;
  final String workspaceLabel;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final bool showDateContext;
  final bool showDateDescription;
  final bool showEmployeeStrip;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OperationalHeader(
          view: view,
          onViewChanged: onViewChanged,
          selectedContext: selected,
          contextOptions: _options,
          onContextChanged: (option) =>
              onEmployeeChanged(option.id == 'company' ? null : option.id),
          leadingIcon: showBackButton
              ? Icons.arrow_back_rounded
              : Icons.menu_rounded,
          leadingTooltip: showBackButton ? 'Back to Work' : 'Open navigation',
          onLeading: showBackButton ? onBack : null,
          settingsTooltip: '$workspaceLabel settings',
          onSettings: onSettings ?? _noop,
          showSettings: onSettings != null,
          contextKey: const ValueKey('work-context-selector'),
          viewKey: const ValueKey('work-view-selector'),
          settingsKey: const ValueKey('work-settings-button'),
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
        if (showDateContext) ...[
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
              return Text(
                MaterialLocalizations.of(context).formatFullDate(selectedDay),
                key: const ValueKey('work-date-heading'),
                style: TextStyle(
                  fontSize: type.pageTitle,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              );
            },
          ),
          if (showDateDescription) ...[
            const SizedBox(height: 3),
            Text(
              workspaceLabel == 'Work'
                  ? 'Jobs, estimates, invoices, customers, and payments for this date.'
                  : '$workspaceLabel for the selected date.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }

  List<OperationalHeaderContextOption> get _options {
    final employeeOptions = [
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
    if (view == AppViewMode.technician) return [employeeOptions.first];
    return [
      const OperationalHeaderContextOption(
        id: 'company',
        kind: OperationalContextKind.employee,
        title: 'Company Overview',
        titleKind: OperationalContextTitleKind.companyOverview,
        detail: 'All authorized work',
        icon: Icons.business_outlined,
      ),
      ...employeeOptions,
    ];
  }

  OperationalHeaderContextOption get _selectedOption {
    final options = _options;
    final id = view == AppViewMode.technician
        ? demoEmployees.first.id
        : selectedEmployeeId ?? 'company';
    return options.firstWhere((option) => option.id == id);
  }

  static void _noop() {}
}
