import 'package:flutter/foundation.dart';

import 'expense_itemization.dart';
import 'expense_money.dart';
import 'expense_optional_fields.dart';

export 'expense_itemization.dart';
export 'expense_money.dart';

part 'expense_revision_snapshot.dart';

const _unchangedExpenseValue = Object();

enum ExpenseApprovalState { notRequired, pending, approved, declined }

enum ExpenseAuditAction {
  created,
  updated,
  corrected,
  deleted,
  restored,
  approvalChanged,
}

@immutable
class ExpenseAuditEvent {
  ExpenseAuditEvent({
    required this.action,
    required this.actorEmployeeId,
    required DateTime occurredAtUtc,
    required this.toRevision,
    required this.permissionRevision,
    this.fromRevision,
    this.note,
  }) : occurredAtUtc = occurredAtUtc.toUtc() {
    _requireNonEmpty(actorEmployeeId, 'actorEmployeeId');
    _requireNonEmpty(permissionRevision, 'permissionRevision');
    if (toRevision < 1) {
      throw ArgumentError.value(toRevision, 'toRevision', 'Must be positive.');
    }
  }

  final ExpenseAuditAction action;
  final String actorEmployeeId;
  final DateTime occurredAtUtc;
  final int? fromRevision;
  final int toRevision;
  final String permissionRevision;
  final String? note;

  Map<String, Object?> toJson() => {
    'action': action.name,
    'actorEmployeeId': actorEmployeeId,
    'occurredAtUtc': occurredAtUtc.toIso8601String(),
    'fromRevision': fromRevision,
    'toRevision': toRevision,
    'permissionRevision': permissionRevision,
    'note': note,
  };

  factory ExpenseAuditEvent.fromJson(Map<String, Object?> json) =>
      ExpenseAuditEvent(
        action: ExpenseAuditAction.values.byName(
          _requiredString(json, 'action'),
        ),
        actorEmployeeId: _requiredString(json, 'actorEmployeeId'),
        occurredAtUtc: _requiredUtcDate(json, 'occurredAtUtc'),
        fromRevision: json['fromRevision'] as int?,
        toRevision: _requiredInt(json, 'toRevision'),
        permissionRevision: _requiredString(json, 'permissionRevision'),
        note: json['note'] as String?,
      );
}

@immutable
class ExpenseApproval {
  const ExpenseApproval({
    required this.state,
    this.decidedByEmployeeId,
    this.decidedAtUtc,
    this.note,
  });

  const ExpenseApproval.notRequired()
    : this(state: ExpenseApprovalState.notRequired);

  const ExpenseApproval.pending() : this(state: ExpenseApprovalState.pending);

  final ExpenseApprovalState state;
  final String? decidedByEmployeeId;
  final DateTime? decidedAtUtc;
  final String? note;

  bool get entersApprovedTotals =>
      state == ExpenseApprovalState.notRequired ||
      state == ExpenseApprovalState.approved;

  Map<String, Object?> toJson() => {
    'state': state.name,
    'decidedByEmployeeId': decidedByEmployeeId,
    'decidedAtUtc': decidedAtUtc?.toUtc().toIso8601String(),
    'note': note,
  };

  factory ExpenseApproval.fromJson(Map<String, Object?> json) {
    final stateName = _requiredString(json, 'state');
    return ExpenseApproval(
      state: ExpenseApprovalState.values.byName(stateName),
      decidedByEmployeeId: json['decidedByEmployeeId'] as String?,
      decidedAtUtc: _optionalUtcDate(json['decidedAtUtc']),
      note: json['note'] as String?,
    );
  }
}

@immutable
class ExpenseLifecycle {
  ExpenseLifecycle({
    required this.revision,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    DateTime? deletedAtUtc,
  }) : createdAtUtc = createdAtUtc.toUtc(),
       updatedAtUtc = updatedAtUtc.toUtc(),
       deletedAtUtc = deletedAtUtc?.toUtc() {
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'Must be positive.');
    }
  }

  final int revision;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? deletedAtUtc;

  bool get isDeleted => deletedAtUtc != null;

  ExpenseLifecycle nextRevision({
    required DateTime updatedAtUtc,
    Object? deletedAtUtc = _unchangedExpenseValue,
  }) => ExpenseLifecycle(
    revision: revision + 1,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: updatedAtUtc.toUtc(),
    deletedAtUtc: identical(deletedAtUtc, _unchangedExpenseValue)
        ? this.deletedAtUtc
        : deletedAtUtc as DateTime?,
  );

  Map<String, Object?> toJson() => {
    'revision': revision,
    'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
    'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
    'deletedAtUtc': deletedAtUtc?.toUtc().toIso8601String(),
  };

  factory ExpenseLifecycle.fromJson(Map<String, Object?> json) =>
      ExpenseLifecycle(
        revision: _requiredInt(json, 'revision'),
        createdAtUtc: _requiredUtcDate(json, 'createdAtUtc'),
        updatedAtUtc: _requiredUtcDate(json, 'updatedAtUtc'),
        deletedAtUtc: _optionalUtcDate(json['deletedAtUtc']),
      );
}

@immutable
class StoredExpenseRecord {
  StoredExpenseRecord({
    required this.expenseId,
    required this.organizationId,
    required this.createdByEmployeeId,
    required this.paidByEmployeeId,
    required DateTime expenseDate,
    required this.vendorName,
    required this.categoryId,
    required this.categoryLabelSnapshot,
    required this.total,
    required this.approval,
    required this.lifecycle,
    List<ExpenseAuditEvent> auditTrail = const [],
    List<ExpenseRevisionSnapshot> priorVersions = const [],
    this.expenseTimeMinutes,
    this.receiptId,
    this.receiptImageCount,
    this.jobId,
    this.vehicleId,
    ExpenseItemization itemization = const ExpenseItemization.totalOnly(),
  }) : auditTrail = List.unmodifiable(auditTrail),
       priorVersions = List.unmodifiable(priorVersions),
       itemization = itemization.immutableCopy(),
       expenseDate = DateTime(
         expenseDate.year,
         expenseDate.month,
         expenseDate.day,
       ) {
    _requireNonEmpty(expenseId, 'expenseId');
    _requireNonEmpty(organizationId, 'organizationId');
    _requireNonEmpty(createdByEmployeeId, 'createdByEmployeeId');
    _requireNonEmpty(paidByEmployeeId, 'paidByEmployeeId');
    if (itemization.mode == ExpenseItemizationMode.itemized) {
      _requireNonEmpty(vendorName, 'vendorName');
    }
    validateOptionalExpenseCategory(categoryId, categoryLabelSnapshot);
    if (total != null && total!.minorUnits < 0) {
      throw ArgumentError.value(
        total!.minorUnits,
        'total',
        'Expense total cannot be negative.',
      );
    }
    _validateReceiptImageCount(receiptId, receiptImageCount);
    itemization.validateFor(total);
    final minutes = expenseTimeMinutes;
    if (minutes != null && (minutes < 0 || minutes >= 1440)) {
      throw ArgumentError.value(
        expenseTimeMinutes,
        'expenseTimeMinutes',
        'Must be between 0 and 1439.',
      );
    }
  }

  final String expenseId;
  final String organizationId;
  final String createdByEmployeeId;
  final String paidByEmployeeId;
  final DateTime expenseDate;
  final int? expenseTimeMinutes;
  final String vendorName;
  final String? categoryId;
  final String? categoryLabelSnapshot;
  final ExpenseMoney? total;
  final String? receiptId;

  /// Null means older data did not record an evidence count.
  final int? receiptImageCount;
  final String? jobId;
  final String? vehicleId;
  final ExpenseItemization itemization;
  final ExpenseApproval approval;
  final ExpenseLifecycle lifecycle;
  final List<ExpenseAuditEvent> auditTrail;
  final List<ExpenseRevisionSnapshot> priorVersions;

  bool hasSameBusinessValuesAs(StoredExpenseRecord other) =>
      paidByEmployeeId == other.paidByEmployeeId &&
      expenseDate == other.expenseDate &&
      expenseTimeMinutes == other.expenseTimeMinutes &&
      vendorName == other.vendorName &&
      categoryId == other.categoryId &&
      categoryLabelSnapshot == other.categoryLabelSnapshot &&
      total == other.total &&
      receiptId == other.receiptId &&
      receiptImageCount == other.receiptImageCount &&
      jobId == other.jobId &&
      vehicleId == other.vehicleId &&
      itemization == other.itemization;

  StoredExpenseRecord copyWith({
    String? vendorName,
    Object? categoryId = _unchangedExpenseValue,
    Object? categoryLabelSnapshot = _unchangedExpenseValue,
    Object? total = _unchangedExpenseValue,
    DateTime? expenseDate,
    Object? expenseTimeMinutes = _unchangedExpenseValue,
    Object? receiptId = _unchangedExpenseValue,
    Object? receiptImageCount = _unchangedExpenseValue,
    Object? jobId = _unchangedExpenseValue,
    Object? vehicleId = _unchangedExpenseValue,
    ExpenseItemization? itemization,
    ExpenseApproval? approval,
    ExpenseLifecycle? lifecycle,
    List<ExpenseAuditEvent>? auditTrail,
    List<ExpenseRevisionSnapshot>? priorVersions,
  }) => StoredExpenseRecord(
    expenseId: expenseId,
    organizationId: organizationId,
    createdByEmployeeId: createdByEmployeeId,
    paidByEmployeeId: paidByEmployeeId,
    expenseDate: expenseDate ?? this.expenseDate,
    expenseTimeMinutes: identical(expenseTimeMinutes, _unchangedExpenseValue)
        ? this.expenseTimeMinutes
        : expenseTimeMinutes as int?,
    vendorName: vendorName ?? this.vendorName,
    categoryId: identical(categoryId, _unchangedExpenseValue)
        ? this.categoryId
        : categoryId as String?,
    categoryLabelSnapshot:
        identical(categoryLabelSnapshot, _unchangedExpenseValue)
        ? this.categoryLabelSnapshot
        : categoryLabelSnapshot as String?,
    total: identical(total, _unchangedExpenseValue)
        ? this.total
        : total as ExpenseMoney?,
    receiptId: identical(receiptId, _unchangedExpenseValue)
        ? this.receiptId
        : receiptId as String?,
    receiptImageCount: identical(receiptImageCount, _unchangedExpenseValue)
        ? this.receiptImageCount
        : receiptImageCount as int?,
    jobId: identical(jobId, _unchangedExpenseValue)
        ? this.jobId
        : jobId as String?,
    vehicleId: identical(vehicleId, _unchangedExpenseValue)
        ? this.vehicleId
        : vehicleId as String?,
    itemization: itemization ?? this.itemization,
    approval: approval ?? this.approval,
    lifecycle: lifecycle ?? this.lifecycle,
    auditTrail: auditTrail ?? this.auditTrail,
    priorVersions: priorVersions ?? this.priorVersions,
  );

  Map<String, Object?> toJson() => {
    'expenseId': expenseId,
    'organizationId': organizationId,
    'createdByEmployeeId': createdByEmployeeId,
    'paidByEmployeeId': paidByEmployeeId,
    'expenseDate': expenseDateKey(expenseDate),
    'expenseTimeMinutes': expenseTimeMinutes,
    'vendorName': vendorName,
    'categoryId': categoryId,
    'categoryLabelSnapshot': categoryLabelSnapshot,
    'total': total?.toJson(),
    'receiptId': receiptId,
    'receiptImageCount': receiptImageCount,
    'jobId': jobId,
    'vehicleId': vehicleId,
    'itemization': itemization.toJson(),
    'approval': approval.toJson(),
    'lifecycle': lifecycle.toJson(),
    'auditTrail': auditTrail.map((event) => event.toJson()).toList(),
    'priorVersions': priorVersions.map((version) => version.toJson()).toList(),
  };

  factory StoredExpenseRecord.fromJson(Map<String, Object?> json) =>
      StoredExpenseRecord(
        expenseId: _requiredString(json, 'expenseId'),
        organizationId: _requiredString(json, 'organizationId'),
        createdByEmployeeId: _requiredString(json, 'createdByEmployeeId'),
        paidByEmployeeId: _requiredString(json, 'paidByEmployeeId'),
        expenseDate: parseExpenseDateKey(_requiredString(json, 'expenseDate')),
        expenseTimeMinutes: json['expenseTimeMinutes'] as int?,
        vendorName: readExpenseMerchant(json),
        categoryId: readOptionalExpenseCategory(json, 'categoryId'),
        categoryLabelSnapshot: readOptionalExpenseCategory(
          json,
          'categoryLabelSnapshot',
        ),
        total: readExpenseTotal(json),
        receiptId: json['receiptId'] as String?,
        receiptImageCount: json['receiptImageCount'] as int?,
        jobId: json['jobId'] as String?,
        vehicleId: json['vehicleId'] as String?,
        itemization: json['itemization'] is Map
            ? ExpenseItemization.fromJson(
                (json['itemization'] as Map).cast<String, Object?>(),
              )
            : const ExpenseItemization.totalOnly(),
        approval: ExpenseApproval.fromJson(_requiredMap(json, 'approval')),
        lifecycle: ExpenseLifecycle.fromJson(_requiredMap(json, 'lifecycle')),
        auditTrail: _requiredList(json, 'auditTrail')
            .map(
              (value) => ExpenseAuditEvent.fromJson(
                (value as Map).cast<String, Object?>(),
              ),
            )
            .toList(),
        priorVersions: _optionalList(json, 'priorVersions')
            .map(
              (value) => ExpenseRevisionSnapshot.fromJson(
                (value as Map).cast<String, Object?>(),
              ),
            )
            .toList(),
      );
}

String expenseDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

DateTime parseExpenseDateKey(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) throw const FormatException('Invalid expense date.');
  final result = DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
  if (expenseDateKey(result) != value) {
    throw const FormatException('Invalid expense date.');
  }
  return result;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Missing or invalid $key.');
  return value;
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('Missing or invalid $key.');
  return value.cast<String, Object?>();
}

List<Object?> _requiredList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Missing or invalid $key.');
  return value;
}

List<Object?> _optionalList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return const [];
  if (value is! List) throw FormatException('Invalid $key.');
  return value;
}

DateTime _requiredUtcDate(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('Missing or invalid $key.');
  return DateTime.parse(value).toUtc();
}

DateTime? _optionalUtcDate(Object? value) =>
    value is String ? DateTime.parse(value).toUtc() : null;

void _requireNonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Cannot be empty.');
  }
}

void _validateReceiptImageCount(String? receiptId, int? count) {
  if (count != null && (count < 0 || (receiptId == null && count > 0))) {
    throw ArgumentError(
      'Receipt image count must be nonnegative and attached evidence needs a receipt identity.',
    );
  }
}
