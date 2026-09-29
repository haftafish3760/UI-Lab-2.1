enum EstimateStage {
  draft('Draft', 'Continue adding the work details and prices'),
  readyToSend('Ready to send', 'Preview and send to customer'),
  awaitingCustomer('Awaiting customer', 'Follow up with customer'),
  viewed('Viewed', 'Customer opened the estimate'),
  changesRequested('Changes requested', 'Review customer request'),
  approved('Approved', 'Create a job when the company is ready'),
  declined('Declined', 'No work is planned'),
  expired('Expired', 'Review pricing before resending'),
  converted('Converted to job', 'Open the linked job'),
  archived('Archived', 'No action required');

  const EstimateStage(this.label, this.nextStep);
  final String label;
  final String nextStep;

  bool get isOpen => switch (this) {
    draft ||
    readyToSend ||
    awaitingCustomer ||
    viewed ||
    changesRequested ||
    approved => true,
    declined || expired || converted || archived => false,
  };

  bool get needsAttention => switch (this) {
    draft || readyToSend || changesRequested || expired => true,
    _ => false,
  };
}

/// Company review is separate from the customer-facing estimate lifecycle.
/// Approving here permits delivery; it never records customer acceptance.
enum EstimateCompanyReviewStatus {
  notRequired('Company approval not required'),
  pending('Awaiting company approval'),
  approved('Approved for sending'),
  changesRequested('Returned for changes'),
  rejected('Rejected by company');

  const EstimateCompanyReviewStatus(this.label);
  final String label;
}

enum EstimateCompanyReviewDecision {
  submitted,
  approved,
  changesRequested,
  rejected,
}

class EstimateCompanyReviewEvent {
  const EstimateCompanyReviewEvent({
    required this.decision,
    required this.actor,
    required this.occurredOn,
    required this.revision,
    required this.note,
    this.contentFingerprint,
  });

  final EstimateCompanyReviewDecision decision;
  final String actor;
  final DateTime occurredOn;
  final int revision;
  final String note;
  final String? contentFingerprint;
}

enum EstimateDeliveryMethod {
  email('Email'),
  textMessage('Text message'),
  deviceShare('Share from device'),
  savedPdf('Saved PDF'),
  print('Print'),
  inPerson('In-person signature');

  const EstimateDeliveryMethod(this.label);
  final String label;
}

class EstimatePermissions {
  const EstimatePermissions({
    required this.canView,
    required this.canCreate,
    required this.canEditItems,
    required this.canSend,
    required this.canCollectSignature,
    required this.canConvertToJob,
    required this.canViewEstimateTotals,
    required this.canViewInternalCosts,
    this.canApproveCompanyReview = false,
    this.canRecordCustomerApproval = false,
  }) : assert(
         canView ||
             (!canCreate &&
                 !canEditItems &&
                 !canSend &&
                 !canCollectSignature &&
                 !canRecordCustomerApproval &&
                 !canConvertToJob &&
                 !canViewEstimateTotals &&
                 !canViewInternalCosts &&
                 !canApproveCompanyReview),
         'An employee who cannot view estimates cannot act on them.',
       );

  const EstimatePermissions.development()
    : canView = true,
      canCreate = true,
      canEditItems = true,
      canSend = true,
      canCollectSignature = true,
      canRecordCustomerApproval = true,
      canConvertToJob = true,
      canViewEstimateTotals = true,
      canViewInternalCosts = true,
      canApproveCompanyReview = true;

  const EstimatePermissions.technicianDevelopment()
    : canView = true,
      canCreate = true,
      canEditItems = true,
      canSend = false,
      canCollectSignature = false,
      canRecordCustomerApproval = false,
      canConvertToJob = false,
      canViewEstimateTotals = true,
      canViewInternalCosts = false,
      canApproveCompanyReview = false;

  final bool canView;
  final bool canCreate;
  final bool canEditItems;
  final bool canSend;
  final bool canCollectSignature;
  final bool canRecordCustomerApproval;
  final bool canConvertToJob;
  final bool canViewEstimateTotals;
  final bool canViewInternalCosts;
  final bool canApproveCompanyReview;
}

class EstimateDates {
  const EstimateDates({
    required this.createdOn,
    required this.lastEditedOn,
    this.sentOn,
    this.viewedOn,
    this.followUpOn,
    this.expiresOn,
    this.proposedServiceOn,
    this.decidedOn,
    this.convertedOn,
  });

  final DateTime createdOn;
  final DateTime lastEditedOn;
  final DateTime? sentOn;
  final DateTime? viewedOn;
  final DateTime? followUpOn;
  final DateTime? expiresOn;
  final DateTime? proposedServiceOn;
  final DateTime? decidedOn;
  final DateTime? convertedOn;

  EstimateDates copyWith({
    DateTime? lastEditedOn,
    DateTime? sentOn,
    DateTime? viewedOn,
    DateTime? followUpOn,
    DateTime? expiresOn,
    DateTime? proposedServiceOn,
    DateTime? decidedOn,
    DateTime? convertedOn,
  }) => EstimateDates(
    createdOn: createdOn,
    lastEditedOn: lastEditedOn ?? this.lastEditedOn,
    sentOn: sentOn ?? this.sentOn,
    viewedOn: viewedOn ?? this.viewedOn,
    followUpOn: followUpOn ?? this.followUpOn,
    expiresOn: expiresOn ?? this.expiresOn,
    proposedServiceOn: proposedServiceOn ?? this.proposedServiceOn,
    decidedOn: decidedOn ?? this.decidedOn,
    convertedOn: convertedOn ?? this.convertedOn,
  );

  bool hasActivityOn(DateTime day) => [
    createdOn,
    lastEditedOn,
    sentOn,
    viewedOn,
    followUpOn,
    expiresOn,
    proposedServiceOn,
    decidedOn,
    convertedOn,
  ].whereType<DateTime>().any((date) => _sameDay(date, day));
}

class EstimateDeliveryRecord {
  const EstimateDeliveryRecord({
    required this.method,
    required this.recipient,
    required this.occurredOn,
    required this.revision,
    required this.description,
  });

  final EstimateDeliveryMethod method;
  final String recipient;
  final DateTime occurredOn;
  final int revision;
  final String description;
}

class EstimateRevisionRecord {
  const EstimateRevisionRecord({
    required this.revision,
    required this.changedOn,
    required this.total,
    required this.description,
    this.customerApproved = false,
  });

  final int revision;
  final DateTime changedOn;
  final double total;
  final String description;
  final bool customerApproved;
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
