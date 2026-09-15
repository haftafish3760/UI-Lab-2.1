import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/operations_workspace.dart';
import '../../shared/operational_scope.dart';
import '../../shared/app_view_mode.dart';
import '../work/work_models.dart';
import '../work/estimate_models.dart';
import '../expenses/report_sources_screen.dart';
import 'dashboard_models.dart';
import '../../data/work/work_job_attention.dart';
import 'dashboard_review_section.dart';
import '../../theme/operational_card_palette.dart';

/// Company queues project the existing authorized records, never a new ledger.
class AdminDashboardOverview extends StatelessWidget {
  const AdminDashboardOverview({
    super.key,
    required this.date,
    required this.permissions,
    required this.onOpenPlan,
    required this.onAttention,
    required this.attentionCount,
  });
  final DateTime date;
  final DashboardPermissions permissions;
  final ValueChanged<PlanItem> onOpenPlan;
  final VoidCallback onAttention;
  final int attentionCount;

  @override
  Widget build(BuildContext context) {
    if (OperationalScope.of(context).view != AppViewMode.admin) {
      return const SizedBox.shrink();
    }
    final store = PrototypeOperationsScope.of(context);
    final grants = store.workSession?.permissions;
    final records = store.workRecords
        .where(
          (r) =>
              grants == null ||
              grants.visibleCreatorIds.contains(r.createdByEmployeeId),
        )
        .toList();
    final today = DateUtils.dateOnly(DateTime.now());
    final jobQueues = <String, List<WorkRecord>>{};
    if (permissions.canViewSchedule) {
      for (final record in records) {
        final queue = WorkJobAttention(record, today).primaryQueue;
        if (queue != null) {
          (jobQueues[queue] ??= []).add(record);
        }
      }
    }
    final estimates = records
        .where(
          (r) =>
              r.kind == WorkRecordKind.estimate &&
              r.resolvedEstimateStage == EstimateStage.awaitingCustomer,
        )
        .toList();
    final invoices = records
        .where((r) => r.kind == WorkRecordKind.invoice && r.issuedOn != null)
        .toList();
    int balance(WorkRecord r) {
      final paid = store.financialEntries
          .where(
            (e) =>
                e.kind == PrototypeFinancialKind.paymentReceived &&
                e.sourceId == r.number,
          )
          .fold<int>(0, (sum, e) => sum + e.amountCents);
      return ((r.total * 100).round() - paid).clamp(0, 1 << 62);
    }

    final unpaid = invoices.where((r) => balance(r) > 0).toList();
    final money = NumberFormat.simpleCurrency(
      name: 'USD',
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    final monthly = permissions.canViewCompanyFinancials
        ? store.reportSummary(
            fromInclusive: DateTime(date.year, date.month),
            toExclusive: DateTime(date.year, date.month + 1),
          )
        : null;
    final financial = monthly?.financial;
    final period = DateFormat.yMMMM(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
    void openSources(String title, List<PrototypeReportSource> sources) =>
        _open(
          context,
          ReportSourcesScreen(
            title: title,
            basis: '$period · USD',
            sources: sources,
          ),
        );
    final sections = <Widget>[
      _panel(context, 'Work needing action', [
        TextButton.icon(
          onPressed: onAttention,
          icon: const Icon(Icons.warning_amber_rounded),
          label: Text('Needs attention · $attentionCount'),
        ),
        for (final label in const [
          'Overdue jobs',
          'Paused or return visit',
          'Needs employees',
          'Needs a work date',
          'Other active jobs',
        ])
          _queue(context, label, jobQueues[label] ?? const []),
        const Text(
          'Overdue work has a scheduled finish (or start, if no finish was set) before today. Unscheduled jobs are not overdue.',
        ),
      ]),
      if (permissions.canViewCompanyFinancials)
        _panel(context, 'Billing and collections', [
          _queue(context, 'Estimates awaiting response', estimates),
          _queue(
            context,
            'Unpaid invoices',
            unpaid,
            detail: (r) =>
                '${money.format(balance(r) / 100)} outstanding${r.dueOn != null && r.dueOn!.isBefore(today) ? ' · Overdue' : ''}',
          ),
          const SizedBox(height: 8),
          Text(
            'Outstanding balance · ${money.format(unpaid.fold<int>(0, (sum, r) => sum + balance(r)) / 100)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Text(
            'All issued invoices, less linked payments. Drafts excluded.',
          ),
        ]),
      if (financial != null)
        _panel(context, '$period · Money · USD', [
          _metric(
            context,
            'Collected money',
            money.format(financial.moneyCollectedCents / 100),
            () => openSources('Collected money', monthly!.paymentsReceived),
          ),
          _metric(
            context,
            'Invoiced revenue',
            money.format(financial.invoicedRevenueCents / 100),
            () => openSources('Invoiced revenue', monthly!.invoicesIssued),
          ),
          _metric(
            context,
            'Recorded spending',
            money.format(financial.recordedExpenseCents / 100),
            () => openSources('Recorded spending', monthly!.recordedExpenses),
          ),
          const Divider(),
          const Text(
            'Profit unavailable — costs incomplete',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Text(
            'Labor, materials and overhead are not fully reconciled. Collected money and invoice totals are not profit.',
          ),
        ]),
    ];
    return Column(
      key: const ValueKey('admin-company-overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Company review', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Open work and unpaid invoices cover all dates. Money totals cover the month shown below.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => OperationsLaneGrid(
            layout: AppLayoutEngine.operationsFor(
              constraints.maxWidth,
              textScaler: MediaQuery.textScalerOf(context),
            ),
            children: sections,
          ),
        ),
      ],
    );
  }

  Widget _panel(BuildContext context, String title, List<Widget> children) =>
      DashboardReviewSection(
        title: title,
        icon: title == 'Work needing action'
            ? Icons.assignment_late_outlined
            : Icons.account_balance_wallet_outlined,
        tone: title == 'Work needing action'
            ? OperationalCardPalette.attention
            : OperationalCardPalette.entries,
        children: children,
      );
  Widget _queue(
    BuildContext context,
    String label,
    List<WorkRecord> records, {
    String Function(WorkRecord)? detail,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: OperationalCardPalette.entries.row,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text('$label · ${records.length}'),
        children: records.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('No matching records.'),
                ),
              ]
            : [
                for (final record in records)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${record.number} · ${record.title}'),
                    subtitle: Text(
                      detail?.call(record) ??
                          '${record.client} · ${record.status.label}\n${record.scheduledStart == null ? 'Not scheduled' : 'Scheduled ${DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toLanguageTag()).format(record.scheduledStart!)}'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final store = PrototypeOperationsScope.of(context);
                      final current = store.workRecords
                          .where((r) => r.id == record.id)
                          .firstOrNull;
                      if (OperationalScope.of(context).view !=
                              AppViewMode.admin ||
                          current == null ||
                          (store.workSession != null &&
                              !store.workSession!.permissions.visibleCreatorIds
                                  .contains(current.createdByEmployeeId))) {
                        return;
                      }
                      onOpenPlan(
                        PlanItem(
                          '',
                          current.title,
                          current.detail,
                          Icons.work_outline,
                          Colors.blueGrey,
                          id: current.id,
                          sourceRecordId: current.id,
                        ),
                      );
                    },
                  ),
              ],
      ),
    ),
  );

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    VoidCallback onTap,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
  void _open(BuildContext context, Widget page) {
    if (!permissions.canViewCompanyFinancials ||
        OperationalScope.of(context).view != AppViewMode.admin) {
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
