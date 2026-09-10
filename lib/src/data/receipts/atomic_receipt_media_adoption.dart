import '../storage/local_attachment_store.dart';
import '../storage/local_media_picker_request.dart';
import '../storage/sqlite_domain_snapshot_store.dart';
import 'authorized_receipt_draft_service.dart';
import 'local_receipt_draft_repository.dart';
import 'receipt_draft_record.dart';
import 'receipt_draft_repository.dart';
import 'receipt_draft_ui_controller.dart';

/// Retained originals and the native request are adopted without exposing an
/// intermediate live receipt. Files are prepared before SQL commit/publication.
class AtomicReceiptMediaAdoption {
  const AtomicReceiptMediaAdoption(this.repository);
  final LocalReceiptDraftRepository repository;

  Future<StoredReceiptDraft> adopt({
    required LocalMediaPickerRequest request,
    required ReceiptDraftCommandPermissions permissions,
    required DateTime occurredAtUtc,
  }) => repository.withStagedMediaImport((stage) async {
    if (request.destination != MediaPickerDestination.receipt ||
        request.organizationId != permissions.organizationId ||
        request.ownerId != permissions.actorEmployeeId ||
        request.retainedAttachmentIds == null ||
        request.returnedFiles == null ||
        request.retainedAttachmentIds!.length !=
            request.returnedFiles!.length) {
      throw const ReceiptDraftPermissionDeniedException(
        'Media adoption is unavailable.',
      );
    }
    final controller = ReceiptDraftUiController(
      AuthorizedReceiptDraftService(stage.repository),
      permissions,
    );
    try {
      if (!await controller.load()) {
        throw const ReceiptDraftPermissionDeniedException(
          'Receipt access is unavailable.',
        );
      }
      final current = controller.recordById(request.targetId);
      if (current == null ||
          current.lifecycle.revision != request.targetRevision) {
        throw const ReceiptDraftRevisionConflictException(
          'The receipt changed before media adoption.',
        );
      }
      // Authorization must precede reading/copying retained bytes.
      if (!permissions.canTarget(current) ||
          !(permissions.owns(current)
              ? permissions.canEditOwn
              : permissions.canEditTeam)) {
        throw const ReceiptDraftPermissionDeniedException(
          'Receipt editing is unavailable.',
        );
      }
      final files = await LocalAttachmentStore(stage.prepare().database)
          .verifiedFiles(
            organizationId: request.organizationId,
            ownerIds: {request.ownerId},
            attachmentIds: request.retainedAttachmentIds!.toSet(),
          );
      final byId = {
        for (final file in files)
          file.uri.pathSegments.last.split('.').first: file,
      };
      final updated = await controller.update(
        draftId: current.draftId,
        title: current.title,
        expenseDate: current.expenseDate,
        expectedRevision: request.targetRevision,
        retainedEvidenceIds: current.activeEvidence
            .map((e) => e.evidenceId)
            .toList(),
        addedEvidence: [
          for (
            var index = 0;
            index < request.retainedAttachmentIds!.length;
            index++
          )
            ReceiptEvidenceImport(
              sourcePath: byId[request.retainedAttachmentIds![index]]!.path,
              originalName: request.returnedFiles![index].name,
              kind:
                  request.source == MediaPickerSource.files &&
                      request.returnedFiles![index].name.toLowerCase().endsWith(
                        '.pdf',
                      )
                  ? ReceiptDraftEvidenceKind.pdf
                  : ReceiptDraftEvidenceKind.photo,
            ),
        ],
        occurredAtUtc: occurredAtUtc,
        linkedJobId: current.linkedJobId,
        linkedJobLabel: current.linkedJobLabel,
      );
      if (updated == null) {
        throw const ReceiptDraftStorageException(
          'Media adoption was not prepared.',
        );
      }
      await commitPreparedDomainChanges(
        [stage.prepare()],
        organizationId: request.organizationId,
        ownerId: request.ownerId,
        mediaRequest: request,
      );
      stage.publishCommitted();
      return updated;
    } finally {
      controller.dispose();
    }
  });
}
