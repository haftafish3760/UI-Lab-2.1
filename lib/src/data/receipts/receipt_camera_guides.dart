import 'dart:io';
import 'package:crypto/crypto.dart';
import '../storage/local_media_picker_request.dart';
import 'authorized_receipt_draft_service.dart';
import 'receipt_draft_record.dart';
import 'receipt_draft_repository.dart';

/// Resolve against the request's saved revision, never a current widget index.
class ReceiptCameraGuideResolver {
  const ReceiptCameraGuideResolver(this.repository, this.permissions);
  final ReceiptDraftRepository repository;
  final ReceiptDraftCommandPermissions permissions;

  Future<Map<String, Object?>> forAppend(
    LocalMediaPickerRequest request,
  ) async {
    if (request.destination != MediaPickerDestination.receipt ||
        request.source != MediaPickerSource.camera ||
        request.organizationId != permissions.organizationId ||
        request.ownerId != permissions.actorEmployeeId) {
      throw StateError('Receipt camera context is unavailable.');
    }
    final receipt = await AuthorizedReceiptDraftService(
      repository,
    ).find(draftId: request.targetId, permissions: permissions);
    if (receipt == null ||
        receipt.lifecycle.revision != request.targetRevision ||
        !permissions.canTarget(receipt) ||
        !(permissions.owns(receipt)
            ? permissions.canEditOwn
            : permissions.canEditTeam)) {
      throw StateError('The receipt camera context changed.');
    }
    final evidence = receipt.activeEvidence;
    if (evidence.isEmpty ||
        evidence.last.kind != ReceiptDraftEvidenceKind.photo) {
      return const {};
    }
    final previous = evidence.last;
    final file = File(previous.localPath);
    if (await file.length() != previous.byteLength ||
        (await sha256.bind(file.openRead()).first).toString() !=
            previous.sha256) {
      throw StateError('The previous receipt photo is missing or changed.');
    }
    return {
      'previousGuide': {
        'path': file.absolute.path,
        'sha256': previous.sha256,
        'length': previous.byteLength,
      },
    };
  }
}
