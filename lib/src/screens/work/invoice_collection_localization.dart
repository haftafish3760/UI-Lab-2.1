import '../../../l10n/app_localizations.dart';
import '../../data/work/invoice_collection_status.dart';

extension InvoiceCollectionLocalization on InvoiceCollectionStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    InvoiceCollectionStatus.draft => l10n.workStatusDraft,
    InvoiceCollectionStatus.unpaid => l10n.workMoneyUnpaid,
    InvoiceCollectionStatus.partiallyPaid => l10n.workPartiallyPaid,
    InvoiceCollectionStatus.overdue => l10n.workMoneyOverdue,
    InvoiceCollectionStatus.overduePartiallyPaid =>
      '${l10n.workMoneyOverdue} · ${l10n.workPartiallyPaid}',
    InvoiceCollectionStatus.paid => l10n.workMoneyPaid,
  };
}
