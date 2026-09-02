import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/operational_scope.dart';
import 'inventory_models.dart';
import 'inventory_scope_header.dart';
import 'inventory_settings_screen.dart';

class StockCountScreen extends StatefulWidget {
  const StockCountScreen({required this.record, super.key});

  final InventoryStockRecord record;

  @override
  State<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends State<StockCountScreen> {
  late final TextEditingController _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: '${widget.record.quantity}');
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: const ValueKey('stock-count-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InventoryScopeHeader(
                          view: scope.view,
                          selectedVehicleId: scope.inventoryVehicleId,
                          onViewChanged: scope.setView,
                          onVehicleChanged: scope.selectInventoryVehicle,
                          onSettings: _openSettings,
                          workspaceLabel: 'Count truck stock',
                          showBackButton: true,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Verify truck stock',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(widget.record.materialName),
                        Text(widget.record.locationLabel),
                        const SizedBox(height: 16),
                        TextField(
                          key: const ValueKey('stock-quantity-field'),
                          controller: _quantity,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Physical count',
                            suffixText: widget.record.unitLabel,
                            helperText:
                                'Enter what is physically present now. This replaces the previous reported amount.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FilledButton.icon(
                            key: const ValueKey('save-stock-count-button'),
                            onPressed: _save,
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text('Save verified count'),
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

  void _save() {
    final value = double.tryParse(_quantity.text.trim());
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid physical count.')),
      );
      return;
    }
    Navigator.pop(
      context,
      widget.record.copyWith(
        quantity: value,
        confidence: InventoryStockConfidence.verified,
        updatedOn: DateTime.now(),
      ),
    );
  }

  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const InventorySettingsScreen()),
  );
}
