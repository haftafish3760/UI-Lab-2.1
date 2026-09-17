import 'work_supply_catalog.dart';
import 'work_supply_catalog_audit.dart';
import 'work_supply_item_identity_resolver.dart';
import 'work_supply_locale_pack.dart';
import 'work_supply_models.dart';

const workSupplyFullTradesCatalogName = 'Full Trades Catalog';
const workSupplyDefaultLocalePackId = workSupplyLocalePackEnUsId;
const workSupplyDefaultCountryCodes = workSupplyLocalePackEnUsCountryCodes;

final _tradePackItemsCache = <String, List<WorkSupplyItem>>{};
final _tradeItemsCache = <String, List<WorkSupplyItem>>{};
final _servicePopularityScoreCache = <String, int>{};

enum WorkSupplyTradePackTier {
  core(
    'core',
    'Core',
    'Top daily-use items for receipt help, inventory entry, and estimates',
    .25,
    'Top 25% by service-truck usefulness',
  ),
  expanded(
    'standard',
    'Standard',
    'Common plus regular job stock for stronger receipt and estimate help',
    .50,
    'Top 50% by residential and light-industrial use',
  ),
  professional(
    'professional',
    'Professional',
    'Deep service inventory for busy contractors and stocked trucks',
    .75,
    'Top 75% before specialty edge cases',
  ),
  full(
    'complete',
    'Complete',
    'Every cataloged item for the trade, including specialty and rare stock',
    1,
    'Complete trade catalog',
  );

  const WorkSupplyTradePackTier(
    this.id,
    this.label,
    this.description,
    this.catalogShare,
    this.popularityBand,
  );

  final String id;
  final String label;
  final String description;
  final double catalogShare;
  final String popularityBand;
}

class WorkSupplyTradePackOption {
  const WorkSupplyTradePackOption({
    required this.tradeName,
    required this.marketScope,
    required this.tier,
    required this.itemCount,
    required this.estimatedRawBytes,
    required this.estimatedCompressedBytes,
    required this.storagePath,
    this.localePackId = workSupplyDefaultLocalePackId,
    this.countryCodes = workSupplyDefaultCountryCodes,
  });

  final String tradeName;
  final WorkSupplyMarketScope? marketScope;
  final WorkSupplyTradePackTier tier;
  final int itemCount;
  final int estimatedRawBytes;
  final int estimatedCompressedBytes;
  final String storagePath;
  final String localePackId;
  final List<String> countryCodes;

  int get estimatedUncompressedBytes => estimatedRawBytes;

  String get displayName {
    if (tradeName == workSupplyFullTradesCatalogName) {
      return workSupplyFullTradesCatalogName;
    }
    final scope = marketScope == null ? '' : '${marketScope!.label} ';
    return '$scope${tier.label} $tradeName Pack';
  }

  String get estimatedSizeLabel => _byteSizeLabel(estimatedCompressedBytes);
  String get estimatedDownloadSizeLabel =>
      _byteSizeLabel(estimatedCompressedBytes);
  String get estimatedOnDeviceSizeLabel =>
      _byteSizeLabel(estimatedUncompressedBytes);

  Map<String, Object?> toManifestMap() {
    return {
      'tradeName': tradeName,
      'marketScope': marketScope?.name,
      'marketScopeLabel': marketScope?.label,
      'tier': tier.id,
      'localePackId': localePackId,
      'countryCodes': countryCodes,
      'displayName': displayName,
      'description': tier.description,
      'popularityBand': tier.popularityBand,
      'catalogSharePercent': (tier.catalogShare * 100).round(),
      'itemCount': itemCount,
      'estimatedUncompressedBytes': estimatedUncompressedBytes,
      'estimatedOnDeviceSizeLabel': estimatedOnDeviceSizeLabel,
      'estimatedCompressedBytes': estimatedCompressedBytes,
      'estimatedDownloadSizeLabel': estimatedDownloadSizeLabel,
      'estimatedSizeLabel': estimatedDownloadSizeLabel,
      'storagePath': storagePath,
      'deliveryMode': 'storage_gzip_chunk',
      'receiptAssistance':
          'Helps match receipt lines, package quantities, aliases, and vendor wording.',
      'estimateAssistance':
          'Can stage matched materials for estimate line items after receipt review.',
    };
  }
}

class WorkSupplyTradePackTradeSummary {
  const WorkSupplyTradePackTradeSummary({
    required this.tradeName,
    required this.optionCount,
    required this.itemCount,
    required this.estimatedCompressedBytes,
  });

  final String tradeName;
  final int optionCount;
  final int itemCount;
  final int estimatedCompressedBytes;

  String get estimatedSizeLabel => _byteSizeLabel(estimatedCompressedBytes);
}

extension WorkSupplyMarketScopeLabel on WorkSupplyMarketScope {
  String get label {
    return switch (this) {
      WorkSupplyMarketScope.residential => 'Residential',
      WorkSupplyMarketScope.lightIndustrial => 'Light Industrial',
      WorkSupplyMarketScope.commercial => 'Commercial',
    };
  }

  String get id {
    return switch (this) {
      WorkSupplyMarketScope.residential => 'residential',
      WorkSupplyMarketScope.lightIndustrial => 'light-industrial',
      WorkSupplyMarketScope.commercial => 'commercial',
    };
  }
}

List<WorkSupplyTradePackOption> buildWorkSupplyTradePackOptions(
  String tradeName, {
  WorkSupplyLocalePack localePack = workSupplyLocalePackEnUs,
}) {
  return buildWorkSupplyTradePackOptionsForScope(
    tradeName,
    localePack: localePack,
  );
}

List<WorkSupplyTradePackOption> buildWorkSupplyTradePackOptionsForScope(
  String tradeName, {
  WorkSupplyMarketScope? marketScope,
  WorkSupplyLocalePack localePack = workSupplyLocalePackEnUs,
}) {
  final core = buildWorkSupplyTradePackItems(
    tradeName,
    WorkSupplyTradePackTier.core,
    marketScope: marketScope,
  );
  final expanded = buildWorkSupplyTradePackItems(
    tradeName,
    WorkSupplyTradePackTier.expanded,
    marketScope: marketScope,
  );
  final professional = buildWorkSupplyTradePackItems(
    tradeName,
    WorkSupplyTradePackTier.professional,
    marketScope: marketScope,
  );
  final full = buildWorkSupplyTradePackItems(
    tradeName,
    WorkSupplyTradePackTier.full,
    marketScope: marketScope,
  );
  return [
    _optionFor(
      tradeName,
      marketScope,
      WorkSupplyTradePackTier.core,
      core,
      localePack: localePack,
    ),
    _optionFor(
      tradeName,
      marketScope,
      WorkSupplyTradePackTier.expanded,
      expanded,
      localePack: localePack,
    ),
    _optionFor(
      tradeName,
      marketScope,
      WorkSupplyTradePackTier.professional,
      professional,
      localePack: localePack,
    ),
    _optionFor(
      tradeName,
      marketScope,
      WorkSupplyTradePackTier.full,
      full,
      localePack: localePack,
    ),
  ];
}

List<WorkSupplyTradePackOption> buildWorkSupplyScopedTradePackOptions(
  String tradeName, {
  WorkSupplyLocalePack localePack = workSupplyLocalePackEnUs,
}) {
  return [
    for (final scope in WorkSupplyMarketScopes.all)
      ...buildWorkSupplyTradePackOptionsForScope(
        tradeName,
        marketScope: scope,
        localePack: localePack,
      ),
  ];
}

List<WorkSupplyTradePackOption> buildAllWorkSupplyTradePackOptions() {
  return [
    for (final trade in workSupplyTrades)
      ...buildWorkSupplyTradePackOptions(trade.name),
  ];
}

List<WorkSupplyTradePackOption> buildAllWorkSupplyDownloadOptions() {
  return [
    buildFullWorkSupplyTradePackOption(),
    ...buildAllWorkSupplyTradePackOptions(),
  ];
}

WorkSupplyTradePackOption buildFullWorkSupplyTradePackOption() {
  final items = buildWorkSupplyTradePackItems(
    workSupplyFullTradesCatalogName,
    WorkSupplyTradePackTier.full,
  );
  return _optionFor(
    workSupplyFullTradesCatalogName,
    null,
    WorkSupplyTradePackTier.full,
    items,
  );
}

List<WorkSupplyTradePackTradeSummary> buildWorkSupplyTradePackSummaries() {
  return [for (final trade in workSupplyTrades) _summaryForTrade(trade.name)];
}

String workSupplyTradePackOptionKey(WorkSupplyTradePackOption option) {
  final tradeKey = workSupplyTradePackTradeKey(option.tradeName);
  final localeKey = option.localePackId == workSupplyDefaultLocalePackId
      ? ''
      : ':${option.localePackId.toLowerCase()}';
  final scopeKey = option.marketScope?.id;
  if (scopeKey == null) return '$tradeKey$localeKey:${option.tier.id}';
  return '$tradeKey$localeKey:$scopeKey:${option.tier.id}';
}

String workSupplyTradePackTradeKey(String tradeName) {
  return _packSlug(tradeName);
}

List<WorkSupplyItem> buildWorkSupplyTradePackItems(
  String tradeName,
  WorkSupplyTradePackTier tier, {
  WorkSupplyMarketScope? marketScope,
}) {
  final scopeKey = marketScope?.id ?? 'all';
  final cacheKey = '$tradeName|$scopeKey|${tier.id}';
  return _tradePackItemsCache.putIfAbsent(cacheKey, () {
    if (tradeName == workSupplyFullTradesCatalogName) {
      return _rankedItemsForTier(
        _filterItemsByMarketScope(workSupplyCatalogItems, marketScope),
        tier,
      );
    }
    return _rankedItemsForTier(
      _filterItemsByMarketScope(_itemsForTrade(tradeName), marketScope),
      tier,
    );
  });
}

WorkSupplyTradePackTradeSummary _summaryForTrade(String tradeName) {
  final items = _itemsForTrade(tradeName);
  final rawBytes = _estimatedPackBytes(
    tradeName,
    null,
    WorkSupplyTradePackTier.full,
    items,
  );
  return WorkSupplyTradePackTradeSummary(
    tradeName: tradeName,
    optionCount: WorkSupplyTradePackTier.values.length,
    itemCount: items.length,
    estimatedCompressedBytes: _estimatedCompressedBytes(rawBytes),
  );
}

List<WorkSupplyItem> _rankedItemsForTier(
  List<WorkSupplyItem> items,
  WorkSupplyTradePackTier tier,
) {
  if (items.isEmpty) return const [];
  final selected = [
    for (final item in items)
      if (_itemBelongsInTradePackTier(item, tier)) item,
  ]..sort(_compareByServicePopularity);
  return List.unmodifiable(selected);
}

bool _itemBelongsInTradePackTier(
  WorkSupplyItem item,
  WorkSupplyTradePackTier tier,
) {
  if (tier == WorkSupplyTradePackTier.full) return true;
  return _workSupplyPackTierRank(item.packTier) <=
      _tradePackTierRankBoundary(tier);
}

int _tradePackTierRankBoundary(WorkSupplyTradePackTier tier) {
  return switch (tier) {
    WorkSupplyTradePackTier.core => _workSupplyPackTierRank(
      WorkSupplyPackTier.core,
    ),
    WorkSupplyTradePackTier.expanded => _workSupplyPackTierRank(
      WorkSupplyPackTier.standard,
    ),
    WorkSupplyTradePackTier.professional => _workSupplyPackTierRank(
      WorkSupplyPackTier.professional,
    ),
    WorkSupplyTradePackTier.full => _workSupplyPackTierRank(
      WorkSupplyPackTier.complete,
    ),
  };
}

int _workSupplyPackTierRank(WorkSupplyPackTier tier) {
  return switch (tier) {
    WorkSupplyPackTier.core => 0,
    WorkSupplyPackTier.standard => 1,
    WorkSupplyPackTier.professional => 2,
    WorkSupplyPackTier.complete => 3,
  };
}

int _compareByServicePopularity(WorkSupplyItem a, WorkSupplyItem b) {
  final score = _servicePopularityScore(
    b,
  ).compareTo(_servicePopularityScore(a));
  if (score != 0) return score;
  return canonicalWorkSupplyItemKey(a).compareTo(canonicalWorkSupplyItemKey(b));
}

int _servicePopularityScore(WorkSupplyItem item) {
  final cacheKey = canonicalWorkSupplyItemKey(item);
  return _servicePopularityScoreCache.putIfAbsent(cacheKey, () {
    final text = [
      item.trade,
      item.category,
      item.system,
      item.itemType,
      item.name,
      item.variant,
      item.unit,
      ...item.aliases,
    ].join(' ').toLowerCase();
    var score = 0;
    const highUseTerms = {
      'pex': 30,
      'pvc': 30,
      'dwv': 26,
      'schedule 40': 26,
      'copper': 24,
      'cpvc': 20,
      'sharkbite': 20,
      'push': 18,
      'supply': 18,
      'valve': 18,
      'ball valve': 22,
      'toilet': 18,
      'faucet': 16,
      'sink': 16,
      'water heater': 16,
      'drain': 16,
      'trap': 16,
      'coupling': 15,
      'elbow': 15,
      'tee': 15,
      'adapter': 14,
      'cap': 12,
      'nipple': 12,
      'washer': 10,
      'o-ring': 10,
      'screw': 8,
      'strap': 8,
      'hanger': 8,
    };
    const lowerPriorityTerms = {
      'expanded': -8,
      'galvanized': -12,
      'black iron': -8,
      'cast iron': -8,
      'specialty': -14,
      'commercial': -12,
    };
    for (final entry in highUseTerms.entries) {
      if (text.contains(entry.key)) score += entry.value;
    }
    for (final entry in lowerPriorityTerms.entries) {
      if (text.contains(entry.key)) score += entry.value;
    }
    if (item.aliases.length >= 3) score += 6;
    if (item.variant.contains('1/2') || item.variant.contains('3/4')) {
      score += 8;
    }
    if (item.variant.contains('1 in') || item.variant.contains('1"')) {
      score += 4;
    }
    return score;
  });
}

WorkSupplyTradePackOption _optionFor(
  String tradeName,
  WorkSupplyMarketScope? marketScope,
  WorkSupplyTradePackTier tier,
  List<WorkSupplyItem> items, {
  WorkSupplyLocalePack localePack = workSupplyLocalePackEnUs,
}) {
  final rawBytes = _estimatedPackBytes(tradeName, marketScope, tier, items);
  final localeScope = localePack.id == workSupplyDefaultLocalePackId
      ? ''
      : '/${localePack.id}';
  final storageScope = marketScope == null ? '' : '/${marketScope.id}';
  return WorkSupplyTradePackOption(
    tradeName: tradeName,
    marketScope: marketScope,
    tier: tier,
    itemCount: items.length,
    estimatedRawBytes: rawBytes,
    estimatedCompressedBytes: _estimatedCompressedBytes(rawBytes),
    localePackId: localePack.id,
    countryCodes: localePack.countryCodes,
    storagePath:
        '$workSupplyCatalogStoragePrefix/${_packSlug(tradeName)}$localeScope$storageScope/${tier.id}.json.gz',
  );
}

List<WorkSupplyItem> _filterItemsByMarketScope(
  List<WorkSupplyItem> items,
  WorkSupplyMarketScope? marketScope,
) {
  if (marketScope == null) return items;
  return [
    for (final item in items)
      if (item.marketScopes.contains(marketScope)) item,
  ];
}

List<WorkSupplyItem> _itemsForTrade(String tradeName) {
  return _tradeItemsCache.putIfAbsent(tradeName, () {
    return [
      for (final item in workSupplyCatalogItems)
        if (item.trade == tradeName) item,
    ];
  });
}

int _estimatedPackBytes(
  String tradeName,
  WorkSupplyMarketScope? marketScope,
  WorkSupplyTradePackTier tier,
  List<WorkSupplyItem> items,
) {
  var total = 220 + tradeName.length + tier.id.length;
  if (marketScope != null) total += marketScope.id.length + 24;
  for (final item in items) {
    total += 180;
    total += canonicalWorkSupplyItemKey(item).length;
    total += item.id.length;
    total += item.name.length;
    total += item.category.length;
    total += item.system.length;
    total += item.itemType.length;
    total += item.variant.length;
    total += item.unit.length;
    total += item.marketScopes.length * 18;
    total += item.packTier.name.length;
    total += item.parserPriority.name.length;
    for (final alias in item.aliases) {
      total += 16 + alias.length;
    }
  }
  return total;
}

int _estimatedCompressedBytes(int rawBytes) {
  if (rawBytes <= 0) return 0;
  return (rawBytes * .08).ceil();
}

String _byteSizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(1)} KB';
  return '${(kib / 1024).toStringAsFixed(1)} MB';
}

String _packSlug(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
