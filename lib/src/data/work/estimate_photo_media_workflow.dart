import '../storage/draft_autosave_session.dart';
import '../storage/local_media_picker_request.dart';
import '../storage/native_media_picker_coordinator.dart';
import 'estimate_media_adoption.dart';
import 'estimate_photos_draft_input.dart';
import 'work_persistence_session.dart';

/// Presentation receives a selection state, not a storage request or SQL row.
class EstimatePhotoSelection {
  const EstimatePhotoSelection._(this._request);
  final LocalMediaPickerRequest _request;
  MediaPickerSource get source => _request.source;
  bool get requiresFileReselection =>
      _request.source == MediaPickerSource.files &&
      _request.returnedFiles == null;
}

class EstimatePhotoMediaWorkflow {
  EstimatePhotoMediaWorkflow._(this._draft, this._coordinator, this._adoption);
  final DraftAutosaveSession _draft;
  final NativeMediaPickerCoordinator _coordinator;
  final EstimateMediaAdoption _adoption;

  Future<EstimatePhotoSelection?> pendingSelection() async {
    final request = await _coordinator.requests.findFor(
      organizationId: _draft.organizationId,
      ownerId: _draft.ownerId,
    );
    if (request == null ||
        request.destination != MediaPickerDestination.estimate ||
        request.targetId != _draft.draftId) {
      return null;
    }
    return EstimatePhotoSelection._(request);
  }

  Future<EstimatePhotosDraftInput?> pick(MediaPickerSource source) async {
    await _draft.flush();
    final request = await _coordinator.start(
      organizationId: _draft.organizationId,
      ownerId: _draft.ownerId,
      destination: MediaPickerDestination.estimate,
      targetId: _draft.draftId,
      targetRevision: _draft.savedRevision,
      source: source,
    );
    return request == null
        ? null
        : _adoption.adopt(request: request, draft: _draft);
  }

  Future<EstimatePhotosDraftInput?> recover() async {
    final pending = (await pendingSelection())?._request;
    if (pending == null) return null;
    final request =
        pending.source == MediaPickerSource.files &&
            pending.returnedFiles == null
        ? await _coordinator.resumeFileSelection(
            organizationId: _draft.organizationId,
            ownerId: _draft.ownerId,
            requestId: pending.requestId,
          )
        : await _coordinator.recover(
            organizationId: _draft.organizationId,
            ownerId: _draft.ownerId,
          );
    if (request == null) return null;
    _validate(request);
    if (request.retainedAttachmentIds == null) {
      throw StateError(
        'No photos have returned yet. The pending selection remains saved.',
      );
    }
    return _adoption.adopt(request: request, draft: _draft);
  }

  Future<void> discard(EstimatePhotoSelection selection) async {
    _validate(selection._request);
    await _coordinator.discardSelection(
      request: selection._request,
      organizationId: _draft.organizationId,
      ownerId: _draft.ownerId,
    );
  }

  void _validate(LocalMediaPickerRequest request) {
    if (request.organizationId != _draft.organizationId ||
        request.ownerId != _draft.ownerId ||
        request.targetId != _draft.draftId ||
        request.destination != MediaPickerDestination.estimate) {
      throw StateError('Open the original estimate to recover its photos.');
    }
  }
}

extension EstimatePhotoMediaWorkflowFactory on WorkPersistenceSession {
  EstimatePhotoMediaWorkflow photoMediaWorkflow({
    required DraftAutosaveSession draft,
    required NativeMediaPickerCoordinator coordinator,
  }) {
    if (draft.organizationId != permissions.organizationId ||
        draft.ownerId != permissions.actorEmployeeId ||
        draft.domain != EstimateMediaAdoption.draftDomain) {
      throw StateError('Estimate media workflow does not match this session.');
    }
    return EstimatePhotoMediaWorkflow._(
      draft,
      coordinator,
      EstimateMediaAdoption(repository, permissions),
    );
  }
}
