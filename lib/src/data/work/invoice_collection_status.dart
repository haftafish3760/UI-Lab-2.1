import '../prototype_financial_models.dart';
import 'invoice_payment_balance.dart';
import 'models/work_models.dart';

enum InvoiceCollectionStatus {
  draft,
  unpaid,
  partiallyPaid,
  overdue,
  overduePartiallyPaid,
  paid;

  bool get isOverdue => this == overdue || this == overduePartiallyPaid;
  bool get isPartial => this == partiallyPaid || this == overduePartiallyPaid;
}

/// Read-only projection from the authorized ledger, not a status mutation.
/// Retains explicit legacy Paid records; drafts never become issued by a date.
InvoiceCollectionStatus invoiceCollectionStatus(
  WorkRecord invoice,
  Iterable<PrototypeFinancialEntry> payments, {
  required DateTime now,
}) {
  if (invoice.status == WorkRecordStatus.draft) {
    return InvoiceCollectionStatus.draft;
  }
  final balance = invoiceBalanceCents(invoice, payments);
  if (invoice.status == WorkRecordStatus.paid ||
      (invoice.total > 0 && balance == 0)) {
    return InvoiceCollectionStatus.paid;
  }
  final due = invoice.dueOn;
  final overdue =
      balance > 0 &&
      due != null &&
      DateTime(
        due.year,
        due.month,
        due.day,
      ).isBefore(DateTime(now.year, now.month, now.day));
  final partial = balance > 0 && invoicePaidCents(invoice, payments) > 0;
  if (overdue) {
    return partial
        ? InvoiceCollectionStatus.overduePartiallyPaid
        : InvoiceCollectionStatus.overdue;
  }
  return partial
      ? InvoiceCollectionStatus.partiallyPaid
      : InvoiceCollectionStatus.unpaid;
}
