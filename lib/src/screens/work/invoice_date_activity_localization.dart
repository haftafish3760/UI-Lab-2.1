import '../../../l10n/app_localizations.dart';
import '../../data/work/invoice_date_activity.dart';

extension InvoiceDateActivityLocalization on InvoiceDateActivity {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    InvoiceDateActivity.created => l10n.workInvoiceActivityCreated,
    InvoiceDateActivity.issued => l10n.workInvoiceActivityIssued,
    InvoiceDateActivity.due => l10n.workInvoiceActivityDue,
    InvoiceDateActivity.paymentReceived => l10n.workInvoiceActivityPayment,
    InvoiceDateActivity.paymentApplied => l10n.workInvoiceActivityApplied,
  };
}
