import 'invoice_approval_content.dart';
import 'invoice_collection_status.dart';
import '../prototype_financial_models.dart';
import 'invoice_payment_balance.dart';
import 'models/estimate_models.dart';
import 'models/work_models.dart';

enum WorkOverviewFilter {
  awaitingCustomer('Estimates awaiting customer'),
  unscheduledJobs('Jobs needing scheduling'),
  activeJobs('Active jobs'),
  unpaidInvoices('Outstanding invoices'),
  invoicesWithoutPayments('Unpaid'),
  allEstimates('All estimates'),
  draftEstimates('Draft estimates'),
  companyReviewEstimates('Estimates awaiting company approval'),
  readyEstimates('Estimates ready to send'),
  changedEstimates('Estimates with changes requested'),
  approvedEstimates('Approved estimates'),
  declinedEstimates('Declined estimates'),
  expiredEstimates('Expired estimates'),
  allJobs('All jobs'),
  completedJobs('Completed jobs'),
  allInvoices('All invoices'),
  draftInvoices('Draft invoices'),
  invoicesNeedingApproval('Needs approval'),
  approvedInvoices('Approved'),
  paidInvoices('Paid invoices'),
  invoicesWithPayments('Invoices with payments'),
  partiallyPaidInvoices('Partially paid invoices'),
  overdueInvoices('Overdue invoices');

  const WorkOverviewFilter(this.label);
  final String label;
}

/// No selected calendar date enters this query. The caller supplies only
/// authorized records and ledger entries; this projection never grants access.
List<WorkRecord> workOverviewRecords({
  required Iterable<WorkRecord> records,
  required Iterable<PrototypeFinancialEntry> payments,
  required WorkOverviewFilter filter,
  required DateTime now,
  String search = '',
}) {
  final needle = search.trim().toLowerCase();
  final result = records.where((record) {
    final isEstimate = record.kind == WorkRecordKind.estimate;
    final isJob = record.kind == WorkRecordKind.job;
    final isInvoice = record.kind == WorkRecordKind.invoice;
    final issuedInvoice = isInvoice && record.status != WorkRecordStatus.draft;
    final collection = isInvoice
        ? invoiceCollectionStatus(record, payments, now: now)
        : null;
    final unpaid =
        issuedInvoice &&
        collection != InvoiceCollectionStatus.paid &&
        invoiceBalanceCents(record, payments) > 0;
    final matches = switch (filter) {
      WorkOverviewFilter.awaitingCustomer =>
        isEstimate &&
            {
              EstimateStage.awaitingCustomer,
              EstimateStage.viewed,
            }.contains(record.estimateStageOn(now)),
      WorkOverviewFilter.unscheduledJobs =>
        isJob &&
            record.status != WorkRecordStatus.completed &&
            record.scheduledStart == null,
      WorkOverviewFilter.activeJobs =>
        isJob &&
            record.status != WorkRecordStatus.completed &&
            record.scheduledStart != null,
      WorkOverviewFilter.unpaidInvoices => unpaid,
      WorkOverviewFilter.invoicesWithoutPayments =>
        unpaid && invoicePaidCents(record, payments) == 0,
      WorkOverviewFilter.allEstimates => isEstimate,
      WorkOverviewFilter.draftEstimates =>
        isEstimate && record.estimateStageOn(now) == EstimateStage.draft,
      WorkOverviewFilter.companyReviewEstimates =>
        isEstimate &&
            record.requiresCompanyReview &&
            record.estimateCompanyReviewStatus ==
                EstimateCompanyReviewStatus.pending,
      WorkOverviewFilter.readyEstimates =>
        isEstimate &&
            record.companyReviewAllowsCustomerApproval &&
            record.estimateStageOn(now) == EstimateStage.readyToSend,
      WorkOverviewFilter.changedEstimates =>
        isEstimate &&
            record.estimateStageOn(now) == EstimateStage.changesRequested,
      WorkOverviewFilter.approvedEstimates =>
        isEstimate && record.estimateStageOn(now) == EstimateStage.approved,
      WorkOverviewFilter.declinedEstimates =>
        isEstimate && record.estimateStageOn(now) == EstimateStage.declined,
      WorkOverviewFilter.expiredEstimates =>
        isEstimate && record.estimateStageOn(now) == EstimateStage.expired,
      WorkOverviewFilter.allJobs => isJob,
      WorkOverviewFilter.completedJobs =>
        isJob && record.status == WorkRecordStatus.completed,
      WorkOverviewFilter.allInvoices => isInvoice,
      WorkOverviewFilter.invoicesNeedingApproval =>
        isInvoice &&
            record.requiresInvoiceApproval &&
            !invoiceHasCurrentApproval(record),
      WorkOverviewFilter.approvedInvoices =>
        isInvoice && invoiceHasCurrentApproval(record),
      WorkOverviewFilter.draftInvoices =>
        isInvoice && record.status == WorkRecordStatus.draft,
      WorkOverviewFilter.invoicesWithPayments =>
        issuedInvoice && invoicePaidCents(record, payments) > 0,
      WorkOverviewFilter.partiallyPaidInvoices =>
        unpaid && collection!.isPartial,
      WorkOverviewFilter.paidInvoices =>
        issuedInvoice && collection == InvoiceCollectionStatus.paid,
      WorkOverviewFilter.overdueInvoices => unpaid && collection!.isOverdue,
    };
    return matches &&
        (needle.isEmpty ||
            '${record.number} ${record.title} ${record.client}'
                .toLowerCase()
                .contains(needle));
  }).toList();
  result.sort((a, b) {
    final date = (b.createdOn ?? DateTime(1970)).compareTo(
      a.createdOn ?? DateTime(1970),
    );
    return date != 0 ? date : a.id.compareTo(b.id);
  });
  return result;
}
