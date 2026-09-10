import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_extension.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_scope.dart';
import '../dashboard/dashboard_models.dart';
import 'expenses_scope_header.dart';
import 'report_period.dart';
import 'reports_lanes.dart';
import 'reports_settings_screen.dart';
import 'reports_summary_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.initialView = AppViewMode.admin});

  final AppViewMode initialView;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  var _period = ReportPeriod.thisMonth;
  var _fixturePreferences = const ReportDisplayPreferences.defaults();
  ReportDisplayPreferences get _preferences =>
      readReportDisplayPreferences(context, _fixturePreferences);

  AppViewMode get _view => OperationalScope.of(context).view;
  String? get _selectedEmployeeId =>
      OperationalScope.of(context).selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('reports-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final companyScope =
                _view == AppViewMode.admin && _selectedEmployeeId == null;
            final reportView = companyScope
                ? AppViewMode.admin
                : AppViewMode.technician;
            final employeeName = companyScope
                ? null
                : dashboardEmployeeById(_selectedEmployeeId ?? 'alex').name;
            final summary = _reportSummary(context, employeeName: employeeName);
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.workFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 32),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExpensesScopeHeader(
                          view: _view,
                          selectedEmployeeId: _selectedEmployeeId,
                          onViewChanged: OperationalScope.of(context).setView,
                          onEmployeeChanged: OperationalScope.of(
                            context,
                          ).selectEmployee,
                          onSettings: _openSettings,
                          workspaceLabel: 'Reports',
                          showBackButton: true,
                          onBack: () => Navigator.of(context).pop(),
                          showEmployeeStrip: false,
                          contextKey: const ValueKey(
                            'reports-context-selector',
                          ),
                          viewKey: const ValueKey('reports-view-selector'),
                          settingsKey: const ValueKey(
                            'reports-settings-button',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ReportsHeading(
                          companyScope: companyScope,
                          ownScope: _view == AppViewMode.technician,
                          employeeName: employeeName,
                          period: _period,
                          onPeriodChanged: (value) =>
                              setState(() => _period = value),
                        ),
                        const SizedBox(height: 14),
                        ReportsSummaryStrip(
                          view: reportView,
                          summary: summary,
                          preferences: _preferences,
                        ),
                        if (companyScope &&
                            _preferences.showEstimatedGrossProfit) ...[
                          const SizedBox(height: 10),
                          const ReportsProfitBasisNote(),
                        ],
                        const SizedBox(height: 16),
                        ReportsLanes(
                          layout: layout,
                          view: reportView,
                          summary: summary,
                          preferences: _preferences,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<ReportDisplayPreferences>(
      MaterialPageRoute<ReportDisplayPreferences>(
        builder: (_) => ReportsSettingsScreen(initial: _preferences),
      ),
    );
    if (mounted && result != null) setState(() => _fixturePreferences = result);
  }

  PrototypeReportSummary _reportSummary(
    BuildContext context, {
    required String? employeeName,
  }) {
    final today = DateUtils.dateOnly(DateTime.now());
    final range = _period.rangeFor(today);
    return PrototypeOperationsScope.of(context).reportSummary(
      fromInclusive: range.fromInclusive,
      toExclusive: range.toExclusive,
      employeeId: employeeName == null ? null : _selectedEmployeeId ?? 'alex',
      employeeName: employeeName,
      asOf: today,
    );
  }
}

class _ReportsHeading extends StatelessWidget {
  const _ReportsHeading({
    required this.companyScope,
    required this.ownScope,
    required this.employeeName,
    required this.period,
    required this.onPeriodChanged,
  });
  final bool companyScope;
  final bool ownScope;
  final String? employeeName;
  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyScope
                  ? 'Company performance'
                  : ownScope
                  ? 'My work recap'
                  : '$employeeName recap',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 3),
            Text(
              period.dateRangeLabel(context, DateTime.now()),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              companyScope
                  ? 'See money collected, business expenses, completed work, and the records behind each total.'
                  : ownScope
                  ? 'Review your completed jobs, business expenses, unfinished records, and the sources behind each total.'
                  : 'Review completed jobs, business expenses, unfinished records, and the sources behind each total.',
            ),
          ],
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          PopupMenuButton<ReportPeriod>(
            initialValue: period,
            onSelected: onPeriodChanged,
            itemBuilder: (_) => [
              for (final option in ReportPeriod.values)
                PopupMenuItem(
                  value: option,
                  child: Text(option.localizedLabel(context.l10n)),
                ),
            ],
            child: _MenuLabel(
              icon: Icons.date_range_outlined,
              label: period.localizedLabel(context.l10n),
            ),
          ),
        ],
      ),
    ],
  );
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 42, maxWidth: 190),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_drop_down, size: 18),
      ],
    ),
  );
}
