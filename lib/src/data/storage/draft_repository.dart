/// Storage-independent saved input. Payload bytes and version are retained even
/// when a newer workflow cannot decode them, so recovery never deletes evidence.
class SavedDraft {
  const SavedDraft({
    required this.organizationId,
    required this.domain,
    required this.draftId,
    required this.ownerId,
    required this.revision,
    required this.payloadVersion,
    required this.payload,
    required this.updatedAtUs,
  });

  final String organizationId;
  final String domain;
  final String draftId;
  final String ownerId;
  final int revision;
  final int payloadVersion;
  final String payload;
  final int updatedAtUs;
}

/// Draft persistence contract, not an authorization grant. Domain workflows
/// supply authorized identities. No widget or workflow needs a database handle.
abstract interface class DraftRepository {
  /// Scoped catalog query. Domains are supplied by an authorized workflow
  /// registry, not inferred from a screen or treated as an authorization grant.
  Future<List<SavedDraft>> listOwned({
    required String organizationId,
    required String ownerId,
    required Set<String> domains,
  });

  Future<List<SavedDraft>> list({
    required String organizationId,
    required String domain,
    required String ownerId,
  });

  Future<SavedDraft?> find({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
  });

  /// Resolves only after the write commits; rejects a stale expected revision.
  Future<int> save({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
    required int expectedRevision,
    required Map<String, Object?> payload,
    required DateTime occurredAt,
  });

  Future<bool> consumeIfUnchanged({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
    required int expectedRevision,
  });

  Map<String, Object?> decode(SavedDraft draft);
}
