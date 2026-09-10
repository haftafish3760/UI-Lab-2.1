import 'local_media_picker_request.dart';
import 'media_picker_result_retention.dart';
import 'serialized_async_actions.dart';

abstract interface class NativeMediaPickerGateway {
  bool get supportsRecovery;
  Future<List<MediaPickerReturnedFile>> pick(
    MediaPickerSource source,
    MediaPickerDestination destination,
  );
  Future<List<MediaPickerReturnedFile>> recover();
}

/// Native implementations may journal results against this durable request ID.
/// Retrieval must be replayable until acknowledgement succeeds. Acknowledgement
/// must be idempotent and must never clear a different request's result.
abstract interface class JournaledNativeMediaPickerGateway
    implements NativeMediaPickerGateway {
  Future<List<MediaPickerReturnedFile>> pickForRequest(
    LocalMediaPickerRequest request,
  );
  Future<List<MediaPickerReturnedFile>> recoverForRequest(
    LocalMediaPickerRequest request,
  );
  Future<void> acknowledgeRetained(LocalMediaPickerRequest request);
  Future<void> abandonRequest(LocalMediaPickerRequest request);
}

typedef AuthorizeMediaTarget =
    Future<void> Function({
      required String organizationId,
      required String ownerId,
      required MediaPickerDestination destination,
      required String targetId,
      required int targetRevision,
    });

/// One app-owned coordinator serializes native launch and recovery. Authorizers
/// must validate current target visibility/edit rights and its saved revision.
class NativeMediaPickerCoordinator {
  NativeMediaPickerCoordinator({
    required this.requests,
    required this.retention,
    required this.gateway,
    required this.authorize,
  }) {
    if (!identical(requests.database, retention.requests.database)) {
      throw ArgumentError('Native media coordination needs one database.');
    }
  }
  final LocalMediaPickerRequestStore requests;
  final MediaPickerResultRetention retention;
  final NativeMediaPickerGateway gateway;
  final AuthorizeMediaTarget authorize;
  final _actions = SerializedAsyncActions();

  /// An external native picker must settle before its database can close.
  Future<AsyncActionPause> pauseOperations() async {
    final lease = await _actions.pauseAndDrain();
    try {
      if (gateway is JournaledNativeMediaPickerGateway) {
        final request = await requests.findForInstallationLifecycle();
        if (request != null && request.source != MediaPickerSource.files) {
          if (request.retainedAttachmentIds == null) {
            throw StateError(
              'Recover or discard the pending media selection before switching storage.',
            );
          }
          await _acknowledge(request);
        }
      }
      return lease;
    } catch (_) {
      lease.release();
      rethrow;
    }
  }

  Future<LocalMediaPickerRequest?> start({
    required String organizationId,
    required String ownerId,
    required MediaPickerDestination destination,
    required String targetId,
    required int targetRevision,
    required MediaPickerSource source,
  }) => _actions.run(() async {
    await authorize(
      organizationId: organizationId,
      ownerId: ownerId,
      destination: destination,
      targetId: targetId,
      targetRevision: targetRevision,
    );
    final request = await requests.begin(
      organizationId: organizationId,
      ownerId: ownerId,
      destination: destination,
      targetId: targetId,
      targetRevision: targetRevision,
      source: source,
    );
    // This call is after the durable intent acknowledgment. Native errors keep
    // the request; an explicit native cancellation returns an empty result.
    final files = await _pick(request);
    if (files.isEmpty) {
      await _cancel(request, organizationId, ownerId);
      return null;
    }
    return _checkpointAndRetain(request, files);
  });

  Future<LocalMediaPickerRequest?> recover({
    required String organizationId,
    required String ownerId,
  }) => _actions.run(() async {
    final request = await requests.findFor(
      organizationId: organizationId,
      ownerId: ownerId,
    );
    // Never consume an unassociated native result or another actor's result.
    if (request == null) return null;
    await _authorize(request);
    if (request.retainedAttachmentIds != null) return _acknowledge(request);
    if (request.returnedFiles != null) return _retain(request);
    if (request.source == MediaPickerSource.files ||
        !gateway.supportsRecovery) {
      return request;
    }
    final native = gateway;
    final files = native is JournaledNativeMediaPickerGateway
        ? await native.recoverForRequest(request)
        : await native.recover();
    // Empty recovery does not prove cancellation: the external activity may
    // still be running, or its result may be unavailable. Preserve the intent.
    if (files.isEmpty) return request;
    return _checkpointAndRetain(request, files);
  });

  /// Explicit user retry only. FilePicker has no image-picker lost-result cache.
  /// Reopen against the same saved destination instead of creating another draft.
  Future<LocalMediaPickerRequest?> resumeFileSelection({
    required String organizationId,
    required String ownerId,
    required String requestId,
  }) => _actions.run(() async {
    final request = await requests.findFor(
      organizationId: organizationId,
      ownerId: ownerId,
    );
    if (request == null ||
        request.requestId != requestId ||
        request.source != MediaPickerSource.files) {
      throw StateError('The saved file selection is unavailable.');
    }
    await _authorize(request);
    if (request.retainedAttachmentIds != null) return _acknowledge(request);
    if (request.returnedFiles != null) return _retain(request);
    final files = await _pick(request);
    if (files.isEmpty) {
      await _cancel(request, organizationId, ownerId);
      return null;
    }
    return _checkpointAndRetain(request, files);
  });

  Future<LocalMediaPickerRequest> _checkpointAndRetain(
    LocalMediaPickerRequest request,
    List<MediaPickerReturnedFile> files,
  ) async {
    final received = await requests.recordReturnedFiles(
      request: request,
      organizationId: request.organizationId,
      ownerId: request.ownerId,
      files: files,
    );
    // Preserve returned sources before revalidation; revoked access prevents
    // copying/adoption but does not silently erase the already received result.
    await _authorize(received);
    return _retain(received);
  }

  Future<void> _authorize(LocalMediaPickerRequest request) => authorize(
    organizationId: request.organizationId,
    ownerId: request.ownerId,
    destination: request.destination,
    targetId: request.targetId,
    targetRevision: request.targetRevision,
  );

  /// Explicit selection discard; raw parent drafts and retained files are kept.
  /// Validate the exact SQL request before retiring its native replay identity.
  Future<void> discardSelection({
    required LocalMediaPickerRequest request,
    required String organizationId,
    required String ownerId,
  }) => _actions.run(() => _cancel(request, organizationId, ownerId));

  Future<void> _cancel(
    LocalMediaPickerRequest request,
    String organizationId,
    String ownerId,
  ) {
    final native = gateway;
    return requests.cancel(
      request: request,
      organizationId: organizationId,
      ownerId: ownerId,
      beforeCancel: native is JournaledNativeMediaPickerGateway
          ? () => native.abandonRequest(request)
          : null,
    );
  }

  Future<List<MediaPickerReturnedFile>> _pick(LocalMediaPickerRequest request) {
    final native = gateway;
    return native is JournaledNativeMediaPickerGateway
        ? native.pickForRequest(request)
        : native.pick(request.source, request.destination);
  }

  Future<LocalMediaPickerRequest> _retain(
    LocalMediaPickerRequest request,
  ) async {
    final retained = await retention.retain(
      requestId: request.requestId,
      organizationId: request.organizationId,
      ownerId: request.ownerId,
    );
    return _acknowledge(retained);
  }

  Future<LocalMediaPickerRequest> _acknowledge(
    LocalMediaPickerRequest request,
  ) async {
    final native = gateway;
    if (native is JournaledNativeMediaPickerGateway) {
      // Retention has verified/copy-flushed originals and committed attachment
      // identities. Failed acknowledgement leaves that SQL state recoverable;
      // the next recover retries acknowledgement without importing again.
      await native.acknowledgeRetained(request);
    }
    return request;
  }
}
