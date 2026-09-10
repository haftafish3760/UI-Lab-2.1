import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/local_record_identity.dart';
import 'customer_confirmation.dart';
import 'customer_draft_controller.dart';
import 'directory_persistence_session.dart';

extension CustomerDraftWorkflow on DirectoryPersistenceSession {
  Future<CustomerDraftController> openCustomerDraft({
    String? existingCustomerId,
    String? recoveryDraftId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    if (!permissions.canViewCustomers || !permissions.canManageCustomers) {
      throw StateError('Client editing is unavailable.');
    }
    if (existingCustomerId != null &&
        !customers.any((c) => c.id == existingCustomerId)) {
      throw StateError('Client record is unavailable.');
    }
    if (existingCustomerId != null && recoveryDraftId != null) {
      throw ArgumentError('Client edit recovery uses its record identity.');
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      domain: 'directory/customer-editor',
      draftId:
          recoverySelection?.draftId ??
          (existingCustomerId == null
              ? recoveryDraftId ?? newLocalRecordIdentity('customer-input')
              : 'edit-${permissions.actorEmployeeId}-$existingCustomerId'),
    );
    void validateIdentity(CustomerDraftInput input) {
      if (input.customerId.isEmpty ||
          input.baseRevision < 0 ||
          input.existingCustomer?.id != existingCustomerId ||
          (existingCustomerId != null &&
              input.customerId != existingCustomerId)) {
        throw StateError('Client recovery identity is inconsistent.');
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
      final controller = CustomerDraftController(
        draft,
        confirm: (input, checkpoint) async {
          validateIdentity(input);
          final customer = buildConfirmedCustomer(input);
          final saved = await saveCustomer(
            customer,
            expectedRevision: input.baseRevision,
            draftCheckpoint: checkpoint,
          );
          return saved ? customer : null;
        },
      );
      final input = controller.recoveredInput;
      if (recoveryDraftId != null && input == null) {
        throw StateError('Selected client recovery is unavailable.');
      }
      if (input != null) validateIdentity(input);
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
