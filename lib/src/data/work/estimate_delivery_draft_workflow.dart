import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'models/estimate_models.dart';
import 'models/work_contact_models.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';
import 'work_record_codec.dart';

String estimateDeliveryRecipient(
  WorkRecord base,
  EstimateDeliveryMethod method,
  Iterable<WorkCustomerProfile> customers,
) {
  WorkCustomerProfile? customer = base.customerSnapshot;
  for (final candidate in customers) {
    if (customer == null && candidate.name == base.client) customer = candidate;
  }
  return switch (method) {
    EstimateDeliveryMethod.email => customer?.email ?? '',
    EstimateDeliveryMethod.textMessage => customer?.phone ?? '',
    _ => base.client,
  };
}

class EstimateDeliveryInput {
  EstimateDeliveryInput({
    required this.base,
    required this.baseRevision,
    required this.method,
    required Map<String, String> recipients,
    required this.reviewed,
    this.preparedAt,
  }) : recipients = Map.unmodifiable(recipients);
  final WorkRecord base;
  final int baseRevision;
  final EstimateDeliveryMethod method;
  final Map<String, String> recipients;
  final bool reviewed;
  final DateTime? preparedAt;
  String get recipient => recipients[method.name]!;

  factory EstimateDeliveryInput.initial(
    WorkRecord base, {
    required int baseRevision,
    required Iterable<WorkCustomerProfile> customers,
  }) => EstimateDeliveryInput(
    base: base,
    baseRevision: baseRevision,
    method: EstimateDeliveryMethod.email,
    recipients: {
      'email': estimateDeliveryRecipient(
        base,
        EstimateDeliveryMethod.email,
        customers,
      ),
    },
    reviewed: false,
  );

  EstimateDeliveryInput withRecipient(String value) => EstimateDeliveryInput(
    base: base,
    baseRevision: baseRevision,
    method: method,
    recipients: {...recipients, method.name: value},
    reviewed: false,
  );
  EstimateDeliveryInput withMethod(
    EstimateDeliveryMethod value,
    String defaultRecipient,
  ) => EstimateDeliveryInput(
    base: base,
    baseRevision: baseRevision,
    method: value,
    recipients: {
      ...recipients,
      value.name: recipients[value.name] ?? defaultRecipient,
    },
    reviewed: false,
  );
  EstimateDeliveryInput withReviewed(bool value) => EstimateDeliveryInput(
    base: base,
    baseRevision: baseRevision,
    method: method,
    recipients: recipients,
    reviewed: value,
    preparedAt: preparedAt,
  );
  EstimateDeliveryInput prepare() {
    if (!reviewed) {
      throw StateError(
        'Review the customer copy and recipient before preparing delivery.',
      );
    }
    if (recipient.trim().isEmpty) {
      throw StateError('Enter or confirm the recipient.');
    }
    if (method == EstimateDeliveryMethod.inPerson) {
      throw StateError('Use the signature workflow for in-person approval.');
    }
    return EstimateDeliveryInput(
      base: base,
      baseRevision: baseRevision,
      method: method,
      recipients: recipients,
      reviewed: reviewed,
      preparedAt: preparedAt ?? DateTime.now().toUtc(),
    );
  }

  WorkRecord confirmedRecord() {
    if (!reviewed ||
        preparedAt == null ||
        recipient.trim().isEmpty ||
        method == EstimateDeliveryMethod.inPerson) {
      throw StateError('Delivery input is not ready for preparation.');
    }
    if (base.items.isEmpty ||
        base.client.trim().isEmpty ||
        base.client == 'Client not selected' ||
        base.title == 'Untitled estimate' ||
        base.detail == 'Proposed work not entered yet.') {
      throw StateError(
        'Add the customer, proposed work and items before sending.',
      );
    }
    final ready = base.resolvedEstimateStage == EstimateStage.draft
        ? base.withEstimateStage(EstimateStage.readyToSend, preparedAt!)
        : base;
    return ready.recordEstimateDelivery(
      method: method,
      recipient: recipient.trim(),
      occurredOn: preparedAt!,
      confirmedDelivered: false,
    );
  }

  Map<String, Object?> toPayload() => {
    'base': encodeWorkRecord(base),
    'baseRevision': baseRevision,
    'method': method.name,
    'recipients': recipients,
    'reviewed': reviewed,
    'preparedAt': preparedAt?.toIso8601String(),
  };
  factory EstimateDeliveryInput.fromPayload(
    Map<String, Object?> payload,
  ) => EstimateDeliveryInput(
    base: decodeWorkRecord((payload['base'] as Map).cast<String, Object?>()),
    baseRevision: payload['baseRevision'] as int,
    method: EstimateDeliveryMethod.values.byName(payload['method'] as String),
    recipients: (payload['recipients'] as Map).cast<String, String>(),
    reviewed: payload['reviewed'] as bool,
    preparedAt: payload['preparedAt'] == null
        ? null
        : DateTime.parse(payload['preparedAt'] as String),
  );
}

class EstimateDeliveryDraftController
    extends DraftWorkflowController<EstimateDeliveryInput> {
  EstimateDeliveryDraftController._(
    DraftAutosaveSession session,
    this._commit,
    this._defaults,
  ) : super(
        session,
        (input) => input.toPayload(),
        EstimateDeliveryInput.fromPayload,
      );
  final Future<WorkRecord?> Function(
    EstimateDeliveryInput,
    LocalDraftCheckpoint,
  )
  _commit;
  final Map<EstimateDeliveryMethod, String> _defaults;
  EstimateDeliveryInput get input => recoveredInput!;
  void updateRecipient(String value) => updateInput(input.withRecipient(value));
  void selectMethod(EstimateDeliveryMethod value) {
    if (value == EstimateDeliveryMethod.inPerson) {
      throw StateError('Use the signature workflow for in-person approval.');
    }
    updateInput(input.withMethod(value, _defaults[value]!));
  }

  void setReviewed(bool value) => updateInput(input.withReviewed(value));
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

extension EstimateDeliveryDraftWorkflow on WorkPersistenceSession {
  void validateEstimateDeliveryHandoff(
    EstimateDeliveryDraftController controller,
    String recordId,
  ) {
    final current = records
        .where((record) => record.id == recordId)
        .firstOrNull;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/estimate-delivery' ||
        controller.input.base.id != recordId ||
        current == null ||
        current.kind != WorkRecordKind.estimate ||
        !permissions.canEdit(current)) {
      throw StateError(
        'Selected estimate delivery belongs to another workflow.',
      );
    }
  }

  Future<EstimateDeliveryDraftController> openEstimateDeliveryDraft(
    String recordId, {
    required Iterable<WorkCustomerProfile> customers,
    DraftRecoverySelection? recoverySelection,
  }) async {
    final current = records.where((r) => r.id == recordId).firstOrNull;
    if (current == null ||
        current.kind != WorkRecordKind.estimate ||
        !permissions.canEdit(current)) {
      throw StateError('Estimate unavailable.');
    }
    final people = customers.toList();
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: 'work/estimate-delivery',
      draftId:
          recoverySelection?.draftId ??
          'edit-${permissions.actorEmployeeId}-$recordId',
      ownerId: permissions.actorEmployeeId,
    );
    void validate(EstimateDeliveryInput input) {
      if (input.base.id != recordId ||
          !permissions.canShareDocuments ||
          input.base.kind != WorkRecordKind.estimate ||
          input.base.createdByEmployeeId != current.createdByEmployeeId ||
          input.baseRevision < 1 ||
          !permissions.canEdit(input.base) ||
          input.method == EstimateDeliveryMethod.inPerson ||
          !input.recipients.containsKey(input.method.name) ||
          (input.preparedAt != null && !input.preparedAt!.isUtc)) {
        throw StateError('Delivery draft does not match this estimate.');
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
      final controller = EstimateDeliveryDraftController._(
        draft,
        (input, checkpoint) async {
          validate(input);
          final record = input.confirmedRecord();
          final saved = await save(
            records: [record],
            expectedStorageRevisions: {record.id: input.baseRevision},
            draftCheckpoint: checkpoint,
          );
          return saved ? record : null;
        },
        {
          for (final method in EstimateDeliveryMethod.values)
            method: estimateDeliveryRecipient(current, method, people),
        },
      );
      if (controller.recoveredInput == null) {
        controller.updateInput(
          EstimateDeliveryInput.initial(
            current,
            baseRevision: storageRevisionFor(recordId),
            customers: people,
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
