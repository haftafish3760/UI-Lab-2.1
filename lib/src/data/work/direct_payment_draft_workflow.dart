import '../expenses/expense_money.dart';
import '../prototype_financial_models.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_identity.dart';
import 'models/work_models.dart';
import 'invoice_payment_draft_workflow.dart';
import 'work_persistence_session.dart';

class DirectPaymentInputValidation implements Exception {
  const DirectPaymentInputValidation(this.message);
  final String message;
}

class DirectPaymentInput {
  const DirectPaymentInput({
    required this.paymentId,
    required this.amount,
    required this.method,
    required this.receivedOn,
    required this.payerName,
    required this.description,
    required this.note,
    required this.linkKind,
    required this.sourceId,
  });

  final String paymentId;
  final String amount;
  final String method;
  final DateTime receivedOn;
  final String payerName;
  final String description;
  final String note;
  final PaymentLinkKind linkKind;
  final String sourceId;

  factory DirectPaymentInput.initial({
    required DateTime day,
    WorkRecord? related,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(day.year, day.month, day.day);
    return DirectPaymentInput(
      paymentId: newLocalRecordIdentity('payment'),
      amount: '',
      method: 'Cash',
      receivedOn: selected.isAfter(today) ? today : selected,
      payerName: related?.client ?? '',
      description: related?.title ?? '',
      note: '',
      linkKind: switch (related?.kind) {
        WorkRecordKind.job => PaymentLinkKind.job,
        WorkRecordKind.estimate => PaymentLinkKind.estimate,
        _ => PaymentLinkKind.none,
      },
      sourceId: related?.id ?? '',
    );
  }

  DirectPaymentInput copyWith({
    String? amount,
    String? method,
    DateTime? receivedOn,
    String? payerName,
    String? description,
    String? note,
    PaymentLinkKind? linkKind,
    String? sourceId,
  }) => DirectPaymentInput(
    paymentId: paymentId,
    amount: amount ?? this.amount,
    method: method ?? this.method,
    receivedOn: receivedOn ?? this.receivedOn,
    payerName: payerName ?? this.payerName,
    description: description ?? this.description,
    note: note ?? this.note,
    linkKind: linkKind ?? this.linkKind,
    sourceId: sourceId ?? this.sourceId,
  );

  Map<String, Object?> toPayload() => {
    'paymentId': paymentId,
    'amount': amount,
    'method': method,
    'receivedOn': receivedOn.toIso8601String(),
    'payerName': payerName,
    'description': description,
    'note': note,
    'linkKind': linkKind.name,
    'sourceId': sourceId,
  };

  factory DirectPaymentInput.fromPayload(Map<String, Object?> payload) =>
      DirectPaymentInput(
        paymentId: payload['paymentId'] as String,
        amount: payload['amount'] as String,
        method: payload['method'] as String,
        receivedOn: DateTime.parse(payload['receivedOn'] as String),
        payerName: payload['payerName'] as String,
        description: payload['description'] as String,
        note: payload['note'] as String,
        linkKind: PaymentLinkKind.values.byName(payload['linkKind'] as String),
        sourceId: payload['sourceId'] as String,
      );

  PrototypeFinancialEntry confirmedPayment() {
    final today = DateTime.now();
    if (DateTime(
      receivedOn.year,
      receivedOn.month,
      receivedOn.day,
    ).isAfter(DateTime(today.year, today.month, today.day))) {
      throw const DirectPaymentInputValidation(
        'Choose today or an earlier date for money already received.',
      );
    }
    if (amount.trim().isEmpty) {
      throw const DirectPaymentInputValidation(
        'Enter the amount actually received.',
      );
    }
    int cents;
    try {
      cents = ExpenseMoney.fromDecimalString(amount).minorUnits;
    } on FormatException {
      throw const DirectPaymentInputValidation(
        'Enter a valid amount with no more than two decimal places.',
      );
    }
    if (cents <= 0) {
      throw const DirectPaymentInputValidation(
        'Enter the amount actually received.',
      );
    }
    if (description.trim().isEmpty) {
      throw const DirectPaymentInputValidation('Describe this payment.');
    }
    if (!InvoicePaymentInput.paymentMethods.contains(method)) {
      throw const DirectPaymentInputValidation('Choose a payment method.');
    }
    if (linkKind == PaymentLinkKind.invoice ||
        linkKind == PaymentLinkKind.quote ||
        (linkKind == PaymentLinkKind.none && sourceId.isNotEmpty) ||
        (linkKind != PaymentLinkKind.none && sourceId.isEmpty)) {
      throw const DirectPaymentInputValidation('Choose a valid payment link.');
    }
    return PrototypeFinancialEntry(
      id: paymentId,
      kind: PrototypeFinancialKind.paymentReceived,
      occurredOn: receivedOn,
      amountCents: cents,
      sourceId: sourceId,
      paymentLinkKind: linkKind,
      payerName: payerName.trim(),
      description: description.trim(),
      paymentMethod: method,
      note: note.trim(),
    );
  }
}

class DirectPaymentDraftController
    extends DraftWorkflowController<DirectPaymentInput> {
  DirectPaymentDraftController._(
    DraftAutosaveSession session,
    this._initialInput,
    this._commit,
  ) : super(
        session,
        (input) => input.toPayload(),
        DirectPaymentInput.fromPayload,
      );

  final Future<PrototypeFinancialEntry?> Function(
    DirectPaymentInput,
    LocalDraftCheckpoint,
  )
  _commit;
  final DirectPaymentInput _initialInput;

  DirectPaymentInput get input => recoveredInput ?? _initialInput;

  Future<PrototypeFinancialEntry?> confirm() async {
    input.confirmedPayment();
    PrototypeFinancialEntry? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension DirectPaymentDraftWorkflow on WorkPersistenceSession {
  void validateDirectPaymentHandoff(DirectPaymentDraftController controller) {
    final input = controller.input;
    final related = records
        .where((record) => record.id == input.sourceId)
        .firstOrNull;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/direct-payment-editor' ||
        !permissions.canRecordPayments ||
        (input.linkKind != PaymentLinkKind.none &&
            (related == null ||
                (input.linkKind == PaymentLinkKind.job &&
                    related.kind != WorkRecordKind.job) ||
                (input.linkKind == PaymentLinkKind.estimate &&
                    related.kind != WorkRecordKind.estimate) ||
                !permissions.visibleCreatorIds.contains(
                  related.createdByEmployeeId,
                ))) ||
        (input.linkKind == PaymentLinkKind.none && input.sourceId.isNotEmpty) ||
        input.linkKind == PaymentLinkKind.invoice ||
        input.linkKind == PaymentLinkKind.quote) {
      throw const DirectPaymentInputValidation(
        'The selected payment is unavailable in this workflow.',
      );
    }
  }

  Future<DirectPaymentDraftController> openDirectPaymentDraft({
    required DateTime initialDay,
    WorkRecord? related,
    DraftRecoverySelection? recoverySelection,
  }) async {
    requireActiveDraftOwner();
    if (!permissions.canRecordPayments) {
      throw const DirectPaymentInputValidation('You cannot record payments.');
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: 'work/direct-payment-editor',
      draftId:
          recoverySelection?.draftId ?? newLocalRecordIdentity('payment-draft'),
      ownerId: permissions.actorEmployeeId,
    );
    try {
      await draft.initialize();
      requireActiveDraftOwner();
      recoverySelection?.verify(
        openedDomain: draft.domain,
        openedDraftId: draft.draftId,
        openedRevision: draft.savedRevision,
        hasInput: draft.input.isNotEmpty,
      );
      return DirectPaymentDraftController._(
        draft,
        DirectPaymentInput.initial(day: initialDay, related: related),
        (input, checkpoint) async {
          final payment = input.confirmedPayment();
          final saved = await save(
            financialEntries: [payment],
            draftCheckpoint: checkpoint,
          );
          return saved ? payment : null;
        },
      );
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
