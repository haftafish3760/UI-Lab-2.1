import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/operations_workspace.dart';
import '../../shared/operational_scope.dart';
import '../../shared/app_view_mode.dart';
import '../work/work_models.dart';
import '../work/estimate_models.dart';
import '../expenses/reports_screen.dart';
import '../../shared/section_card.dart';
import 'dashboard_models.dart';
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
    this.urgentCount = 0,
    this.summaryOnly = false,
  });
  final DateTime date;
  final DashboardPermissions permissions;
  final ValueChanged<PlanItem> onOpenPlan;
  final VoidCallback onAttention;
  final int attentionCount;
  final int urgentCount;
  final bool summaryOnly;

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
    final sections = <Widget>[
      if (summaryOnly && attentionCount > 0)
        _navigationRow(
          title: urgentCount > 0 ? 'Urgent attention' : 'Needs attention',
          detail: urgentCount > 0
              ? '$urgentCount urgent · ${attentionCount - urgentCount} normal'
              : '$attentionCount ${attentionCount == 1 ? 'item needs' : 'items need'} attention',
          icon: Icons.notifications_active_outlined,
          onTap: onAttention,
        ),
      if (!summaryOnly && permissions.canViewCompanyFinancials)
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
      if (summaryOnly && permissions.canViewCompanyFinancials)
        _navigationRow(
          title: 'Recap',
          detail: 'View totals and supporting records',
          icon: Icons.insights_outlined,
          onTap: () => _open(context, const ReportsScreen()),
        ),
    ];
    return Column(
      key: ValueKey(
        summaryOnly ? 'admin-company-summary' : 'admin-company-overview',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        icon: title == 'Money spent'
            ? Icons.receipt_long_outlined
            : Icons.account_balance_wallet_outlined,
        tone: title == 'Money spent'
            ? OperationalCardPalette.expenses
            : title == 'Money received'
            ? OperationalCardPalette.payments
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
        key: PageStorageKey('admin-billing-$label'),
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

  Widget _navigationRow({
    required String title,
    required String detail,
    required IconData icon,
    required VoidCallback onTap,
  }) => SectionCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(detail),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
  void _open(BuildContext context, Widget page) {
    if (!permissions.canViewCompanyFinancials ||
        OperationalScope.of(context).view != AppViewMode.admin) {
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
