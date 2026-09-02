import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../screens/dashboard/dashboard_models.dart';
import '../screens/expenses/expense_models.dart';
import '../screens/inventory/inventory_models.dart';
import '../screens/work/work_contact_models.dart';
import '../screens/work/work_models.dart';
import 'expense_prototype_store.dart';
import 'expenses/expense_ui_repository_controller.dart';
import 'expenses/expense_ui_projection.dart';
import 'operational_attention.dart';
import 'prototype_operations_demo_data.dart';
import 'prototype_financial_models.dart';
import 'prototype_report_models.dart';
import 'prototype_report_projection.dart';

export 'prototype_financial_models.dart';
export 'prototype_report_models.dart';

class PrototypeOperationsStore extends ChangeNotifier {
  PrototypeOperationsStore({
    List<ExpenseRecord>? expenses,
    List<ScheduledExpenseRecord>? scheduledExpenses,
    List<ScheduledExpenseOccurrence>? scheduledExpenseOccurrences,
    List<PrototypeFinancialEntry>? financialEntries,
    List<WorkRecord>? workRecords,
    List<MaterialCostRecord>? materialCosts,
    List<InventoryStockRecord>? inventoryStock,
    Map<String, DashboardDayData>? dashboardDays,
    WorkCompanyProfile? companyProfile,
    List<WorkCustomerProfile>? customers,
  }) : _expenseStore = ExpensePrototypeStore(
         expenses: expenses,
         scheduledExpenses: scheduledExpenses,
         scheduledExpenseOccurrences: scheduledExpenseOccurrences,
       ),
       _financialEntries = [
         ...(financialEntries ?? prototypeDemoFinancialEntries()),
       ],
       _workRecords = [...(workRecords ?? prototypeDemoWorkRecords())],
       _materialCosts = [...(materialCosts ?? demoMaterialCosts)],
       _inventoryStock = [...(inventoryStock ?? demoInventoryStock)],
       _dashboardDays = {...?dashboardDays},
       _companyProfile = companyProfile ?? demoWorkCompany,
       _customers = [...(customers ?? demoWorkCustomers)] {
    attentionCenter = PrototypeAttentionCenter(
      workRecords: () => _workRecords,
      expenses: () => this.expenses,
      inventoryStock: () => _inventoryStock,
      onChanged: notifyListeners,
    );
    _expenseStore.addListener(notifyListeners);
  }

  final ExpensePrototypeStore _expenseStore;
  ExpenseUiRepositoryController? _authorizedExpenseController;
  final List<PrototypeFinancialEntry> _financialEntries;
  final List<WorkRecord> _workRecords;
  final List<MaterialCostRecord> _materialCosts;
  final List<InventoryStockRecord> _inventoryStock;
  final Map<String, DashboardDayData> _dashboardDays;
  late final PrototypeAttentionCenter attentionCenter;
  WorkCompanyProfile _companyProfile;
  final List<WorkCustomerProfile> _customers;

  ExpensePrototypeStore get expenseStore => _expenseStore;
  UnmodifiableListView<ExpenseRecord> get expenses => UnmodifiableListView(
    _authorizedExpenseController?.records ?? _expenseStore.expenses,
  );
  UnmodifiableListView<ExpenseRecord> get deletedExpenses =>
      UnmodifiableListView(
        _authorizedExpenseController?.deletedRecords ??
            _expenseStore.deletedExpenses,
      );
  UnmodifiableListView<PrototypeFinancialEntry> get financialEntries =>
      UnmodifiableListView(_financialEntries);
  UnmodifiableListView<WorkRecord> get workRecords =>
      UnmodifiableListView(_workRecords);
  UnmodifiableListView<MaterialCostRecord> get materialCosts =>
      UnmodifiableListView(_materialCosts);
  UnmodifiableListView<InventoryStockRecord> get inventoryStock =>
      UnmodifiableListView(_inventoryStock);
  WorkCompanyProfile get companyProfile => _companyProfile;
  UnmodifiableListView<WorkCustomerProfile> get customers =>
      UnmodifiableListView(_customers);

  DashboardDayData dashboardDay({
    required DateTime day,
    required String contextId,
    String? employeeId,
  }) {
    final stored =
        _dashboardDays[_dashboardDayKey(day, contextId)] ??
        demoDataFor(day, employeeId: employeeId);
    return _withExpenseProjections(stored, day, employeeId);
  }

  void updateDashboardDay({
    required DateTime day,
    required String contextId,
    required DashboardDayData data,
  }) {
    _dashboardDays[_dashboardDayKey(day, contextId)] = DashboardDayData(
      plan: data.plan,
      entries: data.entries
          .where(
            (entry) =>
                entry.kind != DayEntryKind.expense ||
                entry.sourceRecordId == null,
          )
          .toList(growable: false),
    );
    notifyListeners();
  }

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
      title: record.vendor,
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

  void updateCompanyProfile(WorkCompanyProfile profile) {
    _companyProfile = profile;
    notifyListeners();
  }

  void replaceCustomers(List<WorkCustomerProfile> customers) {
    _customers
      ..clear()
      ..addAll(customers);
    notifyListeners();
  }

  void bindAuthorizedExpenseController(
    ExpenseUiRepositoryController controller,
  ) {
    if (identical(_authorizedExpenseController, controller)) return;
    _authorizedExpenseController?.removeListener(notifyListeners);
    _authorizedExpenseController = controller;
    controller.addListener(notifyListeners);
    notifyListeners();
  }

  Future<ExpenseRecord?> addExpense(ExpenseRecord record) async {
    final controller = _authorizedExpenseController;
    if (controller == null) {
      _expenseStore.addExpense(record);
      return _expenseStore.expenses
          .where((candidate) => candidate.id == record.id)
          .firstOrNull;
    }
    final paidByEmployeeId = record.paidByEmployeeId;
    if (paidByEmployeeId == null || paidByEmployeeId.trim().isEmpty) {
      return null;
    }
    return controller.create(
      record: record,
      paidByEmployeeId: paidByEmployeeId,
      occurredAtUtc: DateTime.now().toUtc(),
    );
  }

  Future<ExpenseRecord?> updateExpense(
    ExpenseRecord record, {
    String? auditNote,
  }) async {
    final controller = _authorizedExpenseController;
    if (controller == null) {
      _expenseStore.updateExpense(record);
      return _expenseStore.expenses
          .where((candidate) => candidate.id == record.id)
          .firstOrNull;
    }
    return controller.update(
      record: record,
      occurredAtUtc: DateTime.now().toUtc(),
      auditNote: auditNote,
    );
  }

  Future<bool> softDeleteExpense(String expenseId) async {
    final controller = _authorizedExpenseController;
    if (controller == null) return _expenseStore.softDeleteExpense(expenseId);
    return controller.softDelete(
      expenseId: expenseId,
      occurredAtUtc: DateTime.now().toUtc(),
    );
  }

  Future<ExpenseRecord?> restoreExpense(String expenseId) async {
    final controller = _authorizedExpenseController;
    if (controller == null) return _expenseStore.restoreExpense(expenseId);
    return controller.restore(
      expenseId: expenseId,
      occurredAtUtc: DateTime.now().toUtc(),
    );
  }

  void addFinancialEntry(PrototypeFinancialEntry entry) {
    if (_financialEntries.any((candidate) => candidate.id == entry.id)) return;
    _financialEntries.add(entry);
    notifyListeners();
  }

  void addWorkRecord(WorkRecord record) {
    if (_workRecords.any((candidate) => candidate.id == record.id)) return;
    _workRecords.add(record);
    notifyListeners();
  }

  void updateWorkRecord(WorkRecord record) {
    final index = _workRecords.indexWhere(
      (candidate) => candidate.id == record.id,
    );
    if (index < 0) return;
    _workRecords[index] = record;
    notifyListeners();
  }

  void addMaterialCost(MaterialCostRecord record) {
    if (_materialCosts.any((candidate) => candidate.id == record.id)) return;
    _materialCosts.insert(0, record);
    notifyListeners();
  }

  void updateInventoryStock(InventoryStockRecord record) {
    final index = _inventoryStock.indexWhere(
      (candidate) => candidate.id == record.id,
    );
    if (index < 0) {
      _inventoryStock.insert(0, record);
    } else {
      _inventoryStock[index] = record;
    }
    notifyListeners();
  }

  PrototypeFinancialSummary financialSummary({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) {
    final ledger = _financialEntries.where(
      (entry) =>
          !entry.occurredOn.isBefore(fromInclusive) &&
          entry.occurredOn.isBefore(toExclusive),
    );
    final invoiced = ledger
        .where((entry) => entry.kind == PrototypeFinancialKind.invoiceIssued)
        .fold(0, (sum, entry) => sum + entry.amountCents);
    final collected = ledger
        .where((entry) => entry.kind == PrototypeFinancialKind.paymentReceived)
        .fold(0, (sum, entry) => sum + entry.amountCents);
    final authorized = _authorizedExpenseController;
    final expenseTotal = authorized == null
        ? expenses
              .where((record) {
                final date = record.resolvedDate;
                return date != null &&
                    record.countsAsRecordedBusinessCost &&
                    !date.isBefore(fromInclusive) &&
                    date.isBefore(toExclusive);
              })
              .fold(0, (sum, record) => sum + (record.amount * 100).round())
        : authorized.projection
              .recordedTotal(
                ExpenseUiProjectionQuery(
                  fromInclusive: fromInclusive,
                  toExclusive: toExclusive,
                ),
              )
              .minorUnits;
    return PrototypeFinancialSummary(
      invoicedRevenueCents: invoiced,
      moneyCollectedCents: collected,
      recordedExpenseCents: expenseTotal,
    );
  }

  PrototypeReportSummary reportSummary({
    required DateTime fromInclusive,
    required DateTime toExclusive,
    String? employeeId,
    String? employeeName,
    DateTime? asOf,
  }) => PrototypeReportProjection.build(
    financialEntries: _financialEntries,
    expenses: expenses,
    expenseMinorUnitsById: {
      for (final projection
          in _authorizedExpenseController?.projection.active ?? const [])
        projection.record.id: projection.exactTotal.minorUnits,
    },
    workRecords: _workRecords,
    fromInclusive: fromInclusive,
    toExclusive: toExclusive,
    employeeId: employeeId,
    employeeName: employeeName,
    asOf: asOf,
  );

  @override
  void dispose() {
    _expenseStore.removeListener(notifyListeners);
    _authorizedExpenseController?.removeListener(notifyListeners);
    _expenseStore.dispose();
    super.dispose();
  }
}

String _dashboardDayKey(DateTime value, String contextId) =>
    '${value.year}-${value.month}-${value.day}:$contextId';

String? _expenseTimeLabel(int? minutes) {
  if (minutes == null) return null;
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

class PrototypeOperationsScope
    extends InheritedNotifier<PrototypeOperationsStore> {
  const PrototypeOperationsScope({
    required PrototypeOperationsStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static PrototypeOperationsStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PrototypeOperationsScope>();
    assert(scope != null, 'PrototypeOperationsScope is missing.');
    return scope!.notifier!;
  }

  static PrototypeOperationsStore? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PrototypeOperationsScope>()
      ?.notifier;
}
