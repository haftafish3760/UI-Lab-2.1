import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'expense_input_validation.dart';
import 'expense_models.dart';

Future<ExpenseLineItem?> showExpenseLineItemEditor(
  BuildContext context, {
  ExpenseLineItem? initial,
  required ExpenseCategory defaultCategory,
  String? jobId,
  String? jobLabel,
}) => Navigator.of(context).push<ExpenseLineItem>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => ExpenseLineItemEditorScreen(
      initial: initial,
      defaultCategory: defaultCategory,
      jobId: jobId,
      jobLabel: jobLabel,
    ),
  ),
);

class ExpenseLineItemEditorScreen extends StatefulWidget {
  const ExpenseLineItemEditorScreen({
    required this.defaultCategory,
    this.initial,
    this.jobId,
    this.jobLabel,
    super.key,
  });

  final ExpenseLineItem? initial;
  final ExpenseCategory defaultCategory;
  final String? jobId;
  final String? jobLabel;

  @override
  State<ExpenseLineItemEditorScreen> createState() =>
      _ExpenseLineItemEditorScreenState();
}

class _ExpenseLineItemEditorScreenState
    extends State<ExpenseLineItemEditorScreen> {
  static const _units = [
    'each',
    'pack',
    'package',
    'box',
    'roll',
    'foot',
    'gallon',
    'pound',
    'hour',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _partNumber;
  late final TextEditingController _quantity;
  late final TextEditingController _unitsPerPackage;
  late final TextEditingController _unitPrice;
  late ExpenseCategory _category;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _description = TextEditingController(text: item?.description ?? '');
    _partNumber = TextEditingController(text: item?.partNumber ?? '');
    _quantity = TextEditingController(
      text: item == null ? '1' : _formatNumber(item.quantity),
    );
    _unitsPerPackage = TextEditingController(
      text: item == null ? '1' : _formatNumber(item.unitsPerPackage),
    );
    _unitPrice = TextEditingController(
      text: item == null ? '' : item.unitPrice.toStringAsFixed(2),
    );
    _category = item?.category ?? widget.defaultCategory;
    _unit = _units.contains(item?.unit) ? item!.unit : 'each';
    _quantity.addListener(_refresh);
    _unitPrice.addListener(_refresh);
  }

  @override
  void dispose() {
    _quantity.removeListener(_refresh);
    _unitPrice.removeListener(_refresh);
    _description.dispose();
    _partNumber.dispose();
    _quantity.dispose();
    _unitsPerPackage.dispose();
    _unitPrice.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  double get _lineTotal {
    final quantity = double.tryParse(_quantity.text.trim()) ?? 0;
    final price = double.tryParse(_unitPrice.text.trim()) ?? 0;
    return quantity * price;
  }

  bool get _usesPackageDetails =>
      _unit == 'pack' || _unit == 'package' || _unit == 'box';

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('expense-line-item-editor-screen'),
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        tooltip: 'Cancel item changes',
        icon: const Icon(Icons.close_rounded),
      ),
      title: Text(
        widget.initial == null ? 'Add receipt item' : 'Edit receipt item',
      ),
      actions: [TextButton(onPressed: _save, child: const Text('Save'))],
    ),
    body: SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final formWidth = AppLayoutEngine.formWorkspaceWidthFor(
            constraints.maxWidth - insets.horizontal,
          );
          return ListView(
            padding: insets.copyWith(top: 12, bottom: 110),
            children: [
              Center(
                child: SizedBox(
                  width: formWidth,
                  child: Form(
                    key: _formKey,
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Receipt item',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Use the wording printed on the receipt. You can change every field.',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const ValueKey('expense-line-description'),
                            controller: _description,
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Item or material',
                              hintText: 'Example: 20-in faucet connector',
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Enter the item shown on the receipt.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('expense-line-part-number'),
                            controller: _partNumber,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Part or item number (optional)',
                              helperText:
                                  'Use the SKU, model, or part number printed on the receipt.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<ExpenseCategory>(
                            key: const ValueKey('expense-line-category'),
                            initialValue: _category,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Expense category',
                            ),
                            items: [
                              for (final category in ExpenseCategory.values)
                                DropdownMenuItem(
                                  value: category,
                                  child: Text(category.label),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _category = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _ResponsiveFieldPair(
                            first: _PriceField(controller: _unitPrice),
                            second: _UnitField(
                              value: _unit,
                              units: _units,
                              onChanged: (value) =>
                                  setState(() => _unit = value),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ResponsiveFieldPair(
                            first: _QuantityField(
                              controller: _quantity,
                              onChanged: _refresh,
                            ),
                            second: _usesPackageDetails
                                ? _PackageField(controller: _unitsPerPackage)
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _LineTotal(
                            total: _lineTotal,
                            quantity:
                                double.tryParse(_quantity.text.trim()) ?? 0,
                            unit: _unit,
                            unitsPerPackage:
                                double.tryParse(_unitsPerPackage.text.trim()) ??
                                0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('save-expense-line-item'),
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save item'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      ExpenseLineItem(
        id:
            widget.initial?.id ??
            'EXP-LINE-${DateTime.now().microsecondsSinceEpoch}',
        description: _description.text.trim(),
        category: _category,
        quantity: double.parse(_quantity.text.replaceAll(',', '').trim()),
        unit: _unit,
        unitPrice: double.parse(_unitPrice.text.replaceAll(',', '').trim()),
        confirmedLineTotal: double.parse(_lineTotal.toStringAsFixed(2)),
        partNumber: _partNumber.text.trim().isEmpty
            ? null
            : _partNumber.text.trim(),
        unitsPerPackage: _usesPackageDetails
            ? double.parse(_unitsPerPackage.text.replaceAll(',', '').trim())
            : 1,
        jobId: widget.initial?.jobId ?? widget.jobId,
        jobLabel: widget.initial?.jobLabel ?? widget.jobLabel,
      ),
    );
  }
}

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
