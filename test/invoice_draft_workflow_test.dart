import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';

import 'support/storage/database_harness.dart';

InvoiceDraftInput inputFor(String actor, {bool existing = false}) =>
    InvoiceDraftInput(
      creatorId: actor,
      number: 'INV-TEST',
      baseStorageRevision: existing ? 1 : 0,
      title: ' Invoice ',
      discount: '12.',
      tax: '1',
      terms: ' Terms ',
      client: 'Customer',
      pricing: WorkPricingModel.flatRate,
      template: 'Service standard',
      createdOn: DateTime(2026, 9, 9),
      items: const [
        WorkLineItem(
          id: 'labor',
          type: WorkLineItemType.labor,
          name: 'Repair',
          quantity: 1,
          unit: 'service',
          customerPrice: 50,
        ),
      ],
      existingRecordId: existing ? 'workflow-invoice' : null,
      recordId: 'workflow-invoice',
      summary: ' Completed service ',
      issuedOn: DateTime(2026, 9, 9),
      dueOn: DateTime(2026, 9, 19),
      sourceJobId: null,
      location: 'Site',
      paymentMethod: 'Not selected',
      pendingLineItem: null,
    );

void main() {
  test(
    'creating an invoice posts it once and consumes recovery input atomically',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final database = await harness.open();
      final work = await openUiLabWorkSession(database);
      addTearDown(work.dispose);
      final controller = await work.openInvoiceDraft();
      final input = inputFor(work.permissions.actorEmployeeId);
      controller.updateInput(input);
      await database.customStatement(
        "CREATE TRIGGER reject_new_invoice BEFORE INSERT ON local_records WHEN NEW.record_id = 'workflow-invoice' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect(await controller.confirm(issue: true), isNull);
      expect(controller.recoveredInput, isNotNull);
      expect(
        work.records.where((record) => record.id == input.recordId),
        isEmpty,
      );
      expect(
        work.financialEntries.where((entry) => entry.sourceId == input.number),
        isEmpty,
      );
      await database.customStatement('DROP TRIGGER reject_new_invoice');
      final issued = await controller.confirm(issue: true);
      expect(issued?.status, WorkRecordStatus.due);
      expect(issued?.total, 39);
      expect(
        work.financialEntries
            .where(
              (entry) =>
                  entry.kind == PrototypeFinancialKind.invoiceIssued &&
                  entry.sourceId == input.number,
            )
            .single
            .amountCents,
        3900,
      );
      expect(
        await work.drafts.find(
          organizationId: work.permissions.organizationId,
          domain: 'work/invoice-editor',
          draftId: controller.session.draftId,
          ownerId: work.permissions.actorEmployeeId,
        ),
        isNull,
      );
      await expectLater(controller.confirm(issue: true), throwsStateError);
      await controller.session.close();
    },
  );

  test(
    'legacy edit recovery retains metadata and survives failed and stale confirmation',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openUiLabWorkSession(database);
      final actor = work.permissions.actorEmployeeId;
      final fixture = inputFor(actor);
      final record = buildConfirmedInvoice(
        InvoiceDraftInput.fromPayload({
          ...fixture.toPayload(),
          'title': 'Original title',
        }),
      ).copyWith(jobNotes: 'Retained note');
      expect(await work.create(record), isTrue);
      final payload = inputFor(actor, existing: true).toPayload();
      await work.drafts.save(
        organizationId: work.permissions.organizationId,
        domain: 'work/invoice-editor',
        draftId: 'edit-workflow-invoice',
        ownerId: actor,
        expectedRevision: 0,
        payload: payload,
        occurredAt: DateTime.utc(2026, 9, 9),
      );
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkSession(database);
      addTearDown(work.dispose);
      final controller = await work.openInvoiceDraft(
        existingRecordId: record.id,
      );
      expect(controller.session.draftId, 'edit-workflow-invoice');
      expect(controller.recoveredInput!.discount, '12.');
      final stale = await work.openInvoiceDraft(existingRecordId: record.id);
      await database.customStatement(
        "CREATE TRIGGER reject_invoice BEFORE UPDATE ON local_records WHEN NEW.record_id = 'workflow-invoice' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect(await controller.confirm(), isNull);
      expect(controller.recoveredInput!.toPayload(), payload);
      expect(work.storageRevisionFor(record.id), 1);
      await database.customStatement('DROP TRIGGER reject_invoice');
      final saved = await controller.confirm();
      expect(saved!.total, 39);
      expect(saved.jobNotes, 'Retained note');
      expect(saved.title, 'Invoice');
      await expectLater(controller.confirm(), throwsStateError);
      expect(await stale.confirm(), isNull);
      expect(work.storageRevisionFor(record.id), 2);
      expect(
        await work.drafts.find(
          organizationId: work.permissions.organizationId,
          domain: 'work/invoice-editor',
          draftId: 'edit-workflow-invoice',
          ownerId: actor,
        ),
        isNull,
      );
      await controller.session.close();
      await stale.session.close();
    },
  );

  test(
    'invalid money stays raw and can be corrected before confirmation',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final controller = await work.openInvoiceDraft();
      final valid = inputFor(work.permissions.actorEmployeeId);
      controller.updateInput(
        InvoiceDraftInput.fromPayload({
          ...valid.toPayload(),
          'discount': '12..',
        }),
      );
      await expectLater(
        controller.confirm(),
        throwsA(isA<InvoiceInputValidation>()),
      );
      expect(controller.recoveredInput!.discount, '12..');
      expect(work.records.where((r) => r.id == valid.recordId), isEmpty);
      controller.updateInput(valid);
      expect((await controller.confirm())!.total, 39);
      await controller.session.close();
      await expectLater(
        work.openInvoiceDraft(recoveryDraftId: 'missing'),
        throwsStateError,
      );
      await expectLater(
        work.openInvoiceDraft(existingRecordId: 'missing'),
        throwsStateError,
      );
    },
  );
}
