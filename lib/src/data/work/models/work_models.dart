import 'signature_ink.dart';
export 'signature_ink.dart';
import 'estimate_models.dart';
import 'work_line_item_models.dart';
import 'work_site_photo.dart';

export 'work_line_item_models.dart';
export 'work_site_photo.dart';
export 'estimate_company_review.dart';
export 'work_record_item_revision.dart';

const _workRecordValueUnchanged = Object();

enum WorkRecordKind { estimate, job, invoice }

enum WorkRecordStatus {
  draft('Draft'),
  ready('Ready'),
  sent('Sent'),
  accepted('Accepted'),
  scheduled('Scheduled'),
  enRoute('En route'),
  arrived('Arrived'),
  inProgress('In progress'),
  paused('Paused'),
  needsReturnVisit('Needs return visit'),
  completed('Completed'),
  due('Due'),
  paid('Paid');

  const WorkRecordStatus(this.label);
  final String label;
}

class WorkCustomerSignature {
  const WorkCustomerSignature({
    required this.signedBy,
    required this.signedOn,
    required this.signedRevision,
    this.ink,
    this.invalidatedOn,
    this.invalidationReason,
  });

  final SignatureInk? ink;
  final String signedBy;
  final DateTime signedOn;
  final int signedRevision;
  final DateTime? invalidatedOn;
  final String? invalidationReason;

  bool isCurrentFor(int revision) =>
      invalidatedOn == null && signedRevision == revision;

  WorkCustomerSignature invalidate(DateTime changedOn, String reason) =>
      WorkCustomerSignature(
        ink: ink,
        signedBy: signedBy,
        signedOn: signedOn,
        signedRevision: signedRevision,
        invalidatedOn: changedOn,
        invalidationReason: reason,
      );
}

class WorkRecord {
  const WorkRecord({
    required this.id,
    required this.kind,
    required this.number,
    this.purchaseOrderNumber = '',
    required this.title,
    required this.client,
    required this.detail,
    required this.pricing,
    this.sourceId,
    this.assignee,
    this.assignedEmployeeIds = const [],
    this.vehicle,
    this.serviceLocation = '',
    this.jobNotes = '',
    this.createdOn,
    this.issuedOn,
    this.dueOn,
    this.scheduledStart,
    this.scheduledEnd,
    this.completedOn,
    this.createdByEmployeeId = 'alex',
    this.status = WorkRecordStatus.draft,
    this.items = const [],
    this.template = 'Service standard',
    this.terms = 'Payment due at time of service.',
    this.paymentMethod = 'Not selected',
    this.discount = 0,
    this.tax = 0,
    this.total = 0,
    this.revision = 1,
    this.customerSignature,
    this.estimateStage,
    this.estimateDates,
    this.estimateDeliveries = const [],
    this.estimateRevisionHistory = const [],
    this.requiresCompanyReview = false,
    this.estimateCompanyReviewStatus = EstimateCompanyReviewStatus.notRequired,
    this.estimateCompanyReviewNote = '',
    this.estimateCompanyReviewHistory = const [],
    this.sitePhotos = const [],
    this.linkedExpenseIds = const [],
  });

  final String id;
  final WorkRecordKind kind;
  final String number;
  final String purchaseOrderNumber;
  final String title;
  final String client;
  final String detail;
  final WorkPricingModel pricing;
  final String? sourceId;
  final String? assignee;
  final List<String> assignedEmployeeIds;
  final String? vehicle;
  final String serviceLocation;
  final String jobNotes;
  final DateTime? createdOn;
  final DateTime? issuedOn;
  final DateTime? dueOn;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? completedOn;
  final String createdByEmployeeId;
  final WorkRecordStatus status;
  final List<WorkLineItem> items;
  final String template;
  final String terms;
  final String paymentMethod;
  final double discount;
  final double tax;
  final double total;
  final int revision;
  final WorkCustomerSignature? customerSignature;
  final EstimateStage? estimateStage;
  final EstimateDates? estimateDates;
  final List<EstimateDeliveryRecord> estimateDeliveries;
  final List<EstimateRevisionRecord> estimateRevisionHistory;
  final bool requiresCompanyReview;
  final EstimateCompanyReviewStatus estimateCompanyReviewStatus;
  final String estimateCompanyReviewNote;
  final List<EstimateCompanyReviewEvent> estimateCompanyReviewHistory;
  final List<WorkSitePhoto> sitePhotos;
  final List<String> linkedExpenseIds;

  EstimateStage get resolvedEstimateStage {
    final stage =
        estimateStage ??
        switch (status) {
          WorkRecordStatus.draft => EstimateStage.draft,
          WorkRecordStatus.ready => EstimateStage.readyToSend,
          WorkRecordStatus.sent => EstimateStage.awaitingCustomer,
          WorkRecordStatus.accepted => EstimateStage.approved,
          _ => EstimateStage.archived,
        };
    final expiry = estimateDates?.expiresOn;
    final today = DateTime.now();
    if (stage.isOpen &&
        stage != EstimateStage.approved &&
        expiry != null &&
        DateTime(
          expiry.year,
          expiry.month,
          expiry.day,
        ).isBefore(DateTime(today.year, today.month, today.day))) {
      return EstimateStage.expired;
    }
    return stage;
  }

  bool get hasCurrentCustomerSignature =>
      customerSignature?.isCurrentFor(revision) ?? false;

  bool get companyReviewAllowsCustomerApproval =>
      !requiresCompanyReview ||
      estimateCompanyReviewStatus == EstimateCompanyReviewStatus.approved;

  bool occursOn(DateTime day) {
    if (kind == WorkRecordKind.estimate && estimateDates != null) {
      return estimateDates!.hasActivityOn(day);
    }
    if (kind == WorkRecordKind.invoice) {
      return [
        createdOn,
        issuedOn,
        if (status != WorkRecordStatus.paid) dueOn,
      ].whereType<DateTime>().any((date) => _sameDate(date, day));
    }
    if (kind != WorkRecordKind.job) {
      return createdOn == null || _sameDate(createdOn!, day);
    }
    if (completedOn != null && _sameDate(completedOn!, day)) return true;
    final start = scheduledStart;
    if (start == null) return true;
    final end = scheduledEnd ?? start;
    final date = DateTime(day.year, day.month, day.day);
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    return !date.isBefore(first) && !date.isAfter(last);
  }

  WorkRecord copyWith({
    String? assignee,
    List<String>? assignedEmployeeIds,
    String? vehicle,
    WorkRecordStatus? status,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    Object? completedOn = _workRecordValueUnchanged,
    String? serviceLocation,
    String? jobNotes,
    DateTime? issuedOn,
    DateTime? dueOn,
    bool? requiresCompanyReview,
    EstimateCompanyReviewStatus? estimateCompanyReviewStatus,
    String? estimateCompanyReviewNote,
    List<EstimateCompanyReviewEvent>? estimateCompanyReviewHistory,
    List<String>? linkedExpenseIds,
  }) => WorkRecord(
    id: id,
    kind: kind,
    number: number,
    purchaseOrderNumber: purchaseOrderNumber,
    title: title,
    client: client,
    detail: detail,
    pricing: pricing,
    sourceId: sourceId,
    assignee: assignee ?? this.assignee,
    assignedEmployeeIds: List.unmodifiable(
      assignedEmployeeIds ?? this.assignedEmployeeIds,
    ),
    vehicle: vehicle ?? this.vehicle,
    serviceLocation: serviceLocation ?? this.serviceLocation,
    jobNotes: jobNotes ?? this.jobNotes,
    createdOn: createdOn,
    issuedOn: issuedOn ?? this.issuedOn,
    dueOn: dueOn ?? this.dueOn,
    scheduledStart: scheduledStart ?? this.scheduledStart,
    scheduledEnd: scheduledEnd ?? this.scheduledEnd,
    completedOn: identical(completedOn, _workRecordValueUnchanged)
        ? this.completedOn
        : completedOn as DateTime?,
    createdByEmployeeId: createdByEmployeeId,
    status: status ?? this.status,
    items: items,
    template: template,
    terms: terms,
    paymentMethod: paymentMethod,
    discount: discount,
    tax: tax,
    total: total,
    revision: revision,
    customerSignature: customerSignature,
    estimateStage: estimateStage,
    estimateDates: estimateDates,
    estimateDeliveries: estimateDeliveries,
    estimateRevisionHistory: estimateRevisionHistory,
    requiresCompanyReview: requiresCompanyReview ?? this.requiresCompanyReview,
    estimateCompanyReviewStatus:
        estimateCompanyReviewStatus ?? this.estimateCompanyReviewStatus,
    estimateCompanyReviewNote:
        estimateCompanyReviewNote ?? this.estimateCompanyReviewNote,
    estimateCompanyReviewHistory: List.unmodifiable(
      estimateCompanyReviewHistory ?? this.estimateCompanyReviewHistory,
    ),
    sitePhotos: sitePhotos,
    linkedExpenseIds: List.unmodifiable(
      linkedExpenseIds ?? this.linkedExpenseIds,
    ),
  );

  WorkRecord withEstimateStage(EstimateStage stage, DateTime changedOn) {
    assert(kind == WorkRecordKind.estimate);
    final mappedStatus = switch (stage) {
      EstimateStage.draft => WorkRecordStatus.draft,
      EstimateStage.readyToSend ||
      EstimateStage.changesRequested ||
      EstimateStage.expired => WorkRecordStatus.ready,
      EstimateStage.awaitingCustomer ||
      EstimateStage.viewed => WorkRecordStatus.sent,
      EstimateStage.approved ||
      EstimateStage.converted => WorkRecordStatus.accepted,
      EstimateStage.declined ||
      EstimateStage.archived => WorkRecordStatus.draft,
    };
    return _copyEstimate(
      stage: stage,
      status: mappedStatus,
      dates: (estimateDates ?? _defaultEstimateDates(changedOn)).copyWith(
        lastEditedOn: changedOn,
        viewedOn: stage == EstimateStage.viewed ? changedOn : null,
        decidedOn:
            stage == EstimateStage.approved || stage == EstimateStage.declined
            ? changedOn
            : null,
        convertedOn: stage == EstimateStage.converted ? changedOn : null,
      ),
    );
  }

  WorkRecord recordEstimateDelivery({
    required EstimateDeliveryMethod method,
    required String recipient,
    required DateTime occurredOn,
    bool confirmedDelivered = false,
  }) {
    assert(kind == WorkRecordKind.estimate);
    if (!companyReviewAllowsCustomerApproval) {
      throw StateError(
        'Company approval is required before this estimate can be sent.',
      );
    }
    return _copyEstimate(
      stage: confirmedDelivered
          ? EstimateStage.awaitingCustomer
          : resolvedEstimateStage,
      status: confirmedDelivered ? WorkRecordStatus.sent : status,
      dates: (estimateDates ?? _defaultEstimateDates(occurredOn)).copyWith(
        lastEditedOn: occurredOn,
        sentOn: confirmedDelivered ? occurredOn : null,
      ),
      deliveries: [
        ...estimateDeliveries,
        EstimateDeliveryRecord(
          method: method,
          recipient: recipient,
          occurredOn: occurredOn,
          revision: revision,
          description: confirmedDelivered
              ? 'Revision $revision delivered by ${method.label}.'
              : 'Revision $revision prepared for ${method.label}; delivery not confirmed.',
        ),
      ],
    );
  }

  WorkRecord recordEstimateSignature(
    String signedBy,
    DateTime signedOn, {
    SignatureInk? ink,
    String? onlineEvidence,
  }) {
    assert(kind == WorkRecordKind.estimate);
    if (!companyReviewAllowsCustomerApproval) {
      throw StateError(
        'Company approval is required before customer approval can be recorded.',
      );
    }
    return _copyEstimate(
      stage: EstimateStage.approved,
      status: WorkRecordStatus.accepted,
      dates: (estimateDates ?? _defaultEstimateDates(signedOn)).copyWith(
        lastEditedOn: signedOn,
        decidedOn: signedOn,
      ),
      signature: WorkCustomerSignature(
        ink: ink,
        signedBy: signedBy,
        signedOn: signedOn,
        signedRevision: revision,
      ),
      deliveries: [
        ...estimateDeliveries,
        EstimateDeliveryRecord(
          method: onlineEvidence == null ? EstimateDeliveryMethod.inPerson : EstimateDeliveryMethod.deviceShare,
          recipient: signedBy,
          occurredOn: signedOn,
          revision: revision,
          description: onlineEvidence ?? 'Customer approved revision $revision in person.',
        ),
      ],
    );
  }

  WorkRecord _copyEstimate({
    required EstimateStage stage,
    required WorkRecordStatus status,
    required EstimateDates dates,
    List<EstimateDeliveryRecord>? deliveries,
    List<EstimateRevisionRecord>? history,
    WorkCustomerSignature? signature,
  }) => WorkRecord(
    id: id,
    kind: kind,
    number: number,
    purchaseOrderNumber: purchaseOrderNumber,
    title: title,
    client: client,
    detail: detail,
    pricing: pricing,
    sourceId: sourceId,
    assignee: assignee,
    assignedEmployeeIds: assignedEmployeeIds,
    vehicle: vehicle,
    serviceLocation: serviceLocation,
    jobNotes: jobNotes,
    createdOn: createdOn,
    issuedOn: issuedOn,
    dueOn: dueOn,
    scheduledStart: scheduledStart,
    scheduledEnd: scheduledEnd,
    completedOn: completedOn,
    createdByEmployeeId: createdByEmployeeId,
    status: status,
    items: items,
    template: template,
    terms: terms,
    paymentMethod: paymentMethod,
    discount: discount,
    tax: tax,
    total: total,
    revision: revision,
    customerSignature: signature ?? customerSignature,
    estimateStage: stage,
    estimateDates: dates,
    estimateDeliveries: List.unmodifiable(deliveries ?? estimateDeliveries),
    estimateRevisionHistory: List.unmodifiable(
      history ?? estimateRevisionHistory,
    ),
    requiresCompanyReview: requiresCompanyReview,
    estimateCompanyReviewStatus: estimateCompanyReviewStatus,
    estimateCompanyReviewNote: estimateCompanyReviewNote,
    estimateCompanyReviewHistory: estimateCompanyReviewHistory,
    sitePhotos: sitePhotos,
    linkedExpenseIds: linkedExpenseIds,
  );
}

EstimateDates _defaultEstimateDates(DateTime date) => EstimateDates(
  createdOn: date,
  lastEditedOn: date,
  expiresOn: date.add(const Duration(days: 30)),
);

bool _sameDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
