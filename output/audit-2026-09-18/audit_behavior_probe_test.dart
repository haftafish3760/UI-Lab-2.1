// Audit-only probes. Failures demonstrate unmet business expectations;
// this file does not change application behavior or existing regression tests.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_report_projection.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_review_examples.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/inventory/inventory_models.dart';

void main() {
  test(
    'AUD-02: added stock survives closing and reopening SQLite sessions',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tame-audit-stock-',
      );
      final file = File('${directory.path}/audit.sqlite');
      var db = LocalDatabase.file(file);
      await db.verifyIntegrity();
      var session = await openUiLabWorkSession(db);
      var store = PrototypeOperationsStore(workSession: session);
      try {
        store.updateInventoryStock(
          InventoryStockRecord(
            id: 'stock',
            materialId: 'item',
            materialName: 'Generator oil',
            locationId: 'shop',
            locationLabel: 'Shop',
            quantity: 3,
            unitLabel: 'each',
            confidence: InventoryStockConfidence.reported,
            updatedOn: DateTime(2026, 9, 18),
            ownerEmployeeId: 'alex',
          ),
        );
        expect(store.inventoryStock.single.quantity, 3);
        store.dispose();
        session.dispose();
        await db.close();
        db = LocalDatabase.file(file);
        session = await openUiLabWorkSession(db);
        store = PrototypeOperationsStore(workSession: session);
        expect(
          store.inventoryStock.where((s) => s.id == 'stock'),
          hasLength(1),
        );
      } finally {
        store.dispose();
        session.dispose();
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
  final day = DateTime(2026, 9, 10);
  WorkRecord invoice() => WorkRecord(
    id: 'audit-invoice',
    kind: WorkRecordKind.invoice,
    number: 'AUDIT-1',
    title: 'Audit invoice',
    client: 'Customer',
    detail: '',
    pricing: WorkPricingModel.timeAndMaterials,
    total: 100,
    status: WorkRecordStatus.due,
    issuedOn: day,
    dueOn: day,
  );
  test('AUD-04: outstanding balance subtracts a recorded partial payment', () {
    final report = PrototypeReportProjection.build(
      financialEntries: [
        PrototypeFinancialEntry(
          id: 'payment',
          kind: PrototypeFinancialKind.paymentReceived,
          occurredOn: day,
          amountCents: 4000,
          sourceId: 'AUDIT-1',
        ),
      ],
      expenses: [],
      workRecords: [invoice()],
      fromInclusive: DateTime(2026, 9),
      toExclusive: DateTime(2026, 10),
      asOf: DateTime(2026, 9, 18),
    );
    expect(report.outstandingInvoiceCents, 6000);
    expect(report.overdueInvoiceCents, 6000);
  });
  test(
    'AUD-05: employee expense scope uses identity even when names match',
    () {
      final report = PrototypeReportProjection.build(
        financialEntries: [],
        expenses: [
          ExpenseRecord(
            id: 'other-person',
            vendor: 'Supplier',
            category: ExpenseCategory.fuel,
            amount: 10,
            date: day,
            owner: 'Same Name',
            paidByEmployeeId: 'employee-b',
          ),
        ],
        workRecords: [],
        fromInclusive: DateTime(2026, 9),
        toExclusive: DateTime(2026, 10),
        employeeId: 'employee-a',
        employeeName: 'Same Name',
      );
      expect(report.expenses, isEmpty);
    },
  );
  test(
    'AUD-06: EV charging offered by picker contributes to vehicle report',
    () {
      final report = PrototypeReportProjection.build(
        financialEntries: [],
        expenses: [
          ExpenseRecord(
            id: 'charging',
            vendor: 'EV Station',
            category: ExpenseCategory.receiptChargingFees,
            amount: 10,
            date: day,
            owner: 'Owner',
          ),
        ],
        workRecords: [],
        fromInclusive: DateTime(2026, 9),
        toExclusive: DateTime(2026, 10),
      );
      expect(report.fuelAndVehicleExpenseCents, 1000);
    },
  );
  test(
    'AUD-03: review examples must not erase unrelated existing Work records',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tame-audit-review-',
      );
      final db = LocalDatabase.file(File('${directory.path}/audit.sqlite'));
      try {
        await db.verifyIntegrity();
        final store = LocalRecordStore(db);
        await store.commit(
          organizationId: expenseUiLabOrganizationId,
          commandId: 'audit-user-record',
          occurredAt: DateTime.now(),
          writes: [
            LocalRecordWrite(
              domain: 'work/records',
              recordId: 'real-user-record',
              ownerId: 'alex',
              expectedRevision: 0,
              payload: {
                'id': 'real-user-record',
                'auditSentinel': 'must survive',
              },
            ),
          ],
        );
        await loadRequestedWorkExamples(db);
        final rows = await store.read(
          organizationId: expenseUiLabOrganizationId,
          domain: 'work/records',
          ownerIds: {'alex'},
          recordIds: {'real-user-record'},
        );
        expect(rows, hasLength(1));
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
