import 'work_customer_approval.dart';

enum WorkPricingModel { flatRate, timeAndMaterials }

enum WorkLineItemType {
  service('Service'),
  labor('Labor'),
  material('Material'),
  equipment('Equipment'),
  procurement('Material pickup'),
  fee('Other charge');

  const WorkLineItemType(this.label);
  final String label;
}

enum JobMaterialBillingTreatment {
  nonBillable(
    'Use on job — do not bill customer',
    'Not billed',
    'Records actual material use and cost only.',
  ),
  invoiceCandidate(
    'Add to invoice later',
    'Invoice review',
    'Offers this material during invoice review without changing the accepted estimate.',
  ),
  customerApprovalRequired(
    'Customer approval required',
    'Approval required',
    'Creates a proposed change for separate customer approval before billing.',
  );

  const JobMaterialBillingTreatment(
    this.label,
    this.statusLabel,
    this.description,
  );

  final String label;
  final String statusLabel;
  final String description;
}

class WorkLineItem {
  const WorkLineItem({
    required this.id,
    required this.type,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.customerPrice,
    this.description = '',
    this.workerCount = 1,
    this.changeApproval,
    this.internalUnitCost,
    this.sourceExpenseId,
    this.sourceExpenseLineId,
    this.sourceReceiptId,
    this.sourceStockId,
    this.isJobAddition = false,
    this.jobMaterialBillingTreatment,
  });

  final String id;
  final WorkLineItemType type;
  final String name;
  final String description;

  /// Total billable units, including all workers for hourly labor.
  final double quantity;
  final int workerCount;
  final WorkCustomerApproval? changeApproval;
  final String unit;
  final double customerPrice;
  final double? internalUnitCost;
  final String? sourceExpenseId;
  final String? sourceExpenseLineId;
  final String? sourceReceiptId;
  final String? sourceStockId;
  final bool isJobAddition;
  final JobMaterialBillingTreatment? jobMaterialBillingTreatment;

  JobMaterialBillingTreatment get resolvedJobMaterialBillingTreatment =>
      jobMaterialBillingTreatment ?? JobMaterialBillingTreatment.nonBillable;

  bool get includedInInvoiceFromJob =>
      !isJobAddition ||
      (resolvedJobMaterialBillingTreatment ==
              JobMaterialBillingTreatment.invoiceCandidate &&
          changeApproval != null);

  double get total => quantity * customerPrice;
}
