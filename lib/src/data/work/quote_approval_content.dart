import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../storage/local_record_command.dart';
import 'models/work_models.dart';
import 'models/estimate_models.dart';
import 'work_record_codec.dart';

/// Approval follows the saved price, customer, terms and revision, not a badge.
String quoteApprovalFingerprint(WorkRecord record) {
  final content = encodeWorkRecord(record);
  for (final key in [
    'status',
    'estimateStage',
    'estimateDates',
    'estimateDeliveries',
    'estimateRevisionHistory',
    'customerApprovals',
    'customerSignature',
    'businessSignature',
    'requiresCompanyReview',
    'estimateCompanyReviewStatus',
    'estimateCompanyReviewNote',
    'estimateCompanyReviewHistory',
    'sitePhotos',
  ]) {
    content.remove(key);
  }
  content['expiresOn'] = record.estimateDates?.expiresOn?.toIso8601String();
  content['proposedServiceOn'] = record.estimateDates?.proposedServiceOn
      ?.toIso8601String();
  return sha256.convert(utf8.encode(canonicalJson(content))).toString();
}

bool quoteHasCurrentCompanyApproval(WorkRecord record) {
  final event = record.estimateCompanyReviewHistory.lastOrNull;
  return record.kind == WorkRecordKind.quote &&
      record.estimateCompanyReviewStatus ==
          EstimateCompanyReviewStatus.approved &&
      event?.decision == EstimateCompanyReviewDecision.approved &&
      event?.revision == record.revision &&
      event?.contentFingerprint == quoteApprovalFingerprint(record);
}
