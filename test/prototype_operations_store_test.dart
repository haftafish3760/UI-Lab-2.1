import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/inventory/inventory_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';

void main() {
  test('dashboard and Calendar Day share context-scoped day records', () {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);
    final day = DateTime.now();
    final original = store.dashboardDay(
      day: day,
      contextId: 'alex',
      employeeId: 'alex',
    );
    final added = DayEntry(
      id: 'shared-calendar-entry',
      time: '2:15 PM',
      title: 'Customer approved added work',
      detail: 'Added from Calendar Day',
      kind: DayEntryKind.note,
      color: const Color(0xFF65727A),
    );

    store.updateDashboardDay(
      day: day,
      contextId: 'alex',
      data: DashboardDayData(
        plan: original.plan,
        entries: [...original.entries, added],
      ),
    );

    expect(
      store
          .dashboardDay(day: day, contextId: 'alex', employeeId: 'alex')
          .entries
          .map((entry) => entry.id),
      contains('shared-calendar-entry'),
    );
    expect(
      store
          .dashboardDay(day: day, contextId: 'jamie', employeeId: 'jamie')
          .entries
          .where((entry) => entry.id == added.id),
      isEmpty,
    );
  });

  test('monthly financial summary is derived from typed shared records', () {
    final store = PrototypeOperationsStore(
      financialEntries: [
        PrototypeFinancialEntry(
          id: 'invoice-a',
          kind: PrototypeFinancialKind.invoiceIssued,
          occurredOn: DateTime(2026, 8, 5),
          amountCents: 100000,
          sourceId: 'INV-A',
        ),
        PrototypeFinancialEntry(
          id: 'invoice-b',
          kind: PrototypeFinancialKind.invoiceIssued,
          occurredOn: DateTime(2026, 8, 12),
          amountCents: 25000,
          sourceId: 'INV-B',
        ),
        PrototypeFinancialEntry(
          id: 'payment-a',
          kind: PrototypeFinancialKind.paymentReceived,
          occurredOn: DateTime(2026, 8, 14),
          amountCents: 60000,
          sourceId: 'INV-A',
        ),
        PrototypeFinancialEntry(
          id: 'outside-period',
          kind: PrototypeFinancialKind.invoiceIssued,
          occurredOn: DateTime(2026, 9, 1),
          amountCents: 999999,
          sourceId: 'INV-OUTSIDE',
        ),
      ],
      expenses: [
        ExpenseRecord(
          id: 'expense-in-period',
          vendor: 'Supply House',
          category: ExpenseCategory.materials,
          amount: 225.50,
          date: DateTime(2026, 8, 7),
          owner: 'Alex Morgan',
        ),
        ExpenseRecord(
          id: 'expense-outside-period',
          vendor: 'Fuel Stop',
          category: ExpenseCategory.fuel,
          amount: 10,
          date: DateTime(2026, 9, 1),
          owner: 'Alex Morgan',
        ),
      ],
    );
    addTearDown(store.dispose);

    final summary = store.financialSummary(
      fromInclusive: DateTime(2026, 8),
      toExclusive: DateTime(2026, 9),
    );

    expect(summary.invoicedRevenueCents, 125000);
    expect(summary.moneyCollectedCents, 60000);
    expect(summary.recordedExpenseCents, 22550);
    expect(summary.estimatedGrossProfitCents, 102450);
    expect(summary.estimatedGrossMargin, closeTo(.8196, .0001));
  });

  test('expense writes use stable IDs and reject duplicate retries', () async {
    final store = PrototypeOperationsStore(expenses: const []);
    addTearDown(store.dispose);
    final record = ExpenseRecord(
      id: 'EXP-RETRY-1',
      vendor: 'Test Vendor',
      category: ExpenseCategory.tools,
      amount: 19.95,
      date: DateTime.now(),
      owner: 'Alex Morgan',
    );

    await store.addExpense(record);
    await store.addExpense(record);

    expect(store.expenses, hasLength(1));
    expect(store.expenses.single.id, 'EXP-RETRY-1');
  });

  test(
    'expense removal is recoverable and does not duplicate records',
    () async {
      final store = PrototypeOperationsStore(
        expenses: [
          ExpenseRecord(
            id: 'EXP-REMOVE-1',
            vendor: 'Test Vendor',
            category: ExpenseCategory.tools,
            amount: 19.95,
            date: DateTime(2026, 9, 1),
            owner: 'Alex Morgan',
            paidByEmployeeId: 'alex',
          ),
        ],
      );
      addTearDown(store.dispose);

      expect(await store.softDeleteExpense('EXP-REMOVE-1'), isTrue);
      expect(store.expenses, isEmpty);
      expect(store.deletedExpenses.single.id, 'EXP-REMOVE-1');
      expect(await store.softDeleteExpense('EXP-REMOVE-1'), isFalse);

      final restored = await store.restoreExpense('EXP-REMOVE-1');
      expect(restored?.id, 'EXP-REMOVE-1');
      expect(store.deletedExpenses, isEmpty);
      expect(store.expenses.single.id, 'EXP-REMOVE-1');
      expect(await store.restoreExpense('EXP-REMOVE-1'), isNull);
    },
  );

  test('work writes reject duplicate retries and preserve updates', () {
    final store = PrototypeOperationsStore(workRecords: const []);
    addTearDown(store.dispose);
    final record = WorkRecord(
      id: 'job-retry-1',
      kind: WorkRecordKind.job,
      number: 'JOB-RETRY-1',
      title: 'Repair leaking pipe',
      client: 'Jordan Customer',
      detail: 'Awaiting assignment',
      pricing: WorkPricingModel.timeAndMaterials,
      createdOn: DateTime.now(),
      status: WorkRecordStatus.scheduled,
    );

    store.addWorkRecord(record);
    store.addWorkRecord(record);
    store.updateWorkRecord(
      record.copyWith(
        assignee: 'Jordan Lee',
        vehicle: 'Transit 14',
        status: WorkRecordStatus.inProgress,
      ),
    );

    expect(store.workRecords, hasLength(1));
    expect(store.workRecords.single.assignee, 'Jordan Lee');
    expect(store.workRecords.single.vehicle, 'Transit 14');
    expect(store.workRecords.single.status, WorkRecordStatus.inProgress);
  });

  test('any signed estimate item change requires customer approval again', () {
    final signed = WorkRecord(
      id: 'estimate-signed-1',
      kind: WorkRecordKind.estimate,
      number: 'EST-1',
      title: 'Signed estimate',
      client: 'Customer',
      detail: 'Accepted by customer',
      pricing: WorkPricingModel.flatRate,
      status: WorkRecordStatus.accepted,
      items: const [
        WorkLineItem(
          id: 'original',
          type: WorkLineItemType.labor,
          name: 'Original work',
          quantity: 1,
          unit: 'service',
          customerPrice: 100,
        ),
      ],
      total: 100,
      customerSignature: WorkCustomerSignature(
        signedBy: 'Customer',
        signedOn: DateTime(2026, 8, 30),
        signedRevision: 1,
      ),
    );

    final revised = signed.reviseItems([
      ...signed.items,
      const WorkLineItem(
        id: 'one-dollar-change',
        type: WorkLineItemType.material,
        name: 'Additional material',
        quantity: 1,
        unit: 'item',
        customerPrice: 1,
      ),
    ], changedOn: DateTime(2026, 8, 31));

    expect(revised.revision, 2);
    expect(revised.total, 101);
    expect(revised.status, WorkRecordStatus.ready);
    expect(revised.hasCurrentCustomerSignature, isFalse);
    expect(revised.customerSignature?.invalidatedOn, isNotNull);
    expect(revised.detail, 'Accepted by customer');
    expect(revised.resolvedEstimateStage, EstimateStage.readyToSend);
    expect(revised.estimateRevisionHistory.single.customerApproved, isTrue);
  });

  test('inventory cost writes reject duplicate retries', () {
    final store = PrototypeOperationsStore(materialCosts: const []);
    addTearDown(store.dispose);
    final record = MaterialCostRecord(
      id: 'cost-retry-1',
      materialId: 'test-material',
      materialName: 'Test material',
      trade: 'Other',
      vendor: 'Test Vendor',
      purchasedOn: DateTime.now(),
      unitCostCents: 1099,
      unitLabel: 'each',
      ownerEmployeeId: 'alex',
      currencyCode: 'USD',
      confirmedBy: 'Alex Morgan',
    );

    store.addMaterialCost(record);
    store.addMaterialCost(record);

    expect(store.materialCosts, hasLength(1));
    expect(store.materialCosts.single.id, 'cost-retry-1');
  });

  test('stock verification updates one stable location record', () {
    final original = demoInventoryStock.first;
    final store = PrototypeOperationsStore(inventoryStock: [original]);
    addTearDown(store.dispose);

    store.updateInventoryStock(
      original.copyWith(
        quantity: 9,
        confidence: InventoryStockConfidence.verified,
        updatedOn: DateTime.now(),
      ),
    );

    expect(store.inventoryStock, hasLength(1));
    expect(store.inventoryStock.single.quantity, 9);
    expect(
      store.inventoryStock.single.confidence,
      InventoryStockConfidence.verified,
    );
  });
}
