part of 'expense_record.dart';

/// A durable copy of the confirmed business values before a later revision.
///
/// The matching [ExpenseAuditEvent] records who changed that revision, when it
/// changed, and why. Receipt files remain owned by Document Intake and are
/// referenced here only by their stable identity.
@immutable
class ExpenseRevisionSnapshot {
  ExpenseRevisionSnapshot({
    required this.revision,
    required DateTime recordedAtUtc,
    required this.paidByEmployeeId,
    required DateTime expenseDate,
    required this.vendorName,
    required this.categoryId,
    required this.categoryLabelSnapshot,
    required this.total,
    required ExpenseItemization itemization,
    required this.approval,
    this.expenseTimeMinutes,
    this.receiptId,
    this.jobId,
    this.vehicleId,
  }) : recordedAtUtc = recordedAtUtc.toUtc(),
       expenseDate = DateTime(
         expenseDate.year,
         expenseDate.month,
         expenseDate.day,
       ),
       itemization = itemization.immutableCopy() {
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'Must be positive.');
    }
    _requireNonEmpty(paidByEmployeeId, 'paidByEmployeeId');
    _requireNonEmpty(vendorName, 'vendorName');
    _requireNonEmpty(categoryId, 'categoryId');
    _requireNonEmpty(categoryLabelSnapshot, 'categoryLabelSnapshot');
  }

  factory ExpenseRevisionSnapshot.fromRecord(StoredExpenseRecord record) =>
      ExpenseRevisionSnapshot(
        revision: record.lifecycle.revision,
        recordedAtUtc: record.lifecycle.updatedAtUtc,
        paidByEmployeeId: record.paidByEmployeeId,
        expenseDate: record.expenseDate,
        expenseTimeMinutes: record.expenseTimeMinutes,
        vendorName: record.vendorName,
        categoryId: record.categoryId,
        categoryLabelSnapshot: record.categoryLabelSnapshot,
        total: record.total,
        receiptId: record.receiptId,
        jobId: record.jobId,
        vehicleId: record.vehicleId,
        itemization: record.itemization,
        approval: record.approval,
      );

  final int revision;
  final DateTime recordedAtUtc;
  final String paidByEmployeeId;
  final DateTime expenseDate;
  final int? expenseTimeMinutes;
  final String vendorName;
  final String categoryId;
  final String categoryLabelSnapshot;
  final ExpenseMoney total;
  final String? receiptId;
  final String? jobId;
  final String? vehicleId;
  final ExpenseItemization itemization;
  final ExpenseApproval approval;

  Map<String, Object?> toJson() => {
    'revision': revision,
    'recordedAtUtc': recordedAtUtc.toIso8601String(),
    'paidByEmployeeId': paidByEmployeeId,
    'expenseDate': expenseDateKey(expenseDate),
    'expenseTimeMinutes': expenseTimeMinutes,
    'vendorName': vendorName,
    'categoryId': categoryId,
    'categoryLabelSnapshot': categoryLabelSnapshot,
    'total': total.toJson(),
    'receiptId': receiptId,
    'jobId': jobId,
    'vehicleId': vehicleId,
    'itemization': itemization.toJson(),
    'approval': approval.toJson(),
  };

  factory ExpenseRevisionSnapshot.fromJson(Map<String, Object?> json) =>
      ExpenseRevisionSnapshot(
        revision: _requiredInt(json, 'revision'),
        recordedAtUtc: _requiredUtcDate(json, 'recordedAtUtc'),
        paidByEmployeeId: _requiredString(json, 'paidByEmployeeId'),
        expenseDate: parseExpenseDateKey(_requiredString(json, 'expenseDate')),
        expenseTimeMinutes: json['expenseTimeMinutes'] as int?,
        vendorName: _requiredString(json, 'vendorName'),
        categoryId: _requiredString(json, 'categoryId'),
        categoryLabelSnapshot: _requiredString(json, 'categoryLabelSnapshot'),
        total: ExpenseMoney.fromJson(_requiredMap(json, 'total')),
        receiptId: json['receiptId'] as String?,
        jobId: json['jobId'] as String?,
        vehicleId: json['vehicleId'] as String?,
        itemization: ExpenseItemization.fromJson(
          _requiredMap(json, 'itemization'),
        ),
        approval: ExpenseApproval.fromJson(_requiredMap(json, 'approval')),
      );
}
