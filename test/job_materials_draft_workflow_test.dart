import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/job_materials_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_material_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_items_draft_input.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'support/storage/database_harness.dart';
import 'work_draft_controller_compatibility_test.dart'
    show legacyItemsWorkspace;

const procurement = WorkLineItem(
  id: 'protected',
  type: WorkLineItemType.procurement,
  name: 'Pickup',
  quantity: 1,
  unit: 'trip',
  customerPrice: 30,
);
const added = WorkLineItem(
  id: 'added',
  type: WorkLineItemType.material,
  name: 'Valve',
  quantity: 2,
  unit: 'item',
  customerPrice: 0,
);
const job = WorkRecord(
  id: 'job-materials-controller',
  kind: WorkRecordKind.job,
  number: 'JOB-MATERIALS',
  title: 'Repair',
  client: 'Customer',
  detail: '',
  pricing: WorkPricingModel.flatRate,
  items: [procurement],
  total: 30,
);
void main() {
  test(
    'billable labor additions require documented approval and persist for invoicing',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      expect(await work.create(job), isTrue);
      final workflow = await work.openJobMaterialsDraft(
        job.id,
        materialPermissions: const JobWorkspacePermissions.development(),
      );
      addTearDown(workflow.session.close);
      WorkLineItem labor(WorkCustomerApproval? approval) => WorkLineItem(
        id: 'extra-labor',
        type: WorkLineItemType.labor,
        name: 'Approved extra installation',
        quantity: 6,
        workerCount: 2,
        unit: 'hour',
        customerPrice: 25,
        isJobAddition: true,
        jobMaterialBillingTreatment:
            JobMaterialBillingTreatment.invoiceCandidate,
        changeApproval: approval,
      );
      workflow.updateWorkspace(WorkItemsDraftInput(items: [labor(null)]));
      await expectLater(workflow.confirm(), throwsStateError);
      expect(labor(null).includedInInvoiceFromJob, isFalse);
      final approval = WorkCustomerApproval(
        method: CustomerApprovalMethod.verbal,
        customerName: 'Customer',
        recordedByEmployeeId: work.permissions.actorEmployeeId,
        recordedOn: DateTime(2026, 9, 24),
        revision: job.revision + 1,
        note: 'Approved six additional worker-hours for 150 dollars.',
      );
      workflow.updateWorkspace(WorkItemsDraftInput(items: [labor(approval)]));
      final saved = await workflow.confirm();
      expect(saved, isNotNull, reason: work.failureMessage);
      expect(saved!.items.first.id, procurement.id);
      expect(saved.items.last.workerCount, 2);
      expect(saved.items.last.includedInInvoiceFromJob, isTrue);
      expect(
        saved.items
            .where((item) => item.includedInInvoiceFromJob)
            .fold<double>(0, (total, item) => total + item.total),
        180,
      );
      final reopened = await openUiLabWorkSession(await harness.open());
      addTearDown(reopened.dispose);
      expect(
        reopened.records
            .singleWhere((record) => record.id == job.id)
            .items
            .last
            .changeApproval!
            .method,
        CustomerApprovalMethod.verbal,
      );
    },
  );

  test(
    'materials recover and retry atomically without converting protected procurement lines',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      expect(await work.create(job), isTrue);
      final revision = work.storageRevisionFor(job.id);
      var workflow = await work.openJobMaterialsDraft(
        job.id,
        materialPermissions: const JobWorkspacePermissions.development(),
      );
      workflow.updateWorkspace(
        WorkItemsDraftInput.fromPayload(legacyItemsWorkspace()),
      );
      await expectLater(workflow.confirm(), throwsStateError);
      expect(workflow.input.workspace.pendingItem!.quantity, '1.');
      workflow.updateWorkspace(WorkItemsDraftInput(items: [added]));
      await db.customStatement(
        "CREATE TRIGGER fail_materials BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/job-materials' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isNull);
      final raw = workflow.session.input;
      final at = workflow.input.confirmedAt;
      expect(work.storageRevisionFor(job.id), revision);
      expect(work.records.singleWhere((r) => r.id == job.id).items.length, 1);
      await workflow.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      workflow = await work.openJobMaterialsDraft(
        job.id,
        materialPermissions: const JobWorkspacePermissions.development(),
      );
      expect(workflow.session.input, raw);
      await db.customStatement('DROP TRIGGER fail_materials');
      final saved = (await workflow.confirm())!;
      expect(saved.items.first.type, WorkLineItemType.procurement);
      expect(saved.items.first.customerPrice, 30);
      expect(saved.items.last.isJobAddition, isTrue);
      expect(saved.revision, job.revision + 1);
      expect(workflow.input.confirmedAt, at);
      expect(work.storageRevisionFor(job.id), revision + 1);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );
  test('stock permission is enforced by confirmation without a screen', () {
    const restricted = JobWorkspacePermissions(
      canEditJob: true,
      canViewEstimate: true,
      canAddMaterials: true,
      canAttachReceipts: false,
      canChangeStatus: false,
      canContactCustomer: false,
    );
    final input = JobMaterialsDraftInput(
      base: job,
      baseRevision: 1,
      workspace: WorkItemsDraftInput(
        items: [
          const WorkLineItem(
            id: 'stock-addition',
            type: WorkLineItemType.material,
            name: 'Stock',
            quantity: 1,
            unit: 'item',
            customerPrice: 0,
            sourceStockId: 'stock',
          ),
        ],
      ),
    ).prepare();
    expect(() => input.confirmedRecord(restricted), throwsStateError);
  });
  test(
    'protected identifiers, duplicate additions and stale base cannot be confirmed',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      expect(await work.create(job), isTrue);
      final workflow = await work.openJobMaterialsDraft(
        job.id,
        materialPermissions: const JobWorkspacePermissions.development(),
      );
      workflow.updateWorkspace(WorkItemsDraftInput(items: [added, added]));
      await expectLater(workflow.confirm(), throwsStateError);
      workflow.updateWorkspace(
        WorkItemsDraftInput(
          items: [
            const WorkLineItem(
              id: 'protected',
              type: WorkLineItemType.material,
              name: 'Replacement',
              quantity: 1,
              unit: 'item',
              customerPrice: 0,
            ),
          ],
        ),
      );
      await expectLater(workflow.confirm(), throwsStateError);
      workflow.updateWorkspace(WorkItemsDraftInput(items: [added]));
      expect(
        await work.update(job.copyWith(jobNotes: 'Concurrent change')),
        isTrue,
      );
      expect(await workflow.confirm(), isNull);
      expect(
        work.records.singleWhere((r) => r.id == job.id).jobNotes,
        'Concurrent change',
      );
      expect(workflow.input.workspace.items.single.id, added.id);
      await workflow.session.close();
    },
  );
}
