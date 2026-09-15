import 'dart:convert';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_draft_store.dart';
import '../storage/sqlite_domain_snapshot_store.dart';
import 'authorized_receipt_draft_service.dart';
import 'local_receipt_draft_repository.dart';
import 'receipt_draft_record.dart';
import 'receipt_draft_repository.dart';
import 'receipt_draft_ui_controller.dart';
import 'receipt_selected_details.dart';
import 'receipt_item_read.dart';

/// Confirms existing evidence metadata and recovery input in one transaction.
/// Originals remain retained; no new files or accounting records are created.
class AtomicReceiptEvidenceReview {
  const AtomicReceiptEvidenceReview(this.repository);
  final LocalReceiptDraftRepository repository;
  static const draftDomain = 'receipts/evidence-review';
  static String draftIdFor(String actor, String receipt) =>
      'review:${jsonEncode([actor, receipt])}';

  Future<StoredReceiptDraft> confirm({
    required String receiptId,
    required int expectedRevision,
    required List<String> orderedEvidenceIds,
    required ReceiptDraftCommandPermissions permissions,
    required LocalDraftCheckpoint checkpoint,
    required DateTime occurredAtUtc,
  }) {
    final ordered = List<String>.unmodifiable(orderedEvidenceIds);
    return repository.withStagedEvidenceReview((stage) async {
      final controller = ReceiptDraftUiController(
        AuthorizedReceiptDraftService(stage.repository),
        permissions,
      );
      try {
        if (!await controller.load()) {
          throw const ReceiptDraftPermissionDeniedException(
            'Receipt review is unavailable.',
          );
        }
        final current = controller.recordById(receiptId);
        if (current == null || current.lifecycle.revision != expectedRevision) {
          throw const ReceiptDraftRevisionConflictException(
            'Receipt review is stale.',
          );
        }
        final planBefore = stage.prepare();
        final drafts = LocalDraftStore(planBefore.database);
        final inputRow = await drafts.find(
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
          domain: checkpoint.domain,
          draftId: checkpoint.draftId,
        );
        final input = inputRow == null ? null : drafts.decode(inputRow);
        if (checkpoint.domain != draftDomain ||
            checkpoint.draftId !=
                draftIdFor(permissions.actorEmployeeId, receiptId) ||
            inputRow?.revision != checkpoint.revision ||
            input?['sourceId'] != receiptId ||
            input?['sourceRevision'] != expectedRevision ||
            jsonEncode(input?['orderedEvidenceIds']) != jsonEncode(ordered)) {
          throw const ReceiptDraftRevisionConflictException(
            'Saved evidence review changed.',
          );
        }
        final detailsPayload = input!['selectedDetails'];
        final itemReads = input.containsKey('itemReads')
            ? decodeReceiptItemReads(input)
            : current.activeItemReads;
        if (itemReads.any(
          (read) => !current.activeEvidence.any(
            (item) => read.matches(item.evidenceId, item.sha256),
          ),
        )) {
          throw const ReceiptDraftRevisionConflictException(
            'Read items do not match their retained image.',
          );
        }
        final details = detailsPayload == null
            ? null
            : ReceiptSelectedDetails.fromJson(
                (detailsPayload as Map).cast<String, Object?>(),
              );
        if (details != null &&
            !current.activeEvidence.any(
              (item) => details.matches(item.evidenceId, item.sha256),
            )) {
          throw const ReceiptDraftRevisionConflictException(
            'Selected details do not match the retained image.',
          );
        }
        final updated = await controller.update(
          itemReads: [
            for (final read in itemReads)
              if (ordered.contains(read.evidenceId)) read,
          ],
          selectedDetails:
              details != null && ordered.contains(details.evidenceId)
              ? details
              : null,
          replaceSelectedDetails: true,
          draftId: receiptId,
          title: current.title,
          expenseDate: current.expenseDate,
          expectedRevision: expectedRevision,
          retainedEvidenceIds: ordered,
          addedEvidence: const [],
          occurredAtUtc: occurredAtUtc,
          linkedJobId: current.linkedJobId,
          linkedJobLabel: current.linkedJobLabel,
        );
        if (updated == null) {
          throw const ReceiptDraftStorageException(
            'Evidence review was not applied.',
          );
        }
        await commitPreparedDomainChanges(
          [stage.prepare()],
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
          checkpoint: checkpoint,
        );
        stage.publishCommitted();
        return updated;
      } finally {
        controller.dispose();
      }
    });
  }
}
