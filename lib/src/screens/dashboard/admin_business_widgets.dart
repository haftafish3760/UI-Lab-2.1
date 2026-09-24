import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/operational_attention.dart';
import '../../shared/operational_attention_panel.dart';
import '../../shared/section_card.dart';
import '../../theme/operational_card_palette.dart';
import '../work/work_models.dart';
import '../work/payments_screen.dart';
import 'dashboard_models.dart';
import 'dashboard_review_section.dart';

/// Company operations are a source-record projection, not technician stops.
class AdminCompanyWork extends StatelessWidget {
  const AdminCompanyWork({required this.date, required this.onOpen, super.key});
  final DateTime date;
  final ValueChanged<PlanItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final start = DateUtils.dateOnly(date);
    final end = DateTime(start.year, start.month, start.day + 1);
    final records =
        store.workRecords.where((record) {
          if (record.kind != WorkRecordKind.job) return false;
          final permissions = store.workSession?.permissions;
          if (permissions != null &&
              !permissions.visibleCreatorIds.contains(
                record.createdByEmployeeId,
              )) {
            return false;
          }
          final scheduled = record.scheduledStart;
          final finish = record.scheduledEnd ?? scheduled;
          final overlaps =
              scheduled != null &&
              finish != null &&
              scheduled.isBefore(end) &&
              !finish.isBefore(start);
          final ongoing =
              sameDashboardDay(date, DateTime.now()) &&
              const {
                WorkRecordStatus.inProgress,
                WorkRecordStatus.paused,
                WorkRecordStatus.needsReturnVisit,
              }.contains(record.status);
          final completed =
              record.completedOn != null &&
              sameDashboardDay(record.completedOn!, date);
          return overlaps || ongoing || completed;
        }).toList()..sort(
          (a, b) =>
              (a.scheduledStart ?? start).compareTo(b.scheduledStart ?? start),
        );
    return DashboardReviewSection(
      key: const ValueKey('admin-company-schedule'),
      title: sameDashboardDay(date, DateTime.now())
          ? 'Company work today'
          : 'Company work',
      icon: Icons.work_outline,
      tone: OperationalCardPalette.plan,
      children: [
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No jobs scheduled or in progress for this day.'),
          ),
        for (final record in records.take(4)) ...[
          _WorkRow(record: record, onOpen: () => _open(record)),
          const SizedBox(height: 8),
        ],
        if (records.length > 4)
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Company work'),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final record in records)
                          ListTile(
                            title: Text(record.title),
                            subtitle: Text(
                              '${record.client} · ${record.status.label}',
                            ),
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _open(record);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            child: Text('View all ${records.length} jobs'),
          ),
      ],
    );
  }

  void _open(WorkRecord record) => onOpen(
    PlanItem(
      '',
      record.title,
      record.detail,
      Icons.work_outline,
      OperationalCardPalette.plan.start,
      id: record.id,
      sourceRecordId: record.id,
    ),
  );
}

class _WorkRow extends StatelessWidget {
  const _WorkRow({required this.record, required this.onOpen});
  final WorkRecord record;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: OperationalCardPalette.plan.row,
    borderRadius: BorderRadius.circular(7),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      title: Text(record.title),
      subtitle: Text(
        '${record.client}\n'
        '${record.assignee?.isNotEmpty == true ? record.assignee : 'Not assigned'}'
        ' · ${record.status.label}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onOpen,
    ),
  );
}

class AdminApprovalQueue extends StatelessWidget {
  const AdminApprovalQueue({
    required this.items,
    required this.onOpen,
    required this.onOpenAll,
    super.key,
  });
  final List<OperationalAttentionItem> items;
  final ValueChanged<OperationalAttentionItem> onOpen;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) => DashboardReviewSection(
    key: const ValueKey('admin-approvals'),
    title: 'Approvals · ${items.length}',
    icon: Icons.fact_check_outlined,
    tone: OperationalCardPalette.attention,
    children: [
      if (items.isEmpty) const Text('Nothing awaiting approval.'),
      for (final item in items.take(3)) ...[
        OperationalAttentionRow(item: item, onOpen: () => onOpen(item)),
        const SizedBox(height: 8),
      ],
      if (items.length > 3)
        TextButton(
          onPressed: onOpenAll,
          child: const Text('View all requests'),
        ),
    ],
  );
}

class AdminPaymentsToday extends StatelessWidget {
  const AdminPaymentsToday({required this.date, super.key});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final permissions = store.workSession?.permissions;
    final visibleInvoices = store.workRecords
        .where(
          (record) =>
              record.kind == WorkRecordKind.invoice &&
              (permissions == null ||
                  permissions.visibleCreatorIds.contains(
                    record.createdByEmployeeId,
                  )),
        )
        .map((record) => record.number)
        .toSet();
    final entries = store.financialEntries.where(
      (entry) =>
          entry.kind == PrototypeFinancialKind.paymentReceived &&
          (permissions == null || visibleInvoices.contains(entry.sourceId)) &&
          sameDashboardDay(entry.occurredOn, date),
    );
    final cents = entries.fold<int>(0, (sum, item) => sum + item.amountCents);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DashboardReviewSection(
      title: 'Payments received',
      icon: Icons.payments_outlined,
      children: [
        Text(
          NumberFormat.simpleCurrency(
            name: 'USD',
            locale: locale,
          ).format(cents / 100),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(DateFormat.yMMMd(locale).format(date)),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PaymentsScreen(initialDay: date),
            ),
          ),
          icon: const Icon(Icons.chevron_right),
          label: Text('View ${entries.length} payments'),
        ),
      ],
    );
  }
}

class AdminAttentionSummary extends StatelessWidget {
  const AdminAttentionSummary({
    required this.items,
    required this.onOpen,
    super.key,
  });
  final List<OperationalAttentionItem> items;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final urgent = items.where((item) => item.isUrgent).length;
    return SectionCard(
      key: const ValueKey('dashboard-needs-attention'),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          urgent > 0 ? Icons.warning_amber : Icons.notifications_none,
        ),
        title: Text(
          urgent > 0
              ? '$urgent urgent items need attention'
              : 'Needs attention',
        ),
        subtitle: Text(
          items.isEmpty
              ? 'No flagged items.'
              : '${items.length} items to review or follow up',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}
