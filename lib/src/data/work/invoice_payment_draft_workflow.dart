import '../storage/draft_recovery_selection.dart';
import '../expenses/expense_money.dart';
import '../prototype_financial_models.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_identity.dart';
import 'models/work_models.dart';
import 'invoice_payment_balance.dart';
import 'work_persistence_session.dart';

class InvoicePaymentInputValidation implements Exception {
  const InvoicePaymentInputValidation(this.message);
  final String message;
}

class InvoicePaymentInput {
  const InvoicePaymentInput({
    required this.invoiceId,
    required this.paymentId,
    required this.amount,
    required this.note,
    required this.method,
    required this.receivedOn,
  });
  final String invoiceId;
  final String paymentId;
  final String amount;
  final String note;
  final String method;
  final DateTime receivedOn;

  factory InvoicePaymentInput.initial({
    required String invoiceId,
    required int balanceCents,
    required DateTime day,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(day.year, day.month, day.day);
    return InvoicePaymentInput(
      invoiceId: invoiceId,
      paymentId: newLocalRecordIdentity('payment'),
      amount: (balanceCents / 100).toStringAsFixed(2),
      note: '',
      method: 'Card',
      receivedOn: selected.isAfter(today) ? today : selected,
    );
  }

  InvoicePaymentInput withValues({
    required String amount,
    required String note,
    required String method,
    required DateTime receivedOn,
  }) => InvoicePaymentInput(
    invoiceId: invoiceId,
    paymentId: paymentId,
    amount: amount,
    note: note,
    method: method,
    receivedOn: receivedOn,
  );
  Map<String, Object?> toPayload() => {
    'invoiceId': invoiceId,
    'paymentId': paymentId,
    'amount': amount,
    'note': note,
    'method': method,
    'receivedOn': receivedOn.toIso8601String(),
  };
  factory InvoicePaymentInput.fromPayload(Map<String, Object?> payload) =>
      InvoicePaymentInput(
        invoiceId: payload['invoiceId'] as String,
        paymentId: payload['paymentId'] as String,
        amount: payload['amount'] as String,
        note: payload['note'] as String,
        method: payload['method'] as String,
        receivedOn: DateTime.parse(payload['receivedOn'] as String),
      );

  PrototypeFinancialEntry confirmedPayment({
    required WorkRecord invoice,
    required int balanceCents,
  }) {
    final today = DateTime.now();
    if (DateTime(
      receivedOn.year,
      receivedOn.month,
      receivedOn.day,
    ).isAfter(DateTime(today.year, today.month, today.day))) {
      throw const InvoicePaymentInputValidation(
        'Choose today or an earlier date for money already received.',
      );
    }
    if (invoice.id != invoiceId ||
        invoice.kind != WorkRecordKind.invoice ||
        paymentId.isEmpty ||
        !paymentMethods.contains(method)) {
      throw StateError('Payment recovery identity is inconsistent.');
    }
    int cents;
    try {
      cents = ExpenseMoney.fromDecimalString(amount).minorUnits;
    } on FormatException {
      throw const InvoicePaymentInputValidation(
        'Enter a valid amount with no more than two decimal places.',
      );
    }
    if (cents <= 0) {
      throw const InvoicePaymentInputValidation(
        'Enter the amount actually received.',
      );
    }
    if (cents > balanceCents) {
      throw const InvoicePaymentInputValidation(
        'This payment is larger than the remaining invoice balance.',
      );
    }
    return PrototypeFinancialEntry(
      id: paymentId,
      kind: PrototypeFinancialKind.paymentReceived,
      occurredOn: receivedOn,
      amountCents: cents,
      sourceId: invoice.number,
      paymentMethod: method,
      note: note.trim(),
    );
  }

  static const paymentMethods = {
    'Card',
    'Check',
    'Cash',
    'Bank transfer',
    'Other',
  };
}

class InvoicePaymentDraftController
    extends DraftWorkflowController<InvoicePaymentInput> {
  InvoicePaymentDraftController._(
    DraftAutosaveSession session,
    this._commit,
    this._balance,
  ) : super(
        session,
        (input) => input.toPayload(),
        InvoicePaymentInput.fromPayload,
      );
  final Future<PrototypeFinancialEntry?> Function(
    InvoicePaymentInput,
    LocalDraftCheckpoint,
  )
  _commit;
  final int Function() _balance;
  InvoicePaymentInput get input => recoveredInput!;
  int get balanceCents {
    try {
      return _balance();
    } on InvoicePaymentInputValidation {
      return 0;
    }
  }

  Future<PrototypeFinancialEntry?> confirm() async {
    PrototypeFinancialEntry? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension InvoicePaymentDraftWorkflow on WorkPersistenceSession {
  void validateInvoicePaymentHandoff(
    InvoicePaymentDraftController controller, {
    required String invoiceId,
  }) {
    final current = records
        .where((record) => record.id == invoiceId)
        .firstOrNull;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/payment-editor' ||
        controller.input.invoiceId != invoiceId ||
        !permissions.canRecordPayments ||
        current == null ||
        current.kind != WorkRecordKind.invoice ||
        current.status == WorkRecordStatus.draft ||
        !permissions.visibleCreatorIds.contains(current.createdByEmployeeId)) {
      throw const InvoicePaymentInputValidation(
        'The selected payment is unavailable in this workflow.',
      );
    }
  }

  Future<InvoicePaymentDraftController> openInvoicePaymentDraft({
    required String invoiceId,
    required DateTime initialDay,
    DraftRecoverySelection? recoverySelection,
  }) async {
    WorkRecord invoice() {
      final current = records
          .where((record) => record.id == invoiceId)
          .firstOrNull;
      if (!permissions.canRecordPayments ||
          current == null ||
          current.kind != WorkRecordKind.invoice ||
          current.status == WorkRecordStatus.draft ||
          !permissions.visibleCreatorIds.contains(
            current.createdByEmployeeId,
          )) {
        throw const InvoicePaymentInputValidation(
          'You cannot record a payment for this invoice.',
        );
      }
      return current;
    }

    int balance() {
      final current = invoice();
      return invoiceBalanceCents(current, financialEntries);
    }

    final initialBalance = balance();
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: 'work/payment-editor',
      draftId:
          recoverySelection?.draftId ??
          'payment-${permissions.actorEmployeeId}-$invoiceId',
      ownerId: permissions.actorEmployeeId,
    );
    void validate(InvoicePaymentInput input) {
      if (input.invoiceId != invoiceId ||
          input.paymentId.isEmpty ||
          !InvoicePaymentInput.paymentMethods.contains(input.method)) {
        throw StateError('Payment recovery identity is inconsistent.');
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
      final controller = InvoicePaymentDraftController._(draft, (
        input,
        checkpoint,
      ) async {
        validate(input);
        final payment = input.confirmedPayment(
          invoice: invoice(),
          balanceCents: balance(),
        );
        final saved = await save(
          financialEntries: [payment],
          draftCheckpoint: checkpoint,
        );
        return saved ? payment : null;
      }, balance);
      if (controller.recoveredInput == null) {
        controller.updateInput(
          InvoicePaymentInput.initial(
            invoiceId: invoiceId,
            balanceCents: initialBalance,
            day: initialDay,
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
