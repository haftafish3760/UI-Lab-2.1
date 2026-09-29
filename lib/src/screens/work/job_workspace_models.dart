import '../../data/work/job_material_permissions.dart';
export '../../data/work/job_material_permissions.dart';
import 'package:flutter/material.dart';

import '../expenses/expense_models.dart';
import 'work_contact_models.dart';
import 'work_models.dart';

enum JobStatus {
  scheduled('Scheduled'),
  enRoute('En route'),
  arrived('Arrived'),
  inProgress('In progress'),
  paused('Paused'),
  needsReturnVisit('Needs return visit'),
  completed('Completed');

  const JobStatus(this.label);
  final String label;
}

enum JobLineKind {
  service('Service', Icons.home_repair_service_outlined),
  material('Material', Icons.inventory_2_outlined),
  labor('Labor', Icons.engineering_outlined),
  equipment('Equipment', Icons.handyman_outlined),
  fee('Fee', Icons.receipt_long_outlined);

  const JobLineKind(this.label, this.icon);
  final String label;
  final IconData icon;
}

class JobLineItem {
  const JobLineItem({
    required this.id,
    required this.kind,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.technicianNote,
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
  final JobLineKind kind;
  final String description;
  final double quantity;
  final int workerCount;
  final WorkCustomerApproval? changeApproval;
  final String unit;
  final double unitPrice;
  final String? technicianNote;
  final double? internalUnitCost;
  final String? sourceExpenseId;
  final String? sourceExpenseLineId;
  final String? sourceReceiptId;
  final String? sourceStockId;
  final bool isJobAddition;
  final JobMaterialBillingTreatment? jobMaterialBillingTreatment;

  JobMaterialBillingTreatment get resolvedJobMaterialBillingTreatment =>
      jobMaterialBillingTreatment ?? JobMaterialBillingTreatment.nonBillable;

  double get total => quantity * unitPrice;

  WorkLineItem toWorkLineItem() => WorkLineItem(
    id: id,
    type: switch (kind) {
      JobLineKind.service => WorkLineItemType.service,
      JobLineKind.material => WorkLineItemType.material,
      JobLineKind.labor => WorkLineItemType.labor,
      JobLineKind.equipment => WorkLineItemType.equipment,
      JobLineKind.fee => WorkLineItemType.fee,
    },
    name: description,
    description: technicianNote ?? '',
    quantity: quantity,
    workerCount: workerCount,
    changeApproval: changeApproval,
    unit: unit,
    customerPrice: unitPrice,
    internalUnitCost: internalUnitCost,
    sourceExpenseId: sourceExpenseId,
    sourceExpenseLineId: sourceExpenseLineId,
    sourceReceiptId: sourceReceiptId,
    sourceStockId: sourceStockId,
    isJobAddition: isJobAddition,
    jobMaterialBillingTreatment: jobMaterialBillingTreatment,
  );

  factory JobLineItem.fromWorkLineItem(
    WorkLineItem item, {
    bool? isJobAddition,
  }) => JobLineItem(
    id: item.id,
    kind: switch (item.type) {
      WorkLineItemType.service => JobLineKind.service,
      WorkLineItemType.material => JobLineKind.material,
      WorkLineItemType.labor => JobLineKind.labor,
      WorkLineItemType.equipment => JobLineKind.equipment,
      WorkLineItemType.procurement || WorkLineItemType.fee => JobLineKind.fee,
    },
    description: item.name,
    quantity: item.quantity,
    workerCount: item.workerCount,
    changeApproval: item.changeApproval,
    unit: item.unit,
    unitPrice: item.customerPrice,
    technicianNote: item.description.isEmpty ? null : item.description,
    internalUnitCost: item.internalUnitCost,
    sourceExpenseId: item.sourceExpenseId,
    sourceExpenseLineId: item.sourceExpenseLineId,
    sourceReceiptId: item.sourceReceiptId,
    sourceStockId: item.sourceStockId,
    isJobAddition: isJobAddition ?? item.isJobAddition,
    jobMaterialBillingTreatment: item.jobMaterialBillingTreatment,
  );
}

enum JobAttachmentKind { receipt, jobPhoto, expense }

class ReceiptAttachment {
  const ReceiptAttachment({
    required this.id,
    required this.name,
    required this.source,
    required this.status,
    this.kind = JobAttachmentKind.receipt,
  });

  final String id;
  final String name;
  final String source;
  final String status;
  final JobAttachmentKind kind;
}

class ActiveJobRecord {
  const ActiveJobRecord({
    required this.id,
    required this.title,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.serviceAddress,
    required this.scheduledTime,
    required this.assignedTechnician,
    required this.assignedVehicle,
    required this.description,
    required this.technicianNotes,
    required this.estimateNumber,
    required this.estimateTerms,
    required this.lineItems,
    required this.receipts,
  });

  final String id;
  final String title;
  final JobStatus status;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String serviceAddress;
  final String scheduledTime;
  final String assignedTechnician;
  final String assignedVehicle;
  final String description;
  final String technicianNotes;
  final String estimateNumber;
  final String estimateTerms;
  final List<JobLineItem> lineItems;
  final List<ReceiptAttachment> receipts;

  double get quotedTotal => lineItems
      .where((item) => !item.isJobAddition)
      .fold(0, (total, item) => total + item.total);

  double get invoiceCandidateTotal => lineItems
      .where(
        (item) =>
            item.isJobAddition &&
            item.resolvedJobMaterialBillingTreatment ==
                JobMaterialBillingTreatment.invoiceCandidate &&
            item.changeApproval != null,
      )
      .fold(0, (total, item) => total + item.total);

  double get approvalRequiredTotal => lineItems
      .where(
        (item) =>
            item.isJobAddition &&
            (item.resolvedJobMaterialBillingTreatment ==
                    JobMaterialBillingTreatment.customerApprovalRequired ||
                (item.resolvedJobMaterialBillingTreatment ==
                        JobMaterialBillingTreatment.invoiceCandidate &&
                    item.changeApproval == null)),
      )
      .fold(0, (total, item) => total + item.total);

  ActiveJobRecord copyWith({
    JobStatus? status,
    String? scheduledTime,
    String? assignedTechnician,
    String? assignedVehicle,
    String? technicianNotes,
    List<JobLineItem>? lineItems,
    List<ReceiptAttachment>? receipts,
  }) => ActiveJobRecord(
    id: id,
    title: title,
    status: status ?? this.status,
    customerName: customerName,
    customerPhone: customerPhone,
    customerEmail: customerEmail,
    serviceAddress: serviceAddress,
    scheduledTime: scheduledTime ?? this.scheduledTime,
    assignedTechnician: assignedTechnician ?? this.assignedTechnician,
    assignedVehicle: assignedVehicle ?? this.assignedVehicle,
    description: description,
    technicianNotes: technicianNotes ?? this.technicianNotes,
    estimateNumber: estimateNumber,
    estimateTerms: estimateTerms,
    lineItems: lineItems ?? this.lineItems,
    receipts: receipts ?? this.receipts,
  );
}

bool canEditJobMaterialAddition(
  JobLineItem item,
  JobWorkspacePermissions permissions,
) => canEditJobMaterialTreatment(
  item.resolvedJobMaterialBillingTreatment,
  permissions,
);

ActiveJobRecord activeJobForRecord(
  WorkRecord record, {
  required String scheduledTime,
  WorkCustomerProfile? customer,
  List<ExpenseRecord> linkedExpenses = const [],
}) {
  final recordedCustomer = record.customerSnapshot ?? customer;
  return ActiveJobRecord(
    id: record.number,
    title: record.title,
    status: switch (record.status) {
      WorkRecordStatus.completed => JobStatus.completed,
      WorkRecordStatus.enRoute => JobStatus.enRoute,
      WorkRecordStatus.arrived => JobStatus.arrived,
      WorkRecordStatus.inProgress => JobStatus.inProgress,
      WorkRecordStatus.paused => JobStatus.paused,
      WorkRecordStatus.needsReturnVisit => JobStatus.needsReturnVisit,
      _ => JobStatus.scheduled,
    },
    customerName: record.client,
    customerPhone: _recordedOrUnavailable(recordedCustomer?.phone),
    customerEmail: _recordedOrUnavailable(recordedCustomer?.email),
    serviceAddress: record.serviceLocation.isNotEmpty
        ? record.serviceLocation
        : 'Service address not assigned',
    scheduledTime: scheduledTime,
    assignedTechnician: record.assignee ?? 'Unassigned',
    assignedVehicle: record.vehicle ?? 'No vehicle assigned',
    description: record.detail.isNotEmpty
        ? record.detail
        : 'Job description not recorded.',
    technicianNotes: record.jobNotes.isNotEmpty
        ? record.jobNotes
        : 'No job notes recorded.',
    estimateNumber: record.sourceId ?? 'Direct job',
    estimateTerms: record.sourceId != null
        ? 'Estimated cost'
        : record.pricing == WorkPricingModel.flatRate
        ? 'Flat rate'
        : 'Time and materials',
    lineItems: record.items.map(JobLineItem.fromWorkLineItem).toList(),
    receipts: [
      for (final expense in linkedExpenses)
        ReceiptAttachment(
          id: 'expense-${expense.id}',
          name: '${expense.vendor} · ${expenseMoney(expense.amount)}',
          source: 'Existing expense',
          status: expense.receiptStatus ?? 'No receipt attached',
          kind: JobAttachmentKind.expense,
        ),
    ],
  );
}

String _recordedOrUnavailable(String? value) =>
    value == null || value.trim().isEmpty ? 'Not recorded' : value;

String jobMoney(double value) => '\$${value.toStringAsFixed(2)}';
