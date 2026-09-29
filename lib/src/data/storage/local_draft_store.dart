import 'dart:convert';

import 'package:drift/drift.dart';

import 'local_database.dart';
import 'draft_repository.dart';
import 'draft_transfer_repository.dart';
import 'local_draft_checkpoint.dart';
import 'draft_session_registry.dart';
import 'local_record_command.dart';

/// Recoverable unconfirmed input, including incomplete numbers and empty fields.
/// A saved draft does not change a balance, stock quantity or issued document.
class LocalDraftStore
    implements DraftTransferRepository, ManagedDraftRepository {
  const LocalDraftStore(this.database);

  @override
  Future<int> transfer({
    required String organizationId,
    required String ownerId,
    required LocalDraftCheckpoint source,
    required String targetDomain,
    required String targetDraftId,
    required Map<String, Object?> targetPayload,
    required DateTime occurredAt,
    int expectedTargetRevision = 0,
  }) {
    // Detach mutable caller input before asynchronous storage work begins.
    final payload = (jsonDecode(canonicalJson(targetPayload)) as Map)
        .cast<String, Object?>();
    if (source.domain == targetDomain && source.draftId == targetDraftId) {
      throw ArgumentError('A draft transfer requires a different destination.');
    }
    return database.transaction(() async {
      final current = await find(
        organizationId: organizationId,
        ownerId: ownerId,
        domain: source.domain,
        draftId: source.draftId,
      );
      if (current == null || current.revision != source.revision) {
        throw const LocalRecordConflict('The source draft changed.');
      }
      final revision = await save(
        organizationId: organizationId,
        ownerId: ownerId,
        domain: targetDomain,
        draftId: targetDraftId,
        expectedRevision: expectedTargetRevision,
        payload: payload,
        occurredAt: occurredAt,
      );
      if (!await consumeIfUnchanged(
        organizationId: organizationId,
        ownerId: ownerId,
        domain: source.domain,
        draftId: source.draftId,
        expectedRevision: source.revision,
      )) {
        throw const LocalRecordConflict('The source draft changed.');
      }
      return revision;
    });
  }

  final LocalDatabase database;
  @override
  DraftSessionRegistry get draftSessions => database.draftSessions;

  @override
  Future<List<SavedDraft>> listOwned({
    required String organizationId,
    required String ownerId,
    required Set<String> domains,
  }) async {
    if (domains.isEmpty) return const [];
    final rows =
        await (database.select(database.localDrafts)
              ..where(
                (row) =>
                    row.organizationId.equals(organizationId) &
                    row.ownerId.equals(ownerId) &
                    row.domain.isIn(domains),
              )
              ..orderBy([
                (row) => OrderingTerm.desc(row.updatedAtUs),
                (row) => OrderingTerm.asc(row.domain),
                (row) => OrderingTerm.asc(row.draftId),
              ]))
            .get();
    return List.unmodifiable(rows.map(_snapshot));
  }

  @override
  Future<List<SavedDraft>> list({
    required String organizationId,
    required String domain,
    required String ownerId,
  }) =>
      (database.select(database.localDrafts)
            ..where(
              (row) =>
                  row.organizationId.equals(organizationId) &
                  row.domain.equals(domain) &
                  row.ownerId.equals(ownerId),
            )
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAtUs)]))
          .get()
          .then((rows) => List.unmodifiable(rows.map(_snapshot)));

  @override
  Future<SavedDraft?> find({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
  }) =>
      (database.select(database.localDrafts)..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.domain.equals(domain) &
                row.draftId.equals(draftId) &
                row.ownerId.equals(ownerId),
          ))
          .getSingleOrNull()
          .then((row) => row == null ? null : _snapshot(row));

  @override
  Future<int> save({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
    required int expectedRevision,
    required Map<String, Object?> payload,
    required DateTime occurredAt,
  }) async {
    // Serialize at submission, before SQLite or another draft can yield.
    // A shallow map copy would still expose nested form values to mutation.
    final submittedPayload = canonicalJson(payload);
    return database.transaction(() async {
      if ([
            organizationId,
            domain,
            draftId,
            ownerId,
          ].any((id) => id.trim().isEmpty) ||
          expectedRevision < 0) {
        throw ArgumentError(
          'A draft needs scoped identity and a valid revision.',
        );
      }
      final current =
          await (database.select(database.localDrafts)..where(
                (row) =>
                    row.organizationId.equals(organizationId) &
                    row.domain.equals(domain) &
                    row.draftId.equals(draftId),
              ))
              .getSingleOrNull();
      if ((current?.revision ?? 0) != expectedRevision ||
          (current != null && current.ownerId != ownerId)) {
        throw const LocalRecordConflict(
          'This draft changed in another editor.',
        );
      }
      final counterKey = _counterKey(organizationId, domain, draftId);
      final previousRevision = await _lastRevision(counterKey);
      final base = previousRevision > (current?.revision ?? 0)
          ? previousRevision
          : (current?.revision ?? 0);
      if (base >= 9223372036854775807) {
        throw StateError('Draft revision capacity exhausted.');
      }
      final nextRevision = base + 1;
      await _retainRevision(counterKey, nextRevision);
      final record = LocalDraftsCompanion.insert(
        organizationId: organizationId,
        domain: domain,
        draftId: draftId,
        ownerId: ownerId,
        revision: nextRevision,
        payloadVersion: 1,
        payload: submittedPayload,
        updatedAtUs: occurredAt.toUtc().microsecondsSinceEpoch,
      );
      if (current == null) {
        await database.into(database.localDrafts).insert(record);
      } else {
        await (database.update(database.localDrafts)..where(
              (row) =>
                  row.organizationId.equals(organizationId) &
                  row.domain.equals(domain) &
                  row.draftId.equals(draftId),
            ))
            .write(record);
      }
      return nextRevision;
    });
  }

  /// Use inside the same database transaction as explicit record confirmation.
  /// Never consumes a newer draft written while confirmation was in progress.
  @override
  Future<bool> consumeIfUnchanged({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
    required int expectedRevision,
  }) => database.transaction(() async {
    final current = await find(
      organizationId: organizationId,
      domain: domain,
      draftId: draftId,
      ownerId: ownerId,
    );
    if (current == null || current.revision != expectedRevision) return false;
    // Preserve the revision even for drafts created before counters existed.
    // Confirmation/discard and this marker must commit or roll back together.
    await _retainRevision(
      _counterKey(organizationId, domain, draftId),
      current.revision,
    );
    return await (database.delete(database.localDrafts)..where(
              (row) =>
                  row.organizationId.equals(organizationId) &
                  row.domain.equals(domain) &
                  row.draftId.equals(draftId) &
                  row.ownerId.equals(ownerId) &
                  row.revision.equals(expectedRevision),
            ))
            .go() ==
        1;
  });

  String _counterKey(String organization, String domain, String id) =>
      'draft.revision.v1:${jsonEncode([organization, domain, id])}';

  Future<int> _lastRevision(String key) async {
    final row = await (database.select(
      database.localMetadata,
    )..where((row) => row.metadataKey.equals(key))).getSingleOrNull();
    if (row == null) return 0;
    final revision = int.tryParse(row.value);
    if (revision == null || revision < 1) {
      throw StateError('Saved draft revision marker is invalid.');
    }
    return revision;
  }

  Future<void> _retainRevision(String key, int revision) async {
    final previous = await _lastRevision(key);
    if (previous >= revision) return;
    await database
        .into(database.localMetadata)
        .insertOnConflictUpdate(
          LocalMetadataCompanion.insert(metadataKey: key, value: '$revision'),
        );
  }

  SavedDraft _snapshot(LocalDraft row) => SavedDraft(
    organizationId: row.organizationId,
    domain: row.domain,
    draftId: row.draftId,
    ownerId: row.ownerId,
    revision: row.revision,
    payloadVersion: row.payloadVersion,
    payload: row.payload,
    updatedAtUs: row.updatedAtUs,
  );

  @override
  Map<String, Object?> decode(SavedDraft draft) {
    if (draft.payloadVersion != 1) {
      throw StateError('Unsupported draft version.');
    }
    return (jsonDecode(draft.payload) as Map).cast<String, Object?>();
  }
}
