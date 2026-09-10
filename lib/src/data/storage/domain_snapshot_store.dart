import 'local_draft_checkpoint.dart';

/// Transitional adapter for existing domain mutation rules. The SQLite adapter
/// persists individual changed records, not one app-wide serialized snapshot.
abstract interface class DomainSnapshotStore<T> {
  T get value;
  bool get recoveredFromDamagedSnapshot;
  Future<void> persist(T next);
}

/// Storage capable of confirming records and consuming exact input atomically.
abstract interface class DraftConfirmingDomainSnapshotStore<T>
    implements DomainSnapshotStore<T> {
  Future<void> persistWithDraft(
    T next, {
    required String organizationId,
    required String ownerId,
    required LocalDraftCheckpoint checkpoint,
  });
}
