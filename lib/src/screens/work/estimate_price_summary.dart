import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import 'estimate_form_section.dart';

/// Groups the estimate's calculated amounts and editable adjustments together.
/// Values and edit callbacks remain owned by the existing estimate draft.
class EstimatePriceSummary extends StatelessWidget {
  const EstimatePriceSummary({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.onEdit,
    this.grouped = false,
    super.key,
  });

  final String subtotal;
  final String discount;
  final String tax;
  final String total;
  final VoidCallback onEdit;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grouped)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit pricing'),
            ),
          ),
        _AmountRow(label: 'Subtotal', amount: subtotal),
        _AmountRow(
          key: const ValueKey('estimate-discount'),
          label: 'Discount',
          amount: discount,
        ),
        _AmountRow(
          key: const ValueKey('estimate-tax'),
          label: 'Tax',
          amount: tax,
        ),
        Divider(color: colors.onSurfaceVariant),
        _AmountRow(label: 'Estimate total', amount: total, emphasized: true),
      ],
    );
    if (grouped) return content;
    return EstimateFormSection(
      title: 'Price summary',
      onEdit: onEdit,
      child: content,
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final String amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;
    return Semantics(
      button: false,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final name = Row(
                mainAxisSize: MainAxisSize.min,
                children: [Flexible(child: Text(label, style: style))],
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
