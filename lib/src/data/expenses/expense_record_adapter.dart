import 'expense_workflow_models.dart';
import 'expense_record.dart';

const _unspecifiedReceiptCount = Object();

class ExpenseRecordAdapter {
  const ExpenseRecordAdapter._();

  static StoredExpenseRecord fromUiRecord({
    required ExpenseRecord record,
    required String organizationId,
    required String createdByEmployeeId,
    required String paidByEmployeeId,
    required DateTime nowUtc,
    String? receiptId,
    Object? receiptImageCountOverride = _unspecifiedReceiptCount,
    int? expenseTimeMinutes,
    String? vehicleId,
    int revision = 1,
  }) {
    final resolvedDate = record.resolvedDate;
    if (resolvedDate == null) {
      throw const FormatException(
        'Expense date must be confirmed before save.',
      );
    }
    final total = _money(record.amount);
    return StoredExpenseRecord(
      expenseId: record.id,
      organizationId: organizationId,
      createdByEmployeeId: createdByEmployeeId,
      paidByEmployeeId: paidByEmployeeId,
      expenseDate: resolvedDate,
      vendorName: record.vendor,
      categoryId: record.category.name,
      categoryLabelSnapshot: record.category.label,
      total: total,
      expenseTimeMinutes: expenseTimeMinutes,
      receiptId: receiptId,
      receiptImageCount:
          identical(receiptImageCountOverride, _unspecifiedReceiptCount)
          ? (receiptId == null ? 0 : record.receiptImageCount)
          : receiptImageCountOverride as int?,
      jobId: record.jobId,
      vehicleId: vehicleId,
      approval: _approvalFromUi(
        record.approvalStatus,
        note: record.approvalReason,
      ),
      itemization: _itemizationFromUi(record, total.currencyCode),
      lifecycle: ExpenseLifecycle(
        revision: revision,
        createdAtUtc: nowUtc.toUtc(),
        updatedAtUtc: nowUtc.toUtc(),
      ),
    );
  }

  static ExpenseRecord toUiRecord({
    required StoredExpenseRecord record,
    required String ownerDisplayName,
    String? jobDisplayName,
  }) {
    final itemization = record.itemization;
    return ExpenseRecord(
      id: record.expenseId,
      vendor: record.vendorName,
      category: ExpenseCategory.values.byName(record.categoryId),
      amount: record.total.minorUnits / 100,
      date: record.expenseDate,
      owner: ownerDisplayName,
      paidByEmployeeId: record.paidByEmployeeId,
      job: jobDisplayName,
      jobId: record.jobId,
      receiptStatus: record.receiptId == null
          ? null
          : record.receiptImageCount == null
          ? 'Receipt linked; image count unavailable'
          : record.receiptImageCount == 0
          ? 'Receipt recorded without an image'
          : 'Receipt attached',
      receiptImageCount: record.receiptImageCount ?? 0,
      receiptType: itemization.mode == ExpenseItemizationMode.itemized
          ? ExpenseReceiptType.detailed
          : ExpenseReceiptType.basic,
      lineItems: itemization.lineItems.map(_lineToUi).toList(growable: false),
      receiptSubtotal: itemization.subtotal == null
          ? null
          : itemization.subtotal!.minorUnits / 100,
      salesTax: itemization.salesTax.minorUnits / 100,
      approvalStatus: _approvalToUi(record.approval.state),
      approvalReason: record.approval.note,
    );
  }

  static ExpenseItemization _itemizationFromUi(
    ExpenseRecord record,
    String currencyCode,
  ) => ExpenseItemization(
    mode: record.receiptType == ExpenseReceiptType.detailed
        ? ExpenseItemizationMode.itemized
        : ExpenseItemizationMode.totalOnly,
    lineItems: List.unmodifiable(
      record.lineItems.map((line) => _lineFromUi(line, currencyCode)),
    ),
    subtotal: record.receiptSubtotal == null
        ? null
        : _money(record.receiptSubtotal!, currencyCode: currencyCode),
    salesTax: _money(record.salesTax, currencyCode: currencyCode),
  );

  static StoredExpenseLineItem _lineFromUi(
    ExpenseLineItem line,
    String currencyCode,
  ) {
    final isCountPackage =
        line.unit == 'pack' || line.unit == 'package' || line.unit == 'box';
    return StoredExpenseLineItem(
      lineItemId: line.id,
      description: line.description,
      categoryId: line.category.name,
      categoryLabelSnapshot: line.category.label,
      packagesPurchased: _decimal(line.quantity),
      packageStyleCode: line.unit,
      pricePerPackage: _money(line.unitPrice, currencyCode: currencyCode),
      extendedTotal: _money(line.total, currencyCode: currencyCode),
      containedQuantityPerPackage: isCountPackage
          ? _decimal(line.unitsPerPackage)
          : null,
      containedUnitCode: isCountPackage ? 'each' : null,
      partNumber: line.partNumber,
      jobId: line.jobId,
      jobLabelSnapshot: line.jobLabel,
    );
  }

  static ExpenseLineItem _lineToUi(StoredExpenseLineItem line) =>
      ExpenseLineItem(
        id: line.lineItemId,
        description: line.description,
        category: ExpenseCategory.values.byName(line.categoryId),
        quantity: double.parse(line.packagesPurchased.decimalValue),
        unit: line.packageStyleCode,
        unitPrice: line.pricePerPackage.minorUnits / 100,
        confirmedLineTotal: line.extendedTotal.minorUnits / 100,
        unitsPerPackage: line.containedQuantityPerPackage == null
            ? 1
            : double.parse(line.containedQuantityPerPackage!.decimalValue),
        partNumber: line.partNumber,
        jobId: line.jobId,
        jobLabel: line.jobLabelSnapshot,
      );

  static ExpenseMoney _money(double value, {String currencyCode = 'USD'}) =>
      ExpenseMoney.fromDecimalString(
        value.toString(),
        currencyCode: currencyCode,
      );

  static ExpenseDecimalValue _decimal(double value) =>
      ExpenseDecimalValue.fromDecimalString(value.toString());

  static ExpenseApproval _approvalFromUi(
    ExpenseApprovalStatus status, {
    String? note,
  }) => switch (status) {
    ExpenseApprovalStatus.notRequired => const ExpenseApproval.notRequired(),
    ExpenseApprovalStatus.pending => ExpenseApproval(
      state: ExpenseApprovalState.pending,
      note: note,
    ),
    ExpenseApprovalStatus.approved => ExpenseApproval(
      state: ExpenseApprovalState.approved,
      note: note,
    ),
    ExpenseApprovalStatus.declined => ExpenseApproval(
      state: ExpenseApprovalState.declined,
      note: note,
    ),
  };

  static ExpenseApprovalStatus _approvalToUi(ExpenseApprovalState state) =>
      switch (state) {
        ExpenseApprovalState.notRequired => ExpenseApprovalStatus.notRequired,
        ExpenseApprovalState.pending => ExpenseApprovalStatus.pending,
        ExpenseApprovalState.approved => ExpenseApprovalStatus.approved,
        ExpenseApprovalState.declined => ExpenseApprovalStatus.declined,
      };
}
