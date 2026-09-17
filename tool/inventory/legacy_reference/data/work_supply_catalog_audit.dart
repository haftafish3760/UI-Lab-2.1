import 'dart:convert';

import 'work_supply_catalog.dart';
import 'work_supply_models.dart';

part 'work_supply_catalog_audit_intelligence.dart';

const workSupplyCatalogPackVersion = '2026.06.local-starter';
const workSupplyCatalogPackId = 'maintainiac.work-supplies.local-starter';
const workSupplyCatalogManifestDocumentPath =
    'catalogPacks/$workSupplyCatalogPackId/manifests/$workSupplyCatalogPackVersion';
const workSupplyCatalogStoragePrefix =
    'catalog-packs/work-supplies/$workSupplyCatalogPackVersion';
const workSupplyCatalogTargetChunkItemCount = 500;
const workSupplyCatalogMaxChunkItemCount = 750;
const workSupplyCatalogMaxCompressedChunkBytes = 384 * 1024;

class WorkSupplyCatalogAuditSummary {
  const WorkSupplyCatalogAuditSummary({
    required this.packReadiness,
    required this.deliveryPlan,
    required this.itemCount,
    required this.tradeCount,
    required this.invalidIdCount,
    required this.duplicateIdCount,
    required this.incompleteItemCount,
    required this.weakSearchTextCount,
    required this.itemsWithMarketScopes,
    required this.itemsWithPackTier,
    required this.itemsWithParserPriority,
    required this.itemsWithSmartIntelligence,
    required this.tradeCoverage,
  });

  final WorkSupplyCatalogPackReadiness packReadiness;
  final WorkSupplyCatalogDeliveryPlan deliveryPlan;
  final int itemCount;
  final int tradeCount;
  final int invalidIdCount;
  final int duplicateIdCount;
  final int incompleteItemCount;
  final int weakSearchTextCount;
  final int itemsWithMarketScopes;
  final int itemsWithPackTier;
  final int itemsWithParserPriority;
  final int itemsWithSmartIntelligence;
  final List<WorkSupplyCatalogTradeCoverage> tradeCoverage;

  double get marketScopeCoverage =>
      itemCount == 0 ? 0 : itemsWithMarketScopes / itemCount;
  double get packTierCoverage =>
      itemCount == 0 ? 0 : itemsWithPackTier / itemCount;
  double get parserPriorityCoverage =>
      itemCount == 0 ? 0 : itemsWithParserPriority / itemCount;
  double get smartIntelligenceCoverage =>
      itemCount == 0 ? 0 : itemsWithSmartIntelligence / itemCount;

  bool get passesCoreIntegrity =>
      invalidIdCount == 0 &&
      duplicateIdCount == 0 &&
      incompleteItemCount == 0 &&
      weakSearchTextCount == 0 &&
      deliveryPlan.isFirestoreReadSafe &&
      deliveryPlan.hasValidChunkPlan;

  List<WorkSupplyCatalogTradeCoverage> get weakestTrades {
    final sorted = [...tradeCoverage]
      ..sort((a, b) {
        final strength = a.parserReadinessScore.compareTo(
          b.parserReadinessScore,
        );
        if (strength != 0) return strength;
        return a.itemCount.compareTo(b.itemCount);
      });
    return sorted.take(4).toList(growable: false);
  }
}

class WorkSupplyCatalogDeliveryPlan {
  const WorkSupplyCatalogDeliveryPlan({
    required this.packId,
    required this.packVersion,
    required this.manifestDocumentPath,
    required this.storagePrefix,
    required this.chunkCount,
    required this.firestoreManifestReadCount,
    required this.firestoreItemDocumentReadCount,
    required this.estimatedUncompressedBytes,
    required this.estimatedCompressedBytes,
    required this.chunks,
  });

  final String packId;
  final String packVersion;
  final String manifestDocumentPath;
  final String storagePrefix;
  final int chunkCount;
  final int firestoreManifestReadCount;
  final int firestoreItemDocumentReadCount;
  final int estimatedUncompressedBytes;
  final int estimatedCompressedBytes;
  final List<WorkSupplyCatalogChunkPlan> chunks;

  bool get isFirestoreReadSafe =>
      firestoreManifestReadCount <= 2 && firestoreItemDocumentReadCount == 0;
  bool get hasValidChunkPlan =>
      chunks.isNotEmpty &&
      chunks.every(
        (chunk) =>
            chunk.itemCount > 0 &&
            chunk.itemCount <= workSupplyCatalogMaxChunkItemCount &&
            chunk.estimatedCompressedBytes <=
                workSupplyCatalogMaxCompressedChunkBytes &&
            chunk.storagePath.startsWith(storagePrefix),
      );

  String get deliveryModeLabel =>
      isFirestoreReadSafe ? 'Manifest + Storage chunks' : 'Too many reads';

  String get estimatedCompressedSizeLabel =>
      _byteSizeLabel(estimatedCompressedBytes);
}

class WorkSupplyCatalogChunkPlan {
  const WorkSupplyCatalogChunkPlan({
    required this.chunkId,
    required this.tradeName,
    required this.itemCount,
    required this.estimatedUncompressedBytes,
    required this.estimatedCompressedBytes,
    required this.storagePath,
  });

  final String chunkId;
  final String tradeName;
  final int itemCount;
  final int estimatedUncompressedBytes;
  final int estimatedCompressedBytes;
  final String storagePath;
}

class WorkSupplyCatalogPackReadiness {
  const WorkSupplyCatalogPackReadiness({
    required this.packId,
    required this.packVersion,
    required this.itemCount,
    required this.tradeCount,
    required this.estimatedPackedBytes,
    required this.parserTermCount,
    required this.itemsWithParserTerms,
    required this.hasStableAppIds,
  });

  final String packId;
  final String packVersion;
  final int itemCount;
  final int tradeCount;
  final int estimatedPackedBytes;
  final int parserTermCount;
  final int itemsWithParserTerms;
  final bool hasStableAppIds;

  double get parserTermCoverage =>
      itemCount == 0 ? 0 : itemsWithParserTerms / itemCount;
  double get averageParserTermsPerItem =>
      itemCount == 0 ? 0 : parserTermCount / itemCount;
  bool get downloadablePackRecommended =>
      estimatedPackedBytes > 5 * 1024 * 1024;

  String get estimatedPackSizeLabel {
    if (estimatedPackedBytes < 1024) return '$estimatedPackedBytes B';
    final kib = estimatedPackedBytes / 1024;
    if (kib < 1024) return '${kib.toStringAsFixed(1)} KB';
    return '${(kib / 1024).toStringAsFixed(1)} MB';
  }

  String get parserReadinessLabel {
    if (!hasStableAppIds) return 'Fix IDs';
    if (parserTermCoverage >= .95 && averageParserTermsPerItem >= 6) {
      return 'Parser ready';
    }
    if (parserTermCoverage >= .75) return 'Needs parser aliases';
    return 'Needs buildout';
  }
}

class WorkSupplyCatalogTradeCoverage {
  const WorkSupplyCatalogTradeCoverage({
    required this.tradeName,
    required this.itemCount,
    required this.categoryCount,
    required this.systemCount,
    required this.itemTypeCount,
    required this.aliasCount,
    required this.parserTermCount,
    required this.itemsWithAliases,
  });

  final String tradeName;
  final int itemCount;
  final int categoryCount;
  final int systemCount;
  final int itemTypeCount;
  final int aliasCount;
  final int parserTermCount;
  final int itemsWithAliases;

  double get aliasCoverage => itemCount == 0 ? 0 : itemsWithAliases / itemCount;
  double get parserReadinessScore {
    final scaleScore = (itemCount / 500).clamp(0, 1).toDouble();
    return ((aliasCoverage * .65) + (scaleScore * .35)).clamp(0, 1).toDouble();
  }

  String get parserReadinessLabel {
    final score = parserReadinessScore;
    if (score >= .75) return 'Strong';
    if (score >= .45) return 'Needs aliases';
    return 'Needs buildout';
  }
}

WorkSupplyCatalogAuditSummary auditWorkSupplyCatalog({
  Iterable<WorkSupplyItem>? items,
}) {
  final catalogItems = (items ?? workSupplyCatalogItems).toList();
  final ids = <String>{};
  final parserTermItems = <String>{};
  var invalidIds = 0;
  var duplicateIds = 0;
  var incomplete = 0;
  var weakSearchText = 0;
  var itemsWithMarketScopes = 0;
  var itemsWithPackTier = 0;
  var itemsWithParserPriority = 0;
  var itemsWithSmartIntelligence = 0;
  var parserTermCount = 0;
  final tradeItems = <String, List<WorkSupplyItem>>{};

  for (final item in catalogItems) {
    if (!RegExp(r'^MI-\d{3,}$').hasMatch(item.id)) invalidIds++;
    if (!ids.add(item.id)) duplicateIds++;
    if (_missingCoreFields(item)) incomplete++;
    if (_hasWeakSearchText(item)) weakSearchText++;
    if (item.marketScopes.isNotEmpty) itemsWithMarketScopes++;
    itemsWithPackTier++;
    itemsWithParserPriority++;
    if (_hasSmartIntelligence(item)) itemsWithSmartIntelligence++;
    final parserTerms = _parserTermsFor(item);
    parserTermCount += parserTerms.length;
    if (parserTerms.isNotEmpty) parserTermItems.add(item.id);
    tradeItems.putIfAbsent(item.trade, () => []).add(item);
  }

  return WorkSupplyCatalogAuditSummary(
    packReadiness: WorkSupplyCatalogPackReadiness(
      packId: workSupplyCatalogPackId,
      packVersion: workSupplyCatalogPackVersion,
      itemCount: catalogItems.length,
      tradeCount: workSupplyTrades.length,
      estimatedPackedBytes: _estimatedPackedBytes(catalogItems),
      parserTermCount: parserTermCount,
      itemsWithParserTerms: parserTermItems.length,
      hasStableAppIds: invalidIds == 0 && duplicateIds == 0,
    ),
    deliveryPlan: _deliveryPlanFor(catalogItems, tradeItems),
    itemCount: catalogItems.length,
    tradeCount: workSupplyTrades.length,
    invalidIdCount: invalidIds,
    duplicateIdCount: duplicateIds,
    incompleteItemCount: incomplete,
    weakSearchTextCount: weakSearchText,
    itemsWithMarketScopes: itemsWithMarketScopes,
    itemsWithPackTier: itemsWithPackTier,
    itemsWithParserPriority: itemsWithParserPriority,
    itemsWithSmartIntelligence: itemsWithSmartIntelligence,
    tradeCoverage: _tradeCoverage(tradeItems),
  );
}

WorkSupplyCatalogDeliveryPlan _deliveryPlanFor(
  List<WorkSupplyItem> catalogItems,
  Map<String, List<WorkSupplyItem>> tradeItems,
) {
  final chunks = <WorkSupplyCatalogChunkPlan>[];
  for (final trade in workSupplyTrades) {
    final items = tradeItems[trade.name] ?? const <WorkSupplyItem>[];
    if (items.isEmpty) continue;
    for (
      var start = 0;
      start < items.length;
      start += workSupplyCatalogTargetChunkItemCount
    ) {
      final end = (start + workSupplyCatalogTargetChunkItemCount).clamp(
        0,
        items.length,
      );
      final chunkItems = items.sublist(start, end);
      final chunkNumber = (start ~/ workSupplyCatalogTargetChunkItemCount) + 1;
      final chunkId =
          '${_packSlug(trade.name)}_${chunkNumber.toString().padLeft(3, '0')}';
      final uncompressedBytes = _estimatedPackedBytes(chunkItems);
      chunks.add(
        WorkSupplyCatalogChunkPlan(
          chunkId: chunkId,
          tradeName: trade.name,
          itemCount: chunkItems.length,
          estimatedUncompressedBytes: uncompressedBytes,
          estimatedCompressedBytes: _estimatedCompressedBytes(
            uncompressedBytes,
          ),
          storagePath:
              '$workSupplyCatalogStoragePrefix/${_packSlug(trade.name)}/$chunkId.json.gz',
        ),
      );
    }
  }

  final uncompressedBytes = _estimatedPackedBytes(catalogItems);
  return WorkSupplyCatalogDeliveryPlan(
    packId: workSupplyCatalogPackId,
    packVersion: workSupplyCatalogPackVersion,
    manifestDocumentPath: workSupplyCatalogManifestDocumentPath,
    storagePrefix: workSupplyCatalogStoragePrefix,
    chunkCount: chunks.length,
    firestoreManifestReadCount: 1,
    firestoreItemDocumentReadCount: 0,
    estimatedUncompressedBytes: uncompressedBytes,
    estimatedCompressedBytes: _estimatedCompressedBytes(uncompressedBytes),
    chunks: List.unmodifiable(chunks),
  );
}

List<WorkSupplyCatalogTradeCoverage> _tradeCoverage(
  Map<String, List<WorkSupplyItem>> tradeItems,
) {
  final coverage = <WorkSupplyCatalogTradeCoverage>[];
  for (final trade in workSupplyTrades) {
    final items = tradeItems[trade.name] ?? const <WorkSupplyItem>[];
    final parserTermCount = items.fold<int>(
      0,
      (sum, item) => sum + _parserTermsFor(item).length,
    );
    final systems = <String>{
      for (final category in trade.categories)
        for (final system in category.systems) system.name,
    };
    final itemTypes = <String>{
      for (final category in trade.categories)
        for (final system in category.systems)
          for (final type in system.itemTypes) type.name,
    };
    coverage.add(
      WorkSupplyCatalogTradeCoverage(
        tradeName: trade.name,
        itemCount: items.length,
        categoryCount: trade.categories.length,
        systemCount: systems.length,
        itemTypeCount: itemTypes.length,
        aliasCount: items.fold<int>(
          0,
          (sum, item) => sum + item.aliases.length,
        ),
        parserTermCount: parserTermCount,
        itemsWithAliases: items.where((item) => item.aliases.isNotEmpty).length,
      ),
    );
  }
  return coverage;
}

bool _missingCoreFields(WorkSupplyItem item) {
  return item.id.trim().isEmpty ||
      item.name.trim().isEmpty ||
      item.trade.trim().isEmpty ||
      item.category.trim().isEmpty ||
      item.system.trim().isEmpty ||
      item.itemType.trim().isEmpty ||
      item.variant.trim().isEmpty ||
      item.unit.trim().isEmpty;
}

bool _hasWeakSearchText(WorkSupplyItem item) {
  final searchable = item.searchableText.trim();
  final tokens = searchable
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.trim().isNotEmpty)
      .toSet();
  return tokens.length < 5 || !searchable.contains(item.name.toLowerCase());
}

Set<String> _parserTermsFor(WorkSupplyItem item) {
  return [
        item.name,
        item.category,
        item.system,
        item.itemType,
        item.variant,
        item.unit,
        ...item.aliases,
        ...item.intelligence.searchableTokens,
      ]
      .join(' ')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.length >= 2 && !_ignoredParserTerm(token))
      .toSet();
}

bool _ignoredParserTerm(String token) {
  return switch (token) {
    'a' || 'an' || 'and' || 'the' || 'for' || 'with' || 'x' => true,
    _ => false,
  };
}

int _estimatedPackedBytes(List<WorkSupplyItem> items) {
  var bytes = utf8
      .encode('$workSupplyCatalogPackId:$workSupplyCatalogPackVersion')
      .length;
  for (final item in items) {
    bytes += utf8
        .encode(
          [
            item.id,
            item.name,
            item.trade,
            item.category,
            item.system,
            item.itemType,
            item.variant,
            item.unit,
            ...item.marketScopes.map((scope) => scope.name),
            item.packTier.name,
            item.parserPriority.name,
            ...item.aliases,
            ...item.intelligence.searchableTokens,
          ].join('|'),
        )
        .length;
  }
  return bytes;
}

int _estimatedCompressedBytes(int uncompressedBytes) {
  if (uncompressedBytes <= 0) return 0;
  return (uncompressedBytes * .38).ceil();
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
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
