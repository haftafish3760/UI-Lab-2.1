import 'models/work_models.dart';
import 'models/estimate_models.dart';
import 'quote_approval_content.dart';

enum QuoteStatus {
  draft('Draft'),
  needsApproval('Needs approval'),
  ready('Ready to send'),
  awaitingCustomer('Awaiting customer approval'),
  accepted('Accepted'),
  changesRequested('Changes requested'),
  declined('Declined'),
  expired('Expired'),
  converted('Converted'),
  archived('Archived');

  const QuoteStatus(this.label);
  final String label;
  bool get closed => {declined, expired, converted, archived}.contains(this);
}

QuoteStatus quoteStatus(WorkRecord record, DateTime today) {
  if (record.kind != WorkRecordKind.quote) {
    throw ArgumentError('Expected a quote.');
  }
  final stage = record.estimateStageOn(today);
  if (stage == EstimateStage.expired) return QuoteStatus.expired;
  if (stage == EstimateStage.archived) return QuoteStatus.archived;
  if (stage == EstimateStage.converted) return QuoteStatus.converted;
  if (stage == EstimateStage.declined) return QuoteStatus.declined;
  if (record.estimateCompanyReviewStatus ==
      EstimateCompanyReviewStatus.changesRequested) {
    return QuoteStatus.changesRequested;
  }
  if (stage == EstimateStage.draft) return QuoteStatus.draft;
  if (record.requiresCompanyReview && !quoteHasCurrentCompanyApproval(record)) {
    return QuoteStatus.needsApproval;
  }
  return switch (stage) {
    EstimateStage.draft => QuoteStatus.draft,
    EstimateStage.readyToSend => QuoteStatus.ready,
    EstimateStage.awaitingCustomer ||
    EstimateStage.viewed => QuoteStatus.awaitingCustomer,
    EstimateStage.approved => QuoteStatus.accepted,
    EstimateStage.changesRequested => QuoteStatus.changesRequested,
    EstimateStage.declined => QuoteStatus.declined,
    EstimateStage.expired => QuoteStatus.expired,
    EstimateStage.converted => QuoteStatus.converted,
    EstimateStage.archived => QuoteStatus.archived,
  };
}

/// A deliberate status selection overrides the general closed-record setting.
/// Call only with records already filtered by the session's visibility rules.
bool quoteMatchesFilters(
  WorkRecord record, {
  required DateTime today,
  required DateTime selectedDay,
  required bool allDates,
  required bool includeClosedRecords,
  required String query,
  QuoteStatus? selectedStatus,
}) {
  final status = quoteStatus(record, today);
  final matchesStatus = selectedStatus != null
      ? status == selectedStatus
      : status != QuoteStatus.draft && (includeClosedRecords || !status.closed);
  final search = query.trim().toLowerCase();
  return matchesStatus &&
      (allDates || record.occursOn(selectedDay)) &&
      (search.isEmpty ||
          '${record.number} ${record.title} ${record.client}'
              .toLowerCase()
              .contains(search));
}
