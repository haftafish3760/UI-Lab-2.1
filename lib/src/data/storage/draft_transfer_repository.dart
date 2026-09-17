import 'draft_repository.dart';
import 'local_draft_checkpoint.dart';

/// Optional repository capability for moving unfinished input between workflows.
/// Destination creation/update and source consumption commit together; no business record is
/// confirmed. Scoped identities must come from the authorized owning service.
abstract interface class DraftTransferRepository implements DraftRepository {
  Future<int> transfer({
    required String organizationId,
    required String ownerId,
    required LocalDraftCheckpoint source,
    required String targetDomain,
    required String targetDraftId,
    required Map<String, Object?> targetPayload,
    required DateTime occurredAt,
    int expectedTargetRevision = 0,
  });
}
