import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/operational_scope.dart';
import 'inventory_scope_header.dart';
import 'inventory_settings_screen.dart';

enum InventoryAction { recordCost, verifyStock }

class InventoryActionScreen extends StatelessWidget {
  const InventoryActionScreen({
    required this.selectedDate,
    required this.canVerifyStock,
    super.key,
  });

  final DateTime selectedDate;
  final bool canVerifyStock;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: const ValueKey('inventory-action-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.workShortcutsFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InventoryScopeHeader(
                          view: scope.view,
                          selectedVehicleId: scope.inventoryVehicleId,
                          onViewChanged: scope.setView,
                          onVehicleChanged: scope.selectInventoryVehicle,
                          onSettings: () => _openSettings(context),
                          workspaceLabel: 'Material actions',
                          showBackButton: true,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Material actions',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose what you are recording. A purchase cost does not change truck stock unless you explicitly count or receive stock.',
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: layout.gap,
                          runSpacing: layout.gap,
                          children: [
                            _ActionTile(
                              width: layout.tileWidth,
                              icon: Icons.price_check_outlined,
                              label: 'Record purchase cost',
                              detail: 'Save a verified vendor and unit cost',
                              onTap: () => Navigator.pop(
                                context,
                                InventoryAction.recordCost,
                              ),
                            ),
                            if (canVerifyStock)
                              _ActionTile(
                                width: layout.tileWidth,
                                icon: Icons.fact_check_outlined,
                                label: 'Verify truck stock',
                                detail:
                                    'Replace a reported count with a physical count',
                                onTap: () => Navigator.pop(
                                  context,
                                  InventoryAction.verifyStock,
                                ),
                              ),
                          ],
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

  void _openSettings(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const InventorySettingsScreen()),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width.clamp(150, 210),
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.all(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}
