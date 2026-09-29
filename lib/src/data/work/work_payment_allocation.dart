import '../prototype_financial_models.dart';
import 'models/work_models.dart';

/// A prior payment can fund an invoice only when the saved document lineage
/// identifies the same work. Name similarity alone is never enough.
bool paymentMayFundInvoice(
  PrototypeFinancialEntry payment,
  WorkRecord invoice,
  Iterable<WorkRecord> visibleRecords,
) {
  if (payment.kind != PrototypeFinancialKind.paymentReceived ||
      invoice.kind != WorkRecordKind.invoice ||
      invoice.sourceId == null) {
    return false;
  }
  if (payment.paymentLinkKind == PaymentLinkKind.job) {
    return invoice.sourceId == payment.sourceId;
  }
  if (payment.paymentLinkKind != PaymentLinkKind.estimate) return false;
  if (invoice.sourceId == payment.sourceId) return true;
  final job = visibleRecords
      .where((record) => record.id == invoice.sourceId)
      .firstOrNull;
  return job?.kind == WorkRecordKind.job && job?.sourceId == payment.sourceId;
}

int unappliedPaymentCents(
  PrototypeFinancialEntry payment,
  Iterable<PrototypeFinancialEntry> ledger,
) {
  final used = ledger
      .where(
        (entry) =>
            entry.kind == PrototypeFinancialKind.paymentApplied &&
            entry.sourcePaymentId == payment.id,
      )
      .fold(0, (sum, entry) => sum + entry.amountCents);
  return (payment.amountCents - used).clamp(0, payment.amountCents);
}
