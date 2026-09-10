import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_recovery_query.dart';
import '../storage/local_record_identity.dart';
import 'invoice_confirmation.dart';
import 'invoice_draft_controller.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';

extension InvoiceDraftWorkflow on WorkPersistenceSession {
  /// Checks domain and current access before transferring a selected workflow.
  void validateInvoiceHandoff(
    InvoiceDraftController controller, {
    String? existingRecordId,
  }) {
    final input = controller.recoveredInput;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/invoice-editor' ||
        input == null ||
        input.existingRecordId != existingRecordId) {
      throw StateError('Selected invoice belongs to another workflow.');
    }
    if (!permissions.editableKinds.contains(WorkRecordKind.invoice) ||
        !permissions.visibleCreatorIds.contains(input.creatorId) ||
        (input.creatorId != permissions.actorEmployeeId &&
            !permissions.canManageOtherCreators)) {
      throw StateError('Invoice editing is unavailable.');
    }
    if (existingRecordId != null) {
      final record = records.where((r) => r.id == existingRecordId).firstOrNull;
      if (record == null ||
          record.kind != WorkRecordKind.invoice ||
          !permissions.canEdit(record)) {
        throw StateError('Invoice record is unavailable.');
      }
    }
  }

  DraftRecoveryQuery get invoiceDraftRecovery =>
      recoveryFor(WorkRecordKind.invoice);

  Future<InvoiceDraftController> openInvoiceDraft({
    String? existingRecordId,
    String? recoveryDraftId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    if (!permissions.editableKinds.contains(WorkRecordKind.invoice)) {
      throw StateError('Invoice editing is unavailable.');
    }
    final existing = existingRecordId == null
        ? null
        : records.where((r) => r.id == existingRecordId).firstOrNull;
    if (existingRecordId != null &&
        (existing == null ||
            existing.kind != WorkRecordKind.invoice ||
            !permissions.canEdit(existing))) {
      throw StateError('Invoice record is unavailable.');
    }
    if (existingRecordId != null && recoveryDraftId != null) {
      throw ArgumentError(
        'Existing invoice recovery uses its record identity.',
      );
    }
    final repository = drafts;
    const domain = 'work/invoice-editor';
    var id = existingRecordId == null
        ? recoveryDraftId ?? newLocalRecordIdentity('invoice-input')
        : 'edit-${permissions.actorEmployeeId}-$existingRecordId';
    if (existingRecordId != null) {
      final legacy = await repository.find(
        organizationId: permissions.organizationId,
        domain: domain,
        draftId: 'edit-$existingRecordId',
        ownerId: permissions.actorEmployeeId,
      );
      if (legacy != null) id = legacy.draftId;
    }
    final draft = DraftAutosaveSession(
      store: repository,
      organizationId: permissions.organizationId,
      domain: domain,
      draftId: recoverySelection?.draftId ?? id,
      ownerId: permissions.actorEmployeeId,
    );
    void validateIdentity(InvoiceDraftInput input) {
      if (input.recordId.isEmpty ||
          input.baseStorageRevision < 0 ||
          input.existingRecordId != existingRecordId ||
          (existingRecordId != null && input.recordId != existingRecordId)) {
        throw StateError('Invoice recovery identity is inconsistent.');
      }
    }

    try {
      await draft.initialize();
      requireActiveDraftOwner();
      recoverySelection?.verify(
        openedDomain: draft.domain,
        openedDraftId: draft.draftId,
        openedRevision: draft.savedRevision,
        hasInput: draft.input.isNotEmpty,
      );
      final controller = InvoiceDraftController(
        draft,
        confirm: (input, checkpoint) async {
          validateIdentity(input);
          final record = buildConfirmedInvoice(input, existing: existing);
          final saved = await save(
            records: [record],
            expectedStorageRevisions: {record.id: input.baseStorageRevision},
            draftCheckpoint: checkpoint,
          );
          return saved ? record : null;
        },
      );
      final recovered = controller.recoveredInput;
      if (recoveryDraftId != null && recovered == null) {
        throw StateError('Selected invoice recovery is unavailable.');
      }
      if (recovered != null) validateIdentity(recovered);
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
