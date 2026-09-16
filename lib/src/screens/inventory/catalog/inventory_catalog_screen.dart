import 'package:flutter/material.dart';
import '../../../data/prototype_operations_store.dart';
import '../../../layout/app_layout_engine.dart';
import '../../../shared/operational_scope.dart';
import '../../../shared/section_card.dart';
import '../inventory_models.dart';
import '../inventory_navigation_card.dart';
import '../inventory_visible_records.dart';
import 'inventory_catalog.dart';
import 'inventory_catalog_item_screen.dart';
import 'inventory_trade_assets.dart';

class InventoryCatalogScreen extends StatefulWidget {
  const InventoryCatalogScreen({
    this.myInventory = false,
    this.path = const [],
    this.locationId,
    this.catalog,
    super.key,
  });
  final bool myInventory;
  final List<String> path;
  final String? locationId;
  final InventoryCatalog? catalog;
  @override
  State<InventoryCatalogScreen> createState() => _InventoryCatalogScreenState();
}

class _InventoryCatalogScreenState extends State<InventoryCatalogScreen> {
  late Future<InventoryCatalog> _catalog;
  late String? _locationId = widget.locationId;
  String _query = '';
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog == null
        ? InventoryCatalog.load()
        : Future.value(widget.catalog);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.path.isEmpty
            ? (widget.myInventory ? 'My Inventory' : 'Browse Catalog')
            : widget.path.last,
      ),
    ),
    body: SafeArea(
      top: false,
      child: FutureBuilder<InventoryCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: SectionCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'The catalog could not be opened. Your stock has not changed.',
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _catalog = InventoryCatalog.load();
                      }),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _contents(snapshot.data!);
        },
      ),
    ),
  );

  Widget _contents(InventoryCatalog source) {
    final store = PrototypeOperationsScope.of(context);
    final scope = OperationalScope.of(context);
    final permitted = visibleInventoryStock(store, scope);
    final stock = permitted
        .where((r) => _locationId == null || r.locationId == _locationId)
        .toList();
    final catalog = widget.myInventory
        ? _stockCatalog(source, stock, store)
        : source;
    final branches = catalog.branches(widget.path);
    final searching = _query.trim().isNotEmpty;
    final results = searching
        ? catalog.search(_query, widget.path)
        : catalog.itemsAt(widget.path);
    final showItems = searching || results.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final layout = AppLayoutEngine.operationsFor(
          constraints.maxWidth - insets.horizontal,
          textScaler: MediaQuery.textScalerOf(context),
        );
        return Center(
          child: SizedBox(
            width: layout.workspaceWidth,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: insets,
                  sliver: SliverList.list(
                    children: [
                      if (widget.path.isNotEmpty) ...[
                        Text(widget.path.join(' / ')),
                        const SizedBox(height: 12),
                      ],
                      if (widget.myInventory && widget.path.isEmpty) ...[
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            width: layout.laneWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: _locationId ?? '',
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Truck or storage location',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('All available locations'),
                                ),
                                for (final entry in {
                                  for (final r in permitted)
                                    r.locationId: r.locationLabel,
                                }.entries)
                                  DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                              ],
                              onChanged: (value) => setState(
                                () => _locationId = value == '' ? null : value,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SizedBox(
                          width: layout.laneWidth,
                          child: TextField(
                            controller: _search,
                            decoration: InputDecoration(
                              labelText: widget.path.isEmpty
                                  ? 'Search items'
                                  : 'Search this category',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        _search.clear();
                                        setState(() => _query = '');
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                            ),
                            onChanged: (value) =>
                                setState(() => _query = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!searching && branches.isNotEmpty) ...[
                        Text(
                          widget.path.isEmpty
                              ? 'Choose a trade'
                              : 'Choose a category',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _branches(catalog, source, branches),
                      ],
                      if ((!showItems && branches.isEmpty) ||
                          (showItems && results.isEmpty))
                        SectionCard(
                          child: Text(
                            _query.isNotEmpty
                                ? 'No matching items. Try another name or size.'
                                : widget.myInventory
                                ? 'No items here yet. Browse Catalog to choose your first item.'
                                : 'This part of the catalog is being rebuilt. Items are not available here yet.',
                          ),
                        ),
                      if (showItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text('${results.length} matching items'),
                        ),
                    ],
                  ),
                ),
                if (showItems)
                  SliverPadding(
                    padding: insets,
                    sliver: SliverList.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        final records = stock
                            .where(
                              (r) =>
                                  r.materialId == item.id ||
                                  r.materialId == item.sourceId,
                            )
                            .toList();
                        return Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            width: layout.laneWidth,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InventoryNavigationCard(
                                title: item.name,
                                subtitle: widget.myInventory
                                    ? records
                                          .map(
                                            (r) =>
                                                '${r.locationLabel}: ${r.confidence == InventoryStockConfidence.unknown ? 'Check quantity' : '${r.quantity} ${r.unitLabel}'}',
                                          )
                                          .join('\n')
                                    : '${item.unit}${item.variant.isEmpty ? '' : ' · ${item.variant}'}',
                                onTap: () => _openItem(item, records),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _branches(
    InventoryCatalog catalog,
    InventoryCatalog source,
    List<String> names,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final grid = AppLayoutEngine.workShortcutsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
        minimumLabelWidth: MediaQuery.textScalerOf(context).scale(140),
      );
      final columns = grid.columns;
      final width = (constraints.maxWidth - grid.gap * (columns - 1)) / columns;
      return Wrap(
        spacing: grid.gap,
        runSpacing: grid.gap,
        children: [
          for (final name in names)
            SizedBox(
              width: width,
              child: InventoryNavigationCard(
                title: name,
                image: widget.path.isEmpty ? inventoryTradeImage(name) : null,
                subtitle: catalog.count([...widget.path, name]) == 0
                    ? 'Not available yet'
                    : '${catalog.count([...widget.path, name])} items available',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InventoryCatalogScreen(
                      myInventory: widget.myInventory,
                      catalog: source,
                      locationId: _locationId,
                      path: [...widget.path, name],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Future<void> _openItem(
    InventoryCatalogItem item,
    List<InventoryStockRecord> records,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            InventoryCatalogItemScreen(item: item, records: records),
      ),
    );
  }

  InventoryCatalog _stockCatalog(
    InventoryCatalog source,
    List<InventoryStockRecord> records,
    PrototypeOperationsStore store,
  ) {
    final items = <String, InventoryCatalogItem>{};
    for (final record in records) {
      final matches = source.items.where(
        (i) => i.id == record.materialId || i.sourceId == record.materialId,
      );
      if (matches.length == 1) {
        items[record.materialId] = matches.single;
        continue;
      }
      final costs = store.materialCosts.where(
        (c) => c.materialId == record.materialId,
      );
      items[record.materialId] = InventoryCatalogItem({
        'id': record.materialId,
        'name': record.materialName,
        'unit': record.unitLabel,
        'trade': costs.isEmpty ? 'Unsorted items' : costs.first.trade,
        'category': 'My added items',
        'system': 'Other items',
        'type': 'Items',
      });
    }
    return InventoryCatalog(items.values.toList());
  }
}
