import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_scope.dart';
import 'inventory_models.dart';
import 'inventory_visible_records.dart';

String newInventoryId(String kind) => '$kind:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(0x7fffffff)}';

class InventoryItemEntryScreen extends StatefulWidget {
  const InventoryItemEntryScreen({this.categoryId, super.key});
  final String? categoryId;
  @override
  State<InventoryItemEntryScreen> createState() => _InventoryItemEntryScreenState();
}
class _InventoryItemEntryScreenState extends State<InventoryItemEntryScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController(text: 'each');
  final _location = TextEditingController();
  final _aliases = TextEditingController();
  final _part = TextEditingController();
  final _cost = TextEditingController();
  final _sizes = <_SizeInput>[];
  String? _locationId;
  bool _saving = false;
  @override
  void dispose() {
    for (final c in [_name, _quantity, _unit, _location, _aliases, _part, _cost]) { c.dispose(); }
    for (final size in _sizes) { size.dispose(); }
    super.dispose();
  }
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final scope = OperationalScope.of(context);
    final locations = inventoryLocations(store, scope);
    return Scaffold(
      appBar: AppBar(title: const Text('Add inventory item')),
      body: LayoutBuilder(builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: AppLayoutEngine.formWorkspaceWidthFor(constraints.maxWidth), child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(key: const ValueKey('inventory-name'), controller: _name, decoration: const InputDecoration(labelText: 'Item name'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: _part, decoration: const InputDecoration(labelText: 'Part number (optional)')),
            const SizedBox(height: 12),
            TextFormField(controller: _aliases, decoration: const InputDecoration(labelText: 'Other names (comma-separated, optional)')),
            const SizedBox(height: 16),
            Text('Sizes (optional)', style: Theme.of(context).textTheme.titleMedium),
            for (var index = 0; index < _sizes.length; index++) _sizeRow(index),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => _sizes.add(_SizeInput(_sizes.length + 1))), icon: const Icon(Icons.add), label: const Text('Add another size'))),
            const SizedBox(height: 12),
            if (scope.view == AppViewMode.admin) ...[
              DropdownButtonFormField<String>(initialValue: _locationId ?? '', isExpanded: true,
                decoration: const InputDecoration(labelText: 'Location'),
                items: [const DropdownMenuItem(value: '', child: Text('New location')), for (final e in locations.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (value) => setState(() => _locationId = value == '' ? null : value)),
              if (_locationId == null) TextFormField(key: const ValueKey('inventory-location'), controller: _location, decoration: const InputDecoration(labelText: 'Location name'), validator: _required),
            ] else Text('Location: ${locations[scope.selectedVehicleId] ?? 'Assigned vehicle'}'),
            const SizedBox(height: 12),
            TextFormField(key: const ValueKey('inventory-quantity'), controller: _quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantity on hand'),
              validator: (value) { final n = double.tryParse(value?.trim() ?? ''); return n == null || !n.isFinite || n < 0 ? 'Enter zero or a positive quantity.' : null; }),
            const SizedBox(height: 12),
            TextFormField(controller: _unit, decoration: const InputDecoration(labelText: 'Stock unit'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: _cost, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cost per stock unit, USD (optional)'),
              validator: (value) => value == null || value.trim().isEmpty || RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim()) ? null : 'Enter a nonnegative amount with up to two decimals.'),
            const SizedBox(height: 20),
            FilledButton(onPressed: _saving ? null : () => _save(false), child: const Text('Add item')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _saving ? null : () => _save(true), child: const Text('Add item and another here')),
          ]),
        )),
      )),
    );
  }
  Widget _sizeRow(int index) {
    final size = _sizes[index];
    return Padding(padding: const EdgeInsets.only(top: 12), child: Column(children: [
      TextFormField(controller: size.label, decoration: InputDecoration(labelText: 'Size ${index + 1} label'), validator: _required),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: TextFormField(controller: size.value, decoration: const InputDecoration(labelText: 'Size'), validator: _required)),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(controller: size.unit, decoration: const InputDecoration(labelText: 'Unit'), validator: _required)),
        IconButton(tooltip: 'Remove size ${index + 1}', onPressed: () => setState(() { _sizes.removeAt(index).dispose(); }), icon: const Icon(Icons.remove_circle_outline)),
      ]),
    ]));
  }
  void _save(bool another) {
    if (_saving || !_form.currentState!.validate()) return;
    final store = PrototypeOperationsScope.of(context);
    final scope = OperationalScope.of(context);
    final actor = store.workSession?.permissions.actorEmployeeId ?? scope.selectedEmployeeId ?? 'alex';
    final locations = inventoryLocations(store, scope);
    final locationId = scope.view == AppViewMode.technician ? scope.selectedVehicleId : _locationId ?? newInventoryId('location');
    final locationLabel = locations[locationId] ?? _location.text.trim();
    final sizes = List<InventoryItemSize>.unmodifiable(_sizes.map((s) => InventoryItemSize(label: s.label.text.trim(), value: s.value.text.trim(), unit: s.unit.text.trim())));
    final duplicates = visibleInventoryStock(store, scope).where((r) => r.materialName.toLowerCase() == _name.text.trim().toLowerCase() && r.partNumber == _part.text.trim() && r.locationLabel.toLowerCase() == locationLabel.toLowerCase() && r.unitLabel == _unit.text.trim() && r.sizes.map((s) => s.display).join('|') == sizes.map((s) => s.display).join('|'));
    if (duplicates.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This item already exists at that location. Open it to update its count.')));
      return;
    }
    final cost = _cost.text.trim().split('.');
    final cents = _cost.text.trim().isEmpty ? null : int.parse(cost[0]) * 100 + (cost.length == 1 ? 0 : int.parse(cost[1].padRight(2, '0')));
    setState(() => _saving = true);
    store.updateInventoryStock(InventoryStockRecord(id: newInventoryId('stock'), materialId: newInventoryId('item'), materialName: _name.text.trim(), locationId: locationId, locationLabel: locationLabel, quantity: double.parse(_quantity.text.trim()), unitLabel: _unit.text.trim(), confidence: InventoryStockConfidence.reported, updatedOn: DateTime.now(), ownerEmployeeId: actor, categoryId: widget.categoryId, sizes: sizes, aliases: List.unmodifiable(_aliases.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet()), partNumber: _part.text.trim(), unitCostCents: cents));
    if (!another) { Navigator.pop(context); return; }
    _locationId = locationId;
    for (final c in [_name, _quantity, _part, _aliases, _cost]) { c.clear(); }
    for (final size in _sizes) { size.dispose(); }
    setState(() { _sizes.clear(); _saving = false; });
  }
}
class _SizeInput {
  _SizeInput(int index) : label = TextEditingController(text: 'Connection $index');
  final TextEditingController label;
  final value = TextEditingController();
  final unit = TextEditingController(text: 'in');
  void dispose() { label.dispose(); value.dispose(); unit.dispose(); }
}
