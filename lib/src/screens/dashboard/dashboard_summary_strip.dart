import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations_extension.dart';
import '../../data/prototype_operations_store.dart';
import '../../shared/operational_summary_strip.dart';
import '../../theme/operational_card_palette.dart';
import 'dashboard_models.dart';

class DashboardSummaryStrip extends StatelessWidget {
  const DashboardSummaryStrip({
    required this.date,
    required this.data,
    required this.attentionCount,
    required this.onAttention,
    required this.onPayments,
    required this.onExpenses,
    required this.onWork,
    required this.onMiles,
    super.key,
  });
  final DateTime date;
  final DashboardDayData data;
  final int attentionCount;
  final VoidCallback onAttention, onPayments, onExpenses, onWork, onMiles;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final financial = PrototypeOperationsScope.of(context).financialSummary(
      fromInclusive: DateUtils.dateOnly(date),
      toExclusive: DateTime(date.year, date.month, date.day + 1),
    );
    final money = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      name: 'USD',
    );
    return OperationalSummaryStrip(
      key: const ValueKey('dashboard-summary-strip'),
      items: [
        OperationalSummaryItem(
          id: 'attention',
          icon: Icons.warning_amber_rounded,
          label: l10n.attentionTitle,
          value: '$attentionCount',
          color: OperationalCardPalette.attention.start,
          endColor: OperationalCardPalette.attention.end,
          foreground: OperationalCardPalette.attention.foreground,
          onTap: onAttention,
        ),
        OperationalSummaryItem(
          id: 'payments',
          icon: Icons.payments_outlined,
          label: l10n.dashboardPaymentsLabel,
          value: money.format(financial.moneyCollectedCents / 100),
          color: OperationalCardPalette.payments.start,
          endColor: OperationalCardPalette.payments.end,
          onTap: onPayments,
        ),
        OperationalSummaryItem(
          id: 'expenses',
          icon: Icons.receipt_long_outlined,
          label: l10n.navExpenses,
          value: money.format(financial.recordedExpenseCents / 100),
          color: OperationalCardPalette.expenses.start,
          endColor: OperationalCardPalette.expenses.end,
          onTap: onExpenses,
        ),
        // Current prototype has no classified-trip-distance projection. Do
        // not fabricate zero miles or turn workday odometer change into
        // confirmed business distance. This stays visibly unavailable.
        OperationalSummaryItem(
          id: 'miles',
          icon: Icons.route_outlined,
          label: l10n.dashboardMilesLabel,
          value: '—',
          color: OperationalCardPalette.miles.start,
          endColor: OperationalCardPalette.miles.end,
          onTap: onMiles,
        ),
        OperationalSummaryItem(
          id: 'work',
          icon: Icons.work_outline,
          label: l10n.navWork,
          value:
              '${data.plan.where((item) => item.status == 'Completed').length}/${data.plan.length}',
          color: OperationalCardPalette.work.start,
          endColor: OperationalCardPalette.work.end,
          foreground: OperationalCardPalette.work.foreground,
          onTap: onWork,
        ),
      ],
    );
  }
}
