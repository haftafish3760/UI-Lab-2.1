import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';
import 'work_record_codec.dart';

class EstimateSignatureInput {
  const EstimateSignatureInput({
    required this.base,
    required this.baseRevision,
    required this.name,
    required this.ink,
    this.accepted = false,
    this.forBusiness = false,
    this.confirmedAt,
  });
  final WorkRecord base;
  final int baseRevision;
  final String name;
  final SignatureInk ink;
  final bool accepted;
  final bool forBusiness;
  final DateTime? confirmedAt;

  EstimateSignatureInput withName(String value) => EstimateSignatureInput(
    base: base,
    forBusiness: forBusiness,
    baseRevision: baseRevision,
    name: value,
    ink: ink,
  );
  EstimateSignatureInput withInk(SignatureInk value) => EstimateSignatureInput(
    base: base,
    forBusiness: forBusiness,
    baseRevision: baseRevision,
    name: name,
    ink: value,
  );
  EstimateSignatureInput withAcceptance(bool value) => EstimateSignatureInput(
    base: base,
    forBusiness: forBusiness,
    baseRevision: baseRevision,
    name: name,
    ink: ink,
    accepted: value,
  );
  EstimateSignatureInput prepare() {
    if (name.trim().isEmpty) throw StateError('Enter the customer name.');
    if (!accepted || !ink.hasInk) {
      throw StateError('Sign and accept the estimate before saving approval.');
    }
    return EstimateSignatureInput(
      base: base,
      forBusiness: forBusiness,
      baseRevision: baseRevision,
      name: name,
      ink: ink,
      accepted: accepted,
      confirmedAt: confirmedAt ?? DateTime.now().toUtc(),
    );
  }

  WorkRecord confirmedRecord() {
    if (!accepted ||
        !ink.hasInk ||
        name.trim().isEmpty ||
        confirmedAt == null) {
      throw StateError('Signature input is not ready for approval.');
    }
    if (forBusiness) {
      return base.copyWith(
        businessSignature: WorkCustomerSignature(
          signedBy: name.trim(),
          signedOn: confirmedAt!,
          signedRevision: base.revision,
          ink: ink,
        ),
      );
    }
    return base.recordEstimateSignature(name.trim(), confirmedAt!, ink: ink);
  }

  Map<String, Object?> toPayload() => {
    'base': encodeWorkRecord(base),
    'baseRevision': baseRevision,
    'name': name,
    'accepted': accepted,
    'forBusiness': forBusiness,
    'ink': ink.toJson(),
    'confirmedAt': confirmedAt?.toIso8601String(),
  };
  factory EstimateSignatureInput.fromPayload(
    Map<String, Object?> payload,
  ) => EstimateSignatureInput(
    base: decodeWorkRecord((payload['base'] as Map).cast<String, Object?>()),
    baseRevision: payload['baseRevision'] as int,
    name: payload['name'] as String,
    accepted: payload['accepted'] as bool,
    forBusiness: payload['forBusiness'] as bool? ?? false,
    ink: SignatureInk.fromJson((payload['ink'] as Map).cast<String, Object?>()),
    confirmedAt: payload['confirmedAt'] == null
        ? null
        : DateTime.parse(payload['confirmedAt'] as String),
  );
}

class EstimateSignatureDraftController
    extends DraftWorkflowController<EstimateSignatureInput> {
  EstimateSignatureDraftController._(DraftAutosaveSession session, this._commit)
    : super(
        session,
        (input) => input.toPayload(),
        EstimateSignatureInput.fromPayload,
      );
  final Future<WorkRecord?> Function(
    EstimateSignatureInput,
    LocalDraftCheckpoint,
  )
  _commit;
  EstimateSignatureInput get input => recoveredInput!;
  void updateName(String value) => updateInput(input.withName(value));
  void updateInk(SignatureInk value) => updateInput(input.withInk(value));
  void setAccepted(bool value) => updateInput(input.withAcceptance(value));
  Future<WorkRecord?> confirm() async {
    updateInput(input.prepare());
    WorkRecord? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension EstimateSignatureDraftWorkflow on WorkPersistenceSession {
  void validateEstimateSignatureHandoff(
    EstimateSignatureDraftController controller,
    String recordId,
  ) {
    final current = records
        .where((record) => record.id == recordId)
        .firstOrNull;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/estimate-signature' ||
        controller.input.base.id != recordId ||
        current == null ||
        current.kind != WorkRecordKind.estimate ||
        !permissions.canEdit(current) ||
        (!controller.input.forBusiness && !permissions.canCollectSignature)) {
      throw StateError(
        'Selected estimate signature belongs to another workflow.',
      );
    }
  }

  Future<EstimateSignatureDraftController> openEstimateSignatureDraft(
    String recordId, {
    DraftRecoverySelection? recoverySelection,
    bool forBusiness = false,
  }) async {
    final current = records.where((r) => r.id == recordId).firstOrNull;
    if (current == null ||
        current.kind != WorkRecordKind.estimate ||
        !permissions.canEdit(current) ||
        (!forBusiness && !permissions.canCollectSignature)) {
      throw StateError('Estimate unavailable.');
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: 'work/estimate-signature',
      draftId:
          recoverySelection?.draftId ??
          '${forBusiness ? 'business' : 'edit'}-${permissions.actorEmployeeId}-$recordId',
      ownerId: permissions.actorEmployeeId,
    );
    void validate(EstimateSignatureInput input) {
      if (input.base.id != recordId ||
          input.base.kind != WorkRecordKind.estimate ||
          input.base.createdByEmployeeId != current.createdByEmployeeId ||
          input.baseRevision < 1 ||
          !permissions.canEdit(input.base) ||
          (!input.forBusiness && !permissions.canCollectSignature) ||
          (input.confirmedAt != null && !input.confirmedAt!.isUtc)) {
        throw StateError('Signature draft belongs to a different estimate.');
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
      final controller = EstimateSignatureDraftController._(draft, (
        input,
        checkpoint,
      ) async {
        validate(input);
        final record = input.confirmedRecord();
        final saved = await save(
          records: [record],
          expectedStorageRevisions: {record.id: input.baseRevision},
          draftCheckpoint: checkpoint,
        );
        return saved ? record : null;
      });
      if (controller.recoveredInput == null) {
        controller.updateInput(
          EstimateSignatureInput(
            base: current,
            baseRevision: storageRevisionFor(recordId),
            name: forBusiness ? '' : current.client,
            forBusiness: forBusiness,
            ink: SignatureInk(const []),
          ),
        );
      } else {
        validate(controller.input);
      }
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
