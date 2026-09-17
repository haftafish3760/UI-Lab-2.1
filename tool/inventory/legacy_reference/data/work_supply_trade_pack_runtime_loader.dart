import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'work_supply_models.dart';
import 'work_supply_trade_pack_import_validator.dart';
import 'work_supply_trade_pack_manifest.dart';

enum WorkSupplyTradePackRuntimeLoadStatus {
  ready,
  validationFailed,
  decodeFailed,
  duplicateItemId,
}

class WorkSupplyTradePackRuntimeLoadResult {
  const WorkSupplyTradePackRuntimeLoadResult({
    required this.status,
    required this.items,
    required this.issues,
  });

  final WorkSupplyTradePackRuntimeLoadStatus status;
  final List<WorkSupplyItem> items;
  final List<String> issues;

  bool get isReady => status == WorkSupplyTradePackRuntimeLoadStatus.ready;
}

/// Decodes only a locally validated pack into data. Downloaded packs never
/// contain executable parser code; the compiled matcher remains the executor.
class WorkSupplyTradePackRuntimeLoader {
  const WorkSupplyTradePackRuntimeLoader({
    WorkSupplyTradePackImportValidator validator =
        const WorkSupplyTradePackImportValidator(),
  }) : _validator = validator;

  final WorkSupplyTradePackImportValidator _validator;

  Future<WorkSupplyTradePackRuntimeLoadResult> loadDirectory(
    Directory directory,
  ) async {
    final validation = await _validator.validateDirectory(directory);
    if (!validation.isReady) {
      return _result(
        WorkSupplyTradePackRuntimeLoadStatus.validationFailed,
        issues: validation.issues,
      );
    }
    try {
      final manifest = await _readManifest(directory);
      if (manifest == null) {
        return _result(
          WorkSupplyTradePackRuntimeLoadStatus.decodeFailed,
          issues: const ['Validated pack manifest could not be decoded.'],
        );
      }
      final items = <WorkSupplyItem>[];
      final ids = <String>{};
      for (final chunk in manifest.chunks) {
        final file = File('${directory.path}/${chunk.storagePath}');
        final bytes = gzip.decode(await file.readAsBytes());
        if (sha256.convert(bytes).toString() != chunk.sha256) {
          return _result(
            WorkSupplyTradePackRuntimeLoadStatus.decodeFailed,
            issues: ['Checksum changed after validation: ${chunk.chunkId}.'],
          );
        }
        final payload = jsonDecode(utf8.decode(bytes));
        if (payload is! Map || payload['items'] is! List) {
          return _result(
            WorkSupplyTradePackRuntimeLoadStatus.decodeFailed,
            issues: ['Unreadable item payload: ${chunk.chunkId}.'],
          );
        }
        for (final raw in payload['items'] as List) {
          if (raw is! Map) {
            return _result(
              WorkSupplyTradePackRuntimeLoadStatus.decodeFailed,
              issues: ['Pack item is not an object: ${chunk.chunkId}.'],
            );
          }
          final item = _itemFromMap(raw.cast<String, Object?>());
          if (item == null) {
            return _result(
              WorkSupplyTradePackRuntimeLoadStatus.decodeFailed,
              issues: ['Pack item is incomplete: ${chunk.chunkId}.'],
            );
          }
          if (!ids.add(item.id)) {
            return _result(
              WorkSupplyTradePackRuntimeLoadStatus.duplicateItemId,
              issues: ['Duplicate pack item ID: ${item.id}.'],
            );
          }
          items.add(item);
        }
      }
      if (items.length != manifest.itemCount) {
        return _result(
          WorkSupplyTradePackRuntimeLoadStatus.decodeFailed,
          issues: ['Runtime item count differs from manifest.'],
        );
      }
      return _result(WorkSupplyTradePackRuntimeLoadStatus.ready, items: items);
    } catch (_) {
      return _result(
        WorkSupplyTradePackRuntimeLoadStatus.decodeFailed,
        issues: const ['Validated pack could not be loaded into runtime data.'],
      );
    }
  }

  Future<WorkSupplyTradePackManifest?> _readManifest(
    Directory directory,
  ) async {
    final file = File('${directory.path}/manifest.json');
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return null;
    final chunks = <WorkSupplyTradePackChunkManifest>[];
    for (final raw in decoded['chunks'] as List? ?? const []) {
      if (raw is! Map) return null;
      chunks.add(
        WorkSupplyTradePackChunkManifest(
          chunkId: _string(raw['chunkId']),
          itemCount: _int(raw['itemCount']),
          storagePath: _string(raw['storagePath']),
          contentEncoding: _string(raw['contentEncoding']),
          uncompressedByteSize: _int(raw['uncompressedByteSize']),
          estimatedCompressedByteSize: _int(raw['estimatedCompressedByteSize']),
          sha256: _string(raw['sha256']),
        ),
      );
    }
    return WorkSupplyTradePackManifest(
      schemaVersion: _int(decoded['schemaVersion']),
      packId: _string(decoded['packId']),
      packVersion: _string(decoded['packVersion']),
      generatedAtIso: _string(decoded['generatedAtIso']),
      tradeName: _string(decoded['tradeName']),
      marketScope: _scope(decoded['marketScope']),
      tier: WorkSupplyTradePackTierExtension.fromId(_string(decoded['tier'])),
      localePackId: _string(decoded['localePackId']),
      countryCodes: _strings(decoded['countryCodes']),
      displayName: _string(decoded['displayName']),
      itemCount: _int(decoded['itemCount']),
      chunkCount: _int(decoded['chunkCount']),
      firestoreManifestReadCount: _int(decoded['firestoreManifestReadCount']),
      firestoreItemDocumentReadCount: _int(
        decoded['firestoreItemDocumentReadCount'],
      ),
      estimatedUncompressedBytes: _int(decoded['estimatedUncompressedBytes']),
      estimatedCompressedBytes: _int(decoded['estimatedCompressedBytes']),
      chunks: chunks,
    );
  }
}

WorkSupplyItem? _itemFromMap(Map<String, Object?> map) {
  final id = _string(map['id']);
  final name = _string(map['name']);
  final trade = _string(map['trade']);
  if (id.isEmpty || name.isEmpty || trade.isEmpty) return null;
  final intelligence = (map['intelligence'] as Map?)?.cast<String, Object?>();
  return WorkSupplyItem(
    id: id,
    name: name,
    trade: trade,
    category: _string(map['category']),
    system: _string(map['system']),
    itemType: _string(map['itemType']),
    variant: _string(map['variant']),
    unit: _string(map['unit']),
    aliases: _aliases(map),
    marketScopes: _scopes(map['marketScopes']),
    packTier: _packTier(_string(map['packTier'])),
    parserPriority: _priority(_string(map['parserPriority'])),
    intelligence: _intelligence(intelligence),
  );
}

WorkSupplyItemIntelligence _intelligence(Map<String, Object?>? map) {
  if (map == null) return WorkSupplyItemIntelligence.empty;
  final classification = (map['classification'] as Map?)
      ?.cast<String, Object?>();
  return WorkSupplyItemIntelligence(
    material: _string(map['material']),
    size: _string(map['size']),
    connectionType: _string(map['connectionType']),
    shapeOrStyle: _string(map['shapeOrStyle']),
    packQuantity: _string(map['packQuantity']),
    isConsumable: map['isConsumable'] == true,
    isDurable: map['isDurable'] == true,
    isBrandSpecific: map['isBrandSpecific'] == true,
    receiptPatterns: _strings(map['receiptPatterns']),
    ocrMistakePatterns: _strings(map['ocrMistakePatterns']),
    vendorMappings: _vendors(map['vendorMappings']),
    attributeTokens: _strings(map['attributeTokens']),
    negativeMatchTokens: _strings(map['negativeMatchTokens']),
    highImportanceTokens: _strings(map['highImportanceTokens']),
    mediumImportanceTokens: _strings(map['mediumImportanceTokens']),
    lowImportanceTokens: _strings(map['lowImportanceTokens']),
    ignoreTokens: _strings(map['ignoreTokens']),
    classification: WorkSupplyItemClassification(
      inventoryCategory: _string(classification?['inventoryCategory']),
      expenseCategory: _string(classification?['expenseCategory']),
      jobMaterialCategory: _string(classification?['jobMaterialCategory']),
      taxReportingCategory: _string(classification?['taxReportingCategory']),
      maintenanceRelevance: _string(classification?['maintenanceRelevance']),
      billableMaterial: classification?['billableMaterial'] != false,
      defaultUnitCostBehavior: _string(
        classification?['defaultUnitCostBehavior'],
      ),
      defaultMarkupBehavior: _string(classification?['defaultMarkupBehavior']),
    ),
    catalogVersion: _string(map['catalogVersion']),
    parserVersion: _string(map['parserVersion']),
    sourceConfidence: _string(map['sourceConfidence']),
    verifiedManually: map['verifiedManually'] == true,
    autoGenerated: map['autoGenerated'] == true,
    needsReview: map['needsReview'] == true,
  );
}

List<String> _aliases(Map<String, Object?> map) {
  final aliases = <String>{};
  for (final key in [
    'aliases',
    'merchantAliases',
    'barcodeAliases',
    'merchantSkuAliases',
  ]) {
    for (final raw in map[key] as List? ?? []) {
      if (raw is Map && _string(raw['value']).isNotEmpty) {
        aliases.add(_string(raw['value']));
      }
    }
  }
  return aliases.toList(growable: false);
}

List<WorkSupplyVendorMapping> _vendors(Object? value) => [
  for (final raw in value as List? ?? const [])
    if (raw is Map)
      WorkSupplyVendorMapping(
        vendor: _string(raw['vendor']),
        code: _string(raw['code']),
        label: _string(raw['label']),
      ),
];

List<WorkSupplyMarketScope> _scopes(Object? value) {
  final scopes = [
    for (final name in _strings(value))
      for (final scope in WorkSupplyMarketScope.values)
        if (scope.name == name) scope,
  ];
  return scopes.isEmpty ? WorkSupplyMarketScopes.all : scopes;
}

WorkSupplyMarketScope? _scope(Object? value) {
  final name = _string(value);
  for (final scope in WorkSupplyMarketScope.values) {
    if (scope.name == name) return scope;
  }
  return null;
}

WorkSupplyPackTier _packTier(String name) => switch (name) {
  'standard' => WorkSupplyPackTier.standard,
  'professional' => WorkSupplyPackTier.professional,
  'complete' => WorkSupplyPackTier.complete,
  _ => WorkSupplyPackTier.core,
};

WorkSupplyParserPriority _priority(String name) {
  for (final value in WorkSupplyParserPriority.values) {
    if (value.name == name) return value;
  }
  return WorkSupplyParserPriority.common;
}

WorkSupplyTradePackRuntimeLoadResult _result(
  WorkSupplyTradePackRuntimeLoadStatus status, {
  List<WorkSupplyItem> items = const [],
  List<String> issues = const [],
}) => WorkSupplyTradePackRuntimeLoadResult(
  status: status,
  items: List.unmodifiable(items),
  issues: List.unmodifiable(issues),
);

String _string(Object? value) => value is String ? value : '';
int _int(Object? value) => value is num ? value.toInt() : 0;
List<String> _strings(Object? value) => [
  for (final entry in value as List? ?? const [])
    if (entry is String) entry,
];
