import 'package:flutter/material.dart';

import '../../data/prototype_financial_models.dart';
import '../../shared/section_card.dart';
import '../../theme/app_theme.dart';
import 'dashboard_models.dart';

class CalendarDayApprovals extends StatefulWidget {
  const CalendarDayApprovals({
    required this.entries,
    required this.onOpen,
    super.key,
  });

  final List<DayEntry> entries;
  final ValueChanged<DayEntry> onOpen;

  @override
  State<CalendarDayApprovals> createState() => _CalendarDayApprovalsState();
}

class _CalendarDayApprovalsState extends State<CalendarDayApprovals> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final pending =
        widget.entries
            .where(
              (entry) =>
                  entry.reviewStatus == DayEntryReviewStatus.needsApproval,
            )
            .toList()
          ..sort(
            (a, b) => dashboardTimeMinutes(
              a.time,
            ).compareTo(dashboardTimeMinutes(b.time)),
          );
    if (pending.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final background = Color.alphaBlend(
      colors.error.withValues(alpha: .07),
      colors.surface,
    );
    return SectionCard(
      key: const ValueKey('calendar-day-approvals'),
      padding: EdgeInsets.zero,
      backgroundColor: background,
      borderColor: colors.error.withValues(alpha: .42),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Icon(Icons.fact_check_outlined, color: colors.error),
            title: Text(
              '${pending.length} ${pending.length == 1 ? 'item needs' : 'items need'} approval',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Review before this day is finalized'),
            trailing: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: colors.error.withValues(alpha: .28)),
            for (final entry in pending)
              ListTile(
                key: ValueKey('approval-row-${entry.id}'),
                onTap: () => widget.onOpen(entry),
                leading: Text(
                  entry.time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                title: Text(entry.title),
                subtitle: Text(entry.approvalReason ?? entry.detail),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
          ],
        ],
      ),
    );
  }
}

class CalendarDayMetricStrip extends StatelessWidget {
  const CalendarDayMetricStrip({
    required this.companyScope,
    required this.data,
    required this.vehicleName,
    required this.onVehicleDetails,
    super.key,
  });

  final bool companyScope;
  final DashboardDayData data;
  final String vehicleName;
  final VoidCallback onVehicleDetails;

  @override
  Widget build(BuildContext context) {
    final plannedJobs = data.plan
        .where((item) => item.kind == PlanItemKind.jobStop)
        .toList();
    final completedJobs = plannedJobs
        .where((item) => item.status.toLowerCase() == 'completed')
        .length;
    final tripCount = data.entries
        .where((entry) => entry.kind == DayEntryKind.trip)
        .length;
    final metrics = companyScope
        ? <_DayMetric>[
            _DayMetric(
              'Planned work',
              _countLabel(data.plan.length, 'item'),
              Icons.event_available_outlined,
            ),
            _DayMetric(
              'Day records',
              _countLabel(data.entries.length, 'record'),
              Icons.history_rounded,
            ),
            _DayMetric(
              'Jobs scheduled',
              _countLabel(plannedJobs.length, 'job'),
              Icons.home_repair_service_outlined,
            ),
            _DayMetric(
              'Jobs completed',
              _countLabel(completedJobs, 'job'),
              Icons.task_alt_outlined,
            ),
          ]
        : <_DayMetric>[
            _DayMetric(
              'Planned work',
              _countLabel(data.plan.length, 'item'),
              Icons.event_available_outlined,
            ),
            _DayMetric(
              'Day records',
              _countLabel(data.entries.length, 'record'),
              Icons.history_rounded,
            ),
            _DayMetric(
              'Trips recorded',
              _countLabel(tripCount, 'trip'),
              Icons.route_outlined,
            ),
            _DayMetric('Vehicle', vehicleName, Icons.local_shipping_outlined),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day at a glance',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            key: const ValueKey('calendar-day-metric-strip'),
            scrollDirection: Axis.horizontal,
            itemCount: metrics.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return _MetricCard(
                metric: metric,
                onTap: metric.label == 'Vehicle' ? onVehicleDetails : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class CalendarDayRecap extends StatelessWidget {
  const CalendarDayRecap({
    required this.companyScope,
    required this.data,
    required this.financialSummary,
    required this.canViewCompanyFinancials,
    required this.pendingApprovals,
    super.key,
  });

  final bool companyScope;
  final DashboardDayData data;
  final PrototypeFinancialSummary financialSummary;
  final bool canViewCompanyFinancials;
  final int pendingApprovals;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries;
    final tripCount = entries
        .where((entry) => entry.kind == DayEntryKind.trip)
        .length;
    final expenseCount = entries
        .where((entry) => entry.kind == DayEntryKind.expense)
        .length;
    final documentCount = entries
        .where(
          (entry) =>
              entry.kind == DayEntryKind.estimate ||
              entry.kind == DayEntryKind.invoice ||
              entry.kind == DayEntryKind.payment,
        )
        .length;
    final rows = companyScope
        ? <(IconData, String, String)>[
            (
              Icons.event_available_outlined,
              'Planned work',
              _countLabel(data.plan.length, 'item'),
            ),
            (
              Icons.history_rounded,
              'Recorded activity',
              _countLabel(entries.length, 'record'),
            ),
            if (canViewCompanyFinancials) ...[
              (
                Icons.description_outlined,
                'Invoiced',
                _moneyCents(financialSummary.invoicedRevenueCents),
              ),
              (
                Icons.payments_outlined,
                'Collected',
                _moneyCents(financialSummary.moneyCollectedCents),
              ),
              (
                Icons.receipt_long_outlined,
                'Recorded expenses',
                _moneyCents(financialSummary.recordedExpenseCents),
              ),
              (
                Icons.trending_up_rounded,
                'Estimated gross profit',
                '${_moneyCents(financialSummary.estimatedGrossProfitCents)} · invoiced minus recorded expenses',
              ),
            ],
            (
              Icons.fact_check_outlined,
              'Review queue',
              pendingApprovals == 0
                  ? 'No items waiting'
                  : '${_countLabel(pendingApprovals, 'item')} waiting',
            ),
          ]
        : <(IconData, String, String)>[
            (
              Icons.event_available_outlined,
              'Planned work',
              _countLabel(data.plan.length, 'item'),
            ),
            (
              Icons.history_rounded,
              'Day records',
              _countLabel(entries.length, 'record'),
            ),
            (Icons.route_outlined, 'Trips', _countLabel(tripCount, 'record')),
            (
              Icons.receipt_long_outlined,
              'Expenses',
              _countLabel(expenseCount, 'record'),
            ),
            (
              Icons.description_outlined,
              'Work documents',
              _countLabel(documentCount, 'record'),
            ),
            (
              Icons.fact_check_outlined,
              'Review status',
              pendingApprovals == 0
                  ? 'No items waiting'
                  : '${_countLabel(pendingApprovals, 'item')} waiting',
            ),
          ];
    final colors = Theme.of(context).colorScheme;
    return SectionCard(
      key: const ValueKey('calendar-day-recap'),
      backgroundColor: colors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            companyScope ? 'Company day recap' : 'Day recap',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            companyScope
                ? 'Authorized totals from this company day.'
                : 'Confirmed activity and records from this workday.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < rows.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(rows[index].$1, size: 18, color: colors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rows[index].$2,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rows[index].$3,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (index != rows.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

String _countLabel(int count, String noun) =>
    '$count ${count == 1 ? noun : '${noun}s'}';

String _moneyCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final amount = cents.abs() / 100;
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$sign\$$whole.${parts.last}';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, this.onTap});

  final _DayMetric metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 100,
      child: Material(
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.outline),
          borderRadius: BorderRadius.circular(AppRadii.surface),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(metric.icon, size: 20, color: colors.primary),
                const Spacer(),
                Text(
                  metric.value,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  maxLines: 2,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayMetric {
  const _DayMetric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}
