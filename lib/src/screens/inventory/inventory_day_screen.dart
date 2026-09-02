import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'inventory_models.dart';
import 'inventory_scope_header.dart';
import 'inventory_settings_screen.dart';
import 'material_detail_screen.dart';

class InventoryDayScreen extends StatefulWidget {
  const InventoryDayScreen({
    required this.selectedDate,
    required this.costs,
    required this.stock,
    this.selectedVehicleId,
    super.key,
  });

  final DateTime selectedDate;
  final List<MaterialCostRecord> costs;
  final List<InventoryStockRecord> stock;
  final String? selectedVehicleId;

  @override
  State<InventoryDayScreen> createState() => _InventoryDayScreenState();
}

class _InventoryDayScreenState extends State<InventoryDayScreen> {
  var _preferences = const InventoryDisplayPreferences.defaults();

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final activeVehicleId = scope.inventoryVehicleId;
    final dayCosts = widget.costs
        .where(
          (record) => sameInventoryDay(record.purchasedOn, widget.selectedDate),
        )
        .toList();
    final dayCounts = widget.stock
        .where(
          (record) =>
              sameInventoryDay(record.updatedOn, widget.selectedDate) &&
              (activeVehicleId == null || record.locationId == activeVehicleId),
        )
        .toList();
    return Scaffold(
      key: const ValueKey('inventory-day-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            final purchases = _DayPurchases(
              records: dayCosts,
              onOpen: (record) => _openMaterial(context, record),
            );
            final counts = _DayCounts(records: dayCounts);
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
                          selectedVehicleId: activeVehicleId,
                          onViewChanged: scope.setView,
                          onVehicleChanged: scope.selectInventoryVehicle,
                          onSettings: () => _openSettings(context),
                          workspaceLabel: 'Materials day',
                          showBackButton: true,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          operationalDateLabel(context, widget.selectedDate),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Confirmed material purchases and physical stock counts recorded on this date.',
                        ),
                        const SizedBox(height: 16),
                        if (layout.columns == 1) ...[
                          purchases,
                          if (_preferences.showTruckStock) ...[
                            SizedBox(height: layout.gap),
                            counts,
                          ],
                        ] else if (_preferences.showTruckStock)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: layout.columnWidth,
                                child: purchases,
                              ),
                              SizedBox(width: layout.gap),
                              SizedBox(
                                width: layout.columnWidth,
                                child: counts,
                              ),
                            ],
                          )
                        else
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: SizedBox(
                              width: layout.columnWidth,
                              child: purchases,
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

  void _openMaterial(BuildContext context, MaterialCostRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MaterialDetailScreen(
          materialName: record.materialName,
          costs: widget.costs
              .where((candidate) => candidate.materialId == record.materialId)
              .toList(),
          stock: widget.stock
              .where((candidate) => candidate.materialId == record.materialId)
              .toList(),
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    final result = await Navigator.of(context)
        .push<InventoryDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => InventorySettingsScreen(
              initial: _preferences,
              workspaceLabel: 'Materials day',
              showCostSourcesOption: false,
            ),
          ),
        );
    if (mounted && result != null) setState(() => _preferences = result);
  }
}

class _DayPurchases extends StatelessWidget {
  const _DayPurchases({required this.records, required this.onOpen});
  final List<MaterialCostRecord> records;
  final ValueChanged<MaterialCostRecord> onOpen;

  @override
  Widget build(BuildContext context) => _DaySection(
    title: 'Material purchases',
    icon: Icons.price_check_outlined,
    children: [
      if (records.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No confirmed material costs were recorded on this date.',
          ),
        )
      else
        for (final record in records)
          ListTile(
            minTileHeight: 64,
            title: Text(record.materialName),
            subtitle: Text('${record.vendor} · ${record.confirmedBy}'),
            trailing: Text(
              '${inventoryMoney(record.unitCostCents, currencyCode: record.currencyCode)}\nper ${record.unitLabel}',
              textAlign: TextAlign.end,
            ),
            onTap: () => onOpen(record),
          ),
    ],
  );
}

class _DayCounts extends StatelessWidget {
  const _DayCounts({required this.records});
  final List<InventoryStockRecord> records;

  @override
  Widget build(BuildContext context) => _DaySection(
    title: 'Stock counts',
    icon: Icons.fact_check_outlined,
    children: [
      if (records.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No physical stock count was recorded on this date.'),
        )
      else
        for (final record in records)
          ListTile(
            minTileHeight: 64,
            title: Text(record.materialName),
            subtitle: Text(
              '${record.locationLabel} · ${record.confidence.label}',
            ),
            trailing: record.confidence == InventoryStockConfidence.unknown
                ? const Text('Unknown')
                : Text('${record.quantity} ${record.unitLabel}'),
          ),
    ],
  );
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        ListTile(
          minTileHeight: 48,
          tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          leading: Icon(icon),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ...children,
      ],
    ),
  );
}
