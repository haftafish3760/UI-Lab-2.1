import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_customer_approval.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'quote_draft_workflow_test.dart' show quoteInput;
import 'support/storage/database_harness.dart';

void main() {
  for (final kind in [WorkRecordKind.estimate, WorkRecordKind.quote]) {
    test(
      '${kind.name} converts atomically to one unissued invoice and survives restart',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        var db = await harness.open();
        var work = await openUiLabWorkSession(db);
        final source = buildConfirmedEstimate(
          quoteInput(
            work.permissions.actorEmployeeId,
            kind: kind,
            id: 'source',
            number: kind == WorkRecordKind.quote ? 'Quote 1' : 'Estimate 1',
          ),
          now: DateTime.now(),
        );
        expect(await work.create(source), isTrue);
        final approved = source.recordCustomerApproval(
          WorkCustomerApproval(
            method: CustomerApprovalMethod.verbal,
            customerName: source.client,
            recordedByEmployeeId: work.permissions.actorEmployeeId,
            recordedOn: DateTime.now().toUtc(),
            revision: source.revision,
          ),
        );
        expect(await work.update(approved), isTrue);
        final version = work.storageRevisionFor(source.id);
        Future<WorkRecord?> convert({int? revision}) =>
            work.createInvoiceFromApprovedProposal(
              sourceId: source.id,
              expectedSourceStorageRevision: revision ?? version,
              invoiceDate: DateTime(2026, 9, 29),
            );
        expect(await convert(revision: version - 1), isNull);
        await db.customStatement(
          r"CREATE TRIGGER reject_invoice BEFORE INSERT ON local_records WHEN json_extract(NEW.payload, '$.kind') = 'invoice' BEGIN SELECT RAISE(ABORT, 'failure'); END",
        );
        expect(await convert(), isNull);
        expect(work.records, hasLength(1));
        expect(
          work.records.single.resolvedEstimateStage,
          EstimateStage.approved,
        );
        await db.customStatement('DROP TRIGGER reject_invoice');
        final invoice = (await convert())!;
        expect(invoice.status, WorkRecordStatus.draft);
        expect(invoice.sourceId, source.id);
        expect(invoice.total, source.total);
        expect(invoice.client, source.client);
        expect(invoice.detail, source.detail);
        expect(invoice.terms, source.terms);
        expect(invoice.customerSignature, isNull);
        expect(invoice.hasCurrentCustomerApproval, isFalse);
        expect(await convert(), isNull);
        work.dispose();
        await harness.close(db);
        db = await harness.open();
        work = await openUiLabWorkSession(db);
        addTearDown(work.dispose);
        expect(
          work.records.where((r) => r.kind == WorkRecordKind.invoice),
          hasLength(1),
        );
        expect(
          work.records
              .singleWhere((r) => r.id == source.id)
              .resolvedEstimateStage,
          EstimateStage.converted,
        );
      },
    );
  }
  test(
    'invoice conversion requires approval and permission for both records',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final source = buildConfirmedEstimate(
        quoteInput(work.permissions.actorEmployeeId),
        now: DateTime.now(),
      );
      expect(await work.create(source), isTrue);
      expect(
        await work.createInvoiceFromApprovedProposal(
          sourceId: source.id,
          expectedSourceStorageRevision: work.storageRevisionFor(source.id),
          invoiceDate: DateTime.now(),
        ),
        isNull,
      );
      expect(
        await work.update(
          source.recordCustomerApproval(
            WorkCustomerApproval(
              method: CustomerApprovalMethod.verbal,
              customerName: source.client,
              recordedByEmployeeId: work.permissions.actorEmployeeId,
              recordedOn: DateTime.now().toUtc(),
              revision: 1,
            ),
          ),
        ),
        isTrue,
      );
      final denied = await WorkPersistenceSession.open(
        work.repository,
        WorkSessionPermissions(
          organizationId: work.permissions.organizationId,
          actorEmployeeId: work.permissions.actorEmployeeId,
          permissionRevision: 'no-invoice',
          visibleCreatorIds: work.permissions.visibleCreatorIds,
          editableKinds: {WorkRecordKind.quote},
        ),
      );
      addTearDown(denied.dispose);
      expect(
        await denied.createInvoiceFromApprovedProposal(
          sourceId: source.id,
          expectedSourceStorageRevision: denied.storageRevisionFor(source.id),
          invoiceDate: DateTime.now(),
        ),
        isNull,
      );
      expect(denied.records, hasLength(1));
    },
  );
}
