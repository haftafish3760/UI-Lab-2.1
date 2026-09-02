import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import '../expenses/expense_detail_screen.dart';
import '../expenses/expense_permissions.dart';
import 'inventory_models.dart';
import 'inventory_scope_header.dart';
import 'inventory_settings_screen.dart';

class MaterialDetailScreen extends StatelessWidget {
  const MaterialDetailScreen({
    required this.materialName,
    required this.costs,
    required this.stock,
    super.key,
  });

  final String materialName;
  final List<MaterialCostRecord> costs;
  final List<InventoryStockRecord> stock;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final sortedCosts = [...costs]
      ..sort((a, b) => b.purchasedOn.compareTo(a.purchasedOn));
    return Scaffold(
      key: const ValueKey('material-detail-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            final costSection = _Costs(costs: sortedCosts);
            final stockSection = _Stock(stock: stock);
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
                          onSettings: () => _openSettings(context),
                          workspaceLabel: 'Material details',
                          showBackButton: true,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          materialName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Verified costs are purchase evidence. Customer price and estimate markup are controlled separately.',
                        ),
                        const SizedBox(height: 16),
                        if (layout.columns == 1) ...[
                          costSection,
                          SizedBox(height: layout.gap),
                          stockSection,
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: layout.columnWidth,
                                child: costSection,
                              ),
                              SizedBox(width: layout.gap),
                              SizedBox(
                                width: layout.columnWidth,
                                child: stockSection,
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

class _Costs extends StatelessWidget {
  const _Costs({required this.costs});
  final List<MaterialCostRecord> costs;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        const ListTile(
          minTileHeight: 48,
          leading: Icon(Icons.price_check_outlined),
          title: Text(
            'Vendor cost history',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        for (final cost in costs)
          ListTile(
            minTileHeight: 62,
            title: Text(cost.vendor),
            subtitle: Text(
              '${operationalDateLabel(context, cost.purchasedOn, weekday: false)} · ${cost.confirmedBy}'
              '${cost.sourceExpenseId == null ? '' : '\nSource expense ${cost.sourceExpenseId} · Tap to open'}',
            ),
            trailing: Text(
              '${inventoryMoney(cost.unitCostCents, currencyCode: cost.currencyCode)}\nper ${cost.unitLabel}',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: cost.sourceExpenseId == null
                ? null
                : () => _openSourceExpense(context, cost.sourceExpenseId!),
          ),
      ],
    ),
  );

  void _openSourceExpense(BuildContext context, String expenseId) {
    final permissions = expensePermissionsForView(
      OperationalScope.of(context).view,
    );
    if (!permissions.canView) return;
    final exists = PrototypeOperationsScope.of(
      context,
    ).expenses.any((expense) => expense.id == expenseId);
    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The linked source expense is no longer available.'),
        ),
      );
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseDetailScreen(expenseId: expenseId, permissions: permissions),
      ),
    );
  }
}

class _Stock extends StatelessWidget {
  const _Stock({required this.stock});
  final List<InventoryStockRecord> stock;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        const ListTile(
          minTileHeight: 48,
          leading: Icon(Icons.local_shipping_outlined),
          title: Text(
            'Known stock locations',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (stock.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No stock location is being tracked for this item.'),
          )
        else
          for (final record in stock)
            ListTile(
              minTileHeight: 62,
              title: Text(record.locationLabel),
              subtitle: Text(
                '${record.confidence.label} · ${operationalDateLabel(context, record.updatedOn, weekday: false)}',
              ),
              trailing: record.confidence == InventoryStockConfidence.unknown
                  ? const Text('Unknown')
                  : Text(
                      '${record.quantity} ${record.unitLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
      ],
    ),
  );
}
