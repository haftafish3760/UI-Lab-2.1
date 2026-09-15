import 'package:flutter/material.dart';

import 'expense_models.dart';

class ExpenseReceiptLineCard extends StatelessWidget {
  const ExpenseReceiptLineCard({required this.item, this.onTap, super.key});

  final ExpenseLineItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    key: ValueKey('expense-line-${item.id}'),
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(7),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      mouseCursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _lineDescription(item),
                style: const TextStyle(fontSize: 12.5, height: 1.2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              expenseMoney(item.total),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, size: 18),
            ],
          ],
        ),
      ),
    ),
  );
}

class ExpenseReceiptTotalRow extends StatelessWidget {
  const ExpenseReceiptTotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final double? value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          expenseMoney(value),
          style: TextStyle(
            fontSize: emphasized ? 18 : null,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

String _number(double value) =>
    value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');

String _lineDescription(ExpenseLineItem item) {
  final part = item.partNumber?.trim();
  final partText = part == null || part.isEmpty ? '' : ' · Part $part';
  final contents = item.unitsPerPackage;
  final isPackage = item.usesPackageContents;
  final packageText = !isPackage
      ? ''
      : contents == null
      ? ' · Package contents not recorded'
      : ' · ${_number(contents)} items per ${item.unit}';
  return '${item.description}$partText\n'
      '${_number(item.quantity)} ${item.unit} × ${expenseUnitPrice(item.unitPrice)}'
      '$packageText · ${item.category.label}';
}
