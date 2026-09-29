import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_customer_approval.dart';
import 'package:ui_lab_2_1/src/data/work/job_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/job_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/job_materials_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_items_draft_input.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'support/storage/database_harness.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/work_contact_codec.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_models.dart';

void main() {
  test(
    'approved estimate through approved addition and completion retains invoice scope and totals',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final actor = work.permissions.actorEmployeeId;
      final day = DateTime(2026, 9, 24);
      const client = WorkCustomerProfile(
        id: 'client-original',
        name: 'Test Customer',
        companyName: '',
        phone: '2025550101',
        email: 'original@example.test',
        preferredContact: 'Email',
        billingAddress: 'Test billing address',
        locations: [],
        notes: '',
        linkedRecordCount: 0,
      );
      final estimate = WorkRecord(
        id: 'flow-estimate',
        kind: WorkRecordKind.estimate,
        number: 'EST-FLOW',
        title: 'Shelf',
        client: 'Test Customer',
        customerSnapshot: client,
        sitePhotos: [
          WorkSitePhoto(
            id: 'before',
            path: '/retained/before.png',
            name: 'Before work',
            source: WorkSitePhotoSource.camera,
            addedOn: day,
            note: 'Existing condition',
          ),
        ],
        detail: 'Build a shelf',
        pricing: WorkPricingModel.flatRate,
        terms: 'Obtain approval for additional work.',
        discount: 10,
        tax: 5,
        total: 95,
        items: const [
          WorkLineItem(
            id: 'wood',
            type: WorkLineItemType.material,
            name: 'Timber',
            quantity: 10,
            unit: 'piece',
            customerPrice: 10,
          ),
        ],
      );
      expect(await work.create(estimate), isTrue);
      final approved = estimate.recordCustomerApproval(
        WorkCustomerApproval(
          method: CustomerApprovalMethod.verbal,
          customerName: 'Test Customer',
          recordedByEmployeeId: actor,
          recordedOn: day,
          revision: 1,
        ),
      );
      expect(await work.update(approved), isTrue, reason: work.failureMessage);
      final job = buildConfirmedJob(
        JobDraftInput(
          jobId: 'flow-job',
          number: 'JOB-FLOW',
          sourceEstimate: approved,
          sourceStorageRevision: work.storageRevisionFor(approved.id),
          scheduledStart: day,
          scheduledEnd: day.add(const Duration(hours: 3)),
          client: approved.client,
          location: 'Test site',
          assignee: null,
          vehicle: null,
          pricing: approved.pricing,
          items: approved.items,
          pendingLineItem: null,
          title: approved.title,
          scope: approved.detail,
          notes: '',
        ),
        actorEmployeeId: actor,
        now: day,
      );
      expect(
        await work.createJobFromApprovedEstimate(
          job: decodeWorkRecord({
            ...encodeWorkRecord(job),
            'customerSnapshot': encodeWorkCustomerProfile(
              client.copyWith(email: 'wrong@example.test'),
            ),
          }),
          expectedSourceStorageRevision: work.storageRevisionFor(approved.id),
          expectedSourceDocumentRevision: approved.revision,
        ),
        isFalse,
      );
      expect(work.records.where((r) => r.id == job.id), isEmpty);
      expect(
        work.records
            .singleWhere((r) => r.id == approved.id)
            .resolvedEstimateStage,
        approved.resolvedEstimateStage,
      );
      expect(
        await work.createJobFromApprovedEstimate(
          job: decodeWorkRecord({...encodeWorkRecord(job), 'sitePhotos': []}),
          expectedSourceStorageRevision: work.storageRevisionFor(approved.id),
          expectedSourceDocumentRevision: approved.revision,
        ),
        isFalse,
      );
      final displayed = activeJobForRecord(
        job,
        scheduledTime: 'Today',
        customer: client.copyWith(
          email: 'changed@example.test',
          phone: '2025550199',
        ),
      );
      expect(displayed.customerEmail, client.email);
      expect(displayed.customerPhone, client.phone);
      expect(
        await work.createJobFromApprovedEstimate(
          job: job,
          expectedSourceStorageRevision: work.storageRevisionFor(approved.id),
          expectedSourceDocumentRevision: approved.revision,
        ),
        isTrue,
        reason: work.failureMessage,
      );
      expect(job.sitePhotos.single.path, estimate.sitePhotos.single.path);
      expect(job.sitePhotos.single.note, 'Existing condition');
      expect(job.terms, estimate.terms);
      expect(job.discount, 10);
      final addition = await work.openJobMaterialsDraft(
        job.id,
        materialPermissions: const JobWorkspacePermissions.development(),
      );
      addition.updateWorkspace(
        WorkItemsDraftInput(
          items: [
            WorkLineItem(
              id: 'extra',
              type: WorkLineItemType.labor,
              name: 'Additional fitting',
              quantity: 2,
              unit: 'hour',
              customerPrice: 25,
              isJobAddition: true,
              jobMaterialBillingTreatment:
                  JobMaterialBillingTreatment.invoiceCandidate,
              changeApproval: WorkCustomerApproval(
                method: CustomerApprovalMethod.message,
                customerName: 'Test Customer',
                recordedByEmployeeId: actor,
                recordedOn: day,
                revision: 2,
                note: 'Customer approved 50 dollars by text.',
              ),
            ),
          ],
        ),
      );
      final revised = await addition.confirm();
      expect(revised, isNotNull, reason: work.failureMessage);
      await addition.session.close();
      final completed = revised!.copyWith(
        status: WorkRecordStatus.completed,
        completedOn: day,
      );
      expect(await work.update(completed), isTrue, reason: work.failureMessage);
      final invoice = await work.openInvoiceDraft();
      invoice.updateInput(
        InvoiceDraftInput(
          creatorId: actor,
          number: 'INV-FLOW',
          baseStorageRevision: 0,
          title: completed.title,
          discount: completed.discount.toString(),
          tax: completed.tax.toString(),
          terms: completed.terms,
          client: completed.client,
          customerSnapshot: completed.customerSnapshot,
          pricing: completed.pricing,
          template: completed.template,
          createdOn: day,
          items: completed.items
              .where((item) => item.includedInInvoiceFromJob)
              .toList(),
          existingRecordId: null,
          recordId: 'flow-invoice',
          summary: completed.detail,
          issuedOn: day,
          dueOn: day.add(const Duration(days: 14)),
          sourceJobId: completed.id,
          location: completed.serviceLocation,
          paymentMethod: 'Not selected',
          pendingLineItem: null,
        ),
      );
      final saved = await invoice.confirm();
      expect(saved, isNotNull, reason: work.failureMessage);
      expect(saved!.total, 145);
      expect(saved.items.map((item) => item.id), ['wood', 'extra']);
      expect(saved.sourceId, job.id);
      expect(saved.customerSnapshot?.id, client.id);
      expect(saved.customerSnapshot?.email, client.email);
      expect(saved.terms, estimate.terms);
      await invoice.session.close();
      final reopened = await openUiLabWorkSession(await harness.open());
      addTearDown(reopened.dispose);
      expect(
        reopened.records
            .singleWhere((record) => record.id == saved.id)
            .customerSnapshot
            ?.email,
        client.email,
      );
      expect(
        reopened.records.singleWhere((record) => record.id == saved.id).total,
        145,
      );
      expect(
        reopened.records
            .singleWhere((record) => record.id == job.id)
            .sitePhotos
            .single
            .id,
        'before',
      );
      expect(
        reopened.records.singleWhere((record) => record.id == job.id).status,
        WorkRecordStatus.completed,
      );
    },
  );
}
