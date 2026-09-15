import 'expenses/expense_workflow_models.dart';
import 'work/models/estimate_models.dart';
import 'work/models/work_models.dart';
import 'prototype_financial_models.dart';
import 'prototype_report_models.dart';

class PrototypeReportProjection {
  const PrototypeReportProjection._();

  static PrototypeReportSummary build({
    required Iterable<PrototypeFinancialEntry> financialEntries,
    required Iterable<ExpenseRecord> expenses,
    required Iterable<WorkRecord> workRecords,
    required DateTime fromInclusive,
    required DateTime toExclusive,
    Map<String, int> expenseMinorUnitsById = const {},
    String? employeeId,
    String? employeeName,
    DateTime? asOf,
  }) {
    final today = _dateOnly(asOf ?? DateTime.now());
    final scopedExpenses = expenses.where((record) {
      final date = record.resolvedDate;
      return date != null &&
          _inRange(date, fromInclusive, toExclusive) &&
          (employeeName == null || record.owner == employeeName);
    }).toList();
    final scopedWork = workRecords.where(
      (record) => _belongsToEmployee(record, employeeId, employeeName),
    );
    final recordedExpenses = scopedExpenses
        .where((record) => record.countsAsRecordedBusinessCost)
        .toList();
    final ledger = employeeName == null
        ? financialEntries.where(
            (entry) => _inRange(entry.occurredOn, fromInclusive, toExclusive),
          )
        : const <PrototypeFinancialEntry>[];
    final invoiceLedger = ledger
        .where((entry) => entry.kind == PrototypeFinancialKind.invoiceIssued)
        .toList();
    final paymentLedger = ledger
        .where((entry) => entry.kind == PrototypeFinancialKind.paymentReceived)
        .toList();
    final issuedInvoices = scopedWork.where(
      (record) =>
          record.kind == WorkRecordKind.invoice &&
          _inRange(record.issuedOn, fromInclusive, toExclusive),
    );
    final outstandingInvoices = issuedInvoices.where(
      (record) => record.status != WorkRecordStatus.paid,
    );
    final overdueInvoices = outstandingInvoices.where(
      (record) => record.dueOn != null && record.dueOn!.isBefore(today),
    );
    final completedJobs = scopedWork.where(
      (record) =>
          record.kind == WorkRecordKind.job &&
          record.status == WorkRecordStatus.completed &&
          _inRange(record.completedOn, fromInclusive, toExclusive),
    );
    final activeJobs = scopedWork.where(
      (record) =>
          record.kind == WorkRecordKind.job &&
          record.status != WorkRecordStatus.completed &&
          _overlapsRange(record, fromInclusive, toExclusive),
    );
    final draftEstimates = scopedWork.where(
      (record) =>
          record.kind == WorkRecordKind.estimate &&
          record.resolvedEstimateStage == EstimateStage.draft &&
          _inRange(
            record.estimateDates?.createdOn ?? record.createdOn,
            fromInclusive,
            toExclusive,
          ),
    );
    final pendingEstimateReviews = scopedWork.where(
      (record) =>
          record.kind == WorkRecordKind.estimate &&
          record.requiresCompanyReview &&
          record.estimateCompanyReviewStatus ==
              EstimateCompanyReviewStatus.pending &&
          _inRange(
            record.estimateDates?.lastEditedOn ?? record.createdOn,
            fromInclusive,
            toExclusive,
          ),
    );
    final pendingExpenseApprovals = scopedExpenses.where(
      (record) => record.approvalStatus == ExpenseApprovalStatus.pending,
    );
    final recordsToFinish = scopedExpenses.where(
      (record) => record.requiresSubmitterAttention,
    );
    PrototypeReportSource expenseSource(ExpenseRecord record) =>
        _expenseSource(record, expenseMinorUnitsById);

    return PrototypeReportSummary(
      financial: PrototypeFinancialSummary(
        invoicedRevenueCents: _financialTotal(invoiceLedger),
        moneyCollectedCents: _financialTotal(paymentLedger),
        recordedExpenseCents: _expenseTotal(
          recordedExpenses,
          expenseMinorUnitsById,
        ),
      ),
      invoicesIssued: invoiceLedger.map(_invoiceEntrySource).toList(),
      paymentsReceived: paymentLedger.map(_paymentSource).toList(),
      expenses: scopedExpenses.map(expenseSource).toList(),
      recordedExpenses: recordedExpenses.map(expenseSource).toList(),
      completedJobs: completedJobs.map(_workSource).toList(),
      activeJobs: activeJobs.map(_workSource).toList(),
      draftEstimates: draftEstimates.map(_workSource).toList(),
      outstandingInvoices: outstandingInvoices.map(_workSource).toList(),
      overdueInvoices: overdueInvoices.map(_workSource).toList(),
      materialExpenses: recordedExpenses
          .where((record) => record.category == ExpenseCategory.materials)
          .map(expenseSource)
          .toList(),
      fuelAndVehicleExpenses: recordedExpenses
          .where((record) => _vehicleCategories.contains(record.category))
          .map(expenseSource)
          .toList(),
      otherExpenses: recordedExpenses
          .where(
            (record) =>
                record.category != ExpenseCategory.materials &&
                !_vehicleCategories.contains(record.category),
          )
          .map(expenseSource)
          .toList(),
      pendingAdminReview: [
        ...pendingEstimateReviews.map(_workSource),
        ...pendingExpenseApprovals.map(expenseSource),
        ...overdueInvoices.map(_workSource),
      ],
      recordsToFinish: recordsToFinish.map(expenseSource).toList(),
      waitingForApproval: [
        ...pendingExpenseApprovals.map(expenseSource),
        ...pendingEstimateReviews.map(_workSource),
      ],
      fuelExpenses: recordedExpenses
          .where((record) => record.category == ExpenseCategory.fuel)
          .map(expenseSource)
          .toList(),
      vehicleRepairExpenses: recordedExpenses
          .where((record) => record.category == ExpenseCategory.vehicleRepair)
          .map(expenseSource)
          .toList(),
      vehicleMaintenanceExpenses: recordedExpenses
          .where(
            (record) => record.category == ExpenseCategory.vehicleMaintenance,
          )
          .map(expenseSource)
          .toList(),
    );
  }
}

const _vehicleCategories = <ExpenseCategory>{
  ExpenseCategory.fuel,
  ExpenseCategory.vehiclePayment,
  ExpenseCategory.vehicleInsurance,
  ExpenseCategory.vehicleRepair,
  ExpenseCategory.vehicleMaintenance,
  ExpenseCategory.vehicle,
};

bool _belongsToEmployee(
  WorkRecord record,
  String? employeeId,
  String? employeeName,
) {
  if (employeeName == null) return true;
  if (record.kind == WorkRecordKind.estimate) {
    return record.createdByEmployeeId == employeeId ||
        record.assignee == employeeName;
  }
  return record.assignee == employeeName;
}

bool _inRange(DateTime? date, DateTime fromInclusive, DateTime toExclusive) =>
    date != null && !date.isBefore(fromInclusive) && date.isBefore(toExclusive);

bool _overlapsRange(
  WorkRecord record,
  DateTime fromInclusive,
  DateTime toExclusive,
) {
  final start = record.scheduledStart ?? record.createdOn;
  if (start == null) return false;
  final end = record.scheduledEnd ?? start;
  return !end.isBefore(fromInclusive) && start.isBefore(toExclusive);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int _financialTotal(Iterable<PrototypeFinancialEntry> entries) =>
    entries.fold(0, (sum, entry) => sum + entry.amountCents);

int _expenseTotal(
  Iterable<ExpenseRecord> expenses,
  Map<String, int> expenseMinorUnitsById,
) => expenses
    .where((record) => record.amount != null)
    .fold(
      0,
      (sum, record) =>
          sum +
          (expenseMinorUnitsById[record.id] ?? (record.amount! * 100).round()),
    );

PrototypeReportSource _expenseSource(
  ExpenseRecord record,
  Map<String, int> expenseMinorUnitsById,
) => PrototypeReportSource(
  kind: PrototypeReportSourceKind.expense,
  id: record.id,
  title: record.displayVendor,
  detail:
      '${record.category.label} · ${record.owner}${record.amount == null ? ' · Amount not entered' : ''}',
  amountCents: record.amount == null
      ? null
      : expenseMinorUnitsById[record.id] ?? (record.amount! * 100).round(),
);

PrototypeReportSource _workSource(WorkRecord record) => PrototypeReportSource(
  kind: PrototypeReportSourceKind.workRecord,
  id: record.id,
  title: record.title,
  detail: '${record.number} · ${record.client} · ${record.status.label}',
  amountCents: record.kind == WorkRecordKind.invoice
      ? (record.total * 100).round()
      : null,
);

PrototypeReportSource _paymentSource(PrototypeFinancialEntry entry) =>
    PrototypeReportSource(
      kind: PrototypeReportSourceKind.payment,
      id: entry.id,
      title: 'Payment for ${entry.sourceId}',
      detail: entry.paymentMethod.isEmpty
          ? 'Payment received'
          : entry.paymentMethod,
      amountCents: entry.amountCents,
      linkedWorkNumber: entry.sourceId,
    );

PrototypeReportSource _invoiceEntrySource(PrototypeFinancialEntry entry) =>
    PrototypeReportSource(
      kind: PrototypeReportSourceKind.invoiceEntry,
      id: entry.id,
      title: 'Invoice ${entry.sourceId}',
      detail: 'Invoice issued',
      amountCents: entry.amountCents,
      linkedWorkNumber: entry.sourceId,
    );
