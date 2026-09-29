import '../prototype_financial_models.dart';
import 'models/work_models.dart';

/// A payment belongs to the exact invoice, including older entries that used
/// the displayed invoice number instead of its stable record ID.
bool paymentBelongsToInvoice(
  PrototypeFinancialEntry entry,
  WorkRecord invoice,
) =>
    (entry.kind == PrototypeFinancialKind.paymentReceived ||
        entry.kind == PrototypeFinancialKind.paymentApplied) &&
    entry.paymentLinkKind == PaymentLinkKind.invoice &&
    (entry.sourceId == invoice.id || entry.sourceId == invoice.number);

int invoicePaidCents(
  WorkRecord invoice,
  Iterable<PrototypeFinancialEntry> entries, {
  DateTime? before,
}) => entries
    .where(
      (entry) =>
          paymentBelongsToInvoice(entry, invoice) &&
          (before == null || entry.occurredOn.isBefore(before)),
    )
    .fold(0, (sum, entry) => sum + entry.amountCents);

int invoiceBalanceCents(
  WorkRecord invoice,
  Iterable<PrototypeFinancialEntry> entries, {
  DateTime? before,
}) {
  final total = (invoice.total * 100).round();
  return (total - invoicePaidCents(invoice, entries, before: before)).clamp(
    0,
    total,
  );
}
