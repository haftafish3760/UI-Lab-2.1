import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/invoice_payment_draft_workflow.dart';
import 'invoice_payment_entry_screen.dart';

/// Routes selected payment input without seeding a new draft or posting payment.
Future<void> openInvoicePaymentRecovery(
  BuildContext context,
  InvoicePaymentDraftController workflow,
) async {
  try {
    if (!context.mounted) return;
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null) throw StateError('Payment recovery is unavailable.');
    final input = workflow.input;
    work.validateInvoicePaymentHandoff(workflow, invoiceId: input.invoiceId);
    final invoice = work.records.firstWhere(
      (record) => record.id == input.invoiceId,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => InvoicePaymentEntryScreen(
          invoice: invoice,
          balanceCents: workflow.balanceCents,
          initialDay: input.receivedOn,
          recoveredWorkflow: workflow,
        ),
      ),
    );
  } finally {
    await workflow.session.close();
  }
}
