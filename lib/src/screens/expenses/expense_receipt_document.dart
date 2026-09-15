import 'package:flutter/material.dart';

import '../../shared/localized_date.dart';
import '../../shared/section_card.dart';
import '../dashboard/dashboard_models.dart';
import 'expense_models.dart';
import 'expense_receipt_document_widgets.dart';

class ExpenseReceiptDocument extends StatefulWidget {
  const ExpenseReceiptDocument({
    required this.expense,
    this.onEditLine,
    this.onOpenEvidence,
    super.key,
  });

  final ExpenseRecord expense;
  final ValueChanged<ExpenseLineItem>? onEditLine;
  final VoidCallback? onOpenEvidence;

  @override
  State<ExpenseReceiptDocument> createState() => _ExpenseReceiptDocumentState();
}

class _ExpenseReceiptDocumentState extends State<ExpenseReceiptDocument> {
  final _search = TextEditingController();
  var _visibleLimit = 25;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final colors = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();
    final matches = expense.lineItems.where((item) {
      if (query.isEmpty) return true;
      return item.description.toLowerCase().contains(query) ||
          (item.partNumber ?? '').toLowerCase().contains(query) ||
          item.category.label.toLowerCase().contains(query) ||
          (item.jobLabel ?? '').toLowerCase().contains(query);
    }).toList();
    final visible = matches.take(_visibleLimit).toList();

    return SectionCard(
      key: const ValueKey('expense-receipt-details'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 10, 8),
            color: colors.surfaceContainerHigh,
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 21),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Receipt details',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text('${expense.lineItems.length} items'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (expense.receiptImageCount > 0)
                  _InlineReceiptEvidence(
                    expense: expense,
                    onOpenEvidence: widget.onOpenEvidence,
                  )
                else
                  Text(expense.receiptStatus ?? 'No receipt image attached.'),
                const SizedBox(height: 12),
                Text(
                  expense.displayVendor,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  operationalDateLabel(
                    context,
                    expense.resolvedDate ?? dashboardToday,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (expense.receiptType == ExpenseReceiptType.detailed) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Items on this receipt',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    widget.onEditLine == null
                        ? 'Reviewed receipt items.'
                        : 'Tap any item to review or change it.',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  _ReceiptLineSearch(
                    controller: _search,
                    query: query,
                    onChanged: () => setState(() => _visibleLimit = 25),
                    onClear: () {
                      _search.clear();
                      setState(() => _visibleLimit = 25);
                    },
                  ),
                  const SizedBox(height: 8),
                  if (expense.lineItems.isEmpty)
                    const Text('No reviewed line items have been saved yet.')
                  else if (matches.isEmpty)
                    const Text('No receipt items match that search.')
                  else ...[
                    Text(
                      'Showing ${visible.length} of ${matches.length}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (var index = 0; index < visible.length; index++) ...[
                      ExpenseReceiptLineCard(
                        item: visible[index],
                        onTap: widget.onEditLine == null
                            ? null
                            : () => widget.onEditLine!(visible[index]),
                      ),
                      if (index != visible.length - 1)
                        const SizedBox(height: 6),
                    ],
                    if (visible.length < matches.length)
                      TextButton.icon(
                        onPressed: () => setState(() => _visibleLimit += 25),
                        icon: const Icon(Icons.expand_more_rounded),
                        label: Text(
                          'Show ${(matches.length - visible.length).clamp(0, 25)} more',
                        ),
                      ),
                  ],
                ],
                const SizedBox(height: 12),
                if (expense.receiptType == ExpenseReceiptType.detailed ||
                    expense.receiptSubtotal != null ||
                    expense.salesTax != 0) ...[
                  ExpenseReceiptTotalRow(
                    label: 'Subtotal',
                    value: expense.resolvedReceiptSubtotal,
                  ),
                  ExpenseReceiptTotalRow(
                    label: 'Sales tax',
                    value: expense.salesTax,
                  ),
                  const Divider(height: 12),
                ],
                ExpenseReceiptTotalRow(
                  label: 'Total',
                  value: expense.amount,
                  emphasized: true,
                ),
                if (expense.prepareMaterialsReview) ...[
                  const SizedBox(height: 10),
                  _MaterialsReviewStatus(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptLineSearch extends StatelessWidget {
  const _ReceiptLineSearch({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey('expense-detail-line-search'),
    controller: controller,
    onChanged: (_) => onChanged(),
    decoration: InputDecoration(
      labelText: 'Find an item on this receipt',
      hintText: 'Search item, part number, category, or job',
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: query.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
    ),
  );
}

class _MaterialsReviewStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.inventory_2_outlined, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Prepared for Materials review. No inventory quantity changes until an authorized person confirms them.',
          ),
        ),
      ],
    ),
  );
}

class _InlineReceiptEvidence extends StatelessWidget {
  const _InlineReceiptEvidence({
    required this.expense,
    required this.onOpenEvidence,
  });

  final ExpenseRecord expense;
  final VoidCallback? onOpenEvidence;

  @override
  Widget build(BuildContext context) => Material(
    key: ValueKey('receipt-evidence-preview-${expense.id}'),
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(7),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpenEvidence,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 88),
        child: _ReceiptPaper(
          expense: expense,
          opensEvidence: onOpenEvidence != null,
        ),
      ),
    ),
  );
}

class _ReceiptPaper extends StatelessWidget {
  const _ReceiptPaper({required this.expense, required this.opensEvidence});

  final ExpenseRecord expense;
  final bool opensEvidence;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.receipt_long_outlined, size: 28),
        const SizedBox(height: 5),
        Text(
          expense.displayVendor,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(
          'Retained receipt evidence · ${expenseMoney(expense.amount)}',
          textAlign: TextAlign.center,
        ),
        if (opensEvidence)
          Text(
            'Tap to review the original files',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
      ],
    ),
  );
}
