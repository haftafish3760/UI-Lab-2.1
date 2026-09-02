import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/section_card.dart';
import 'report_period.dart';
import 'report_sources_screen.dart';

class ReportsLanes extends StatelessWidget {
  const ReportsLanes({
    required this.layout,
    required this.view,
    required this.summary,
    required this.preferences,
    super.key,
  });

  final OperationsWorkspaceLayout layout;
  final AppViewMode view;
  final PrototypeReportSummary summary;
  final ReportDisplayPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final sections = view == AppViewMode.admin
        ? _adminSections(summary, preferences)
        : _technicianSections(summary);
    if (layout.columns == 1) {
      return Column(
        children: [
          for (var index = 0; index < sections.length; index++) ...[
            sections[index],
            if (index != sections.length - 1) SizedBox(height: layout.gap),
          ],
        ],
      );
    }
    return Wrap(
      key: ValueKey('reports-${layout.columns}-column-layout'),
      spacing: layout.gap,
      runSpacing: layout.gap,
      children: [
        for (final section in sections)
          SizedBox(width: layout.laneWidth, child: section),
      ],
    );
  }
}

List<Widget> _adminSections(
  PrototypeReportSummary summary,
  ReportDisplayPreferences preferences,
) => [
  _ReportSection(
    title: 'Money collected',
    icon: Icons.account_balance_wallet_outlined,
    rows: [
      _row(
        'payments-recorded',
        'Payments recorded',
        '${summary.paymentsReceived.length} · ${reportMoneyCents(summary.financial.moneyCollectedCents)}',
        'Payments received during the selected period.',
        summary.paymentsReceived,
      ),
      _row(
        'invoices-issued',
        'Invoices issued',
        '${summary.invoicesIssued.length} · ${reportMoneyCents(summary.financial.invoicedRevenueCents)}',
        'Invoices issued during the selected period.',
        summary.invoicesIssued,
      ),
      _row(
        'still-owed',
        'Still owed',
        reportMoneyCents(summary.outstandingInvoiceCents),
        'Unpaid invoices issued during the selected period.',
        summary.outstandingInvoices,
      ),
      _row(
        'overdue',
        'Overdue',
        reportMoneyCents(summary.overdueInvoiceCents),
        'Unpaid selected-period invoices past their due date.',
        summary.overdueInvoices,
      ),
    ],
  ),
  _ReportSection(
    title: 'Money spent',
    icon: Icons.receipt_long_outlined,
    rows: [
      _row(
        'materials-spent',
        'Materials',
        reportMoneyCents(summary.materialExpenseCents),
        'Material expenses dated within the selected period.',
        summary.materialExpenses,
      ),
      _row(
        'fuel-vehicle-spent',
        'Fuel and vehicles',
        reportMoneyCents(summary.fuelAndVehicleExpenseCents),
        'Fuel and vehicle expenses dated within the selected period.',
        summary.fuelAndVehicleExpenses,
      ),
      _row(
        'other-spent',
        'Other business costs',
        reportMoneyCents(summary.otherExpenseCents),
        'Other business expenses dated within the selected period.',
        summary.otherExpenses,
      ),
      _row(
        'all-expenses',
        'All recorded expenses',
        reportMoneyCents(summary.financial.recordedExpenseCents),
        'All business expenses dated within the selected period.',
        summary.recordedExpenses,
      ),
    ],
  ),
  if (preferences.showEstimatedGrossProfit)
    _ReportSection(
      title: 'Profit and review',
      icon: Icons.trending_up_outlined,
      rows: [
        _row(
          'gross-profit',
          'Estimated gross profit',
          reportMoneyCents(summary.financial.estimatedGrossProfitCents),
          'Invoiced revenue minus recorded business expenses.',
          [...summary.invoicesIssued, ...summary.recordedExpenses],
        ),
        _row(
          'gross-margin',
          'Estimated gross margin',
          '${(summary.financial.estimatedGrossMargin * 100).toStringAsFixed(1)}%',
          'Estimated gross profit divided by invoiced revenue.',
          [...summary.invoicesIssued, ...summary.recordedExpenses],
        ),
        _row(
          'records-needing-review',
          'Records needing review',
          '${summary.pendingAdminReview.length}',
          'Pending company approvals and overdue invoices in this period.',
          summary.pendingAdminReview,
        ),
      ],
    ),
  if (preferences.showVehicleHealth)
    _ReportSection(
      title: 'Vehicles and fuel',
      icon: Icons.local_shipping_outlined,
      rows: [
        _row(
          'fuel-expenses',
          'Fuel expenses',
          reportMoneyCents(summary.fuelExpenseCents),
          'Fuel expenses dated within the selected period.',
          summary.fuelExpenses,
        ),
        _row(
          'vehicle-repairs',
          'Vehicle repairs',
          reportMoneyCents(summary.vehicleRepairExpenseCents),
          'Vehicle repair expenses dated within the selected period.',
          summary.vehicleRepairExpenses,
        ),
        _row(
          'vehicle-maintenance',
          'Vehicle maintenance',
          reportMoneyCents(summary.vehicleMaintenanceExpenseCents),
          'Vehicle maintenance expenses dated within the selected period.',
          summary.vehicleMaintenanceExpenses,
        ),
        const _ReportRowData(
          keyName: 'mileage-fuel-economy',
          label: 'Mileage and fuel economy',
          value: 'Not recorded yet',
          basis:
              'These metrics appear after confirmed trip and odometer records are stored.',
          sources: [],
        ),
      ],
    ),
];

List<Widget> _technicianSections(PrototypeReportSummary summary) => [
  _ReportSection(
    title: 'Completed work',
    icon: Icons.task_alt_outlined,
    rows: [
      _row(
        'completed-jobs',
        'Completed jobs',
        '${summary.completedJobs.length}',
        'Your jobs with a confirmed completion date in this period.',
        summary.completedJobs,
      ),
      _row(
        'scheduled-active-jobs',
        'Scheduled or active jobs',
        '${summary.activeJobs.length}',
        'Your non-completed jobs that overlap this period.',
        summary.activeJobs,
      ),
      _row(
        'draft-estimates',
        'Estimate drafts',
        '${summary.draftEstimates.length}',
        'Estimate drafts you created during this period.',
        summary.draftEstimates,
      ),
    ],
  ),
  _ReportSection(
    title: 'My expenses and review',
    icon: Icons.receipt_long_outlined,
    rows: [
      _row(
        'expense-records',
        'Expense records',
        '${summary.expenses.length}',
        'Your business expenses dated within this period.',
        summary.expenses,
      ),
      _row(
        'my-expenses-total',
        'My expenses',
        reportMoneyCents(summary.scopedExpenseCents),
        'The total of your expense records in this period.',
        summary.expenses,
      ),
      _row(
        'records-to-finish',
        'Records to finish',
        '${summary.recordsToFinish.length}',
        'Your records that still need information from you.',
        summary.recordsToFinish,
      ),
      _row(
        'waiting-for-approval',
        'Waiting for approval',
        '${summary.waitingForApproval.length}',
        'Your submitted records waiting for company review.',
        summary.waitingForApproval,
      ),
    ],
  ),
  const _ReportSection(
    title: 'Time and travel',
    icon: Icons.route_outlined,
    rows: [
      _ReportRowData(
        keyName: 'hours-recorded',
        label: 'Hours recorded',
        value: 'Not recorded yet',
        basis:
            'Hours will appear after confirmed work-session records are stored.',
        sources: [],
      ),
      _ReportRowData(
        keyName: 'miles-recorded',
        label: 'Miles recorded',
        value: 'Not recorded yet',
        basis:
            'Miles will appear after confirmed trip and odometer records are stored.',
        sources: [],
      ),
    ],
  ),
];

_ReportRowData _row(
  String keyName,
  String label,
  String value,
  String basis,
  List<PrototypeReportSource> sources,
) => _ReportRowData(
  keyName: keyName,
  label: label,
  value: value,
  basis: basis,
  sources: sources,
);

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_ReportRowData> rows;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        ListTile(
          minTileHeight: 48,
          tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          leading: Icon(icon),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        for (final row in rows)
          ListTile(
            key: ValueKey('report-row-${row.keyName}'),
            minTileHeight: 52,
            title: Text(row.label),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (row.sources.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ],
            ),
            onTap: row.sources.isEmpty
                ? null
                : () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ReportSourcesScreen(
                        title: row.label,
                        basis: row.basis,
                        sources: row.sources,
                      ),
                    ),
                  ),
          ),
      ],
    ),
  );
}

class _ReportRowData {
  const _ReportRowData({
    required this.keyName,
    required this.label,
    required this.value,
    required this.basis,
    required this.sources,
  });

  final String keyName;
  final String label;
  final String value;
  final String basis;
  final List<PrototypeReportSource> sources;
}
