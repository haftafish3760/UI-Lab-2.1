import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'expense_input_validation.dart';
import 'expense_models.dart';

class ReceiptDetailChoice extends StatelessWidget {
  const ReceiptDetailChoice({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ExpenseReceiptType value;
  final ValueChanged<ExpenseReceiptType> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('expense-receipt-type-selector'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'How much receipt detail do you need?',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      _ReceiptChoiceTile(
        key: const ValueKey('receipt-total-only-choice'),
        selected: value == ExpenseReceiptType.basic,
        icon: Icons.receipt_outlined,
        title: 'Save the receipt total',
        description:
            'Keep the vendor, category, final total, and receipt image.',
        onTap: () => onChanged(ExpenseReceiptType.basic),
      ),
      const SizedBox(height: 8),
      _ReceiptChoiceTile(
        key: const ValueKey('receipt-every-item-choice'),
        selected: value == ExpenseReceiptType.detailed,
        icon: Icons.format_list_numbered_rounded,
        title: 'Review every item on the receipt',
        description:
            'Use for materials or any receipt where each purchased item must be searchable and editable.',
        onTap: () => onChanged(ExpenseReceiptType.detailed),
      ),
    ],
  );
}

class _ReceiptChoiceTile extends StatelessWidget {
  const _ReceiptChoiceTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? colors.primary : colors.outline,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? colors.primary : colors.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(description, style: const TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReceiptTotalsFields extends StatelessWidget {
  const ReceiptTotalsFields({
    required this.lineSubtotal,
    required this.subtotalController,
    required this.salesTaxController,
    required this.totalController,
    required this.onComponentsChanged,
    required this.totalValidator,
    super.key,
  });

  final double lineSubtotal;
  final TextEditingController subtotalController;
  final TextEditingController salesTaxController;
  final TextEditingController totalController;
  final VoidCallback onComponentsChanged;
  final FormFieldValidator<String> totalValidator;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Receipt totals',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        const Text('Enter these amounts exactly as printed on the receipt.'),
        if (lineSubtotal > 0) ...[
          const SizedBox(height: 10),
          _TotalReadout(label: 'Items add up to', value: lineSubtotal),
        ],
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final subtotal = TextFormField(
              key: const ValueKey('expense-receipt-subtotal-field'),
              controller: subtotalController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Receipt subtotal',
                prefixText: r'$ ',
                helperText: 'Before sales tax',
              ),
              onChanged: (_) => onComponentsChanged(),
              validator: validateOptionalExpenseMoney,
            );
            final tax = TextFormField(
              key: const ValueKey('expense-sales-tax-field'),
              controller: salesTaxController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Sales tax',
                prefixText: r'$ ',
              ),
              onChanged: (_) => onComponentsChanged(),
              validator: validateOptionalExpenseMoney,
            );
            if (AppLayoutEngine.stackFormFieldsFor(
              constraints.maxWidth,
              textScaler: MediaQuery.textScalerOf(context),
            )) {
              return Column(
                children: [subtotal, const SizedBox(height: 12), tax],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: subtotal),
                const SizedBox(width: 12),
                Expanded(child: tax),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('expense-amount-field'),
          controller: totalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Final amount paid',
            prefixText: r'$ ',
            helperText: 'Subtotal plus tax and any printed fees',
          ),
          validator: totalValidator,
        ),
      ],
    ),
  );
}

class MaterialsFollowupChoice extends StatelessWidget {
  const MaterialsFollowupChoice({
    required this.prepareMaterialsReview,
    required this.onChanged,
    super.key,
  });

  final bool prepareMaterialsReview;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('expense-materials-followup-choice'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'What should happen to these items next?',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      _ReceiptChoiceTile(
        key: const ValueKey('keep-items-in-expenses-choice'),
        selected: !prepareMaterialsReview,
        icon: Icons.receipt_long_outlined,
        title: 'Keep them with this expense',
        description:
            'Save the receipt and item details without changing Materials or truck inventory.',
        onTap: () => onChanged(false),
      ),
      const SizedBox(height: 8),
      _ReceiptChoiceTile(
        key: const ValueKey('prepare-materials-review-choice'),
        selected: prepareMaterialsReview,
        icon: Icons.inventory_2_outlined,
        title: 'Prepare the items for Materials review',
        description:
            'Keep the verified prices as cost history. Inventory quantities will not change until you review and confirm them.',
        onTap: () => onChanged(true),
      ),
    ],
  );
}

class _TotalReadout extends StatelessWidget {
  const _TotalReadout({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          expenseMoney(value),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
