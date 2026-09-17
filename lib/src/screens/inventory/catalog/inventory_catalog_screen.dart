import 'package:flutter/material.dart';
import '../../../data/prototype_operations_store.dart';
import '../../../layout/app_layout_engine.dart';
import '../../../shared/operational_scope.dart';
import '../../../shared/section_card.dart';
import '../inventory_models.dart';
import '../inventory_visible_records.dart';
import 'inventory_catalog.dart';
import 'materials_catalog_item_details.dart';
import 'materials_catalog_tiles.dart';
import 'materials_catalog_labels.dart';
import 'inventory_trade_assets.dart';
import '../../../../l10n/app_localizations_extension.dart';
import 'materials_catalog_route.dart';

class InventoryCatalogScreen extends StatefulWidget {
  const InventoryCatalogScreen({
    this.myInventory = false,
    this.path = const [],
    this.locationId,
    this.catalog,
    this.listView = false,
    super.key,
  });
  final bool myInventory;
  final bool listView;
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
  late bool _listView = widget.listView;
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
            ? (widget.myInventory
                  ? context.l10n.catalogInventory
                  : context.l10n.catalogBrowse)
            : materialsBranchLabel(context, widget.path.last),
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
                        Text(
                          widget.path
                              .map(
                                (part) => materialsBranchLabel(context, part),
                              )
                              .join(' / '),
                        ),
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
                                  ? context.l10n.catalogSearch
                                  : context.l10n.catalogSearchCategory,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: context.l10n.catalogClear,
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
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: false,
                              icon: const Icon(Icons.grid_view),
                              label: Text(context.l10n.catalogGrid),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: const Icon(Icons.view_list),
                              label: Text(context.l10n.catalogList),
                            ),
                          ],
                          selected: {_listView},
                          onSelectionChanged: (value) =>
                              setState(() => _listView = value.single),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!searching && branches.isNotEmpty) ...[
                        Text(
                          widget.path.isEmpty
                              ? context.l10n.catalogChooseTrade
                              : context.l10n.catalogChooseCategory,
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
                                ? context.l10n.catalogNoMatches
                                : widget.myInventory
                                ? 'No items here yet. Browse Catalog to choose your first item.'
                                : context.l10n.catalogEmpty,
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
                    sliver: SliverToBoxAdapter(
                      child: MaterialsCatalogTiles(
                        listView: _listView,
                        entries: [
                          for (final item in results)
                            MaterialsCatalogTileData(
                              label: !searching && item.variant.isNotEmpty
                                  ? item.variant
                                  : materialsItemLabel(context, item),
                              detail: widget.myInventory
                                  ? stock
                                        .where(
                                          (r) =>
                                              r.materialId == item.id ||
                                              r.materialId == item.sourceId,
                                        )
                                        .map(
                                          (r) =>
                                              '${r.locationLabel}: ${r.confidence == InventoryStockConfidence.unknown ? 'Check quantity' : '${r.quantity} ${r.unitLabel}'}',
                                        )
                                        .join('\n')
                                  : searching
                                  ? materialsUnitLabel(context, item.unit)
                                  : '',
                              onTap: () => _openItem(
                                item,
                                stock
                                    .where(
                                      (r) =>
                                          r.materialId == item.id ||
                                          r.materialId == item.sourceId,
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
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
  ) => MaterialsCatalogTiles(
    listView: _listView,
    entries: [
      for (final name in names)
        MaterialsCatalogTileData(
          label: materialsBranchLabel(context, name),
          imageAsset: widget.path.isEmpty ? inventoryTradeImage(name) : null,
          onTap: () => Navigator.of(context).push(
            MaterialsCatalogRoute<void>(
              context: context,
              builder: (_) => InventoryCatalogScreen(
                myInventory: widget.myInventory,
                catalog: source,
                locationId: _locationId,
                path: [...widget.path, name],
                listView: _listView,
              ),
            ),
          ),
        ),
    ],
  );

  Future<void> _openItem(
    InventoryCatalogItem item,
    List<InventoryStockRecord> records,
  ) async {
    await Navigator.of(context).push(
      MaterialsCatalogRoute<void>(
        context: context,
        builder: (_) =>
            MaterialsCatalogItemDetails(item: item, records: records),
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
