import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_payment_balance.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'payments without invoices survive reopen and retain their link',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      final repository = SqliteWorkRepository(database);
      const job = WorkRecord(
        id: 'job-1',
        kind: WorkRecordKind.job,
        number: 'Job 1',
        title: 'Lawn service',
        client: 'Customer',
        detail: 'Mow lawn',
        pricing: WorkPricingModel.flatRate,
        createdByEmployeeId: 'owner',
      );
      await repository.commit(
        organizationId: 'business',
        commandId: 'seed-job',
        actorEmployeeId: 'owner',
        permissionRevision: 'owner-1',
        occurredAt: DateTime.utc(2030, 1, 1),
        mutations: [
          const WorkRecordMutation(record: job, expectedStorageRevision: 0),
        ],
      );
      WorkSessionPermissions permissions({bool canRecord = true}) =>
          WorkSessionPermissions(
            organizationId: 'business',
            actorEmployeeId: 'owner',
            permissionRevision: 'owner-1',
            visibleCreatorIds: {'owner'},
            editableKinds: WorkRecordKind.values.toSet(),
            canRecordPayments: canRecord,
          );
      final session = await WorkPersistenceSession.open(
        repository,
        permissions(),
      );
      PrototypeFinancialEntry payment(
        String id,
        PaymentLinkKind link,
        String sourceId,
      ) => PrototypeFinancialEntry(
        id: id,
        kind: PrototypeFinancialKind.paymentReceived,
        occurredOn: DateTime.utc(2030, 1, 2),
        amountCents: 4500,
        sourceId: sourceId,
        paymentLinkKind: link,
        payerName: 'Customer',
        description: 'Lawn service',
        paymentMethod: 'Cash',
      );
      expect(
        await session.save(
          financialEntries: [payment('walk-in', PaymentLinkKind.none, '')],
        ),
        isTrue,
      );
      expect(
        await session.save(
          financialEntries: [
            payment('job-payment', PaymentLinkKind.job, job.id),
          ],
        ),
        isTrue,
      );
      session.dispose();
      await harness.close(database);
      database = await harness.open();
      final reopened = await WorkPersistenceSession.open(
        SqliteWorkRepository(database),
        permissions(),
      );
      expect(reopened.financialEntries, hasLength(2));
      expect(
        reopened.financialEntries
            .singleWhere((entry) => entry.id == 'walk-in')
            .paymentLinkKind,
        PaymentLinkKind.none,
      );
      expect(
        reopened.financialEntries
            .singleWhere((entry) => entry.id == 'job-payment')
            .sourceId,
        job.id,
      );
      final invoice = WorkRecord(
        id: 'invoice-1',
        kind: WorkRecordKind.invoice,
        number: job.id,
        title: 'Lawn service invoice',
        client: 'Customer',
        detail: 'Mow lawn',
        pricing: WorkPricingModel.flatRate,
        total: 45,
      );
      expect(invoicePaidCents(invoice, reopened.financialEntries), 0);
      expect(invoiceBalanceCents(invoice, reopened.financialEntries), 4500);
      expect(
        await reopened.save(
          financialEntries: [
            payment('missing-job', PaymentLinkKind.job, 'unknown'),
          ],
        ),
        isFalse,
      );
      final denied = await WorkPersistenceSession.open(
        SqliteWorkRepository(database),
        permissions(canRecord: false),
      );
      addTearDown(denied.dispose);
      addTearDown(reopened.dispose);
      expect(
        await denied.save(
          financialEntries: [payment('denied', PaymentLinkKind.none, '')],
        ),
        isFalse,
      );
    },
  );
}
