import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'work_supply_catalog_pack_payload.dart';
import 'work_supply_models.dart';
import 'work_supply_trade_pack_manifest.dart';
import 'work_supply_trade_pack_tiers.dart';

enum WorkSupplyTradePackValidationStatus {
  ready,
  missingManifest,
  invalidManifest,
  unsafeFirestoreShape,
  missingChunk,
  invalidChunkPath,
  unreadableChunk,
  checksumMismatch,
  itemCountMismatch,
  invalidPayloadSchema,
  missingParserMetadata,
  packScopeMismatch,
}

class WorkSupplyTradePackValidationResult {
  const WorkSupplyTradePackValidationResult({
    required this.status,
    required this.checkedChunkCount,
    required this.checkedItemCount,
    required this.issues,
  });

  final WorkSupplyTradePackValidationStatus status;
  final int checkedChunkCount;
  final int checkedItemCount;
  final List<String> issues;

  bool get isReady => status == WorkSupplyTradePackValidationStatus.ready;
}

class WorkSupplyTradePackImportValidator {
  const WorkSupplyTradePackImportValidator();

  Future<WorkSupplyTradePackValidationResult> validateDirectory(
    Directory directory,
  ) async {
    final manifest = await _readManifest(directory);
    if (manifest == null) {
      return _result(WorkSupplyTradePackValidationStatus.missingManifest, [
        'manifest.json is missing or could not be parsed.',
      ]);
    }
    final manifestIssues = _manifestIssues(manifest);
    if (manifestIssues.isNotEmpty) {
      return _result(
        WorkSupplyTradePackValidationStatus.unsafeFirestoreShape,
        manifestIssues,
      );
    }

    var checkedChunks = 0;
    var checkedItems = 0;
    for (final chunk in manifest.chunks) {
      final pathIssue = _chunkPathIssue(chunk);
      if (pathIssue != null) {
        return _result(
          WorkSupplyTradePackValidationStatus.invalidChunkPath,
          [pathIssue],
          chunks: checkedChunks,
          items: checkedItems,
        );
      }
      final chunkFile = File('${directory.path}/${chunk.storagePath}');
      if (!await chunkFile.exists()) {
        return _result(
          WorkSupplyTradePackValidationStatus.missingChunk,
          ['Chunk file is missing: ${chunk.storagePath}.'],
          chunks: checkedChunks,
          items: checkedItems,
        );
      }
      final payload = await _readChunkPayload(chunkFile, chunk);
      if (payload.status != null) {
        return _result(
          payload.status!,
          payload.issues,
          chunks: checkedChunks,
          items: checkedItems,
        );
      }
      final items = payload.payload!['items'];
      if (items is! List || items.length != chunk.itemCount) {
        return _result(
          WorkSupplyTradePackValidationStatus.itemCountMismatch,
          ['Item count mismatch: ${chunk.chunkId}.'],
          chunks: checkedChunks,
          items: checkedItems,
        );
      }
      final parserIssue = _parserMetadataIssue(items);
      if (parserIssue != null) {
        return _result(
          WorkSupplyTradePackValidationStatus.missingParserMetadata,
          [parserIssue],
          chunks: checkedChunks,
          items: checkedItems,
        );
      }
      final scopeIssue = _packScopeIssue(items, manifest);
      if (scopeIssue != null) {
        return _result(
          WorkSupplyTradePackValidationStatus.packScopeMismatch,
          [scopeIssue],
          chunks: checkedChunks,
          items: checkedItems,
        );
      }
      checkedChunks++;
      checkedItems += items.length;
    }

    if (checkedChunks != manifest.chunkCount ||
        checkedItems != manifest.itemCount) {
      return _result(
        WorkSupplyTradePackValidationStatus.itemCountMismatch,
        ['Manifest totals do not match checked chunk totals.'],
        chunks: checkedChunks,
        items: checkedItems,
      );
    }
    return _result(
      WorkSupplyTradePackValidationStatus.ready,
      const [],
      chunks: checkedChunks,
      items: checkedItems,
    );
  }

  Future<WorkSupplyTradePackManifest?> _readManifest(
    Directory directory,
  ) async {
    final file = File('${directory.path}/manifest.json');
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString()) as Map;
      final chunks = (decoded['chunks'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (chunk) => WorkSupplyTradePackChunkManifest(
              chunkId: _string(chunk['chunkId']),
              itemCount: _int(chunk['itemCount']),
              storagePath: _string(chunk['storagePath']),
              contentEncoding: _string(chunk['contentEncoding']),
              uncompressedByteSize: _int(chunk['uncompressedByteSize']),
              estimatedCompressedByteSize: _int(
                chunk['estimatedCompressedByteSize'],
              ),
              sha256: _string(chunk['sha256']),
            ),
          )
          .toList(growable: false);
      return WorkSupplyTradePackManifest(
        schemaVersion: _int(decoded['schemaVersion']),
        packId: _string(decoded['packId']),
        packVersion: _string(decoded['packVersion']),
        generatedAtIso: _string(decoded['generatedAtIso']),
        tradeName: _string(decoded['tradeName']),
        marketScope: _marketScopeFromManifest(decoded['marketScope']),
        tier: WorkSupplyTradePackTierExtension.fromId(_string(decoded['tier'])),
        localePackId: _string(decoded['localePackId']),
        countryCodes: _stringList(decoded['countryCodes']),
        displayName: _string(decoded['displayName']),
        itemCount: _int(decoded['itemCount']),
        chunkCount: _int(decoded['chunkCount']),
        firestoreManifestReadCount: _int(decoded['firestoreManifestReadCount']),
        firestoreItemDocumentReadCount: _int(
          decoded['firestoreItemDocumentReadCount'],
        ),
        estimatedUncompressedBytes:
            _int(decoded['estimatedUncompressedBytes']) > 0
            ? _int(decoded['estimatedUncompressedBytes'])
            : chunks.fold(0, (sum, chunk) => sum + chunk.uncompressedByteSize),
        estimatedCompressedBytes: _int(decoded['estimatedCompressedBytes']),
        chunks: chunks,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _manifestIssues(WorkSupplyTradePackManifest manifest) {
    final issues = <String>[];
    if (manifest.schemaVersion != 1) issues.add('Unsupported manifest schema.');
    if (manifest.packId.trim().isEmpty) issues.add('Pack ID is missing.');
    if (!manifest.isFirestoreReadSafe) {
      issues.add('Manifest would require per-item Firestore reads.');
    }
    if (manifest.chunkCount <= 0 ||
        manifest.chunks.length != manifest.chunkCount) {
      issues.add('Manifest chunk count is invalid.');
    }
    return issues;
  }

  String? _chunkPathIssue(WorkSupplyTradePackChunkManifest chunk) {
    if (chunk.storagePath.contains('..') ||
        chunk.storagePath.startsWith('/') ||
        chunk.storagePath.startsWith(r'\')) {
      return 'Chunk path is unsafe: ${chunk.storagePath}.';
    }
    if (!chunk.storagePath.endsWith('.json.gz')) {
      return 'Chunk path must end in .json.gz: ${chunk.storagePath}.';
    }
    if (chunk.contentEncoding != 'gzip') {
      return 'Chunk encoding must be gzip: ${chunk.chunkId}.';
    }
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(chunk.sha256)) {
      return 'Chunk checksum is invalid: ${chunk.chunkId}.';
    }
    return null;
  }

  Future<_ChunkReadResult> _readChunkPayload(
    File file,
    WorkSupplyTradePackChunkManifest chunk,
  ) async {
    try {
      final jsonBytes = gzip.decode(await file.readAsBytes());
      if (sha256.convert(jsonBytes).toString() != chunk.sha256) {
        return _ChunkReadResult.issue(
          WorkSupplyTradePackValidationStatus.checksumMismatch,
          ['Checksum mismatch: ${chunk.chunkId}.'],
        );
      }
      final payload =
          jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
      if (payload['schemaVersion'] != workSupplyCatalogPackSchemaVersion) {
        return _ChunkReadResult.issue(
          WorkSupplyTradePackValidationStatus.invalidPayloadSchema,
          ['Unsupported payload schema: ${chunk.chunkId}.'],
        );
      }
      return _ChunkReadResult.payload(payload);
    } catch (_) {
      return _ChunkReadResult.issue(
        WorkSupplyTradePackValidationStatus.unreadableChunk,
        ['Chunk could not be decoded: ${chunk.chunkId}.'],
      );
    }
  }

  String? _parserMetadataIssue(List<dynamic> items) {
    for (final rawItem in items) {
      if (rawItem is! Map) return 'Pack item is not an object.';
      if (_string(rawItem['canonicalKey']).isEmpty) {
        return 'Pack item is missing canonicalKey.';
      }
      if (rawItem['searchTerms'] is! List ||
          (rawItem['searchTerms'] as List).isEmpty) {
        return 'Pack item is missing searchTerms.';
      }
      if (rawItem['aliases'] is! List || (rawItem['aliases'] as List).isEmpty) {
        return 'Pack item is missing normalized aliases.';
      }
    }
    return null;
  }

  String? _packScopeIssue(
    List<dynamic> items,
    WorkSupplyTradePackManifest manifest,
  ) {
    final expectedTrade = manifest.tradeName.trim().toLowerCase();
    for (final rawItem in items) {
      if (rawItem is! Map) continue;
      final itemTrade = _string(rawItem['trade']).trim().toLowerCase();
      if (expectedTrade != workSupplyFullTradesCatalogName.toLowerCase() &&
          itemTrade != expectedTrade) {
        return 'Pack item trade does not match manifest: $itemTrade.';
      }
      final itemTier = _string(rawItem['packTier']).trim().toLowerCase();
      if (!_isTierAllowedInPack(itemTier, manifest.tier)) {
        return 'Pack item tier exceeds manifest tier: $itemTier.';
      }
    }
    return null;
  }

  bool _isTierAllowedInPack(String itemTier, WorkSupplyTradePackTier packTier) {
    return switch (packTier) {
      WorkSupplyTradePackTier.core => itemTier == 'core',
      WorkSupplyTradePackTier.expanded =>
        itemTier == 'core' || itemTier == 'standard',
      WorkSupplyTradePackTier.professional =>
        itemTier == 'core' ||
            itemTier == 'standard' ||
            itemTier == 'professional',
      WorkSupplyTradePackTier.full =>
        itemTier == 'core' ||
            itemTier == 'standard' ||
            itemTier == 'professional' ||
            itemTier == 'complete',
    };
  }

  WorkSupplyTradePackValidationResult _result(
    WorkSupplyTradePackValidationStatus status,
    List<String> issues, {
    int chunks = 0,
    int items = 0,
  }) {
    return WorkSupplyTradePackValidationResult(
      status: status,
      checkedChunkCount: chunks,
      checkedItemCount: items,
      issues: List.unmodifiable(issues),
    );
  }
}

class _ChunkReadResult {
  const _ChunkReadResult({this.payload, this.status, this.issues = const []});

  final Map<String, dynamic>? payload;
  final WorkSupplyTradePackValidationStatus? status;
  final List<String> issues;

  factory _ChunkReadResult.payload(Map<String, dynamic> payload) {
    return _ChunkReadResult(payload: payload);
  }

  factory _ChunkReadResult.issue(
    WorkSupplyTradePackValidationStatus status,
    List<String> issues,
  ) {
    return _ChunkReadResult(status: status, issues: issues);
  }
}

extension WorkSupplyTradePackTierExtension on WorkSupplyTradePackTier {
  static WorkSupplyTradePackTier fromId(String id) {
    if (id == 'expanded') return WorkSupplyTradePackTier.expanded;
    if (id == 'full') return WorkSupplyTradePackTier.full;
    for (final tier in WorkSupplyTradePackTier.values) {
      if (tier.id == id) return tier;
    }
    return WorkSupplyTradePackTier.full;
  }
}

WorkSupplyMarketScope? _marketScopeFromManifest(Object? value) {
  final raw = _string(value);
  if (raw.isEmpty) return null;
  for (final scope in WorkSupplyMarketScope.values) {
    if (scope.name == raw || scope.id == raw) return scope;
  }
  return null;
}

String _string(Object? value) => value is String ? value : '';

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry is String && entry.trim().isNotEmpty) entry,
  ];
}
