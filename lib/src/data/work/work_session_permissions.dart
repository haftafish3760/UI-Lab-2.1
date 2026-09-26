import 'models/work_models.dart';

/// Application-issued authority; a UI view label does not create these grants.
class WorkSessionPermissions {
  WorkSessionPermissions({
    required this.organizationId,
    required this.actorEmployeeId,
    required this.permissionRevision,
    required Set<String> visibleCreatorIds,
    required Set<WorkRecordKind> editableKinds,
    this.canManageOtherCreators = false,
    this.canIssueInvoices = false,
    this.canRecordPayments = false,
    this.canDeleteDrafts = false,
    this.canAssignJobs = false,
    this.canScheduleJobs = false,
    this.canShareDocuments = false,
    this.canRecordCustomerApproval = false,
    this.canCollectSignature = false,
  }) : visibleCreatorIds = Set.unmodifiable(visibleCreatorIds),
       editableKinds = Set.unmodifiable(editableKinds);

  final String organizationId;
  final String actorEmployeeId;
  final String permissionRevision;
  final Set<String> visibleCreatorIds;
  final Set<WorkRecordKind> editableKinds;
  final bool canManageOtherCreators;
  final bool canIssueInvoices;
  final bool canRecordPayments;
  final bool canDeleteDrafts;
  final bool canAssignJobs;
  final bool canScheduleJobs;
  final bool canShareDocuments;
  final bool canRecordCustomerApproval;
  final bool canCollectSignature;

  bool canEdit(WorkRecord record) =>
      editableKinds.contains(record.kind) &&
      visibleCreatorIds.contains(record.createdByEmployeeId) &&
      (record.createdByEmployeeId == actorEmployeeId || canManageOtherCreators);
}
