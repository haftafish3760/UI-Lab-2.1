part of 'prototype_operations_store.dart';

extension _ExpenseDashboardProjection on PrototypeOperationsStore {
  DashboardDayData _withExpenseProjections(
    DashboardDayData stored,
    DateTime day,
    String? employeeId,
  ) {
    final matching = <String, ExpenseRecord>{
      for (final record in expenses)
        if (_expenseOccursFor(record, day, employeeId)) record.id: record,
    };
    final projectedIds = <String>{};
    final entries = <DayEntry>[];
    for (final entry in stored.entries) {
      final sourceId = entry.sourceRecordId;
      if (entry.kind != DayEntryKind.expense || sourceId == null) {
        entries.add(entry);
        continue;
      }
      final record = matching[sourceId];
      if (record == null) continue;
      entries.add(_expenseDayEntry(record, previous: entry));
      projectedIds.add(sourceId);
    }
    for (final record in matching.values) {
      if (projectedIds.add(record.id)) entries.add(_expenseDayEntry(record));
    }
    return DashboardDayData(plan: stored.plan, entries: entries);
  }

  bool _expenseOccursFor(
    ExpenseRecord record,
    DateTime day,
    String? employeeId,
  ) {
    final date = record.resolvedDate;
    if (date == null ||
        date.year != day.year ||
        date.month != day.month ||
        date.day != day.day) {
      return false;
    }
    return employeeId == null || record.paidByEmployeeId == employeeId;
  }

  DayEntry _expenseDayEntry(ExpenseRecord record, {DayEntry? previous}) {
    final projection = _authorizedExpenseController?.projection.projectionById(
      record.id,
    );
    return DayEntry(
      id: previous?.id ?? 'dashboard-${record.id}',
      time:
          _expenseTimeLabel(projection?.expenseTimeMinutes) ??
          previous?.time ??
          'Time not recorded',
      title: record.displayVendor,
      detail: [record.category.label, ?record.job].join(' · '),
      kind: DayEntryKind.expense,
      color: previous?.color ?? const Color(0xFFA55B00),
      amount: expenseMoney(record.amount),
      reviewStatus: switch (record.approvalStatus) {
        ExpenseApprovalStatus.pending => DayEntryReviewStatus.needsApproval,
        ExpenseApprovalStatus.approved => DayEntryReviewStatus.approved,
        ExpenseApprovalStatus.declined => DayEntryReviewStatus.denied,
        ExpenseApprovalStatus.notRequired => DayEntryReviewStatus.none,
      },
      approvalReason: record.approvalReason,
      approvalExpectedAmount: previous?.approvalExpectedAmount,
      approvalDifference: previous?.approvalDifference,
      linkedRecord: record.job,
      sourceRecordId: record.id,
      submittedBy: record.owner,
    );
  }
}
