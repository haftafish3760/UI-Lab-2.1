import '../prototype_financial_models.dart';
import 'invoice_payment_balance.dart';
import 'models/work_models.dart';

enum InvoiceDateActivity {
  created,
  issued,
  due,
  paymentReceived,
  paymentApplied,
}

/// A dated index of one visible invoice. Callers must supply only ledger data
/// the actor may read. Multiple events never duplicate the invoice in a list.
Set<InvoiceDateActivity> invoiceDateActivity(
  WorkRecord invoice,
  DateTime day,
  Iterable<PrototypeFinancialEntry> authorizedPayments,
) {
  if (invoice.kind != WorkRecordKind.invoice ||
      invoice.status == WorkRecordStatus.draft) {
    return const {};
  }
  bool matches(DateTime? value) =>
      value != null &&
      value.year == day.year &&
      value.month == day.month &&
      value.day == day.day;
  return {
    if (matches(invoice.createdOn) && !matches(invoice.issuedOn))
      InvoiceDateActivity.created,
    if (matches(invoice.issuedOn)) InvoiceDateActivity.issued,
    if (invoice.status != WorkRecordStatus.paid && matches(invoice.dueOn))
      InvoiceDateActivity.due,
    for (final entry in authorizedPayments)
      if (matches(entry.occurredOn) && paymentBelongsToInvoice(entry, invoice))
        entry.kind == PrototypeFinancialKind.paymentApplied
            ? InvoiceDateActivity.paymentApplied
            : InvoiceDateActivity.paymentReceived,
  };
}
