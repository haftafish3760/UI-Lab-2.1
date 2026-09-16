import 'package:flutter/material.dart';
import '../../../data/prototype_operations_store.dart';
import '../../../layout/app_layout_engine.dart';
import '../../../shared/app_view_mode.dart';
import '../../../shared/operational_scope.dart';
import '../../../shared/section_card.dart';
import '../../../shared/localized_date.dart';
import '../inventory_models.dart';
import '../inventory_visible_records.dart';
import '../stock_count_screen.dart';
import 'inventory_catalog.dart';

class InventoryCatalogItemScreen extends StatefulWidget {
  const InventoryCatalogItemScreen({
    required this.item,
    this.records = const [],
    super.key,
  });
  final InventoryCatalogItem item;
  final List<InventoryStockRecord> records;
  @override
  State<InventoryCatalogItemScreen> createState() =>
      _InventoryCatalogItemScreenState();
}

class _InventoryCatalogItemScreenState
    extends State<InventoryCatalogItemScreen> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _location = TextEditingController();
  final _threshold = TextEditingController();
  bool _lowStock = false;
  bool _submitted = false;
  String? _locationId;
  @override
  void dispose() {
    _quantity.dispose();
    _location.dispose();
    _threshold.dispose();
    super.dispose();
  }

  String? _number(String? text) {
    final value = double.tryParse(text?.trim() ?? '');
    return value == null || !value.isFinite || value < 0
        ? 'Enter zero or a positive number.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final store = PrototypeOperationsScope.of(context);
    final locations = inventoryLocations(store, scope);
    final permissions = store.workSession?.permissions;
    final costs =
        store.materialCosts
            .where(
              (r) =>
                  (r.materialId == widget.item.id ||
                      r.materialId == widget.item.sourceId) &&
                  (permissions == null ||
                      permissions.visibleCreatorIds.contains(
                        r.ownerEmployeeId,
                      )),
            )
            .toList()
          ..sort((a, b) => b.purchasedOn.compareTo(a.purchasedOn));
    final records = visibleInventoryStock(store, scope)
        .where(
          (r) =>
              r.materialId == widget.item.id ||
              r.materialId == widget.item.sourceId,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Item details')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final layout = AppLayoutEngine.detailWorkspaceFor(
            constraints.maxWidth - insets.horizontal,
            textScaler: MediaQuery.textScalerOf(context),
          );
          return Center(
            child: SizedBox(
              width: layout.columnWidth,
              child: ListView(
                padding: insets.add(const EdgeInsets.symmetric(vertical: 16)),
                children: [
                  Text(
                    widget.item.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(widget.item.path.join(' / ')),
                  const SizedBox(height: 8),
                  Text('Counted in ${widget.item.unit}'),
                  if (widget.item.variant.isNotEmpty) Text(widget.item.variant),
                  const SizedBox(height: 16),
                  for (final record in records)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${record.locationLabel}\n'
                              '${record.confidence == InventoryStockConfidence.unknown ? 'Check quantity' : '${record.quantity} ${record.unitLabel} on hand'}',
                            ),
                            TextButton(
                              onPressed: () async {
                                final result = await Navigator.of(context)
                                    .push<InventoryStockRecord>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            StockCountScreen(record: record),
                                      ),
                                    );
                                if (mounted && result != null) {
                                  store.updateInventoryStock(result);
                                }
                              },
                              child: const Text(
                                'Check count or change minimum',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SectionCard(
                    child: Text(
                      'Layout review: inventory changes are not yet saved after closing the app.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'What you paid',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (costs.isEmpty)
                          const Text('No purchase price recorded yet.'),
                        for (final cost in costs)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${inventoryMoney(cost.unitCostCents, currencyCode: cost.currencyCode)} per ${cost.unitLabel}\n'
                              '${cost.vendor} · ${operationalShortDateLabel(context, cost.purchasedOn)}',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Add to My Inventory',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No receipt needed. Enter the amount you are adding.',
                          ),
                          const SizedBox(height: 16),
                          if (scope.view == AppViewMode.admin)
                            Column(
                              children: [
                                if (locations.isNotEmpty) ...[
                                  DropdownButtonFormField<String>(
                                    initialValue: _locationId ?? '',
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Choose a location',
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: '',
                                        child: Text('New storage location'),
                                      ),
                                      for (final entry in locations.entries)
                                        DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(entry.value),
                                        ),
                                    ],
                                    onChanged: (value) => setState(
                                      () => _locationId = value == ''
                                          ? null
                                          : value,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (_locationId == null)
                                  TextFormField(
                                    controller: _location,
                                    decoration: const InputDecoration(
                                      labelText: 'Truck or storage location',
                                      helperText:
                                          'For example: Shop shelves or Shed.',
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Enter a location.'
                                        : null,
                                  ),
                              ],
                            )
                          else
                            Text(
                              'Location: ${locations[scope.selectedVehicleId]}',
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _quantity,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText:
                                  'Quantity to add (${widget.item.unit})',
                            ),
                            validator: _number,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Set a low-stock minimum'),
                            subtitle: const Text(
                              'Leave off to keep any existing minimum.',
                            ),
                            value: _lowStock,
                            onChanged: (value) =>
                                setState(() => _lowStock = value),
                          ),
                          if (_lowStock)
                            TextFormField(
                              controller: _threshold,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Low at this quantity or less',
                              ),
                              validator: _number,
                            ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _add,
                            icon: const Icon(Icons.add),
                            label: const Text('Add to My Inventory'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _add() {
    if (_submitted || !_form.currentState!.validate()) return;
    final store = PrototypeOperationsScope.of(context);
    final scope = OperationalScope.of(context);
    final actor =
        store.workSession?.permissions.actorEmployeeId ??
        scope.selectedEmployeeId ??
        'alex';
    final permitted = visibleInventoryStock(store, scope);
    final locations = inventoryLocations(store, scope);
    final label = scope.view == AppViewMode.technician
        ? locations[scope.selectedVehicleId]!
        : _locationId == null
        ? _location.text.trim()
        : locations[_locationId]!;
    final existingLocation = permitted.where(
      (r) => r.locationLabel.toLowerCase() == label.toLowerCase(),
    );
    final locationId = scope.view == AppViewMode.technician
        ? scope.selectedVehicleId
        : _locationId ??
              (existingLocation.isEmpty
                  ? 'storage:${label.toLowerCase()}'
                  : existingLocation.first.locationId);
    final existing = permitted.where(
      (r) =>
          (r.materialId == widget.item.id ||
              r.materialId == widget.item.sourceId) &&
          r.locationId == locationId,
    );
    if (existing.any((r) => r.confidence == InventoryStockConfidence.unknown)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Check the current quantity in My Inventory before adding more.',
          ),
        ),
      );
      return;
    }
    final previous = existing.isEmpty ? null : existing.first;
    final total =
        (previous?.quantity ?? 0) + double.parse(_quantity.text.trim());
    if (!total.isFinite ||
        (previous != null && previous.unitLabel != widget.item.unit)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'These quantities cannot be combined. Check the unit and amount.',
          ),
        ),
      );
      return;
    }
    _submitted = true;
    store.updateInventoryStock(
      InventoryStockRecord(
        id: previous?.id ?? 'stock:${widget.item.id}:$locationId',
        materialId: widget.item.id,
        materialName: widget.item.name,
        locationId: locationId,
        locationLabel: existingLocation.isEmpty
            ? label
            : existingLocation.first.locationLabel,
        quantity: total,
        unitLabel: widget.item.unit,
        confidence: InventoryStockConfidence.reported,
        updatedOn: DateTime.now(),
        ownerEmployeeId: previous?.ownerEmployeeId ?? actor,
        lowAt: _lowStock
            ? double.parse(_threshold.text.trim())
            : previous?.lowAt,
      ),
    );
    Navigator.pop(context);
  }
}
