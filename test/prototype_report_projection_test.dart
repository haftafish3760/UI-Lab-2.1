import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/prototype_report_projection.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';

void main() {
  test('authorized exact cents override UI display doubles', () {
    final day = DateTime(2026, 8, 30);
    final expense = ExpenseRecord(
      id: 'exact-expense',
      vendor: 'Exact Supply',
      category: ExpenseCategory.materials,
      amount: 10.004,
      date: day,
      owner: 'Alex Morgan',
    );

    final summary = PrototypeReportProjection.build(
      financialEntries: const [],
      expenses: [expense],
      expenseMinorUnitsById: const {'exact-expense': 1001},
      workRecords: const [],
      fromInclusive: day,
      toExclusive: day.add(const Duration(days: 1)),
    );

    expect(summary.financial.recordedExpenseCents, 1001);
    expect(summary.expenses.single.amountCents, 1001);
  });

  final from = DateTime(2026, 1);
  final to = DateTime(2026, 2);
  final asOf = DateTime(2026, 2, 1);

  test('company report totals and review counts come from source records', () {
    final store = _store();
    final summary = store.reportSummary(
      fromInclusive: from,
      toExclusive: to,
      asOf: asOf,
    );

    expect(summary.financial.invoicedRevenueCents, 100000);
    expect(summary.financial.moneyCollectedCents, 60000);
    expect(summary.financial.recordedExpenseCents, 4000);
    expect(summary.outstandingInvoiceCents, 20000);
    expect(summary.overdueInvoiceCents, 20000);
    expect(summary.materialExpenseCents, 0);
    expect(summary.fuelAndVehicleExpenseCents, 0);
    expect(summary.otherExpenseCents, 4000);
    expect(summary.pendingAdminReview, hasLength(3));
    expect(
      summary.pendingAdminReview.map((source) => source.id),
      containsAll(['estimate-review', 'expense-materials', 'invoice-due']),
    );
    expect(
      store
          .financialSummary(fromInclusive: from, toExclusive: to)
          .recordedExpenseCents,
      4000,
    );
  });

  test(
    'outstanding and overdue show the unpaid cents after partial payment',
    () {
      final invoice = WorkRecord(
        id: 'invoice-1',
        kind: WorkRecordKind.invoice,
        number: 'INV-1',
        title: 'Repair',
        client: 'Customer',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
        status: WorkRecordStatus.due,
        total: 100,
        issuedOn: DateTime(2026, 1, 2),
        dueOn: DateTime(2026, 1, 10),
      );
      final payments = [
        PrototypeFinancialEntry(
          id: 'payment-1',
          kind: PrototypeFinancialKind.paymentReceived,
          occurredOn: DateTime(2026, 1, 11),
          amountCents: 4000,
          sourceId: invoice.number,
        ),
        PrototypeFinancialEntry(
          id: 'future-payment',
          kind: PrototypeFinancialKind.paymentReceived,
          occurredOn: DateTime(2026, 2, 3),
          amountCents: 6000,
          sourceId: invoice.id,
        ),
      ];
      final summary = PrototypeReportProjection.build(
        financialEntries: payments,
        expenses: const [],
        workRecords: [invoice],
        fromInclusive: DateTime(2026, 1),
        toExclusive: DateTime(2026, 2),
        asOf: DateTime(2026, 2, 1),
      );
      expect(summary.outstandingInvoiceCents, 6000);
      expect(summary.overdueInvoiceCents, 6000);
      expect(summary.outstandingInvoices.single.amountCents, 6000);
      final paidLater = PrototypeReportProjection.build(
        financialEntries: payments,
        expenses: const [],
        workRecords: [invoice],
        fromInclusive: DateTime(2026, 1),
        toExclusive: DateTime(2026, 2),
        asOf: DateTime(2026, 2, 4),
      );
      expect(paidLater.outstandingInvoices, isEmpty);
      expect(paidLater.outstandingInvoiceCents, 0);
    },
  );

  test(
    'employee report excludes company money and other employees records',
    () {
      final store = _store();
      final summary = store.reportSummary(
        fromInclusive: from,
        toExclusive: to,
        employeeId: 'alex',
        employeeName: 'Alex Morgan',
        asOf: asOf,
      );

      expect(summary.financial.invoicedRevenueCents, 0);
      expect(summary.financial.moneyCollectedCents, 0);
      expect(summary.expenses, hasLength(2));
      expect(summary.recordedExpenses, isEmpty);
      expect(summary.scopedExpenseCents, 5000);
      expect(summary.completedJobs.single.id, 'job-complete');
      expect(summary.activeJobs.single.id, 'job-active');
      expect(summary.draftEstimates.single.id, 'estimate-draft');
      expect(summary.recordsToFinish.single.id, 'expense-fuel');
      expect(
        summary.waitingForApproval.map((source) => source.id),
        containsAll(['expense-materials', 'estimate-review']),
      );
    },
  );
}

PrototypeOperationsStore _store() => PrototypeOperationsStore(
  financialEntries: [
    PrototypeFinancialEntry(
      id: 'ledger-invoice',
      kind: PrototypeFinancialKind.invoiceIssued,
      occurredOn: DateTime(2026, 1, 2),
      amountCents: 100000,
      sourceId: 'INV-1',
    ),
    PrototypeFinancialEntry(
      id: 'ledger-payment',
      kind: PrototypeFinancialKind.paymentReceived,
      occurredOn: DateTime(2026, 1, 9),
      amountCents: 60000,
      sourceId: 'INV-1',
    ),
  ],
  expenses: [
    ExpenseRecord(
      id: 'expense-materials',
      vendor: 'Supply Company',
      category: ExpenseCategory.materials,
      amount: 30,
      date: DateTime(2026, 1, 3),
      owner: 'Alex Morgan',
      approvalStatus: ExpenseApprovalStatus.pending,
    ),
    ExpenseRecord(
      id: 'expense-fuel',
      vendor: 'Fuel Stop',
      category: ExpenseCategory.fuel,
      amount: 20,
      date: DateTime(2026, 1, 4),
      owner: 'Alex Morgan',
      requiresSubmitterAttention: true,
    ),
    ExpenseRecord(
      id: 'expense-office',
      vendor: 'Office Store',
      category: ExpenseCategory.office,
      amount: 40,
      date: DateTime(2026, 1, 5),
      owner: 'Jordan Lee',
    ),
  ],
  workRecords: [
    _work(
      id: 'job-complete',
      kind: WorkRecordKind.job,
      status: WorkRecordStatus.completed,
      assignee: 'Alex Morgan',
      completedOn: DateTime(2026, 1, 6),
    ),
    _work(
      id: 'job-active',
      kind: WorkRecordKind.job,
      status: WorkRecordStatus.inProgress,
      assignee: 'Alex Morgan',
      scheduledStart: DateTime(2026, 1, 7),
      scheduledEnd: DateTime(2026, 1, 8),
    ),
    _work(
      id: 'estimate-draft',
      kind: WorkRecordKind.estimate,
      status: WorkRecordStatus.draft,
      createdOn: DateTime(2026, 1, 9),
      estimateStage: EstimateStage.draft,
    ),
    _work(
      id: 'estimate-review',
      kind: WorkRecordKind.estimate,
      status: WorkRecordStatus.ready,
      createdOn: DateTime(2026, 1, 10),
      estimateStage: EstimateStage.readyToSend,
      requiresCompanyReview: true,
      estimateCompanyReviewStatus: EstimateCompanyReviewStatus.pending,
    ),
    _work(
      id: 'invoice-due',
      kind: WorkRecordKind.invoice,
      status: WorkRecordStatus.due,
      issuedOn: DateTime(2026, 1, 2),
      dueOn: DateTime(2026, 1, 10),
      total: 200,
    ),
  ],
);

WorkRecord _work({
  required String id,
  required WorkRecordKind kind,
  required WorkRecordStatus status,
  String? assignee,
  DateTime? createdOn,
  DateTime? issuedOn,
  DateTime? dueOn,
  DateTime? scheduledStart,
  DateTime? scheduledEnd,
  DateTime? completedOn,
  double total = 0,
  EstimateStage? estimateStage,
  bool requiresCompanyReview = false,
  EstimateCompanyReviewStatus estimateCompanyReviewStatus =
      EstimateCompanyReviewStatus.notRequired,
}) => WorkRecord(
  id: id,
  kind: kind,
  number: id.toUpperCase(),
  title: id,
  client: 'Test Customer',
  detail: 'Test record',
  pricing: WorkPricingModel.flatRate,
  assignee: assignee,
  createdOn: createdOn,
  issuedOn: issuedOn,
  dueOn: dueOn,
  scheduledStart: scheduledStart,
  scheduledEnd: scheduledEnd,
  completedOn: completedOn,
  status: status,
  total: total,
  estimateStage: estimateStage,
  requiresCompanyReview: requiresCompanyReview,
  estimateCompanyReviewStatus: estimateCompanyReviewStatus,
);
