import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../dashboard/dashboard_models.dart';
import '../expenses/expense_models.dart';
import 'inventory_models.dart';
import 'inventory_scope_header.dart';
import 'inventory_settings_screen.dart';

class MaterialCostEditorScreen extends StatefulWidget {
  const MaterialCostEditorScreen({required this.purchaseDate, super.key});

  final DateTime purchaseDate;

  @override
  State<MaterialCostEditorScreen> createState() =>
      _MaterialCostEditorScreenState();
}

class _MaterialCostEditorScreenState extends State<MaterialCostEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _material = TextEditingController();
  final _vendor = TextEditingController();
  final _cost = TextEditingController();
  final _unit = TextEditingController(text: 'each');
  var _trade = 'Plumbing';
  String? _sourceExpenseId;

  @override
  void dispose() {
    _material.dispose();
    _vendor.dispose();
    _cost.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceExpenses = _eligibleSourceExpenses(context);
    return Scaffold(
      key: const ValueKey('material-cost-editor-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scope = OperationalScope.of(context);
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 32),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InventoryScopeHeader(
                          view: scope.view,
                          selectedVehicleId: scope.inventoryVehicleId,
                          onViewChanged: scope.setView,
                          onVehicleChanged: scope.selectInventoryVehicle,
                          onSettings: _openSettings,
                          workspaceLabel: 'Record purchase cost',
                          showBackButton: true,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Record a verified material cost',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          operationalDateLabel(context, widget.purchaseDate),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Save what was actually paid. Estimate markup and customer price remain separate.',
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  key: const ValueKey('material-name-field'),
                                  controller: _material,
                                  decoration: const InputDecoration(
                                    labelText: 'Material name',
                                    helperText:
                                        'Use the product name you will search for later.',
                                  ),
                                  validator: _required,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _trade,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Trade or service type',
                                  ),
                                  items:
                                      const [
                                            'Plumbing',
                                            'Electrical',
                                            'HVAC',
                                            'Cleaning',
                                            'Handyman',
                                            'Lawn care',
                                            'Other',
                                          ]
                                          .map(
                                            (value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(value),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) =>
                                      setState(() => _trade = value ?? _trade),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const ValueKey('material-vendor-field'),
                                  controller: _vendor,
                                  decoration: const InputDecoration(
                                    labelText: 'Vendor',
                                  ),
                                  validator: _required,
                                ),
                                const SizedBox(height: 12),
                                _MaterialCostAndUnitFields(
                                  costController: _cost,
                                  unitController: _unit,
                                  moneyValidator: _money,
                                  requiredValidator: _required,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  key: const ValueKey(
                                    'material-source-expense-field',
                                  ),
                                  initialValue: _sourceExpenseId ?? '',
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Existing expense (optional)',
                                    helperText: sourceExpenses.isEmpty
                                        ? 'No confirmed Materials expenses are available to link.'
                                        : 'Link the actual expense that supports this cost. This does not create a second expense.',
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text('No linked expense'),
                                    ),
                                    for (final expense in sourceExpenses)
                                      DropdownMenuItem(
                                        value: expense.id,
                                        child: Text(
                                          '${expense.id} · ${expense.vendor}',
                                        ),
                                      ),
                                  ],
                                  selectedItemBuilder: (context) => [
                                    const Text('None'),
                                    for (final expense in sourceExpenses)
                                      Text(expense.id),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _sourceExpenseId =
                                        value == null || value.isEmpty
                                        ? null
                                        : value,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: FilledButton.icon(
                                    key: const ValueKey(
                                      'save-material-cost-button',
                                    ),
                                    onPressed: _save,
                                    icon: const Icon(Icons.save_outlined),
                                    label: const Text('Save verified cost'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<ExpenseRecord> _eligibleSourceExpenses(BuildContext context) {
    final records = PrototypeOperationsScope.of(context).expenses.where(
      (expense) =>
          expense.category == ExpenseCategory.materials &&
          expense.countsAsRecordedBusinessCost &&
          !expense.requiresSubmitterAttention &&
          expense.resolvedDate != null,
    );
    return records.toList()..sort(
      (left, right) => right.resolvedDate!.compareTo(left.resolvedDate!),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'This information is required.'
      : null;

  String? _money(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    return amount == null || amount < 0 ? 'Enter a valid cost.' : null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final employeeId =
        OperationalScope.of(context).selectedEmployeeId ?? 'alex';
    Navigator.pop(
      context,
      MaterialCostRecord(
        id: 'cost-${now.microsecondsSinceEpoch}',
        materialId: _material.text.trim().toLowerCase().replaceAll(' ', '-'),
        materialName: _material.text.trim(),
        trade: _trade,
        vendor: _vendor.text.trim(),
        purchasedOn: inventoryDay(widget.purchaseDate),
        unitCostCents: (double.parse(_cost.text.trim()) * 100).round(),
        unitLabel: _unit.text.trim(),
        ownerEmployeeId: employeeId,
        currencyCode: 'USD',
        confirmedBy: dashboardEmployeeById(employeeId).name,
        sourceExpenseId: _sourceExpenseId,
      ),
    );
  }

  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const InventorySettingsScreen()),
  );
}

class _MaterialCostAndUnitFields extends StatelessWidget {
  const _MaterialCostAndUnitFields({
    required this.costController,
    required this.unitController,
    required this.moneyValidator,
    required this.requiredValidator,
  });

  final TextEditingController costController;
  final TextEditingController unitController;
  final FormFieldValidator<String> moneyValidator;
  final FormFieldValidator<String> requiredValidator;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stack = AppLayoutEngine.stackFormFieldsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      );
      final cost = TextFormField(
        key: const ValueKey('material-unit-cost-field'),
        controller: costController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Cost per unit',
          prefixText: 'USD ',
        ),
        validator: moneyValidator,
      );
      final unit = TextFormField(
        key: const ValueKey('material-unit-label-field'),
        controller: unitController,
        decoration: const InputDecoration(
          labelText: 'Unit',
          helperText: 'Each, foot, roll, box…',
        ),
        validator: requiredValidator,
      );
      if (stack) {
        return Column(children: [cost, const SizedBox(height: 12), unit]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cost),
          const SizedBox(width: 12),
          Expanded(child: unit),
        ],
      );
    },
  );
}
