import 'package:ui_lab_2_1/src/data/work/invoice_approval_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'support/storage/database_harness.dart';
import 'invoice_draft_workflow_test.dart' as fixture;

InvoiceDraftInput priceInput(String price, {bool keepItems = false}) =>
    InvoiceDraftInput.fromPayload({
      ...fixture.inputFor('alex').toPayload(),
      if (!keepItems) 'items': [],
      'servicePrice': price,
      'discount': '10',
      'tax': '5',
    });

void main() {
  test(
    'changing overall price keeps history but invalidates invoice approval',
    () {
      final original = buildConfirmedInvoice(
        priceInput('100'),
      ).copyWith(requiresInvoiceApproval: true);
      final approved = original.copyWith(
        invoiceApprovalHistory: [
          InvoiceApprovalEvent(
            decision: InvoiceApprovalDecision.approved,
            actorEmployeeId: 'supervisor',
            occurredOn: DateTime.utc(2026, 9, 28),
            contentFingerprint: invoiceApprovalFingerprint(original),
          ),
        ],
      );
      expect(invoiceHasCurrentApproval(approved), isTrue);
      final changed = buildConfirmedInvoice(
        priceInput('200'),
        existing: approved,
      );
      expect(changed.requiresInvoiceApproval, isTrue);
      expect(changed.invoiceApprovalHistory, hasLength(1));
      expect(invoiceHasCurrentApproval(changed), isFalse);
      expect(changed.total, 195);
    },
  );

  test(
    'overall price survives SQLite draft recovery and saves as summary invoice',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openUiLabWorkSession(database);
      var draft = await work.openInvoiceDraft();
      final draftId = draft.session.draftId;
      draft.updateInput(priceInput('100,50'));
      await draft.session.flush();
      await draft.session.close();
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkSession(database);
      addTearDown(work.dispose);
      draft = await work.openInvoiceDraft(recoveryDraftId: draftId);
      expect(draft.recoveredInput!.servicePrice, '100,50');
      final record = await draft.confirm();
      expect(record, isNotNull);
      expect(record!.total, 95.5);
      expect(record.documentPresentation, WorkDocumentPresentation.summary);
      expect(record.items.single.type, WorkLineItemType.service);
      expect(record.items.single.customerPrice, 100.5);
      expect(record.items.single.description, 'Completed service');
      await draft.session.close();
      final reopened = await openUiLabWorkSession(database);
      addTearDown(reopened.dispose);
      expect(reopened.records.single.total, 95.5);
    },
  );

  test(
    'editing a simple service as an item retains its edited description',
    () {
      final simple = buildConfirmedInvoice(priceInput('100'));
      final item = Map<String, Object?>.from(
        (encodeWorkRecord(simple)['items'] as List).single as Map,
      )..['description'] = 'Owner-entered item description';
      final raw = InvoiceDraftInput.fromPayload({
        ...priceInput('').toPayload(),
        'itemized': true,
        'items': [item],
      });
      final saved = buildConfirmedInvoice(raw, existing: simple);
      expect(saved.documentPresentation, WorkDocumentPresentation.detailed);
      expect(saved.items.single.description, 'Owner-entered item description');
      expect(InvoiceDraftInput.fromPayload(raw.toPayload()).itemized, isTrue);
    },
  );

  test(
    'price cannot replace an existing itemized breakdown or accept malformed money',
    () {
      expect(
        () => buildConfirmedInvoice(priceInput('100', keepItems: true)),
        throwsA(isA<InvoiceInputValidation>()),
      );
      for (final price in ['', '-1', 'NaN', '1.005', '1,234.56']) {
        expect(
          () => buildConfirmedInvoice(priceInput(price)),
          throwsA(isA<InvoiceInputValidation>()),
          reason: price,
        );
      }
      expect(buildConfirmedInvoice(priceInput('0')).total, 0);
    },
  );
}
