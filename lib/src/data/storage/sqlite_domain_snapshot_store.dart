import 'dart:convert';

import 'package:drift/drift.dart';

import 'domain_snapshot_store.dart';
import 'dual_slot_json_store.dart';
import 'local_database.dart';
import 'local_draft_checkpoint.dart';
import 'local_draft_store.dart';
import 'local_media_picker_request.dart';
import 'local_record_command.dart';
import 'local_record_store.dart';
import 'serialized_async_actions.dart';

part 'prepared_domain_snapshot_change.dart';

class DomainCollection {
  const DomainCollection({
    required this.name,
    required this.idField,
    required this.ownerField,
  });
  final String name;
  final String idField;
  final String ownerField;
}

/// Reuses existing validated domain aggregates while storage changes. Each
/// collection item has its own SQL identity, revision and retained history.
/// One application bootstrap owns each adapter; a stale external writer is
/// rejected by SQLite rather than overwriting newer data from its cached view.
class SqliteDomainSnapshotStore<T>
    implements DraftConfirmingDomainSnapshotStore<T> {
  SqliteDomainSnapshotStore._({
    required this.database,
    required this.organizationId,
    required this.domain,
    required this.collections,
    required this.encode,
    required this.decode,
    required this.value,
    required this._rows,
  });

  final LocalDatabase database;
  final String organizationId;
  final String domain;
  final List<DomainCollection> collections;
  final Map<String, Object?> Function(T) encode;
  final T Function(Map<String, Object?>) decode;
  Map<(String, String), LocalRecord> _rows;
  @override
  T value;
  @override
  bool get recoveredFromDamagedSnapshot => false;

  static Future<SqliteDomainSnapshotStore<T>> open<T>({
    required LocalDatabase database,
    required String organizationId,
    required String domain,
    required List<DomainCollection> collections,
    required Map<String, Object?> Function(T) encode,
    required T Function(Map<String, Object?>) decode,
  }) async {
    final rows =
        await (database.select(database.localRecords)..where(
              (row) =>
                  row.organizationId.equals(organizationId) &
                  row.domain.isIn(collections.map((c) => '$domain/${c.name}')),
            ))
            .get();
    final payload = <String, Object?>{
      for (final c in collections) c.name: <Object?>[],
    };
    for (final row in rows) {
      if (row.payloadVersion != 1) {
        throw StateError('Unsupported stored domain version.');
      }
      final collection = collections.singleWhere(
        (c) => row.domain == '$domain/${c.name}',
      );
      final body = (jsonDecode(row.payload) as Map).cast<String, Object?>();
      if (body[collection.idField] != row.recordId ||
          body['organizationId'] != row.organizationId ||
          body[collection.ownerField] != row.ownerId) {
        throw StateError(
          'Stored record identity does not match its domain payload.',
        );
      }
      (payload[collection.name] as List).add(body);
    }
    return SqliteDomainSnapshotStore<T>._(
      database: database,
      organizationId: organizationId,
      domain: domain,
      collections: collections,
      encode: encode,
      decode: decode,
      value: decode(payload),
      rows: {for (final row in rows) (row.domain, row.recordId): row},
    );
  }

  @override
  Future<void> persist(T next) => _persist(next);

  @override
  Future<void> persistWithDraft(
    T next, {
    required String organizationId,
    required String ownerId,
    required LocalDraftCheckpoint checkpoint,
  }) {
    if (organizationId != this.organizationId ||
        ownerId.trim().isEmpty ||
        checkpoint.revision < 1) {
      throw const DualSlotSnapshotWriteException(
        'The draft cannot be confirmed in this session.',
      );
    }
    return _persist(next, ownerId: ownerId, checkpoint: checkpoint);
  }

  Future<void> _persist(
    T next, {
    String? ownerId,
    LocalDraftCheckpoint? checkpoint,
  }) async {
    await commitPreparedDomainChanges(
      [prepare(next)],
      organizationId: organizationId,
      ownerId: ownerId,
      checkpoint: checkpoint,
    );
  }

  /// Validates and freezes changes without writing SQL or advancing the cache.
  PreparedDomainSnapshotChange prepare(T next) {
    final baseRows = _rows;
    final payload = (jsonDecode(canonicalJson(encode(next))) as Map)
        .cast<String, Object?>();
    // Independently re-run existing collection/link invariants before SQL.
    final validated = decode(payload);
    final nextKeys = <(String, String)>{};
    final writesByOrganization = <String, List<LocalRecordWrite>>{};
    for (final collection in collections) {
      for (final item in payload[collection.name] as List) {
        final body = (item as Map).cast<String, Object?>();
        final id = body[collection.idField] as String;
        final organization = body['organizationId'] as String;
        if (organization != organizationId) {
          throw StateError('Record is outside this organization.');
        }
        final rowDomain = '$domain/${collection.name}';
        final key = (rowDomain, id);
        if (!nextKeys.add(key)) {
          throw StateError('Duplicate domain record identity.');
        }
        final previous = _rows[key];
        if (previous != null && previous.organizationId != organization) {
          throw StateError('Record organization cannot be rewritten.');
        }
        if (previous?.payload == canonicalJson(body)) continue;
        (writesByOrganization[organization] ??= []).add(
          LocalRecordWrite(
            domain: rowDomain,
            recordId: id,
            ownerId: body[collection.ownerField] as String,
            expectedRevision: previous?.revision ?? 0,
            payload: body,
          ),
        );
      }
    }
    if (_rows.keys.any((key) => !nextKeys.contains(key))) {
      throw StateError(
        'Business records must use their domain removal lifecycle.',
      );
    }
    final time = DateTime.now().toUtc();
    final committed = {..._rows};
    for (final group in writesByOrganization.entries) {
      for (final write in group.value) {
        committed[(write.domain, write.recordId)] = LocalRecord(
          organizationId: group.key,
          domain: write.domain,
          recordId: write.recordId,
          ownerId: write.ownerId,
          revision: write.nextRevision,
          payloadVersion: write.payloadVersion,
          payload: write.payloadJson,
          updatedAtUs: time.microsecondsSinceEpoch,
        );
      }
    }
    return PreparedDomainSnapshotChange._(
      database,
      (organizationId, domain),
      () {
        if (!identical(_rows, baseRows)) {
          throw const LocalRecordConflict('Prepared values are stale.');
        }
      },
      () async {
        for (final group in writesByOrganization.entries) {
          final identity = payloadDigest(
            canonicalJson(group.value.map((w) => w.toJson()).toList()),
          );
          await LocalRecordStore(database).commit(
            organizationId: group.key,
            commandId: '$domain:$identity',
            writes: group.value,
            occurredAt: time,
          );
        }
      },
      () {
        _rows = committed;
        value = validated;
      },
    );
  }
}
