import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_overview_query.dart';

void main() {
  final today = DateTime(2026, 9, 28);
  WorkRecord invoice(
    String id, {
    WorkRecordStatus status = WorkRecordStatus.due,
    DateTime? due,
  }) => WorkRecord(
    id: id,
    kind: WorkRecordKind.invoice,
    number: 'INV-$id',
    title: 'Invoice $id',
    client: 'Customer',
    detail: '',
    pricing: WorkPricingModel.flatRate,
    total: 100,
    status: status,
    dueOn: due ?? today.subtract(const Duration(days: 1)),
  );
  PrototypeFinancialEntry payment(
    String source,
    int cents, {
    PaymentLinkKind link = PaymentLinkKind.invoice,
  }) => PrototypeFinancialEntry(
    id: 'payment-$source',
    kind: PrototypeFinancialKind.paymentReceived,
    occurredOn: today,
    amountCents: cents,
    sourceId: source,
    paymentLinkKind: link,
  );
  List<String> ids(
    WorkOverviewFilter filter,
    List<WorkRecord> records,
    List<PrototypeFinancialEntry> payments,
  ) => workOverviewRecords(
    records: records,
    payments: payments,
    filter: filter,
    now: today,
  ).map((record) => record.id).toList();

  test(
    'partially paid remains outstanding; settled invoice leaves overdue',
    () {
      final records = [
        invoice('partial'),
        invoice('settled'),
        invoice('draft', status: WorkRecordStatus.draft),
        invoice('today', due: today),
      ];
      final ledger = [payment('partial', 4000), payment('settled', 10000)];
      expect(ids(WorkOverviewFilter.unpaidInvoices, records, ledger), [
        'partial',
        'today',
      ]);
      expect(ids(WorkOverviewFilter.overdueInvoices, records, ledger), [
        'partial',
      ]);
      expect(ids(WorkOverviewFilter.paidInvoices, records, ledger), [
        'settled',
      ]);
      expect(ids(WorkOverviewFilter.invoicesWithPayments, records, ledger), [
        'partial',
        'settled',
      ]);
      expect(ids(WorkOverviewFilter.partiallyPaidInvoices, records, ledger), [
        'partial',
      ]);
      expect(ids(WorkOverviewFilter.allInvoices, records, ledger).length, 4);
    },
  );

  test(
    'job deposits and another invoice payment do not settle this invoice',
    () {
      final records = [invoice('one')];
      final ledger = [
        payment('one', 10000, link: PaymentLinkKind.job),
        payment('other', 10000),
      ];
      expect(ids(WorkOverviewFilter.unpaidInvoices, records, ledger), ['one']);
      expect(ids(WorkOverviewFilter.paidInvoices, records, ledger), isEmpty);
    },
  );

  test(
    'company review remains separate from customer approval and sending',
    () {
      final estimate = WorkRecord(
        id: 'review',
        kind: WorkRecordKind.estimate,
        number: 'E-2',
        title: 'Repair',
        client: 'Customer',
        detail: '',
        pricing: WorkPricingModel.flatRate,
        status: WorkRecordStatus.ready,
        requiresCompanyReview: true,
        estimateCompanyReviewStatus: EstimateCompanyReviewStatus.pending,
      );
      expect(ids(WorkOverviewFilter.companyReviewEstimates, [estimate], []), [
        'review',
      ]);
      expect(ids(WorkOverviewFilter.readyEstimates, [estimate], []), isEmpty);
      expect(ids(WorkOverviewFilter.awaitingCustomer, [estimate], []), isEmpty);
      expect(
        ids(WorkOverviewFilter.approvedEstimates, [estimate], []),
        isEmpty,
      );
    },
  );

  test('estimate expiry follows reporting date, not host clock', () {
    final estimate = WorkRecord(
      id: 'estimate',
      kind: WorkRecordKind.estimate,
      number: 'E-1',
      title: 'Repair',
      client: 'Customer',
      detail: '',
      pricing: WorkPricingModel.flatRate,
      status: WorkRecordStatus.sent,
      estimateDates: EstimateDates(
        createdOn: DateTime(2040),
        lastEditedOn: DateTime(2040),
        expiresOn: DateTime(2040, 1, 2),
      ),
    );
    for (final (date, expected) in [
      (DateTime(2040, 1, 2, 23), WorkOverviewFilter.awaitingCustomer),
      (DateTime(2040, 1, 3), WorkOverviewFilter.expiredEstimates),
    ]) {
      expect(
        workOverviewRecords(
          records: [estimate],
          payments: [],
          filter: expected,
          now: date,
        ),
        [estimate],
      );
    }
  });
}
