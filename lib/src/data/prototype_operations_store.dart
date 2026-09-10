import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../screens/dashboard/dashboard_models.dart';
import 'expenses/expense_workflow_models.dart';
import '../screens/inventory/inventory_models.dart';
import 'work/models/work_contact_models.dart';
import 'work/models/work_models.dart';
import 'expense_prototype_store.dart';
import 'work/work_persistence_session.dart';
import '../screens/dashboard/work_dashboard_projection.dart';
import 'work/directory_persistence_session.dart';
import 'workday/workday_persistence_session.dart';
import 'day_notes/day_note_persistence_session.dart';
import 'day_notes/day_note_dashboard_projection.dart';
import 'workday/workday_dashboard_projection.dart';
import 'expenses/expense_ui_repository_controller.dart';
import 'expenses/expense_ui_projection.dart';
import 'operational_attention.dart';
import 'prototype_operations_demo_data.dart';
import 'prototype_financial_models.dart';
import 'prototype_report_models.dart';
import 'prototype_report_projection.dart';

export 'prototype_financial_models.dart';
export 'prototype_report_models.dart';

part 'prototype_expense_dashboard_projection.dart';

class PrototypeOperationsStore extends ChangeNotifier {
  PrototypeOperationsStore({
    this.workSession,
    this.workdaySession,
    this.dayNoteSession,
    this.directorySession,
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
         ...(financialEntries ??
             (workSession == null
                 ? prototypeDemoFinancialEntries()
                 : const [])),
       ],
       _workRecords = [
         ...(workRecords ??
             (workSession == null ? prototypeDemoWorkRecords() : const [])),
       ],
       _materialCosts = [...(materialCosts ?? demoMaterialCosts)],
       _inventoryStock = [...(inventoryStock ?? demoInventoryStock)],
       _dashboardDays = {...?dashboardDays},
       _companyProfile = companyProfile ?? demoWorkCompany,
       _customers = [...(customers ?? demoWorkCustomers)] {
    attentionCenter = PrototypeAttentionCenter(
      workRecords: () => this.workRecords,
      expenses: () => this.expenses,
      inventoryStock: () => _inventoryStock,
      onChanged: notifyListeners,
    );
    _expenseStore.addListener(notifyListeners);
    workSession?.addListener(notifyListeners);
    workdaySession?.addListener(notifyListeners);
    dayNoteSession?.addListener(notifyListeners);
    directorySession?.addListener(notifyListeners);
  }

  final WorkPersistenceSession? workSession;
  final WorkdayPersistenceSession? workdaySession;
  final DayNotePersistenceSession? dayNoteSession;
  final DirectoryPersistenceSession? directorySession;
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
      UnmodifiableListView(workSession?.financialEntries ?? _financialEntries);
  UnmodifiableListView<WorkRecord> get workRecords =>
      UnmodifiableListView(workSession?.records ?? _workRecords);
  UnmodifiableListView<MaterialCostRecord> get materialCosts =>
      UnmodifiableListView(_materialCosts);
  UnmodifiableListView<InventoryStockRecord> get inventoryStock =>
      UnmodifiableListView(_inventoryStock);
  WorkCompanyProfile get companyProfile =>
      directorySession?.company ?? _companyProfile;
  UnmodifiableListView<WorkCustomerProfile> get customers =>
      directorySession?.customers ?? UnmodifiableListView(_customers);

  DashboardDayData dashboardDay({
    required DateTime day,
    required String contextId,
    String? employeeId,
  }) {
    final stored =
        _dashboardDays[_dashboardDayKey(day, contextId)] ??
        demoDataFor(day, employeeId: employeeId);
    final work = workSession;
    final planned = work == null
        ? stored
        : withWorkPlanProjections(
            data: stored,
            records: work.records,
            day: day,
            employeeId: employeeId,
          );
    final activity = work == null
        ? planned
        : withWorkStatusProjections(
            data: planned,
            events: work.statusEvents,
            day: day,
            employeeId: employeeId,
          );
    final data = _withExpenseProjections(activity, day, employeeId);
    final workday = workdaySession;
    final workdayData = workday == null
        ? data
        : withWorkdayProjections(
            data: data,
            session: workday,
            day: day,
            employeeId: employeeId,
          );
    final notes = dayNoteSession;
    return notes == null
        ? workdayData
        : withDayNoteProjections(
            data: workdayData,
            session: notes,
            day: day,
            employeeId: employeeId,
          );
  }

  void updateDashboardDay({
    required DateTime day,
    required String contextId,
    required DashboardDayData data,
  }) {
    _dashboardDays[_dashboardDayKey(day, contextId)] = DashboardDayData(
      plan: workSession == null
          ? data.plan
          : data.plan
                .where((item) => item.kind != PlanItemKind.jobStop)
                .toList(growable: false),
      entries: data.entries
          .where(
            (entry) =>
                (workSession == null ||
                    entry.kind != DayEntryKind.jobActivity) &&
                (entry.kind != DayEntryKind.expense ||
                    entry.sourceRecordId == null) &&
                (workdaySession == null ||
                    entry.kind != DayEntryKind.workday) &&
                (dayNoteSession == null ||
                    entry.kind != DayEntryKind.note ||
                    entry.sourceRecordId == null),
          )
          .toList(growable: false),
    );
    notifyListeners();
  }

  Future<bool> updateCompanyProfile(WorkCompanyProfile profile) {
    if (directorySession != null) return directorySession!.saveCompany(profile);
    _companyProfile = profile;
    notifyListeners();
    return Future.value(true);
  }

  Future<bool> replaceCustomers(List<WorkCustomerProfile> customers) {
    if (directorySession != null) {
      return directorySession!.saveCustomers(customers);
    }
    _customers
      ..clear()
      ..addAll(customers);
    notifyListeners();
    return Future.value(true);
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

  Future<bool> addFinancialEntry(PrototypeFinancialEntry entry) {
    final session = workSession;
    if (session != null) return session.save(financialEntries: [entry]);
    if (_financialEntries.any((candidate) => candidate.id == entry.id)) {
      return Future.value(true);
    }
    _financialEntries.add(entry);
    notifyListeners();
    return Future.value(true);
  }

  Future<bool> addWorkRecord(WorkRecord record) {
    final session = workSession;
    if (session != null) return session.create(record);
    if (_workRecords.any((candidate) => candidate.id == record.id)) {
      return Future.value(true);
    }
    _workRecords.add(record);
    notifyListeners();
    return Future.value(true);
  }

  Future<bool> updateWorkRecord(WorkRecord record) {
    final session = workSession;
    if (session != null) return session.update(record);
    final index = _workRecords.indexWhere(
      (candidate) => candidate.id == record.id,
    );
    if (index < 0) return Future.value(false);
    _workRecords[index] = record;
    notifyListeners();
    return Future.value(true);
  }

  Future<bool> saveWorkAndFinancial({
    required List<WorkRecord> records,
    required List<PrototypeFinancialEntry> entries,
  }) {
    final session = workSession;
    if (session != null) {
      return session.save(records: records, financialEntries: entries);
    }
    for (final record in records) {
      final index = _workRecords.indexWhere((item) => item.id == record.id);
      if (index < 0) {
        _workRecords.add(record);
      } else {
        _workRecords[index] = record;
      }
    }
    for (final entry in entries) {
      if (!_financialEntries.any((item) => item.id == entry.id)) {
        _financialEntries.add(entry);
      }
    }
    notifyListeners();
    return Future.value(true);
  }

  Future<bool> recordInvoicePayment(
    WorkRecord invoice,
    PrototypeFinancialEntry entry,
  ) {
    final session = workSession;
    if (session != null) return session.save(financialEntries: [entry]);
    final paid =
        financialEntries
            .where(
              (item) =>
                  item.kind == PrototypeFinancialKind.paymentReceived &&
                  item.sourceId == invoice.number &&
                  item.id != entry.id,
            )
            .fold(0, (sum, item) => sum + item.amountCents) +
        entry.amountCents;
    return saveWorkAndFinancial(
      records: [
        if (paid == (invoice.total * 100).round())
          invoice.copyWith(status: WorkRecordStatus.paid),
      ],
      entries: [entry],
    );
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
    final ledger = financialEntries.where(
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
    financialEntries: financialEntries,
    expenses: expenses,
    expenseMinorUnitsById: {
      for (final projection
          in _authorizedExpenseController?.projection.active ?? const [])
        projection.record.id: projection.exactTotal.minorUnits,
    },
    workRecords: workRecords,
    fromInclusive: fromInclusive,
    toExclusive: toExclusive,
    employeeId: employeeId,
    employeeName: employeeName,
    asOf: asOf,
  );

  @override
  void dispose() {
    workSession?.removeListener(notifyListeners);
    workdaySession?.removeListener(notifyListeners);
    dayNoteSession?.removeListener(notifyListeners);
    directorySession?.removeListener(notifyListeners);
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
