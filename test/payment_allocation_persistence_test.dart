import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_payment_balance.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';

import 'support/storage/database_harness.dart';

void main() {
  test('one deposit is applied once and never collected twice', () async {
    final harness = await DatabaseHarness.create();
    addTearDown(harness.dispose);
    var database = await harness.open();
    final repository = SqliteWorkRepository(database);
    const job = WorkRecord(
      id: 'job-deposit',
      kind: WorkRecordKind.job,
      number: 'Job 1',
      title: 'Repair',
      client: 'Customer',
      detail: 'Repair work',
      pricing: WorkPricingModel.flatRate,
      createdByEmployeeId: 'owner',
    );
    const invoice = WorkRecord(
      id: 'invoice-deposit',
      kind: WorkRecordKind.invoice,
      number: 'Invoice 1',
      title: 'Repair',
      client: 'Customer',
      detail: 'Repair work',
      pricing: WorkPricingModel.flatRate,
      createdByEmployeeId: 'owner',
      sourceId: 'job-deposit',
      status: WorkRecordStatus.due,
      total: 100,
    );
    const secondInvoice = WorkRecord(
      id: 'invoice-deposit-2',
      kind: WorkRecordKind.invoice,
      number: 'Invoice 2',
      title: 'Repair follow-up',
      client: 'Customer',
      detail: 'Repair work',
      pricing: WorkPricingModel.flatRate,
      createdByEmployeeId: 'owner',
      sourceId: 'job-deposit',
      status: WorkRecordStatus.due,
      total: 100,
    );
    await repository.commit(
      organizationId: 'business',
      commandId: 'seed-allocation',
      actorEmployeeId: 'owner',
      permissionRevision: 'owner-1',
      occurredAt: DateTime.utc(2030, 1, 1),
      mutations: [
        WorkRecordMutation(record: job, expectedStorageRevision: 0),
        WorkRecordMutation(record: invoice, expectedStorageRevision: 0),
        WorkRecordMutation(record: secondInvoice, expectedStorageRevision: 0),
      ],
    );
    final permissions = WorkSessionPermissions(
      organizationId: 'business',
      actorEmployeeId: 'owner',
      permissionRevision: 'owner-1',
      visibleCreatorIds: {'owner'},
      editableKinds: {WorkRecordKind.invoice},
      canRecordPayments: true,
    );
    var work = await WorkPersistenceSession.open(repository, permissions);
    final deposit = PrototypeFinancialEntry(
      id: 'deposit-1',
      kind: PrototypeFinancialKind.paymentReceived,
      occurredOn: DateTime.utc(2030, 1, 2),
      amountCents: 6000,
      sourceId: job.id,
      paymentLinkKind: PaymentLinkKind.job,
      description: 'Repair deposit',
      paymentMethod: 'Cash',
    );
    expect(await work.save(financialEntries: [deposit]), isTrue);
    final otherSession = await WorkPersistenceSession.open(
      repository,
      permissions,
    );
    addTearDown(otherSession.dispose);
    final application = PrototypeFinancialEntry(
      id: 'apply-1',
      kind: PrototypeFinancialKind.paymentApplied,
      occurredOn: DateTime.utc(2030, 1, 3),
      amountCents: 6000,
      sourceId: invoice.id,
      sourcePaymentId: deposit.id,
      description: 'Deposit applied',
      paymentMethod: 'Cash',
    );
    expect(await work.save(financialEntries: [application]), isTrue);
    expect(invoiceBalanceCents(invoice, work.financialEntries), 4000);
    expect(
      await otherSession.save(
        financialEntries: [
          PrototypeFinancialEntry(
            id: 'apply-other-invoice',
            kind: PrototypeFinancialKind.paymentApplied,
            occurredOn: DateTime.utc(2030, 1, 3),
            amountCents: 6000,
            sourceId: secondInvoice.id,
            sourcePaymentId: deposit.id,
          ),
        ],
      ),
      isFalse,
    );
    expect(
      work.financialEntries
          .where(
            (entry) => entry.kind == PrototypeFinancialKind.paymentReceived,
          )
          .fold(0, (sum, entry) => sum + entry.amountCents),
      6000,
    );
    expect(
      await work.save(
        financialEntries: [
          PrototypeFinancialEntry(
            id: 'apply-twice',
            kind: PrototypeFinancialKind.paymentApplied,
            occurredOn: DateTime.utc(2030, 1, 4),
            amountCents: 100,
            sourceId: invoice.id,
            sourcePaymentId: deposit.id,
          ),
        ],
      ),
      isFalse,
    );
    work.dispose();
    await harness.close(database);
    database = await harness.open();
    work = await WorkPersistenceSession.open(
      SqliteWorkRepository(database),
      permissions,
    );
    addTearDown(work.dispose);
    expect(invoiceBalanceCents(invoice, work.financialEntries), 4000);
    expect(work.financialEntries, hasLength(2));
  });
}
