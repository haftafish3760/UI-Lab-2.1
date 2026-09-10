import 'package:flutter/foundation.dart';

import '../storage/local_media_picker_request.dart';
import '../storage/native_media_picker_coordinator.dart';
import '../storage/serialized_async_actions.dart';
import 'atomic_receipt_media_adoption.dart';
import 'authorized_receipt_draft_service.dart';
import 'local_receipt_draft_repository.dart';
import 'receipt_draft_record.dart';
import 'receipt_draft_repository.dart';
import 'receipt_draft_ui_controller.dart';

/// App-owned receipt capture and retry. Startup retains recovered originals;
/// adoption occurs on the owning receipt, never on an unrelated open editor.
class ReceiptMediaSession extends ChangeNotifier {
  ReceiptMediaSession({
    required this.coordinator,
    required this.repository,
    required this.receipts,
    required this.permissions,
  });

  final LocalReceiptDraftRepository repository;
  final ReceiptDraftUiController receipts;
  final ReceiptDraftCommandPermissions permissions;
  final NativeMediaPickerCoordinator coordinator;
  final _actions = SerializedAsyncActions();

  /// An external native picker must settle before its database can close.
  Future<AsyncActionPause> pauseOperations() => _actions.pauseAndDrain();
  LocalMediaPickerRequest? pending;
  String? failure;
  bool busy = false;
  bool _disposed = false;

  Future<T> _run<T>(Future<T> Function() action) => _actions.run(() async {
    busy = true;
    failure = null;
    _notify();
    try {
      return await action();
    } catch (_) {
      failure =
          'The selected evidence could not be attached. Your saved receipt is still available. Retry to recover the selection.';
      rethrow;
    } finally {
      try {
        pending = await coordinator.requests.findFor(
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
        );
      } catch (_) {
        failure =
            'The saved photo selection could not be read. Retry when local storage is available.';
      }
      busy = false;
      _notify();
    }
  });

  /// Plugin/recovery failure must not prevent opening the local application.
  Future<void> recoverAtStartup() async {
    try {
      await _run(
        () => coordinator.recover(
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
        ),
      );
    } catch (_) {
      // Visible session failure and durable request preserve the retry path.
    }
  }

  Future<StoredReceiptDraft?> pick({
    required String receiptId,
    required int revision,
    required MediaPickerSource source,
  }) => _run(() async {
    final request = await coordinator.start(
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      destination: MediaPickerDestination.receipt,
      targetId: receiptId,
      targetRevision: revision,
      source: source,
    );
    return request == null ? null : _adopt(request);
  });

  Future<StoredReceiptDraft?> retry(String receiptId) => _run(() async {
    final existing = await coordinator.requests.findFor(
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
    );
    if (existing == null) return null;
    if (existing.targetId != receiptId ||
        existing.destination != MediaPickerDestination.receipt) {
      throw const ReceiptDraftPermissionDeniedException(
        'Open the original receipt to recover its photos.',
      );
    }
    final recovered =
        existing.source == MediaPickerSource.files &&
            existing.returnedFiles == null
        ? await coordinator.resumeFileSelection(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
            requestId: existing.requestId,
          )
        : await coordinator.recover(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
          );
    if (recovered?.retainedAttachmentIds == null) return null;
    return _adopt(recovered!);
  });

  Future<StoredReceiptDraft> _adopt(LocalMediaPickerRequest request) async {
    final result = await AtomicReceiptMediaAdoption(repository).adopt(
      request: request,
      permissions: permissions,
      occurredAtUtc: DateTime.now().toUtc(),
    );
    await receipts.load();
    return result;
  }

  Future<void> discardSelection(LocalMediaPickerRequest request) =>
      _run(() async {
        await coordinator.discardSelection(
          request: request,
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
        );
      });

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
