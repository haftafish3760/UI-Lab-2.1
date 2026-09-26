import '../../data/prototype_operations_store.dart';
import '../../data/work/directory_persistence_session.dart';
import '../../data/work/employee_work_status.dart';
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
    final options = _options(context);
    final selected =
        options
            .where((o) => o.id == (selectedEmployeeId ?? 'company'))
            .firstOrNull ??
        options.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OperationalHeader(
          view: view,
          onViewChanged: onViewChanged,
          selectedContext: selected,
          contextOptions: options,
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
            employees: workEmployeeOptions(context),
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

  List<OperationalHeaderContextOption> _options(BuildContext context) {
    final employees = workEmployeeOptions(context);
    final employeeOptions = [
      for (final employee in employees)
        OperationalHeaderContextOption(
          id: employee.id,
          kind: OperationalContextKind.employee,
          title: employee.name,
          detail: employee.status,
          icon: employee.icon,
          iconColor: employee.color,
        ),
    ];
    if (view == AppViewMode.technician) {
      return [
        employeeOptions.where((e) => e.id == selectedEmployeeId).firstOrNull ??
            OperationalHeaderContextOption(
              id: selectedEmployeeId ?? 'alex',
              kind: OperationalContextKind.employee,
              title: 'My work',
              detail: '',
              icon: Icons.person_outline,
            ),
      ];
    }
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

  static void _noop() {}
}

List<EmployeeStatus> workEmployeeOptions(BuildContext context) {
  final store = PrototypeOperationsScope.maybeOf(context);
  final directory = store?.directorySession;
  if (directory == null) return demoEmployees;
  final work = store?.workSession;
  final workday = store?.workdaySession;
  final now = DateTime.now();
  return [
    for (final e in directory.employees.where((e) => e.active))
      EmployeeStatus(
        e.id,
        e.name,
        work == null
            ? 'Job status unavailable'
            : employeeWorkStatus(
                employeeId: e.id,
                visibleJobs: work.records,
                visibleWorkdays:
                    workday?.records.map((item) => item.record) ?? const [],
                now: now,
              ).label,
        Icons.person_outline,
        Theme.of(context).colorScheme.primary,
      ),
  ];
}
