import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';

/// Groups the estimate's calculated amounts and editable adjustments together.
/// Values and edit callbacks remain owned by the existing estimate draft.
class EstimatePriceSummary extends StatelessWidget {
  const EstimatePriceSummary({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.onDiscount,
    required this.onTax,
    super.key,
  });

  final String subtotal;
  final String discount;
  final String tax;
  final String total;
  final VoidCallback onDiscount;
  final VoidCallback onTax;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SectionCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: colors.surfaceContainer,
      borderColor: colors.onSurfaceVariant,
      shadows: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Price summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          _AmountRow(label: 'Subtotal', amount: subtotal),
          _AmountRow(
            key: const ValueKey('estimate-discount'),
            label: 'Discount',
            amount: discount,
            onEdit: onDiscount,
          ),
          _AmountRow(
            key: const ValueKey('estimate-tax'),
            label: 'Tax',
            amount: tax,
            onEdit: onTax,
          ),
          Divider(color: colors.onSurfaceVariant),
          _AmountRow(label: 'Estimate total', amount: total, emphasized: true),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.onEdit,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final String amount;
  final VoidCallback? onEdit;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;
    return Semantics(
      button: onEdit != null,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final name = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(label, style: style)),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              );
              if (AppLayoutEngine.stackCompactFieldsFor(
                constraints.maxWidth,
                textScaler: MediaQuery.textScalerOf(context),
              )) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    name,
                    Text(amount, style: style),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: name),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        amount,
                        style: style,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
