import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/section_card.dart';
import 'report_sources_screen.dart';
import 'report_period.dart';

class ReportsSummaryStrip extends StatelessWidget {
  const ReportsSummaryStrip({
    required this.view,
    required this.summary,
    required this.preferences,
    super.key,
  });

  final AppViewMode view;
  final PrototypeReportSummary summary;
  final ReportDisplayPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final metrics = view == AppViewMode.admin
        ? <_SummaryMetric>[
            if (preferences.showInvoicedRevenue)
              _SummaryMetric(
                keyName: 'invoiced-revenue',
                label: 'Invoiced revenue',
                value: reportMoneyCents(summary.financial.invoicedRevenueCents),
                icon: Icons.request_quote_outlined,
                basis: 'Invoices issued during the selected period.',
                sources: summary.invoicesIssued,
              ),
            if (preferences.showMoneyCollected)
              _SummaryMetric(
                keyName: 'money-collected',
                label: 'Money collected',
                value: reportMoneyCents(summary.financial.moneyCollectedCents),
                icon: Icons.payments_outlined,
                basis: 'Payments received during the selected period.',
                sources: summary.paymentsReceived,
              ),
            if (preferences.showRecordedExpenses)
              _SummaryMetric(
                keyName: 'recorded-expenses',
                label: 'Recorded expenses',
                value: reportMoneyCents(summary.financial.recordedExpenseCents),
                icon: Icons.receipt_long_outlined,
                basis: 'Business expenses dated within the selected period.',
                sources: summary.recordedExpenses,
              ),
            if (preferences.showEstimatedGrossProfit)
              _SummaryMetric(
                keyName: 'estimated-gross-profit',
                label: 'Estimated gross profit',
                value: reportMoneyCents(
                  summary.financial.estimatedGrossProfitCents,
                ),
                icon: Icons.trending_up_outlined,
                basis:
                    'Invoiced revenue minus recorded business expenses for the selected period.',
                sources: [
                  ...summary.invoicesIssued,
                  ...summary.recordedExpenses,
                ],
              ),
          ]
        : <_SummaryMetric>[
            _SummaryMetric(
              keyName: 'completed-jobs',
              label: 'Completed jobs',
              value: '${summary.completedJobs.length}',
              icon: Icons.task_alt_outlined,
              basis:
                  'Your jobs with a confirmed completion date in the selected period.',
              sources: summary.completedJobs,
            ),
            _SummaryMetric(
              keyName: 'expense-records',
              label: 'Expense records',
              value: '${summary.expenses.length}',
              icon: Icons.receipt_long_outlined,
              basis: 'Your business expenses dated within the selected period.',
              sources: summary.expenses,
            ),
            _SummaryMetric(
              keyName: 'my-expenses',
              label: 'My expenses',
              value: reportMoneyCents(summary.scopedExpenseCents),
              icon: Icons.payments_outlined,
              basis:
                  'The total of your expense records in the selected period.',
              sources: summary.expenses,
            ),
            _SummaryMetric(
              keyName: 'records-to-finish',
              label: 'Records to finish',
              value: '${summary.recordsToFinish.length}',
              icon: Icons.edit_note_outlined,
              basis: 'Your records that still need information from you.',
              sources: summary.recordsToFinish,
            ),
          ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final metric in metrics) _SummaryCard(metric: metric)],
    );
  }
}

class ReportsProfitBasisNote extends StatelessWidget {
  const ReportsProfitBasisNote({super.key});

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Estimated gross profit is invoiced revenue minus recorded costs. It is not tax or payroll advice and excludes costs that have not been recorded.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.metric});

  final _SummaryMetric metric;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 140, maxWidth: 190),
    child: SectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('report-summary-${metric.keyName}'),
        onTap: () => _openSources(context, metric),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(metric.icon, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(metric.label, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}

void _openSources(BuildContext context, _SummaryMetric metric) {
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ReportSourcesScreen(
        title: metric.label,
        basis: metric.basis,
        sources: metric.sources,
      ),
    ),
  );
}

class _SummaryMetric {
  const _SummaryMetric({
    required this.keyName,
    required this.label,
    required this.value,
    required this.icon,
    required this.basis,
    required this.sources,
  });

  final String keyName;
  final String label;
  final String value;
  final IconData icon;
  final String basis;
  final List<PrototypeReportSource> sources;
}
