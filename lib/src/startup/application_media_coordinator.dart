import '../data/storage/local_database.dart';
import '../data/storage/local_attachment_store.dart';
import '../data/storage/local_media_picker_request.dart';
import '../data/storage/media_picker_result_retention.dart';
import '../data/storage/native_media_picker_coordinator.dart';
import '../data/receipts/authorized_receipt_draft_service.dart';
import '../data/receipts/local_receipt_draft_repository.dart';
import '../data/receipts/receipt_draft_repository.dart';
import '../data/work/estimate_media_adoption.dart';
import '../data/work/work_persistence_session.dart';

/// One native cache owner. Domain authorization remains in its owning service.
NativeMediaPickerCoordinator createApplicationMediaCoordinator({
  required LocalDatabase database,
  required NativeMediaPickerGateway gateway,
  required ReceiptDraftCommandPermissions receiptPermissions,
  LocalReceiptDraftRepository? receipts,
  WorkPersistenceSession? work,
}) {
  final requests = LocalMediaPickerRequestStore(database);
  return NativeMediaPickerCoordinator(
    requests: requests,
    retention: MediaPickerResultRetention(
      requests: requests,
      attachments: LocalAttachmentStore(database),
    ),
    gateway: gateway,
    authorize:
        ({
          required organizationId,
          required ownerId,
          required destination,
          required targetId,
          required targetRevision,
        }) async {
          if (destination == MediaPickerDestination.estimate) {
            if (work == null ||
                !identical(work.repository.database, database)) {
              throw StateError('Estimate photo access is unavailable.');
            }
            return EstimateMediaAdoption(
              work.repository,
              work.permissions,
            ).authorize(
              organizationId: organizationId,
              ownerId: ownerId,
              destination: destination,
              targetId: targetId,
              targetRevision: targetRevision,
            );
          }
          if (receipts == null ||
              organizationId != receiptPermissions.organizationId ||
              ownerId != receiptPermissions.actorEmployeeId) {
            throw const ReceiptDraftPermissionDeniedException(
              'Photo access unavailable.',
            );
          }
          final receipt = await AuthorizedReceiptDraftService(
            receipts,
          ).find(draftId: targetId, permissions: receiptPermissions);
          if (receipt == null ||
              !receiptPermissions.canTarget(receipt) ||
              !(receiptPermissions.owns(receipt)
                  ? receiptPermissions.canEditOwn
                  : receiptPermissions.canEditTeam)) {
            throw const ReceiptDraftPermissionDeniedException(
              'Receipt editing unavailable.',
            );
          }
          if (receipt.lifecycle.revision != targetRevision) {
            throw const ReceiptDraftRevisionConflictException(
              'The receipt changed.',
            );
          }
        },
  );
}

/// Missing/failed native recovery must not prevent local application startup.
Future<void> recoverApplicationMedia(
  NativeMediaPickerCoordinator coordinator, {
  required String organizationId,
  required String ownerId,
}) async {
  try {
    await coordinator.recover(organizationId: organizationId, ownerId: ownerId);
  } catch (_) {
    /* The durable request remains available on its owning editor. */
  }
}
