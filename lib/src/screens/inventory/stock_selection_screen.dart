import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/operational_scope.dart';
import 'inventory_models.dart';
import 'inventory_scope_header.dart';
import 'inventory_settings_screen.dart';
import 'stock_count_screen.dart';

class StockSelectionScreen extends StatelessWidget {
  const StockSelectionScreen({required this.records, super.key});

  final List<InventoryStockRecord> records;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: const ValueKey('stock-selection-screen'),
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
                          onSettings: () => _openSettings(context),
                          workspaceLabel: 'Choose stock to count',
                          showBackButton: true,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Which item did you count?',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose one truck item. The next screen records the physical count and date.',
                        ),
                        const SizedBox(height: 14),
                        for (final record in records)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              minTileHeight: 64,
                              title: Text(record.materialName),
                              subtitle: Text(
                                '${record.locationLabel} · ${record.confidence.label}',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _count(context, record),
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

  Future<void> _count(BuildContext context, InventoryStockRecord record) async {
    final updated = await Navigator.of(context).push<InventoryStockRecord>(
      MaterialPageRoute(builder: (_) => StockCountScreen(record: record)),
    );
    if (context.mounted && updated != null) Navigator.pop(context, updated);
  }

  void _openSettings(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const InventorySettingsScreen()),
  );
}
