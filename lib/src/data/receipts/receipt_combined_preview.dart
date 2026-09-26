import '../storage/local_attachment_store.dart';
import '../storage/local_draft_store.dart';
import 'receipt_evidence_draft_workflow.dart';
import 'receipt_submission_session.dart';

/// Resolves retained bytes through the owning receipt session. Layouts receive
/// a verified path, never a database, generated row or attachment store.
extension ReceiptCombinedPreview on ReceiptSubmissionSession {
  Future<String?> verifiedCombinedPreview(
    ReceiptEvidenceDraftController review,
  ) async {
    void requireOwner() {
      expenses.requireActiveDraftOwner();
      if (review.session.isClosed ||
          !review.recoveryAvailable ||
          !identical(review.session.store, drafts) ||
          review.session.organizationId != receiptPermissions.organizationId ||
          review.session.ownerId != receiptPermissions.actorEmployeeId ||
          receiptPermissions.readAccess == null) {
        throw StateError('Receipt preview access is unavailable.');
      }
    }

    requireOwner();
    final attachmentId = review.input.stitchState?.attachmentId;
    if (attachmentId == null) return null;
    final current = (await receipts.findById(
      draftId: review.source.draftId,
    )).record;
    requireOwner();
    if (current == null ||
        current.lifecycle.revision != review.input.sourceRevision ||
        !receiptPermissions.canTarget(current)) {
      throw StateError('Receipt access or evidence changed.');
    }
    final store = drafts;
    if (store is! LocalDraftStore) {
      throw StateError('Retained receipt storage is unavailable.');
    }
    final files = await LocalAttachmentStore(store.database).verifiedFiles(
      organizationId: review.session.organizationId,
      ownerIds: {review.session.ownerId},
      attachmentIds: {attachmentId},
    );
    requireOwner();
    if (review.input.stitchState?.attachmentId != attachmentId) {
      throw StateError('Receipt preview changed while loading.');
    }
    return files.single.path;
  }
}
