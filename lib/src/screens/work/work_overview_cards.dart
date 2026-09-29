import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations_extension.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/invoice_payment_balance.dart';
import '../../data/work/work_overview_query.dart';
import '../../shared/operational_summary_strip.dart';
import '../../theme/operational_card_palette.dart';
import 'work_overview_scope.dart';

/// Invoice money across all dates, restricted to the current visible records.
/// Unpaid has no recorded payment; Overdue can overlap unpaid or partial.
class WorkOverviewCards extends StatelessWidget {
  const WorkOverviewCards({
    required this.onSelected,
    this.selectedFilter,
    super.key,
  });
  final ValueChanged<WorkOverviewFilter> onSelected;
  final WorkOverviewFilter? selectedFilter;

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final records = visibleWorkOverviewRecords(context).toList();
    final l10n = context.l10n;
    final money = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      name: 'USD',
    );
    final cards = [
      (
        WorkOverviewFilter.invoicesWithoutPayments,
        l10n.workMoneyUnpaid,
        Icons.receipt_long_outlined,
        OperationalCardPalette.plan,
      ),
      (
        WorkOverviewFilter.partiallyPaidInvoices,
        l10n.workPartiallyPaid,
        Icons.payments_outlined,
        OperationalCardPalette.plan,
      ),
      (
        WorkOverviewFilter.overdueInvoices,
        l10n.workMoneyOverdue,
        Icons.schedule_outlined,
        OperationalCardPalette.attention,
      ),
      (
        WorkOverviewFilter.paidInvoices,
        l10n.workMoneyPaid,
        Icons.payments_outlined,
        OperationalCardPalette.payments,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.workMoneyAllTime,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        OperationalSummaryStrip(
          items: [
            for (final (filter, label, icon, tone) in cards)
              OperationalSummaryItem(
                id: 'work-${filter.name}',
                selected: selectedFilter == filter,
                label: label,
                value: money.format(
                  workOverviewRecords(
                        records: records,
                        payments: store.financialEntries,
                        filter: filter,
                        now: DateTime.now(),
                      ).fold<int>(
                        0,
                        (sum, record) =>
                            sum +
                            (filter == WorkOverviewFilter.paidInvoices
                                ? (record.total * 100).round()
                                : invoiceBalanceCents(
                                    record,
                                    store.financialEntries,
                                  )),
                      ) /
                      100,
                ),
                color: tone.start,
                endColor: tone.end,
                foreground: tone.foreground,
                icon: icon,
                onTap: () => onSelected(filter),
              ),
          ],
        ),
      ],
    );
  }
}
