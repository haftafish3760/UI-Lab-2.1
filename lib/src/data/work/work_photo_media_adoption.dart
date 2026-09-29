import 'estimate_draft_media_commit.dart';
import 'estimate_photos_draft_input.dart';
import 'models/work_models.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/local_attachment_store.dart';
import '../storage/local_draft_store.dart';
import '../storage/local_media_picker_request.dart';
import '../storage/local_record_command.dart';
import '../storage/local_record_identity.dart';
import 'sqlite_work_repository.dart';
import 'work_record_codec.dart';
import 'work_record_detail_codec.dart';
import 'work_session_permissions.dart';

/// Authorizes the current SQL target, then adopts retained originals into the
/// unfinished photo editor. It never creates or changes a confirmed Work record.
class WorkPhotoMediaAdoption {
  const WorkPhotoMediaAdoption(
    this.repository,
    this.permissions, {
    this.destination = MediaPickerDestination.estimate,
    this.domain = 'work/estimate-editor',
    this.recordKind = WorkRecordKind.estimate,
    this.recordIdKey = 'estimateId',
  });
  const WorkPhotoMediaAdoption.job(this.repository, this.permissions)
    : destination = MediaPickerDestination.job,
      domain = 'work/job-photos',
      recordKind = WorkRecordKind.job,
      recordIdKey = 'jobId';
  final MediaPickerDestination destination;
  final String domain;
  final WorkRecordKind recordKind;
  final String recordIdKey;
  final SqliteWorkRepository repository;
  final WorkSessionPermissions permissions;

  Future<void> authorize({
    required String organizationId,
    required String ownerId,
    required MediaPickerDestination destination,
    required String targetId,
    required int targetRevision,
  }) async {
    await _authorizedInput(
      organizationId: organizationId,
      ownerId: ownerId,
      destination: destination,
      targetId: targetId,
      targetRevision: targetRevision,
    );
  }

  Future<Map<String, Object?>> _authorizedInput({
    required String organizationId,
    required String ownerId,
    required MediaPickerDestination destination,
    required String targetId,
    required int targetRevision,
  }) async {
    if (organizationId != permissions.organizationId ||
        ownerId != permissions.actorEmployeeId ||
        destination != this.destination ||
        !permissions.editableKinds.contains(recordKind) ||
        (recordKind == WorkRecordKind.job && !permissions.canAttachJobPhotos)) {
      throw StateError('Work photo access is unavailable.');
    }
    final store = LocalDraftStore(repository.database);
    final row = await store.find(
      organizationId: organizationId,
      domain: domain,
      draftId: targetId,
      ownerId: ownerId,
    );
    if (row == null || row.revision != targetRevision) {
      throw const LocalRecordConflict('The photo input changed.');
    }
    final input = store.decode(row);
    final creator = input['creatorId'] as String;
    if (!permissions.visibleCreatorIds.contains(creator) ||
        (creator != ownerId && !permissions.canManageOtherCreators)) {
      throw StateError('Work editing is unavailable.');
    }
    final base = input['baseRecord'] as Map?;
    if (recordKind == WorkRecordKind.job && base == null) {
      throw StateError('The original job is required.');
    }
    if (base != null) {
      final original = decodeWorkRecord(base.cast<String, Object?>());
      final current = await repository.find(
        organizationId: organizationId,
        recordId: input[recordIdKey] as String,
        visibleCreatorIds: permissions.visibleCreatorIds,
      );
      if (original.kind != recordKind ||
          original.id != input[recordIdKey] ||
          original.createdByEmployeeId != creator ||
          current == null ||
          current.record.kind != recordKind ||
          !permissions.canEdit(current.record)) {
        throw StateError('The original work record is unavailable.');
      }
      if (current.storageRevision != input['baseStorageRevision']) {
        throw const LocalRecordConflict('The original work record changed.');
      }
    }
    return input;
  }

  Future<EstimatePhotosDraftInput> adopt({
    required LocalMediaPickerRequest request,
    required DraftAutosaveSession draft,
  }) async {
    final drafts = draft.store;
    if (drafts is! LocalDraftStore ||
        !identical(repository.database, drafts.database) ||
        draft.organizationId != request.organizationId ||
        draft.ownerId != request.ownerId ||
        draft.draftId != request.targetId ||
        draft.domain != domain ||
        request.returnedFiles == null ||
        request.retainedAttachmentIds == null ||
        request.returnedFiles!.length !=
            request.retainedAttachmentIds!.length) {
      throw StateError('The photo selection does not match this photo input.');
    }
    final input = await _authorizedInput(
      organizationId: request.organizationId,
      ownerId: request.ownerId,
      destination: request.destination,
      targetId: request.targetId,
      targetRevision: request.targetRevision,
    );
    final files = await LocalAttachmentStore(repository.database).verifiedFiles(
      organizationId: request.organizationId,
      ownerIds: {request.ownerId},
      attachmentIds: request.retainedAttachmentIds!.toSet(),
    );
    final byId = {
      for (final file in files)
        file.uri.pathSegments.last.split('.').first: file,
    };
    final nested = (input['photoEditor'] as Map?)?.cast<String, Object?>();
    final existing = (nested?['photos'] ?? input['sitePhotos']) as List;
    // Decode existing records before retaining their ordered representation.
    final photos = existing
        .map(
          (value) =>
              decodeWorkSitePhoto((value as Map).cast<String, Object?>()),
        )
        .toList();
    for (
      var index = 0;
      index < request.retainedAttachmentIds!.length;
      index++
    ) {
      photos.add(
        WorkSitePhoto(
          id: newLocalRecordIdentity('site-photo'),
          path: byId[request.retainedAttachmentIds![index]]!.path,
          name: request.returnedFiles![index].name,
          source: switch (request.source) {
            MediaPickerSource.camera => WorkSitePhotoSource.camera,
            MediaPickerSource.library => WorkSitePhotoSource.library,
            MediaPickerSource.files => WorkSitePhotoSource.file,
          },
          addedOn: DateTime.now(),
        ),
      );
    }
    final photoEditor = EstimatePhotosDraftInput(
      photos: photos,
      pendingNotes: (nested?['pendingNotes'] as Map? ?? <String, String>{})
          .cast<String, String>(),
    );
    await draft.adoptMediaInput(
      request: request,
      input: {...input, 'photoEditor': photoEditor.toPayload()},
      validateBeforeCommit: () => authorize(
        organizationId: request.organizationId,
        ownerId: request.ownerId,
        destination: request.destination,
        targetId: request.targetId,
        targetRevision: request.targetRevision,
      ),
    );
    return photoEditor;
  }
}
