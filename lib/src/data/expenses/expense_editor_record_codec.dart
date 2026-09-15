import 'expense_workflow_models.dart';

/// Complete domain base retained with a draft so recovery cannot adopt newer values.
Map<String, Object?> encodeExpenseEditorRecord(ExpenseRecord record) => {
  'id': record.id,
  'vendor': record.vendor,
  'category': record.category.name,
  'amount': record.amount,
  'date': record.resolvedDate!.toIso8601String(),
  'owner': record.owner,
  'paidByEmployeeId': record.paidByEmployeeId,
  'job': record.job,
  'jobId': record.jobId,
  'receiptStatus': record.receiptStatus,
  'receiptType': record.receiptType.name,
  'receiptImageCount': record.receiptImageCount,
  'receiptSubtotal': record.receiptSubtotal,
  'salesTax': record.salesTax,
  'prepareMaterialsReview': record.prepareMaterialsReview,
  'approvalStatus': record.approvalStatus.name,
  'approvalReason': record.approvalReason,
  'requiresSubmitterAttention': record.requiresSubmitterAttention,
  'submitterAttentionReason': record.submitterAttentionReason,
  'lines': record.lineItems.map(encodeExpenseEditorLine).toList(),
};

ExpenseRecord decodeExpenseEditorRecord(Map<String, Object?> value) =>
    ExpenseRecord(
      id: value['id'] as String,
      vendor: value['vendor'] as String,
      category: ExpenseCategory.values.byName(value['category'] as String),
      amount: (value['amount'] as num?)?.toDouble(),
      date: DateTime.parse(value['date'] as String),
      owner: value['owner'] as String,
      paidByEmployeeId: value['paidByEmployeeId'] as String?,
      job: value['job'] as String?,
      jobId: value['jobId'] as String?,
      receiptStatus: value['receiptStatus'] as String?,
      receiptType: ExpenseReceiptType.values.byName(
        value['receiptType'] as String,
      ),
      receiptImageCount: value['receiptImageCount'] as int,
      receiptSubtotal: (value['receiptSubtotal'] as num?)?.toDouble(),
      salesTax: (value['salesTax'] as num).toDouble(),
      prepareMaterialsReview: value['prepareMaterialsReview'] as bool,
      approvalStatus: ExpenseApprovalStatus.values.byName(
        value['approvalStatus'] as String,
      ),
      approvalReason: value['approvalReason'] as String?,
      requiresSubmitterAttention: value['requiresSubmitterAttention'] as bool,
      submitterAttentionReason: value['submitterAttentionReason'] as String?,
      lineItems: (value['lines'] as List)
          .map(
            (line) =>
                decodeExpenseEditorLine((line as Map).cast<String, Object?>()),
          )
          .toList(),
    );

Map<String, Object?> encodeExpenseEditorLine(ExpenseLineItem line) => {
  'id': line.id,
  'description': line.description,
  'category': line.category.name,
  'quantity': line.quantity,
  'unit': line.unit,
  'unitPrice': line.unitPrice,
  'confirmedLineTotal': line.confirmedLineTotal,
  'unitsPerPackage': line.unitsPerPackage,
  'partNumber': line.partNumber,
  'jobId': line.jobId,
  'jobLabel': line.jobLabel,
};

ExpenseLineItem decodeExpenseEditorLine(Map<String, Object?> line) =>
    ExpenseLineItem(
      id: line['id'] as String,
      description: line['description'] as String,
      category: ExpenseCategory.values.byName(line['category'] as String),
      quantity: (line['quantity'] as num).toDouble(),
      unit: line['unit'] as String,
      unitPrice: (line['unitPrice'] as num).toDouble(),
      confirmedLineTotal: (line['confirmedLineTotal'] as num?)?.toDouble(),
      unitsPerPackage: _decodePackageContents(line),
      partNumber: line['partNumber'] as String?,
      jobId: line['jobId'] as String?,
      jobLabel: line['jobLabel'] as String?,
    );

double? _decodePackageContents(Map<String, Object?> line) {
  if (!line.containsKey('unitsPerPackage')) {
    throw const FormatException('Missing package contents field.');
  }
  return (line['unitsPerPackage'] as num?)?.toDouble();
}
