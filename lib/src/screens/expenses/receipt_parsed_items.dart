import 'package:flutter/material.dart';
import '../../data/receipts/receipt_item_proposal.dart';

/// Bounded previews of observations, deliberately separate from confirmed lines.
class ReceiptParsedItems extends StatefulWidget {
  const ReceiptParsedItems({required this.result, super.key});
  final ReceiptItemParseResult result;
  @override
  State<ReceiptParsedItems> createState() => _ReceiptParsedItemsState();
}

class _ReceiptParsedItemsState extends State<ReceiptParsedItems> {
  int _visible = 10;
  int _unresolvedVisible = 10;
  @override
  void didUpdateWidget(covariant ReceiptParsedItems oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.result, widget.result)) {
      _visible = 10;
      _unresolvedVisible = 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Items found: ${result.items.length}',
            style: theme.textTheme.titleMedium,
          ),
          const Text(
            'Check the wording and amounts against the photo. These suggestions have not been added to your expense or stock.',
          ),
          for (final item in result.items.take(_visible))
            Container(
              key: ValueKey('receipt-proposal-${item.id}'),
              margin: const EdgeInsets.only(top: 8),
              child: Material(
                color: theme.colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(item.description, style: theme.textTheme.titleSmall),
                      Text(
                        'Quantity: ${item.quantity?.decimalValue ?? 'Not read'}',
                      ),
                      Text('Sold as: ${item.purchaseUnit ?? 'Not read'}'),
                      Text(
                        'Price for one: ${item.unitPrice?.decimalValue ?? 'Not read'}',
                      ),
                      if (item.lineTotalMinor != null)
                        Text(
                          'Printed line amount: ${_money(item.lineTotalMinor!)}',
                        ),
                      if (item.calculatedTotalMinor != null &&
                          item.calculatedTotalMinor != item.lineTotalMinor)
                        Text(
                          'Calculated line amount: ${_money(item.calculatedTotalMinor!)}',
                        ),
                      for (final warning in item.warnings) Text(warning),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Original receipt text'),
                        children: [
                          SelectableText(
                            item.sourceRows.map((row) => row.text).join('\n'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_visible < result.items.length)
            TextButton(
              onPressed: () => setState(() => _visible += 25),
              child: const Text('Show more items'),
            ),
          if (result.unresolvedRows.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Other text to check: ${result.unresolvedRows.length}',
              ),
              children: [
                const Text(
                  'These rows were not understood as purchases. They may include discounts, adjustments or other receipt details.',
                ),
                for (final row in result.unresolvedRows.take(
                  _unresolvedVisible,
                ))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SelectableText(row.text),
                  ),
                if (_unresolvedVisible < result.unresolvedRows.length)
                  TextButton(
                    onPressed: () => setState(() => _unresolvedVisible += 25),
                    child: const Text('Show more text'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

String _money(int minor) =>
    '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
