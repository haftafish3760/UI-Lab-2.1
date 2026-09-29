import '../../../l10n/app_localizations.dart';
import '../../data/work/work_overview_query.dart';
import '../../data/work/models/work_models.dart';
import '../../data/work/models/estimate_models.dart';

extension WorkOverviewFilterLocalization on WorkOverviewFilter {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    WorkOverviewFilter.awaitingCustomer => l10n.workFilterAwaitingCustomer,
    WorkOverviewFilter.unscheduledJobs => l10n.workFilterUnscheduledJobs,
    WorkOverviewFilter.activeJobs => l10n.workFilterActiveJobs,
    WorkOverviewFilter.unpaidInvoices => l10n.workFilterUnpaidInvoices,
    WorkOverviewFilter.invoicesWithoutPayments => l10n.workMoneyUnpaid,
    WorkOverviewFilter.allEstimates => l10n.workFilterAllEstimates,
    WorkOverviewFilter.draftEstimates => l10n.workFilterDraftEstimates,
    WorkOverviewFilter.companyReviewEstimates =>
      l10n.workFilterCompanyReviewEstimates,
    WorkOverviewFilter.readyEstimates => l10n.workFilterReadyEstimates,
    WorkOverviewFilter.changedEstimates => l10n.workFilterChangedEstimates,
    WorkOverviewFilter.approvedEstimates => l10n.workFilterApprovedEstimates,
    WorkOverviewFilter.declinedEstimates => l10n.workFilterDeclinedEstimates,
    WorkOverviewFilter.expiredEstimates => l10n.workFilterExpiredEstimates,
    WorkOverviewFilter.allJobs => l10n.workFilterAllJobs,
    WorkOverviewFilter.completedJobs => l10n.workFilterCompletedJobs,
    WorkOverviewFilter.allInvoices => l10n.workFilterAllInvoices,
    WorkOverviewFilter.invoicesNeedingApproval =>
      l10n.invoiceNeedsApproval,
    WorkOverviewFilter.approvedInvoices => l10n.workStatusApproved,
    WorkOverviewFilter.draftInvoices => l10n.workFilterDraftInvoices,
    WorkOverviewFilter.invoicesWithPayments => l10n.workInvoicesWithPayments,
    WorkOverviewFilter.partiallyPaidInvoices => l10n.workPartiallyPaid,
    WorkOverviewFilter.paidInvoices => l10n.workFilterPaidInvoices,
    WorkOverviewFilter.overdueInvoices => l10n.workFilterOverdueInvoices,
  };
}

extension WorkRecordStatusLocalization on WorkRecordStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    WorkRecordStatus.draft => l10n.workStatusDraft,
    WorkRecordStatus.ready => l10n.workStatusReady,
    WorkRecordStatus.sent => l10n.workStatusSent,
    WorkRecordStatus.accepted => l10n.workStatusAccepted,
    WorkRecordStatus.scheduled => l10n.workStatusScheduled,
    WorkRecordStatus.enRoute => l10n.workStatusEnRoute,
    WorkRecordStatus.arrived => l10n.workStatusArrived,
    WorkRecordStatus.inProgress => l10n.workStatusInProgress,
    WorkRecordStatus.paused => l10n.workStatusPaused,
    WorkRecordStatus.needsReturnVisit => l10n.workStatusNeedsReturnVisit,
    WorkRecordStatus.completed => l10n.workStatusCompleted,
    WorkRecordStatus.due => l10n.workStatusDue,
    WorkRecordStatus.paid => l10n.workStatusPaid,
  };
}

extension EstimateStageLocalization on EstimateStage {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    EstimateStage.draft => l10n.workStatusDraft,
    EstimateStage.readyToSend => l10n.workStatusReadyToSend,
    EstimateStage.awaitingCustomer => l10n.workStatusAwaitingCustomer,
    EstimateStage.viewed => l10n.workStatusViewed,
    EstimateStage.changesRequested => l10n.workStatusChangesRequested,
    EstimateStage.approved => l10n.workStatusApproved,
    EstimateStage.declined => l10n.workStatusDeclined,
    EstimateStage.expired => l10n.workStatusExpired,
    EstimateStage.converted => l10n.workStatusConverted,
    EstimateStage.archived => l10n.workStatusArchived,
  };
}
