import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'normal Work bootstrap preserves store edits and ledger on reopen',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var session = await openUiLabWorkSession(database);
      var store = PrototypeOperationsStore(workSession: session);
      final actor = session.permissions.actorEmployeeId;
      final estimate = WorkRecord(
        id: 'startup-estimate',
        kind: WorkRecordKind.estimate,
        number: 'EST-STARTUP',
        title: 'Startup estimate',
        client: 'Customer',
        detail: 'Repair work',
        pricing: WorkPricingModel.timeAndMaterials,
        createdByEmployeeId: actor,
      );
      final draftInvoice = WorkRecord(
        id: 'startup-invoice',
        kind: WorkRecordKind.invoice,
        number: 'INV-STARTUP',
        title: 'Startup invoice',
        client: 'Customer',
        detail: 'Repair work',
        pricing: WorkPricingModel.timeAndMaterials,
        createdByEmployeeId: actor,
        total: 100,
      );
      expect(await store.addWorkRecord(estimate), isTrue);
      expect(await store.addWorkRecord(draftInvoice), isTrue);
      final invoice = draftInvoice.copyWith(
        status: WorkRecordStatus.due,
        issuedOn: DateTime.utc(2026, 9, 9),
      );
      expect(
        await store.saveWorkAndFinancial(
          records: [invoice],
          entries: [
            PrototypeFinancialEntry(
              id: 'startup-issued',
              kind: PrototypeFinancialKind.invoiceIssued,
              occurredOn: DateTime.utc(2026, 9, 9),
              amountCents: 10000,
              sourceId: invoice.number,
            ),
          ],
        ),
        isTrue,
      );
      final originalCount = store.workRecords.length;
      expect(
        await store.updateWorkRecord(
          estimate.copyWith(serviceLocation: 'Saved location'),
        ),
        isTrue,
      );
      final total = (invoice.total * 100).round();
      final previouslyPaid = store.financialEntries
          .where(
            (entry) =>
                entry.sourceId == invoice.number &&
                entry.kind == PrototypeFinancialKind.paymentReceived,
          )
          .fold(0, (sum, entry) => sum + entry.amountCents);
      expect(
        await store.recordInvoicePayment(
          invoice,
          PrototypeFinancialEntry(
            id: 'startup-payment',
            kind: PrototypeFinancialKind.paymentReceived,
            occurredOn: DateTime.utc(2026, 9, 9),
            amountCents: total - previouslyPaid,
            sourceId: invoice.number,
          ),
        ),
        isTrue,
      );
      final ledgerCount = store.financialEntries.length;
      store.dispose();
      session.dispose();
      await harness.close(database);
      database = await harness.open();
      session = await openUiLabWorkSession(database);
      store = PrototypeOperationsStore(workSession: session);
      addTearDown(session.dispose);
      addTearDown(store.dispose);
      expect(store.workRecords, hasLength(originalCount));
      expect(
        store.workRecords
            .singleWhere((r) => r.id == estimate.id)
            .serviceLocation,
        'Saved location',
      );
      expect(
        store.workRecords.singleWhere((r) => r.id == invoice.id).status,
        WorkRecordStatus.paid,
      );
      expect(store.financialEntries, hasLength(ledgerCount));
      expect(
        store.financialEntries
            .singleWhere((e) => e.id == 'startup-payment')
            .amountCents,
        total - previouslyPaid,
      );
    },
  );
}
