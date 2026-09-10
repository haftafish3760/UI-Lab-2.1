import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'domain_snapshot_store.dart';

typedef DualSlotSnapshotWriter =
    Future<void> Function(File target, List<int> bytes);

typedef DualSlotPayloadEncoder<T> = Map<String, Object?> Function(T value);
typedef DualSlotPayloadDecoder<T> = T Function(Map<String, Object?> payload);

/// Small, domain-neutral, checksummed local snapshot store.
///
/// Business repositories retain their own validation, authorization, audit,
/// and mutation rules. This class owns only the two-slot write/recovery
/// mechanics so every offline module does not grow a private copy.
class DualSlotJsonStore<T> implements DomainSnapshotStore<T> {
  DualSlotJsonStore._({
    required this._directory,
    required this._fileStem,
    required this._schemaVersion,
    required this._encodePayload,
    required this._decodePayload,
    required this._snapshotWriter,
    required this.value,
    required this._generation,
    required this._activeSlot,
    required this.recoveredFromDamagedSnapshot,
  });

  final Directory _directory;
  final String _fileStem;
  final int _schemaVersion;
  final DualSlotPayloadEncoder<T> _encodePayload;
  final DualSlotPayloadDecoder<T> _decodePayload;
  final DualSlotSnapshotWriter _snapshotWriter;

  @override
  T value;
  int _generation;
  int _activeSlot;
  @override
  final bool recoveredFromDamagedSnapshot;

  static Future<DualSlotJsonStore<T>> open<T>({
    required Directory directory,
    required String fileStem,
    required int schemaVersion,
    required T emptyValue,
    required DualSlotPayloadEncoder<T> encodePayload,
    required DualSlotPayloadDecoder<T> decodePayload,
    DualSlotSnapshotWriter? snapshotWriter,
  }) async {
    if (fileStem.trim().isEmpty) {
      throw ArgumentError.value(fileStem, 'fileStem', 'Cannot be empty.');
    }
    if (schemaVersion < 1) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'Must be positive.',
      );
    }
    await directory.create(recursive: true);
    final snapshots = <_DecodedSnapshot<T>>[];
    var sawStoredData = false;
    var invalidSnapshotCount = 0;
    for (var slot = 0; slot < 2; slot++) {
      final file = _slotFile(directory, fileStem, slot);
      if (!await file.exists()) continue;
      sawStoredData = true;
      try {
        snapshots.add(
          await _readSnapshot(
            file: file,
            slot: slot,
            schemaVersion: schemaVersion,
            decodePayload: decodePayload,
          ),
        );
      } on Object {
        invalidSnapshotCount += 1;
      }
    }
    if (sawStoredData && snapshots.isEmpty) {
      throw const DualSlotSnapshotCorruptionException(
        'No valid local snapshot could be recovered.',
      );
    }
    snapshots.sort((a, b) => b.generation.compareTo(a.generation));
    final active = snapshots.firstOrNull;
    return DualSlotJsonStore<T>._(
      directory: directory,
      fileStem: fileStem,
      schemaVersion: schemaVersion,
      encodePayload: encodePayload,
      decodePayload: decodePayload,
      snapshotWriter: snapshotWriter ?? _writeFileAndFlush,
      value: active?.value ?? emptyValue,
      generation: active?.generation ?? 0,
      activeSlot: active?.slot ?? 1,
      recoveredFromDamagedSnapshot:
          invalidSnapshotCount > 0 && snapshots.isNotEmpty,
    );
  }

  @override
  Future<void> persist(T next) async {
    final nextGeneration = _generation + 1;
    final nextSlot = _activeSlot == 0 ? 1 : 0;
    final target = _slotFile(_directory, _fileStem, nextSlot);
    final temporary = File('${target.path}.tmp');
    final bytes = _encodeSnapshot(
      schemaVersion: _schemaVersion,
      generation: nextGeneration,
      domainPayload: _encodePayload(next),
    );
    try {
      await _snapshotWriter(temporary, bytes);
      await _readSnapshot<T>(
        file: temporary,
        slot: nextSlot,
        schemaVersion: _schemaVersion,
        decodePayload: _decodePayload,
      );
      if (await target.exists()) await target.delete();
      await temporary.rename(target.path);
    } on Object catch (error) {
      if (await temporary.exists()) {
        try {
          await temporary.delete();
        } on Object {
          // A stale temporary file is ignored during the next open.
        }
      }
      throw DualSlotSnapshotWriteException(
        'The local snapshot was not saved. Existing data remains available. '
        '($error)',
      );
    }
    value = next;
    _generation = nextGeneration;
    _activeSlot = nextSlot;
  }
}

class _DecodedSnapshot<T> {
  const _DecodedSnapshot({
    required this.slot,
    required this.generation,
    required this.value,
  });

  final int slot;
  final int generation;
  final T value;
}

List<int> _encodeSnapshot({
  required int schemaVersion,
  required int generation,
  required Map<String, Object?> domainPayload,
}) {
  if (domainPayload.containsKey('schemaVersion') ||
      domainPayload.containsKey('generation')) {
    throw const DualSlotSnapshotWriteException(
      'Domain payload cannot replace snapshot metadata.',
    );
  }
  final payload = <String, Object?>{
    'schemaVersion': schemaVersion,
    'generation': generation,
    ...domainPayload,
  };
  final payloadText = jsonEncode(payload);
  return utf8.encode(
    jsonEncode({
      'checksum': sha256.convert(utf8.encode(payloadText)).toString(),
      'payload': payload,
    }),
  );
}

Future<_DecodedSnapshot<T>> _readSnapshot<T>({
  required File file,
  required int slot,
  required int schemaVersion,
  required DualSlotPayloadDecoder<T> decodePayload,
}) async {
  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) throw const FormatException('Invalid envelope.');
    final envelope = decoded.cast<String, Object?>();
    final payloadValue = envelope['payload'];
    if (payloadValue is! Map) throw const FormatException('Invalid payload.');
    final payload = payloadValue.cast<String, Object?>();
    final payloadText = jsonEncode(payload);
    final expected = sha256.convert(utf8.encode(payloadText)).toString();
    if (envelope['checksum'] != expected) {
      throw const FormatException('Checksum mismatch.');
    }
    if (payload['schemaVersion'] != schemaVersion) {
      throw const FormatException('Unsupported schema version.');
    }
    final generation = payload['generation'];
    if (generation is! int || generation < 1) {
      throw const FormatException('Invalid snapshot generation.');
    }
    return _DecodedSnapshot<T>(
      slot: slot,
      generation: generation,
      value: decodePayload(payload),
    );
  } on Object catch (error) {
    throw DualSlotSnapshotCorruptionException(
      'Local snapshot ${file.path} is invalid. ($error)',
    );
  }
}

File _slotFile(Directory directory, String fileStem, int slot) =>
    File.fromUri(directory.uri.resolve('$fileStem-$slot.json'));

Future<void> _writeFileAndFlush(File file, List<int> bytes) async {
  await file.writeAsBytes(bytes, flush: true);
}

sealed class DualSlotSnapshotException implements Exception {
  const DualSlotSnapshotException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class DualSlotSnapshotCorruptionException extends DualSlotSnapshotException {
  const DualSlotSnapshotCorruptionException(super.message);
}

class DualSlotSnapshotWriteException extends DualSlotSnapshotException {
  const DualSlotSnapshotWriteException(super.message);
}
