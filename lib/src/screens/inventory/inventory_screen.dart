import 'package:flutter/material.dart';

import '../../data/operational_attention.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_attention_panel.dart';
import '../../shared/operational_scope.dart';
import '../../shared/operations_workspace.dart';
import '../../shared/section_card.dart';
import '../../shared/module_month_calendar.dart';
import 'inventory_action_screen.dart';
import 'inventory_attention_screen.dart';
import 'inventory_day_screen.dart';
import 'inventory_models.dart';
import 'inventory_scope_header.dart';
import 'inventory_settings_screen.dart';
import 'material_cost_editor_screen.dart';
import 'material_detail_screen.dart';
import 'stock_count_screen.dart';
import 'stock_selection_screen.dart';

part 'inventory_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  var _search = '';
  var _preferences = const InventoryDisplayPreferences.defaults();

  AppViewMode get _view => OperationalScope.of(context).view;
  PrototypeOperationsStore get _store => PrototypeOperationsScope.of(context);

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final costs = _visibleCosts;
    final stock = _visibleStock;
    final attentionQuery = _attentionQuery(scope);
    final attentionItems = _store.attentionCenter.itemsFor(attentionQuery);
    final showAttention = _store.attentionCenter.shouldShow(
      attentionQuery,
      attentionItems,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final layout = AppLayoutEngine.operationsFor(
          constraints.maxWidth - insets.horizontal,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final showInlineActions = layout.showsInlineModuleActions;
        return Scaffold(
          key: const ValueKey('inventory-module-screen'),
          floatingActionButton: showInlineActions
              ? null
              : FloatingActionButton.extended(
                  heroTag: 'inventory-action-fab',
                  onPressed: _openActions,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add material'),
                ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
              children: [
                OperationsWorkspaceFrame(
                  layout: layout,
                  primaryContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InventoryScopeHeader(
                        key: const ValueKey('inventory-module-header'),
                        view: _view,
                        selectedVehicleId: scope.inventoryVehicleId,
                        onViewChanged: scope.setView,
                        onVehicleChanged: scope.selectInventoryVehicle,
                        onSettings: _openSettings,
                      ),
                      const SizedBox(height: 14),
                      _InventoryDateHeading(selectedDate: inventoryDemoToday),
                      if (showAttention) ...[
                        const SizedBox(height: 12),
                        OperationalAttentionPanel(
                          key: const ValueKey('inventory-attention'),
                          items: attentionItems,
                          rowKeyFor: (item) => ValueKey(
                            'inventory-attention-row-${item.sourceId}',
                          ),
                          onOpen: _openAttentionItem,
                          onOpenAll: () => _openAttentionList(attentionItems),
                          onDismiss: () => _store.attentionCenter.dismiss(
                            attentionQuery,
                            attentionItems,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _InventoryHeading(
                        view: _view,
                        showWideActions: showInlineActions,
                        onRecordCost: _recordCost,
                        onVerifyStock: stock.isEmpty ? null : _selectStock,
                      ),
                      const SizedBox(height: 14),
                      _InventorySummary(costs: costs, stock: stock),
                      const SizedBox(height: 16),
                      _InventoryLanes(
                        layout: layout,
                        costs: costs,
                        stock: stock,
                        search: _search,
                        preferences: _preferences,
                        onSearch: (value) => setState(() => _search = value),
                        onMaterial: _openMaterial,
                        onStock: _countStock,
                        onCalendarDay: _openDay,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<MaterialCostRecord> get _visibleCosts {
    // Purchase history belongs to the company catalog. Vehicle scope applies
    // only to physical stock, never to the historical price lookup.
    return [..._store.materialCosts];
  }

  List<InventoryStockRecord> get _visibleStock {
    final stock = _store.inventoryStock;
    final vehicleId = OperationalScope.of(context).inventoryVehicleId;
    if (vehicleId == null) return [...stock];
    return stock.where((record) => record.locationId == vehicleId).toList();
  }

  OperationalAttentionQuery _attentionQuery(OperationalScopeController scope) =>
      OperationalAttentionQuery(
        panelId: 'inventory-home',
        module: OperationalAttentionModule.inventory,
        view: scope.view,
        access: const OperationalAttentionAccess({
          OperationalAttentionCapability.reviewInventoryStock,
        }),
        selectedVehicleId: scope.inventoryVehicleId,
        resourceKinds: const {OperationalAttentionResourceKind.inventoryStock},
      );

  Future<void> _openAttentionItem(OperationalAttentionItem item) async {
    final matches = _store.inventoryStock.where(
      (record) => record.id == item.sourceId,
    );
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This stock record is no longer available.'),
        ),
      );
      return;
    }
    await _countStock(matches.first);
  }

  void _openAttentionList(List<OperationalAttentionItem> items) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => InventoryAttentionScreen(
          items: items,
          onOpen: _openAttentionItem,
          onSettings: _openSettings,
        ),
      ),
    );
  }

  Future<void> _openActions() async {
    final action = await Navigator.of(context).push<InventoryAction>(
      MaterialPageRoute(
        builder: (_) => InventoryActionScreen(
          selectedDate: inventoryDemoToday,
          canVerifyStock: _visibleStock.isNotEmpty,
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case InventoryAction.recordCost:
        await _recordCost();
      case InventoryAction.verifyStock:
        await _selectStock();
    }
  }

  Future<void> _recordCost() async {
    final record = await Navigator.of(context).push<MaterialCostRecord>(
      MaterialPageRoute(
        builder: (_) =>
            MaterialCostEditorScreen(purchaseDate: inventoryDemoToday),
      ),
    );
    if (record != null) _store.addMaterialCost(record);
  }

  Future<void> _selectStock() async {
    final updated = await Navigator.of(context).push<InventoryStockRecord>(
      MaterialPageRoute(
        builder: (_) => StockSelectionScreen(records: _visibleStock),
      ),
    );
    if (updated != null) _store.updateInventoryStock(updated);
  }

  Future<void> _countStock(InventoryStockRecord record) async {
    final updated = await Navigator.of(context).push<InventoryStockRecord>(
      MaterialPageRoute(builder: (_) => StockCountScreen(record: record)),
    );
    if (updated != null) _store.updateInventoryStock(updated);
  }

  void _openMaterial(String materialId) {
    final costs = _store.materialCosts
        .where((record) => record.materialId == materialId)
        .toList();
    final stock = _store.inventoryStock
        .where((record) => record.materialId == materialId)
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MaterialDetailScreen(
          materialName: costs.first.materialName,
          costs: costs,
          stock: stock,
        ),
      ),
    );
  }

  void _openDay(DateTime day) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => InventoryDayScreen(
        selectedDate: day,
        selectedVehicleId: OperationalScope.of(context).inventoryVehicleId,
        costs: _visibleCosts,
        stock: _store.inventoryStock,
      ),
    ),
  );

  Future<void> _openSettings() async {
    final result = await Navigator.of(context)
        .push<InventoryDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => InventorySettingsScreen(initial: _preferences),
          ),
        );
    if (mounted && result != null) setState(() => _preferences = result);
  }
}
