import 'models/work_models.dart';
import 'models/estimate_models.dart';
import 'work_payload_values.dart';

Map<String, Object?> encodeWorkLineItem(WorkLineItem value) => {
  'id': value.id,
  'type': value.type.name,
  'name': value.name,
  'description': value.description,
  'quantity': encodeWorkDecimal(value.quantity),
  'unit': value.unit,
  'customerPrice': encodeWorkDecimal(value.customerPrice),
  'internalUnitCost': value.internalUnitCost == null
      ? null
      : encodeWorkDecimal(value.internalUnitCost!),
  'sourceExpenseId': value.sourceExpenseId,
  'sourceExpenseLineId': value.sourceExpenseLineId,
  'sourceReceiptId': value.sourceReceiptId,
  'sourceStockId': value.sourceStockId,
  'isJobAddition': value.isJobAddition,
  'jobMaterialBillingTreatment': value.jobMaterialBillingTreatment?.name,
};

WorkLineItem decodeWorkLineItem(Map<String, Object?> json) => WorkLineItem(
  id: json['id'] as String,
  type: WorkLineItemType.values.byName(json['type'] as String),
  name: json['name'] as String,
  description: json['description'] as String,
  quantity: decodeWorkDecimal(json['quantity']),
  unit: json['unit'] as String,
  customerPrice: decodeWorkDecimal(json['customerPrice']),
  internalUnitCost: json['internalUnitCost'] == null
      ? null
      : decodeWorkDecimal(json['internalUnitCost']),
  sourceExpenseId: json['sourceExpenseId'] == null
      ? null
      : json['sourceExpenseId'] as String,
  sourceExpenseLineId: json['sourceExpenseLineId'] == null
      ? null
      : json['sourceExpenseLineId'] as String,
  sourceReceiptId: json['sourceReceiptId'] == null
      ? null
      : json['sourceReceiptId'] as String,
  sourceStockId: json['sourceStockId'] == null
      ? null
      : json['sourceStockId'] as String,
  isJobAddition: json['isJobAddition'] as bool,
  jobMaterialBillingTreatment: json['jobMaterialBillingTreatment'] == null
      ? null
      : JobMaterialBillingTreatment.values.byName(
          json['jobMaterialBillingTreatment'] as String,
        ),
);

Map<String, Object?> encodeEstimateDates(EstimateDates value) => {
  'createdOn': value.createdOn.toIso8601String(),
  'lastEditedOn': value.lastEditedOn.toIso8601String(),
  'sentOn': value.sentOn?.toIso8601String(),
  'viewedOn': value.viewedOn?.toIso8601String(),
  'followUpOn': value.followUpOn?.toIso8601String(),
  'expiresOn': value.expiresOn?.toIso8601String(),
  'proposedServiceOn': value.proposedServiceOn?.toIso8601String(),
  'decidedOn': value.decidedOn?.toIso8601String(),
  'convertedOn': value.convertedOn?.toIso8601String(),
};

EstimateDates decodeEstimateDates(Map<String, Object?> json) => EstimateDates(
  createdOn: DateTime.parse(json['createdOn'] as String),
  lastEditedOn: DateTime.parse(json['lastEditedOn'] as String),
  sentOn: json['sentOn'] == null
      ? null
      : DateTime.parse(json['sentOn'] as String),
  viewedOn: json['viewedOn'] == null
      ? null
      : DateTime.parse(json['viewedOn'] as String),
  followUpOn: json['followUpOn'] == null
      ? null
      : DateTime.parse(json['followUpOn'] as String),
  expiresOn: json['expiresOn'] == null
      ? null
      : DateTime.parse(json['expiresOn'] as String),
  proposedServiceOn: json['proposedServiceOn'] == null
      ? null
      : DateTime.parse(json['proposedServiceOn'] as String),
  decidedOn: json['decidedOn'] == null
      ? null
      : DateTime.parse(json['decidedOn'] as String),
  convertedOn: json['convertedOn'] == null
      ? null
      : DateTime.parse(json['convertedOn'] as String),
);

Map<String, Object?> encodeEstimateDeliveryRecord(
  EstimateDeliveryRecord value,
) => {
  'method': value.method.name,
  'recipient': value.recipient,
  'occurredOn': value.occurredOn.toIso8601String(),
  'revision': value.revision,
  'description': value.description,
};

EstimateDeliveryRecord decodeEstimateDeliveryRecord(
  Map<String, Object?> json,
) => EstimateDeliveryRecord(
  method: EstimateDeliveryMethod.values.byName(json['method'] as String),
  recipient: json['recipient'] as String,
  occurredOn: DateTime.parse(json['occurredOn'] as String),
  revision: json['revision'] as int,
  description: json['description'] as String,
);

Map<String, Object?> encodeEstimateRevisionRecord(
  EstimateRevisionRecord value,
) => {
  'revision': value.revision,
  'changedOn': value.changedOn.toIso8601String(),
  'total': encodeWorkDecimal(value.total),
  'description': value.description,
  'customerApproved': value.customerApproved,
};

EstimateRevisionRecord decodeEstimateRevisionRecord(
  Map<String, Object?> json,
) => EstimateRevisionRecord(
  revision: json['revision'] as int,
  changedOn: DateTime.parse(json['changedOn'] as String),
  total: decodeWorkDecimal(json['total']),
  description: json['description'] as String,
  customerApproved: json['customerApproved'] as bool,
);

Map<String, Object?> encodeEstimateCompanyReviewEvent(
  EstimateCompanyReviewEvent value,
) => {
  'decision': value.decision.name,
  'actor': value.actor,
  'occurredOn': value.occurredOn.toIso8601String(),
  'revision': value.revision,
  'note': value.note,
};

EstimateCompanyReviewEvent decodeEstimateCompanyReviewEvent(
  Map<String, Object?> json,
) => EstimateCompanyReviewEvent(
  decision: EstimateCompanyReviewDecision.values.byName(
    json['decision'] as String,
  ),
  actor: json['actor'] as String,
  occurredOn: DateTime.parse(json['occurredOn'] as String),
  revision: json['revision'] as int,
  note: json['note'] as String,
);

Map<String, Object?> encodeWorkSitePhoto(WorkSitePhoto value) => {
  'id': value.id,
  'path': value.path,
  'name': value.name,
  'source': value.source.name,
  'addedOn': value.addedOn.toIso8601String(),
  'note': value.note,
};

WorkSitePhoto decodeWorkSitePhoto(Map<String, Object?> json) => WorkSitePhoto(
  id: json['id'] as String,
  path: json['path'] as String,
  name: json['name'] as String,
  source: WorkSitePhotoSource.values.byName(json['source'] as String),
  addedOn: DateTime.parse(json['addedOn'] as String),
  note: json['note'] as String,
);
