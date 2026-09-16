import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/localized_date.dart';
import '../../shared/module_month_calendar.dart';
import '../../shared/operational_scope.dart';
import '../../shared/operations_workspace.dart';
import '../../shared/section_card.dart';
import '../../shell/app_menu_scope.dart';
import '../../theme/app_theme.dart';
import 'catalog/inventory_catalog_screen.dart';
import 'inventory_day_screen.dart';
import 'inventory_models.dart';
import 'inventory_navigation_card.dart';
import 'inventory_review_examples.dart';
import 'inventory_visible_records.dart';
import 'stock_count_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

// Preserve the screen's original state identity while existing debug sessions
// hot reload the inventory redesign inside AppShell's IndexedStack.
class _InventoryScreenState extends State<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final scope = OperationalScope.of(context);
    final stock = visibleInventoryStock(store, scope);
    final low = stock.where((r) => r.isLow).toList();
    final unknown = stock
        .where((r) => r.confidence == InventoryStockConfidence.unknown)
        .toList();
    final permissions = store.workSession?.permissions;
    final costs = store.materialCosts
        .where(
          (r) =>
              permissions == null ||
              permissions.visibleCreatorIds.contains(r.ownerEmployeeId),
        )
        .toList();
    return Scaffold(
      key: const ValueKey('inventory-module-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.operationsFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: insets.add(const EdgeInsets.symmetric(vertical: 10)),
              children: [
                OperationsWorkspaceFrame(
                  layout: layout,
                  primaryContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionCard(
                        key: const ValueKey('inventory-module-header'),
                        backgroundColor: AppColors.header,
                        borderColor: AppColors.headerBorder,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Open navigation',
                              onPressed: AppMenuScope.maybeOpenOf(context),
                              icon: const Icon(
                                Icons.menu,
                                color: AppColors.onHeader,
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Materials',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.onHeader,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Inventory settings',
                              onPressed: () => _help(context),
                              icon: const Icon(
                                Icons.settings_outlined,
                                color: AppColors.onHeader,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        operationalDateLabel(context, DateTime.now()),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      OperationsLaneGrid(
                        layout: layout,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Needs attention',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 10),
                              if (low.isNotEmpty)
                                InventoryNavigationCard(
                                  key: const ValueKey('inventory-low-stock'),
                                  title: 'Running low',
                                  subtitle:
                                      '${low.length} item locations at or below your chosen minimum',
                                  icon: Icons.shopping_basket_outlined,
                                  onTap: () =>
                                      _attention(context, 'Running low', low),
                                ),
                              if (unknown.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                InventoryNavigationCard(
                                  title: 'Check quantities',
                                  subtitle:
                                      '${unknown.length} item locations need a count',
                                  onTap: () => _attention(
                                    context,
                                    'Check quantities',
                                    unknown,
                                  ),
                                ),
                              ],
                              if (low.isEmpty && unknown.isEmpty)
                                SectionCard(
                                  child: Text(
                                    stock.isEmpty
                                        ? 'Start with the items you already have. You can add them without a receipt.'
                                        : 'No stock alerts right now. Alerts use the minimums you set for each location.',
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Your materials',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 10),
                              InventoryNavigationCard(
                                key: const ValueKey('inventory-my-inventory'),
                                title: 'My Inventory',
                                subtitle:
                                    'Find items on your trucks and in storage',
                                icon: Icons.inventory_2_outlined,
                                onTap: () => _browse(context, true),
                              ),
                              const SizedBox(height: 10),
                              InventoryNavigationCard(
                                key: const ValueKey('inventory-browse-catalog'),
                                title: 'Browse Catalog',
                                subtitle:
                                    'Choose a trade, find an item, and add it to your stock',
                                icon: Icons.category_outlined,
                                onTap: () => _browse(context, false),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SectionCard(
                        child: Text(
                          inventoryReviewExamplesEnabled
                              ? 'Sample inventory for layout review. Changes are not yet saved after closing the app.'
                              : 'Layout review: inventory changes are not yet saved after closing the app.',
                        ),
                      ),
                    ],
                  ),
                  followingContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Materials calendar',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      WorkMonthCalendar(
                        maximumWidth: layout.laneWidth,
                        selectedDay: inventoryDemoToday,
                        entryCountForDay: (day) => costs
                            .where(
                              (r) => DateUtils.isSameDay(r.purchasedOn, day),
                            )
                            .length,
                        recordKind: CalendarRecordKind.inventoryRecord,
                        onDaySelected: (day) => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => InventoryDayScreen(
                              selectedDate: day,
                              selectedVehicleId: null,
                              costs: costs,
                              stock: stock,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  void _browse(BuildContext context, bool mine) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => InventoryCatalogScreen(myInventory: mine),
    ),
  );
  void _attention(
    BuildContext context,
    String title,
    List<InventoryStockRecord> records,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _InventoryStockAttention(
        title: title,
        recordIds: records.map((r) => r.id).toSet(),
      ),
    ),
  );
  void _help(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Inventory settings')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'My Inventory shows items you have added, grouped by trade and location.\n\n'
                    'Browse Catalog lets you find items by trade, material, type, and size. No receipt is required to add stock.\n\n'
                    'Set a minimum quantity when adding an item to show it under Running low. The minimum applies to that location.\n\n'
                    'A quantity that needs checking is never treated as zero.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _browse(context, true),
                    child: const Text('Manage item minimums'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _InventoryStockAttention extends StatelessWidget {
  const _InventoryStockAttention({
    required this.title,
    required this.recordIds,
  });
  final String title;
  final Set<String> recordIds;
  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final records = visibleInventoryStock(store, OperationalScope.of(context))
        .where(
          (r) =>
              recordIds.contains(r.id) &&
              (title == 'Running low'
                  ? r.isLow
                  : r.confidence == InventoryStockConfidence.unknown),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayoutEngine.maximumFormWorkspaceWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (records.isEmpty)
                const SectionCard(
                  child: Text('These stock checks are taken care of.'),
                ),
              for (final record in records)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InventoryNavigationCard(
                    title: record.materialName,
                    subtitle:
                        '${record.locationLabel}\n${record.confidence == InventoryStockConfidence.unknown ? 'Check quantity' : '${record.quantity} ${record.unitLabel} · minimum ${record.lowAt}'}',
                    onTap: () async {
                      final result = await Navigator.of(context)
                          .push<InventoryStockRecord>(
                            MaterialPageRoute(
                              builder: (_) => StockCountScreen(record: record),
                            ),
                          );
                      if (context.mounted && result != null) {
                        store.updateInventoryStock(result);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
