import 'work_contact_codec.dart';
import 'models/work_models.dart';
import 'models/estimate_models.dart';
import 'work_payload_values.dart';
import 'work_record_detail_codec.dart';

Map<String, Object?> encodeWorkRecord(WorkRecord value) => {
  'id': value.id,
  'kind': value.kind.name,
  'number': value.number,
  'purchaseOrderNumber': value.purchaseOrderNumber,
  'title': value.title,
  'client': value.client,
  'customerSnapshot': value.customerSnapshot == null
      ? null
      : encodeWorkCustomerProfile(value.customerSnapshot!),
  'detail': value.detail,
  'pricing': value.pricing.name,
  'sourceId': value.sourceId,
  'assignee': value.assignee,
  'assignedEmployeeIds': value.assignedEmployeeIds,
  'vehicle': value.vehicle,
  'serviceLocation': value.serviceLocation,
  'jobNotes': value.jobNotes,
  'createdOn': value.createdOn?.toIso8601String(),
  'issuedOn': value.issuedOn?.toIso8601String(),
  'dueOn': value.dueOn?.toIso8601String(),
  'scheduledStart': value.scheduledStart?.toIso8601String(),
  'scheduledEnd': value.scheduledEnd?.toIso8601String(),
  'completedOn': value.completedOn?.toIso8601String(),
  'createdByEmployeeId': value.createdByEmployeeId,
  'status': value.status.name,
  'items': value.items.map((item) => encodeWorkLineItem(item)).toList(),
  'template': value.template,
  'terms': value.terms,
  'paymentMethod': value.paymentMethod,
  'discount': encodeWorkDecimal(value.discount),
  'tax': encodeWorkDecimal(value.tax),
  'total': encodeWorkDecimal(value.total),
  'revision': value.revision,
  'customerApprovals': value.customerApprovals
      .map((approval) => approval.toJson())
      .toList(),
  'businessSignature': value.businessSignature == null
      ? null
      : encodeWorkCustomerSignature(value.businessSignature!),
  'customerSignature': value.customerSignature == null
      ? null
      : encodeWorkCustomerSignature(value.customerSignature!),
  'estimateStage': value.estimateStage?.name,
  'estimateDates': value.estimateDates == null
      ? null
      : encodeEstimateDates(value.estimateDates!),
  'estimateDeliveries': value.estimateDeliveries
      .map((item) => encodeEstimateDeliveryRecord(item))
      .toList(),
  'estimateRevisionHistory': value.estimateRevisionHistory
      .map((item) => encodeEstimateRevisionRecord(item))
      .toList(),
  'requiresCompanyReview': value.requiresCompanyReview,
  'estimateCompanyReviewStatus': value.estimateCompanyReviewStatus.name,
  'estimateCompanyReviewNote': value.estimateCompanyReviewNote,
  'estimateCompanyReviewHistory': value.estimateCompanyReviewHistory
      .map((item) => encodeEstimateCompanyReviewEvent(item))
      .toList(),
  'sitePhotos': value.sitePhotos
      .map((item) => encodeWorkSitePhoto(item))
      .toList(),
  'linkedExpenseIds': value.linkedExpenseIds.map((item) => item).toList(),
};

WorkRecord decodeWorkRecord(Map<String, Object?> json) => WorkRecord(
  id: json['id'] as String,
  kind: WorkRecordKind.values.byName(json['kind'] as String),
  number: json['number'] as String,
  purchaseOrderNumber: json['purchaseOrderNumber'] as String? ?? '',
  title: json['title'] as String,
  client: json['client'] as String,
  customerSnapshot: json['customerSnapshot'] == null
      ? null
      : decodeWorkCustomerProfile(
          (json['customerSnapshot'] as Map).cast<String, Object?>(),
        ),
  detail: json['detail'] as String,
  pricing: WorkPricingModel.values.byName(json['pricing'] as String),
  sourceId: json['sourceId'] == null ? null : json['sourceId'] as String,
  assignee: json['assignee'] == null ? null : json['assignee'] as String,
  assignedEmployeeIds:
      (json['assignedEmployeeIds'] as List?)?.cast<String>() ?? const [],
  vehicle: json['vehicle'] == null ? null : json['vehicle'] as String,
  serviceLocation: json['serviceLocation'] as String,
  jobNotes: json['jobNotes'] as String,
  createdOn: json['createdOn'] == null
      ? null
      : DateTime.parse(json['createdOn'] as String),
  issuedOn: json['issuedOn'] == null
      ? null
      : DateTime.parse(json['issuedOn'] as String),
  dueOn: json['dueOn'] == null ? null : DateTime.parse(json['dueOn'] as String),
  scheduledStart: json['scheduledStart'] == null
      ? null
      : DateTime.parse(json['scheduledStart'] as String),
  scheduledEnd: json['scheduledEnd'] == null
      ? null
      : DateTime.parse(json['scheduledEnd'] as String),
  completedOn: json['completedOn'] == null
      ? null
      : DateTime.parse(json['completedOn'] as String),
  createdByEmployeeId: json['createdByEmployeeId'] as String,
  status: WorkRecordStatus.values.byName(json['status'] as String),
  items: List.unmodifiable(
    (json['items'] as List).map(
      (item) => decodeWorkLineItem((item as Map).cast<String, Object?>()),
    ),
  ),
  template: json['template'] as String,
  terms: json['terms'] as String,
  paymentMethod: json['paymentMethod'] as String,
  discount: decodeWorkDecimal(json['discount']),
  tax: decodeWorkDecimal(json['tax']),
  total: decodeWorkDecimal(json['total']),
  revision: json['revision'] as int,
  customerApprovals: List.unmodifiable(
    (json['customerApprovals'] as List? ?? const []).map(
      (entry) =>
          WorkCustomerApproval.fromJson((entry as Map).cast<String, Object?>()),
    ),
  ),
  businessSignature: json['businessSignature'] == null
      ? null
      : decodeWorkCustomerSignature(
          (json['businessSignature'] as Map).cast<String, Object?>(),
        ),
  customerSignature: json['customerSignature'] == null
      ? null
      : decodeWorkCustomerSignature(
          (json['customerSignature'] as Map).cast<String, Object?>(),
        ),
  estimateStage: json['estimateStage'] == null
      ? null
      : EstimateStage.values.byName(json['estimateStage'] as String),
  estimateDates: json['estimateDates'] == null
      ? null
      : decodeEstimateDates(
          (json['estimateDates'] as Map).cast<String, Object?>(),
        ),
  estimateDeliveries: List.unmodifiable(
    (json['estimateDeliveries'] as List).map(
      (item) =>
          decodeEstimateDeliveryRecord((item as Map).cast<String, Object?>()),
    ),
  ),
  estimateRevisionHistory: List.unmodifiable(
    (json['estimateRevisionHistory'] as List).map(
      (item) =>
          decodeEstimateRevisionRecord((item as Map).cast<String, Object?>()),
    ),
  ),
  requiresCompanyReview: json['requiresCompanyReview'] as bool,
  estimateCompanyReviewStatus: EstimateCompanyReviewStatus.values.byName(
    json['estimateCompanyReviewStatus'] as String,
  ),
  estimateCompanyReviewNote: json['estimateCompanyReviewNote'] as String,
  estimateCompanyReviewHistory: List.unmodifiable(
    (json['estimateCompanyReviewHistory'] as List).map(
      (item) => decodeEstimateCompanyReviewEvent(
        (item as Map).cast<String, Object?>(),
      ),
    ),
  ),
  sitePhotos: List.unmodifiable(
    (json['sitePhotos'] as List).map(
      (item) => decodeWorkSitePhoto((item as Map).cast<String, Object?>()),
    ),
  ),
  linkedExpenseIds: List.unmodifiable(
    (json['linkedExpenseIds'] as List).map((item) => item as String),
  ),
);

Map<String, Object?> encodeWorkCustomerSignature(WorkCustomerSignature value) =>
    {
      if (value.ink != null) 'ink': value.ink!.toJson(),
      'signedBy': value.signedBy,
      'signedOn': value.signedOn.toIso8601String(),
      'signedRevision': value.signedRevision,
      'invalidatedOn': value.invalidatedOn?.toIso8601String(),
      'invalidationReason': value.invalidationReason,
    };

WorkCustomerSignature decodeWorkCustomerSignature(Map<String, Object?> json) =>
    WorkCustomerSignature(
      ink: json['ink'] == null
          ? null
          : SignatureInk.fromJson((json['ink'] as Map).cast<String, Object?>()),
      signedBy: json['signedBy'] as String,
      signedOn: DateTime.parse(json['signedOn'] as String),
      signedRevision: json['signedRevision'] as int,
      invalidatedOn: json['invalidatedOn'] == null
          ? null
          : DateTime.parse(json['invalidatedOn'] as String),
      invalidationReason: json['invalidationReason'] == null
          ? null
          : json['invalidationReason'] as String,
    );
