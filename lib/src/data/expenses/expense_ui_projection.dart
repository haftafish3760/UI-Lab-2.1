import 'package:flutter/foundation.dart';

import 'expense_workflow_models.dart';
import 'expense_record.dart';

@immutable
class ExpenseUiProjectionRecord {
  ExpenseUiProjectionRecord({
    required this.record,
    required this.exactTotal,
    required this.paidByEmployeeId,
    required DateTime expenseDate,
    required this.categoryId,
    required this.approvalState,
    required this.revision,
    required this.isDeleted,
    this.expenseTimeMinutes,
    this.jobId,
    this.vehicleId,
  }) : expenseDate = DateTime(
         expenseDate.year,
         expenseDate.month,
         expenseDate.day,
       ) {
    if (record.id.trim().isEmpty) {
      throw ArgumentError.value(record.id, 'record.id', 'Cannot be empty.');
    }
    if ((record.amount == null) != (exactTotal == null)) {
      throw ArgumentError(
        'The visible record and projection disagree on whether an amount was entered.',
      );
    }
    if (paidByEmployeeId.trim().isEmpty) {
      throw ArgumentError.value(
        paidByEmployeeId,
        'paidByEmployeeId',
        'Cannot be empty.',
      );
    }
    if (record.paidByEmployeeId != null &&
        record.paidByEmployeeId != paidByEmployeeId) {
      throw ArgumentError(
        'The visible record and projection have different employee IDs.',
      );
    }
    if (record.category.storageId != categoryId) {
      throw ArgumentError(
        'The visible record and projection have different categories.',
      );
    }
    final visibleDate = record.resolvedDate;
    if (visibleDate == null ||
        visibleDate.year != this.expenseDate.year ||
        visibleDate.month != this.expenseDate.month ||
        visibleDate.day != this.expenseDate.day) {
      throw ArgumentError(
        'The visible record and projection have different Expense dates.',
      );
    }
    if (record.jobId != jobId) {
      throw ArgumentError(
        'The visible record and projection have different Job IDs.',
      );
    }
    if (_approvalStateFor(record.approvalStatus) != approvalState) {
      throw ArgumentError(
        'The visible record and projection have different approval states.',
      );
    }
    if (exactTotal != null && exactTotal!.minorUnits < 0) {
      throw ArgumentError.value(
        exactTotal!.minorUnits,
        'exactTotal',
        'Cannot be negative.',
      );
    }
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'Must be positive.');
    }
    final minutes = expenseTimeMinutes;
    if (minutes != null && (minutes < 0 || minutes >= 1440)) {
      throw ArgumentError.value(
        minutes,
        'expenseTimeMinutes',
        'Must be between 0 and 1439.',
      );
    }
  }

  final ExpenseRecord record;
  final ExpenseMoney? exactTotal;
  final String paidByEmployeeId;
  final DateTime expenseDate;
  final int? expenseTimeMinutes;
  final String? categoryId;
  final String? jobId;
  final String? vehicleId;
  final ExpenseApprovalState approvalState;
  final int revision;
  final bool isDeleted;

  bool get entersRecordedTotals =>
      exactTotal != null &&
      (approvalState == ExpenseApprovalState.notRequired ||
          approvalState == ExpenseApprovalState.approved);
}

@immutable
class ExpenseUiProjectionQuery {
  const ExpenseUiProjectionQuery({
    this.fromInclusive,
    this.toExclusive,
    this.paidByEmployeeId,
    this.category,
    this.jobId,
    this.vehicleId,
    this.approvalState,
    this.vendorContains,
    this.recordedOnly = false,
  });

  final DateTime? fromInclusive;
  final DateTime? toExclusive;
  final String? paidByEmployeeId;
  final ExpenseCategory? category;
  final String? jobId;
  final String? vehicleId;
  final ExpenseApprovalState? approvalState;
  final String? vendorContains;
  final bool recordedOnly;

  bool matches(ExpenseUiProjectionRecord projection) {
    if (fromInclusive != null &&
        projection.expenseDate.isBefore(fromInclusive!)) {
      return false;
    }
    if (toExclusive != null && !projection.expenseDate.isBefore(toExclusive!)) {
      return false;
    }
    if (paidByEmployeeId != null &&
        projection.paidByEmployeeId != paidByEmployeeId) {
      return false;
    }
    if (category != null && projection.categoryId != category!.storageId) {
      return false;
    }
    if (jobId != null && projection.jobId != jobId) return false;
    if (vehicleId != null && projection.vehicleId != vehicleId) return false;
    if (approvalState != null && projection.approvalState != approvalState) {
      return false;
    }
    final vendorNeedle = vendorContains?.trim().toLowerCase();
    if (vendorNeedle != null &&
        vendorNeedle.isNotEmpty &&
        !projection.record.vendor.toLowerCase().contains(vendorNeedle)) {
      return false;
    }
    if (recordedOnly && !projection.entersRecordedTotals) return false;
    return true;
  }
}

@immutable
class ExpenseUiProjectionSnapshot {
  ExpenseUiProjectionSnapshot({
    Iterable<ExpenseUiProjectionRecord> active = const [],
    Iterable<ExpenseUiProjectionRecord> deleted = const [],
  }) : active = _prepare(active, isDeleted: false),
       deleted = _prepare(deleted, isDeleted: true) {
    final ids = <String>{};
    for (final projection in [...this.active, ...this.deleted]) {
      if (!ids.add(projection.record.id)) {
        throw ArgumentError.value(
          projection.record.id,
          'projection record ID',
          'Must be unique across active and deleted records.',
        );
      }
    }
  }

  static final empty = ExpenseUiProjectionSnapshot();

  final List<ExpenseUiProjectionRecord> active;
  final List<ExpenseUiProjectionRecord> deleted;

  List<ExpenseRecord> get records =>
      List.unmodifiable(active.map((projection) => projection.record));

  List<ExpenseRecord> get deletedRecords =>
      List.unmodifiable(deleted.map((projection) => projection.record));

  ExpenseUiProjectionRecord? projectionById(
    String expenseId, {
    bool includeDeleted = false,
  }) {
    for (final projection in active) {
      if (projection.record.id == expenseId) return projection;
    }
    if (includeDeleted) {
      for (final projection in deleted) {
        if (projection.record.id == expenseId) return projection;
      }
    }
    return null;
  }

  ExpenseRecord? recordById(String expenseId) =>
      projectionById(expenseId)?.record;

  List<ExpenseUiProjectionRecord> query(
    ExpenseUiProjectionQuery query, {
    bool includeDeleted = false,
  }) => List.unmodifiable(
    [...active, if (includeDeleted) ...deleted].where(query.matches),
  );

  List<ExpenseUiProjectionRecord> queryDeleted(
    ExpenseUiProjectionQuery query,
  ) => List.unmodifiable(deleted.where(query.matches));

  ExpenseMoney recordedTotal(
    ExpenseUiProjectionQuery query, {
    String currencyCode = 'USD',
  }) {
    var minorUnits = 0;
    for (final projection in active.where(query.matches)) {
      if (!projection.entersRecordedTotals) continue;
      _requireCurrency(projection.exactTotal!, currencyCode);
      minorUnits += projection.exactTotal!.minorUnits;
    }
    return ExpenseMoney(minorUnits: minorUnits, currencyCode: currencyCode);
  }

  Map<ExpenseCategory, ExpenseMoney> recordedTotalsByCategory(
    ExpenseUiProjectionQuery query, {
    String currencyCode = 'USD',
  }) {
    final totals = <ExpenseCategory, int>{};
    for (final projection in active.where(query.matches)) {
      if (!projection.entersRecordedTotals) continue;
      _requireCurrency(projection.exactTotal!, currencyCode);
      final category = ExpenseCategory.fromStorageId(projection.categoryId);
      totals.update(
        category,
        (value) => value + projection.exactTotal!.minorUnits,
        ifAbsent: () => projection.exactTotal!.minorUnits,
      );
    }
    return Map.unmodifiable(
      totals.map(
        (category, minorUnits) => MapEntry(
          category,
          ExpenseMoney(minorUnits: minorUnits, currencyCode: currencyCode),
        ),
      ),
    );
  }

  ExpenseUiProjectionSnapshot upsert(ExpenseUiProjectionRecord changed) {
    final withoutChanged = <ExpenseUiProjectionRecord>[
      ...active.where((item) => item.record.id != changed.record.id),
      ...deleted.where((item) => item.record.id != changed.record.id),
    ];
    return ExpenseUiProjectionSnapshot(
      active: [
        ...withoutChanged.where((item) => !item.isDeleted),
        if (!changed.isDeleted) changed,
      ],
      deleted: [
        ...withoutChanged.where((item) => item.isDeleted),
        if (changed.isDeleted) changed,
      ],
    );
  }

  ExpenseUiProjectionSnapshot remove(String expenseId) =>
      ExpenseUiProjectionSnapshot(
        active: active.where((item) => item.record.id != expenseId),
        deleted: deleted.where((item) => item.record.id != expenseId),
      );
}

List<ExpenseUiProjectionRecord> _prepare(
  Iterable<ExpenseUiProjectionRecord> records, {
  required bool isDeleted,
}) {
  final prepared = records.toList(growable: false);
  for (final projection in prepared) {
    if (projection.isDeleted != isDeleted) {
      throw ArgumentError(
        'An Expense projection was placed in the wrong lifecycle list.',
      );
    }
  }
  prepared.sort(_compareProjectionMostRecent);
  return List.unmodifiable(prepared);
}

int _compareProjectionMostRecent(
  ExpenseUiProjectionRecord a,
  ExpenseUiProjectionRecord b,
) {
  final date = b.expenseDate.compareTo(a.expenseDate);
  if (date != 0) return date;
  final time = (b.expenseTimeMinutes ?? -1).compareTo(
    a.expenseTimeMinutes ?? -1,
  );
  return time == 0 ? a.record.id.compareTo(b.record.id) : time;
}

void _requireCurrency(ExpenseMoney value, String expectedCurrencyCode) {
  if (value.currencyCode != expectedCurrencyCode) {
    throw StateError(
      'Cannot combine ${value.currencyCode} with $expectedCurrencyCode totals.',
    );
  }
}

ExpenseApprovalState _approvalStateFor(ExpenseApprovalStatus status) =>
    switch (status) {
      ExpenseApprovalStatus.notRequired => ExpenseApprovalState.notRequired,
      ExpenseApprovalStatus.pending => ExpenseApprovalState.pending,
      ExpenseApprovalStatus.approved => ExpenseApprovalState.approved,
      ExpenseApprovalStatus.declined => ExpenseApprovalState.declined,
    };
