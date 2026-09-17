import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'work_supply_catalog_audit.dart';
import 'work_supply_catalog_pack_payload.dart';
import 'work_supply_models.dart';
import 'work_supply_trade_pack_delivery_policy.dart';
import 'work_supply_trade_pack_tiers.dart';

const workSupplyTradePackTargetChunkItemCount = 500;

class WorkSupplyTradePackManifest {
  const WorkSupplyTradePackManifest({
    required this.schemaVersion,
    required this.packId,
    required this.packVersion,
    required this.generatedAtIso,
    required this.tradeName,
    required this.marketScope,
    required this.tier,
    required this.localePackId,
    required this.countryCodes,
    required this.displayName,
    required this.itemCount,
    required this.chunkCount,
    required this.firestoreManifestReadCount,
    required this.firestoreItemDocumentReadCount,
    required this.estimatedUncompressedBytes,
    required this.estimatedCompressedBytes,
    required this.chunks,
  });

  final int schemaVersion;
  final String packId;
  final String packVersion;
  final String generatedAtIso;
  final String tradeName;
  final WorkSupplyMarketScope? marketScope;
  final WorkSupplyTradePackTier tier;
  final String localePackId;
  final List<String> countryCodes;
  final String displayName;
  final int itemCount;
  final int chunkCount;
  final int firestoreManifestReadCount;
  final int firestoreItemDocumentReadCount;
  final int estimatedUncompressedBytes;
  final int estimatedCompressedBytes;
  final List<WorkSupplyTradePackChunkManifest> chunks;

  bool get isFirestoreReadSafe =>
      firestoreManifestReadCount <= 2 && firestoreItemDocumentReadCount == 0;

  Map<String, Object?> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'packId': packId,
      'packVersion': packVersion,
      'generatedAtIso': generatedAtIso,
      'tradeName': tradeName,
      'marketScope': marketScope?.name,
      'marketScopeLabel': marketScope?.label,
      'tier': tier.id,
      'localePackId': localePackId,
      'countryCodes': countryCodes,
      'displayName': displayName,
      'itemCount': itemCount,
      'chunkCount': chunkCount,
      'firestoreManifestReadCount': firestoreManifestReadCount,
      'firestoreItemDocumentReadCount': firestoreItemDocumentReadCount,
      'estimatedUncompressedBytes': estimatedUncompressedBytes,
      'estimatedCompressedBytes': estimatedCompressedBytes,
      'deliveryMode': 'trade_pack_manifest_storage_chunks',
      'deliveryPolicy': workSupplyTradePackDeliveryPolicy.toMap(),
      'chunks': [for (final chunk in chunks) chunk.toMap()],
    };
  }
}

class WorkSupplyTradePackChunkManifest {
  const WorkSupplyTradePackChunkManifest({
    required this.chunkId,
    required this.itemCount,
    required this.storagePath,
    required this.contentEncoding,
    required this.uncompressedByteSize,
    required this.estimatedCompressedByteSize,
    required this.sha256,
  });

  final String chunkId;
  final int itemCount;
  final String storagePath;
  final String contentEncoding;
  final int uncompressedByteSize;
  final int estimatedCompressedByteSize;
  final String sha256;

  Map<String, Object?> toMap() {
    return {
      'chunkId': chunkId,
      'itemCount': itemCount,
      'storagePath': storagePath,
      'contentEncoding': contentEncoding,
      'uncompressedByteSize': uncompressedByteSize,
      'estimatedCompressedByteSize': estimatedCompressedByteSize,
      'sha256': sha256,
    };
  }
}

class WorkSupplyTradePackChunkPayload {
  const WorkSupplyTradePackChunkPayload({
    required this.manifest,
    required this.jsonBytes,
  });

  final WorkSupplyTradePackChunkManifest manifest;
  final List<int> jsonBytes;

  String get sha256Hex => sha256.convert(jsonBytes).toString();
}

WorkSupplyTradePackManifest buildWorkSupplyTradePackManifest(
  WorkSupplyTradePackOption option, {
  DateTime? generatedAt,
}) {
  final payloads = buildWorkSupplyTradePackChunkPayloads(option);
  return buildWorkSupplyTradePackManifestForPayloads(
    option,
    payloads,
    generatedAt: generatedAt,
  );
}

WorkSupplyTradePackManifest buildWorkSupplyTradePackManifestForPayloads(
  WorkSupplyTradePackOption option,
  List<WorkSupplyTradePackChunkPayload> payloads, {
  DateTime? generatedAt,
}) {
  return WorkSupplyTradePackManifest(
    schemaVersion: 1,
    packId: _packIdFor(option),
    packVersion: workSupplyCatalogPackVersion,
    generatedAtIso: (generatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    tradeName: option.tradeName,
    marketScope: option.marketScope,
    tier: option.tier,
    localePackId: option.localePackId,
    countryCodes: option.countryCodes,
    displayName: option.displayName,
    itemCount: payloads.fold(
      0,
      (sum, payload) => sum + payload.manifest.itemCount,
    ),
    chunkCount: payloads.length,
    firestoreManifestReadCount: 1,
    firestoreItemDocumentReadCount: 0,
    estimatedUncompressedBytes: payloads.fold(
      0,
      (sum, payload) => sum + payload.manifest.uncompressedByteSize,
    ),
    estimatedCompressedBytes: payloads.fold(
      0,
      (sum, payload) => sum + payload.manifest.estimatedCompressedByteSize,
    ),
    chunks: List.unmodifiable([
      for (final payload in payloads) payload.manifest,
    ]),
  );
}

List<WorkSupplyTradePackChunkPayload> buildWorkSupplyTradePackChunkPayloads(
  WorkSupplyTradePackOption option,
) {
  final items = buildWorkSupplyTradePackItems(
    option.tradeName,
    option.tier,
    marketScope: option.marketScope,
  );
  final payloads = <WorkSupplyTradePackChunkPayload>[];
  for (
    var start = 0;
    start < items.length;
    start += workSupplyTradePackTargetChunkItemCount
  ) {
    final end = (start + workSupplyTradePackTargetChunkItemCount).clamp(
      0,
      items.length,
    );
    final chunkItems = items.sublist(start, end);
    final chunkNumber = (start ~/ workSupplyTradePackTargetChunkItemCount) + 1;
    payloads.add(_chunkPayloadFor(option, chunkItems, chunkNumber));
  }
  return List.unmodifiable(payloads);
}

WorkSupplyTradePackChunkPayload _chunkPayloadFor(
  WorkSupplyTradePackOption option,
  List<WorkSupplyItem> items,
  int chunkNumber,
) {
  final payload = _chunkPayloadMap(option, items);
  final encoded = utf8.encode(jsonEncode(payload));
  final gzippedLength = gzip.encode(encoded).length;
  final tradeKey = workSupplyTradePackTradeKey(option.tradeName);
  final scopePath = option.marketScope == null
      ? ''
      : '/${option.marketScope!.id}';
  final scopeId = option.marketScope == null
      ? ''
      : '_${option.marketScope!.id}';
  final chunkId =
      '$tradeKey${scopeId}_${option.tier.id}_${chunkNumber.toString().padLeft(3, '0')}';
  return WorkSupplyTradePackChunkPayload(
    manifest: WorkSupplyTradePackChunkManifest(
      chunkId: chunkId,
      itemCount: items.length,
      storagePath:
          '$workSupplyCatalogStoragePrefix/$tradeKey$scopePath/${option.tier.id}/$chunkId.json.gz',
      contentEncoding: 'gzip',
      uncompressedByteSize: encoded.length,
      estimatedCompressedByteSize: gzippedLength,
      sha256: sha256.convert(encoded).toString(),
    ),
    jsonBytes: encoded,
  );
}

Map<String, Object?> _chunkPayloadMap(
  WorkSupplyTradePackOption option,
  List<WorkSupplyItem> items,
) {
  return {
    'schemaVersion': workSupplyCatalogPackSchemaVersion,
    'packId': _packIdFor(option),
    'packVersion': workSupplyCatalogPackVersion,
    'tradeName': option.tradeName,
    'marketScope': option.marketScope?.name,
    'marketScopeLabel': option.marketScope?.label,
    'tier': option.tier.id,
    'localePackId': option.localePackId,
    'countryCodes': option.countryCodes,
    'items': [
      for (final item in items)
        buildWorkSupplyCatalogPackItemPayload(item).toMap(),
    ],
  };
}

String _packIdFor(WorkSupplyTradePackOption option) {
  final scope = option.marketScope == null ? '' : '.${option.marketScope!.id}';
  return 'maintainiac.work-supplies.'
      '${workSupplyTradePackTradeKey(option.tradeName)}$scope.${option.tier.id}';
}
