import 'invoice_approval_content.dart';
import 'quote_approval_content.dart';
import 'models/estimate_models.dart';
import 'models/work_models.dart';
import 'work_session_permissions.dart';

/// Applies to every generated customer-copy export, regardless of entry route.
/// Call with the verified saved record, not unconfirmed editor input.
void requireWorkDocumentExport(
  WorkRecord record,
  WorkSessionPermissions permissions,
) {
  if (!permissions.canShareDocuments || !permissions.canEdit(record)) {
    throw StateError('You do not have permission to export this document.');
  }
  if (record.kind == WorkRecordKind.quote &&
      (record.requiresCompanyReview || permissions.requiresQuoteApproval) &&
      !quoteHasCurrentCompanyApproval(record)) {
    throw StateError(
      'This quote needs supervisor or admin approval before sharing.',
    );
  }
  if (record.isProposal &&
      (record.resolvedEstimateStage == EstimateStage.draft ||
          !record.companyReviewAllowsCustomerApproval)) {
    throw StateError(
      'Mark the document ready and complete any required company approval before sharing.',
    );
  }
  if (record.kind != WorkRecordKind.invoice) return;
  if (!permissions.canIssueInvoices) {
    throw StateError('You do not have permission to share this invoice.');
  }
  if ((record.requiresInvoiceApproval || permissions.requiresInvoiceApproval) &&
      !invoiceHasCurrentApproval(record)) {
    throw StateError('This invoice needs approval before sharing.');
  }
}
