import 'package:flutter/material.dart';

import '../../data/operational_attention.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/operational_attention_panel.dart';
import '../../shared/operational_scope.dart';
import 'inventory_scope_header.dart';

class InventoryAttentionScreen extends StatelessWidget {
  const InventoryAttentionScreen({
    required this.items,
    required this.onOpen,
    required this.onSettings,
    super.key,
  });

  final List<OperationalAttentionItem> items;
  final ValueChanged<OperationalAttentionItem> onOpen;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: const ValueKey('inventory-attention-list'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final available = constraints.maxWidth - insets.horizontal;
            final layout = AppLayoutEngine.detailWorkspaceFor(
              available,
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
                          onSettings: onSettings,
                          workspaceLabel: 'Materials attention',
                          showBackButton: true,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 12),
                        OperationalAttentionList(
                          items: items,
                          rowKeyFor: (item) => ValueKey(
                            'inventory-attention-list-${item.sourceId}',
                          ),
                          onOpen: onOpen,
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
}
