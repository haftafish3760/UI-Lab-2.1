import 'package:flutter/material.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../data/work/work_overview_query.dart';

const invoiceListFilters = [
  WorkOverviewFilter.allInvoices,
  WorkOverviewFilter.unpaidInvoices,
  WorkOverviewFilter.partiallyPaidInvoices,
  WorkOverviewFilter.overdueInvoices,
  WorkOverviewFilter.paidInvoices,
  WorkOverviewFilter.invoicesWithPayments,
  WorkOverviewFilter.draftInvoices,
];

/// Compact invoice-only controls: no unrelated job/estimate choices.
class WorkInvoiceFilterStrip extends StatefulWidget {
  const WorkInvoiceFilterStrip({
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final WorkOverviewFilter selected;
  final ValueChanged<WorkOverviewFilter> onSelected;

  @override
  State<WorkInvoiceFilterStrip> createState() => _WorkInvoiceFilterStripState();
}

class _WorkInvoiceFilterStripState extends State<WorkInvoiceFilterStrip> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealSelected();
  }

  @override
  void didUpdateWidget(WorkInvoiceFilterStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _revealSelected();
  }

  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedContext = _selectedKey.currentContext;
      if (mounted && selectedContext != null) {
        final renderObject = selectedContext.findRenderObject();
        if (renderObject != null) {
          Scrollable.of(
            selectedContext,
          ).position.ensureVisible(renderObject, alignment: .5);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.workFilterAllShort,
      l10n.workMoneyUnpaid,
      l10n.workPartiallyPaid,
      l10n.workMoneyOverdue,
      l10n.workMoneyPaid,
      l10n.workPaymentsReceivedShort,
      l10n.workDraftsShort,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < invoiceListFilters.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              key: widget.selected == invoiceListFilters[i]
                  ? _selectedKey
                  : null,
              child: ChoiceChip(
                key: ValueKey('invoice-status-${invoiceListFilters[i].name}'),
                label: Text(labels[i]),
                selected: widget.selected == invoiceListFilters[i],
                onSelected: (_) => widget.onSelected(invoiceListFilters[i]),
              ),
            ),
        ],
      ),
    );
  }
}
