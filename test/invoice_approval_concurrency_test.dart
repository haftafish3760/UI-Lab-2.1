import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_approval_content.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'supervisor cannot approve a stale invoice or forge another actor',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final database = await harness.open();
      final repository = SqliteWorkRepository(database);
      WorkSessionPermissions permissions(String actor) =>
          WorkSessionPermissions(
            organizationId: 'business',
            actorEmployeeId: actor,
            permissionRevision: 'v1',
            visibleCreatorIds: {'worker'},
            editableKinds: {WorkRecordKind.invoice},
            canManageOtherCreators: actor == 'supervisor',
            canApproveInvoices: actor == 'supervisor',
            requiresInvoiceApproval: true,
          );
      final worker = await WorkPersistenceSession.open(
        repository,
        permissions('worker'),
      );
      addTearDown(worker.dispose);
      const original = WorkRecord(
        id: 'invoice',
        kind: WorkRecordKind.invoice,
        number: 'INV-9',
        title: 'Repair outlet',
        client: 'Morgan Lee',
        detail: '',
        pricing: WorkPricingModel.flatRate,
        createdByEmployeeId: 'worker',
        total: 80,
        requiresInvoiceApproval: true,
      );
      expect(await worker.create(original), isTrue);
      expect(
        await worker.recordInvoiceApproval(
          original,
          InvoiceApprovalDecision.submitted,
        ),
        isTrue,
      );
      final submitted = worker.records.single;
      final supervisor = await WorkPersistenceSession.open(
        repository,
        permissions('supervisor'),
      );
      addTearDown(supervisor.dispose);
      final forged = submitted.copyWith(
        invoiceApprovalHistory: [
          ...submitted.invoiceApprovalHistory,
          InvoiceApprovalEvent(
            decision: InvoiceApprovalDecision.approved,
            actorEmployeeId: 'supervisor',
            occurredOn: DateTime.now().toUtc(),
            contentFingerprint: invoiceApprovalFingerprint(submitted),
          ),
        ],
      );
      expect(await worker.update(forged), isFalse);
      expect(
        await worker.update(
          submitted.copyWith(serviceLocation: '12 Oak Street'),
        ),
        isTrue,
      );
      expect(
        await supervisor.recordInvoiceApproval(
          submitted,
          InvoiceApprovalDecision.approved,
        ),
        isFalse,
      );
      final reopened = await WorkPersistenceSession.open(
        repository,
        permissions('supervisor'),
      );
      addTearDown(reopened.dispose);
      final latest = reopened.records.single;
      expect(latest.serviceLocation, '12 Oak Street');
      expect(latest.invoiceApprovalHistory, hasLength(1));
      expect(invoiceHasCurrentApproval(latest), isFalse);
      expect(
        await reopened.recordInvoiceApproval(
          latest,
          InvoiceApprovalDecision.approved,
        ),
        isFalse,
      );
      expect(
        await reopened.recordInvoiceApproval(
          latest,
          InvoiceApprovalDecision.submitted,
        ),
        isTrue,
      );
      expect(
        await reopened.recordInvoiceApproval(
          reopened.records.single,
          InvoiceApprovalDecision.approved,
        ),
        isTrue,
      );
      expect(invoiceHasCurrentApproval(reopened.records.single), isTrue);
      expect(
        reopened.records.single.invoiceApprovalHistory.last.actorEmployeeId,
        'supervisor',
      );
    },
  );
}
