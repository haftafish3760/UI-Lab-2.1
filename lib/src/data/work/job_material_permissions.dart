import 'models/work_models.dart';

class JobWorkspacePermissions {
  const JobWorkspacePermissions({
    required this.canEditJob,
    required this.canViewEstimate,
    required this.canAddMaterials,
    required this.canAttachReceipts,
    required this.canChangeStatus,
    required this.canContactCustomer,
    this.canLinkExpenses = false,
    this.canUseTruckStock = false,
    this.canViewInternalCost = false,
    this.canViewCustomerPrice = false,
    this.canSetCustomerPrice = false,
    this.canAddBillableAdjustment = false,
    this.canProposeChangeOrder = false,
  });

  const JobWorkspacePermissions.development()
    : canEditJob = true,
      canViewEstimate = true,
      canAddMaterials = true,
      canAttachReceipts = true,
      canChangeStatus = true,
      canContactCustomer = true,
      canLinkExpenses = true,
      canUseTruckStock = true,
      canViewInternalCost = true,
      canViewCustomerPrice = true,
      canSetCustomerPrice = true,
      canAddBillableAdjustment = true,
      canProposeChangeOrder = true;

  final bool canEditJob;
  final bool canViewEstimate;
  final bool canAddMaterials;
  final bool canAttachReceipts;
  final bool canChangeStatus;
  final bool canContactCustomer;
  final bool canLinkExpenses;
  final bool canUseTruckStock;
  final bool canViewInternalCost;
  final bool canViewCustomerPrice;
  final bool canSetCustomerPrice;
  final bool canAddBillableAdjustment;
  final bool canProposeChangeOrder;
}

List<JobMaterialBillingTreatment> jobMaterialBillingTreatmentsFor(
  JobWorkspacePermissions permissions,
) => List.unmodifiable([
  JobMaterialBillingTreatment.nonBillable,
  if (permissions.canSetCustomerPrice && permissions.canAddBillableAdjustment)
    JobMaterialBillingTreatment.invoiceCandidate,
  if (permissions.canSetCustomerPrice && permissions.canProposeChangeOrder)
    JobMaterialBillingTreatment.customerApprovalRequired,
]);

bool canEditJobMaterialTreatment(
  JobMaterialBillingTreatment treatment,
  JobWorkspacePermissions permissions,
) =>
    permissions.canAddMaterials &&
    jobMaterialBillingTreatmentsFor(permissions).contains(treatment);
bool canViewJobCustomerPrice(JobWorkspacePermissions permissions) =>
    permissions.canViewCustomerPrice || permissions.canSetCustomerPrice;
