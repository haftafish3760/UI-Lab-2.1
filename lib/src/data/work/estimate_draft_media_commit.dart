import '../storage/draft_autosave_session.dart';
import '../storage/local_draft_store.dart';
import '../storage/local_media_picker_request.dart';
import '../storage/local_record_command.dart';

/// Work-owned media transaction. The generic autosave session only serializes
/// input and publishes the committed result; it knows no estimate/media rules.
extension EstimateDraftMediaCommit on DraftAutosaveSession {
  Future<void> adoptMediaInput({
    required LocalMediaPickerRequest request,
    required Map<String, Object?> input,
    Future<void> Function()? validateBeforeCommit,
  }) {
    final drafts = store;
    if (drafts is! LocalDraftStore ||
        request.organizationId != organizationId ||
        request.ownerId != ownerId ||
        request.targetId != draftId ||
        !((request.destination == MediaPickerDestination.estimate &&
                domain == 'work/estimate-editor') ||
            (request.destination == MediaPickerDestination.job &&
                domain == 'work/job-photos') ||
            (request.destination == MediaPickerDestination.estimateApproval &&
                domain == 'work/estimate-approval') ||
            (request.destination == MediaPickerDestination.quoteApproval &&
                domain == 'work/quote-approval')) ||
        request.retainedAttachmentIds == null) {
      throw const LocalRecordConflict(
        'Media destination does not match this draft.',
      );
    }
    return commitInput(
      expectedRevision: request.targetRevision,
      input: input,
      commit: (prepared) =>
          LocalMediaPickerRequestStore(drafts.database).consume(
            request: request,
            organizationId: organizationId,
            ownerId: ownerId,
            commit: () async {
              await validateBeforeCommit?.call();
              return drafts.save(
                organizationId: organizationId,
                domain: domain,
                draftId: draftId,
                ownerId: ownerId,
                expectedRevision: request.targetRevision,
                payload: prepared,
                occurredAt: DateTime.now().toUtc(),
              );
            },
          ),
    );
  }
}
