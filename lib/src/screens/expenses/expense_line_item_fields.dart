part of 'expense_line_item_editor.dart';

class _ResponsiveFieldPair extends StatelessWidget {
  const _ResponsiveFieldPair({required this.first, this.second});
  final Widget first;
  final Widget? second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final trailing = second;
      if (trailing == null) return first;
      if (AppLayoutEngine.stackFormFieldsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      )) {
        return Column(children: [first, const SizedBox(height: 12), trailing]);
      }
      return Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: trailing),
        ],
      );
    },
  );
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('expense-line-unit-price'),
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: const InputDecoration(
      labelText: 'Price for one',
      prefixText: r'$ ',
    ),
    validator: validateRequiredExpenseMoney,
  );
}

class _UnitField extends StatelessWidget {
  const _UnitField({
    required this.value,
    required this.units,
    required this.onChanged,
  });
  final String value;
  final List<String> units;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: const ValueKey('expense-line-unit'),
    initialValue: value,
    decoration: const InputDecoration(labelText: 'Sold as'),
    items: [
      for (final unit in units)
        DropdownMenuItem(value: unit, child: Text(unit)),
    ],
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}

class _QuantityField extends StatelessWidget {
  const _QuantityField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('expense-line-quantity'),
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: const InputDecoration(labelText: 'How many were purchased?'),
    onChanged: (_) => onChanged(),
    validator: validateRequiredExpenseQuantity,
  );
}

class _PackageField extends StatelessWidget {
  const _PackageField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('expense-line-units-per-package'),
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: const InputDecoration(labelText: 'Items inside each package'),
    validator: validateRequiredExpenseQuantity,
  );
}

class _LineTotal extends StatelessWidget {
  const _LineTotal({
    required this.total,
    required this.quantity,
    required this.unit,
    required this.unitsPerPackage,
  });
  final double total;
  final double quantity;
  final String unit;
  final double unitsPerPackage;

  bool get _hasPackageMath =>
      (unit == 'pack' || unit == 'package' || unit == 'box') &&
      quantity > 0 &&
      unitsPerPackage > 0;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Calculated line total',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              expenseMoney(total),
              key: const ValueKey('expense-line-total'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        if (_hasPackageMath) ...[
          const SizedBox(height: 4),
          Text(
            '${_formatNumber(quantity)} $unit purchased · '
            '${_formatNumber(quantity * unitsPerPackage)} items total · '
            '${expenseMoney(total / (quantity * unitsPerPackage))} per item',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
        ],
      ],
    ),
  );
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
