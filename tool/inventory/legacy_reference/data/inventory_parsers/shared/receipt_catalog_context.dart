part of '../../work_supply_receipt_parser.dart';

List<WorkSupplyItem>? _activeReceiptCatalogItems;
_ReceiptCatalogIndexes? _activeReceiptCatalogIndexes;

List<WorkSupplyItem>? _cachedReceiptCatalogSource;
_ReceiptCatalogContext? _cachedReceiptCatalogContext;

final _baseReceiptCatalogContext = _ReceiptCatalogContext.fromItems(
  catalog.workSupplyCatalogItems,
);

List<WorkSupplyItem> get _activeWorkSupplyCatalogItems =>
    _activeReceiptCatalogItems ?? catalog.workSupplyCatalogItems;

Map<String, _ReceiptCatalogEntry> get _receiptCatalogEntryById =>
    _activeReceiptCatalogIndexes?.entriesById ??
    _baseReceiptCatalogContext.indexes.entriesById;

List<WorkSupplyItem> get _plumbingPvcDwvSanitaryTeeItems =>
    _activeReceiptCatalogIndexes?.plumbingPvcDwvSanitaryTeeItems ??
    _baseReceiptCatalogContext.indexes.plumbingPvcDwvSanitaryTeeItems;

List<_ReceiptVendorMappingEntry> get _receiptVendorMappingIndex =>
    _activeReceiptCatalogIndexes?.vendorMappings ??
    _baseReceiptCatalogContext.indexes.vendorMappings;

Map<String, List<_ReceiptCatalogEntry>> get _receiptCatalogTokenIndex =>
    _activeReceiptCatalogIndexes?.tokenIndex ??
    _baseReceiptCatalogContext.indexes.tokenIndex;

/// Narrows exact-name matcher work without changing its final predicate.
/// If a catalog does not expose one of the required tokens, callers retain
/// legacy full-catalog behavior instead of risking a false negative.
Iterable<WorkSupplyItem> _activeReceiptCatalogItemsForRequiredNameTokens(
  Iterable<String> requiredNameParts,
) {
  final tokens = {
    for (final part in requiredNameParts)
      ..._receiptCandidateTokens(_normalize(part)),
  };
  if (tokens.isEmpty) return _activeWorkSupplyCatalogItems;
  final entriesByToken = [
    for (final token in tokens) _receiptCatalogTokenIndex[token],
  ];
  if (entriesByToken.any((entries) => entries == null)) {
    return _activeWorkSupplyCatalogItems;
  }
  final orderedLists = entriesByToken.cast<List<_ReceiptCatalogEntry>>()
    ..sort((left, right) => left.length.compareTo(right.length));
  final requiredIds = [
    for (final entries in orderedLists.skip(1))
      {for (final entry in entries) entry.item.id},
  ];
  return [
    for (final entry in orderedLists.first)
      if (requiredIds.every((ids) => ids.contains(entry.item.id))) entry.item,
  ];
}

T _runWithReceiptCatalogItems<T>(
  List<WorkSupplyItem>? catalogItems, {
  String? tradeScope,
  required T Function() action,
}) {
  final previousItems = _activeReceiptCatalogItems;
  final previousIndexes = _activeReceiptCatalogIndexes;
  final context = catalogItems == null
      ? _baseReceiptCatalogContext
      : _customReceiptCatalogContext(catalogItems);
  final scoped = context.forTradeScope(tradeScope);
  _activeReceiptCatalogItems = scoped.items;
  _activeReceiptCatalogIndexes = scoped.indexes;
  try {
    return action();
  } finally {
    _activeReceiptCatalogItems = previousItems;
    _activeReceiptCatalogIndexes = previousIndexes;
  }
}

_ReceiptCatalogContext _customReceiptCatalogContext(
  List<WorkSupplyItem> source,
) {
  if (identical(source, _cachedReceiptCatalogSource)) {
    return _cachedReceiptCatalogContext!;
  }
  final context = _ReceiptCatalogContext.fromItems(source);
  _cachedReceiptCatalogSource = source;
  _cachedReceiptCatalogContext = context;
  return context;
}

class _ReceiptCatalogContext {
  _ReceiptCatalogContext._({
    required this.items,
    required this.indexes,
    required this.tradeScopes,
  });

  factory _ReceiptCatalogContext.fromItems(List<WorkSupplyItem> source) {
    final items = List<WorkSupplyItem>.unmodifiable(source);
    return _ReceiptCatalogContext._(
      items: items,
      indexes: _ReceiptCatalogIndexes.build(items),
      tradeScopes: {for (final item in items) item.trade.trim().toLowerCase()},
    );
  }

  final List<WorkSupplyItem> items;
  final _ReceiptCatalogIndexes indexes;
  final Set<String> tradeScopes;
  final _scopedContexts = <String, _ReceiptCatalogContext>{};

  _ReceiptCatalogContext forTradeScope(String? tradeScope) {
    final scope = tradeScope?.trim().toLowerCase();
    if (scope == null || scope.isEmpty) return this;
    if (tradeScopes.length == 1 && tradeScopes.contains(scope)) return this;
    return _scopedContexts.putIfAbsent(scope, () {
      final scopedItems = [
        for (final item in items)
          if (item.trade.toLowerCase() == scope) item,
      ];
      return _ReceiptCatalogContext.fromItems(scopedItems);
    });
  }
}

List<WorkSupplyItem> _searchActiveReceiptCatalogItems(String query) {
  final tokens = _normalize(
    query,
  ).split(' ').where((token) => token.length >= 2).toList();
  if (tokens.isEmpty) return _activeWorkSupplyCatalogItems.take(25).toList();
  return [
    for (final item in _activeWorkSupplyCatalogItems)
      if (tokens.every(item.searchableText.contains)) item,
  ];
}

class _ReceiptCatalogIndexes {
  const _ReceiptCatalogIndexes({
    required this.entries,
    required this.entriesById,
    required this.plumbingPvcDwvSanitaryTeeItems,
    required this.vendorMappings,
    required this.tokenIndex,
  });

  final List<_ReceiptCatalogEntry> entries;
  final Map<String, _ReceiptCatalogEntry> entriesById;
  final List<WorkSupplyItem> plumbingPvcDwvSanitaryTeeItems;
  final List<_ReceiptVendorMappingEntry> vendorMappings;
  final Map<String, List<_ReceiptCatalogEntry>> tokenIndex;

  factory _ReceiptCatalogIndexes.build(List<WorkSupplyItem> items) {
    final entries = [
      for (final item in items)
        (
          item: item,
          searchableText: item.searchableText.toLowerCase(),
          normalizedText: _normalize(
            '${item.searchableText} ${item.aliases.join(' ')}',
          ),
          variantText: _normalize(item.variant),
        ),
    ];
    return _ReceiptCatalogIndexes(
      entries: List.unmodifiable(entries),
      entriesById: Map.unmodifiable({
        for (final entry in entries) entry.item.id: entry,
      }),
      plumbingPvcDwvSanitaryTeeItems: List.unmodifiable([
        for (final item in items)
          if (item.trade == 'Plumbing' &&
              item.name.toLowerCase().contains('pvc dwv') &&
              item.name.toLowerCase().contains('sanitary tee'))
            item,
      ]),
      vendorMappings: List.unmodifiable([
        for (final entry in entries)
          for (final mapping in entry.item.intelligence.vendorMappings)
            if (_compactVendorCode(mapping.code).length >= 4 ||
                _normalize(mapping.label).length >= 4)
              (
                item: entry.item,
                code: _compactVendorCode(mapping.code),
                label: _normalize(mapping.label),
              ),
      ]),
      tokenIndex: Map.unmodifiable(_buildReceiptCatalogTokenIndex(entries)),
    );
  }
}
