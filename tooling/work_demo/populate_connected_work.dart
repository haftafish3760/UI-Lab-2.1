import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_approval_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_payment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/reusable_job.dart';
import 'package:ui_lab_2_1/src/data/work/reusable_job_library.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';

/// Runs only inside a newly created development installation, never on startup.
Future<void> populateConnectedWork(
  WorkPersistenceSession owner,
  List<WorkCustomerProfile> clients,
  DateTime now,
) async {
  final today = DateTime(now.year, now.month, now.day);
  for (var i = 0; i < 2; i++) {
    final client = clients[i];
    final form = await owner.openEstimateDraft(
      creatorId: owner.permissions.actorEmployeeId,
      documentKind: WorkRecordKind.quote,
    );
    form.updateInput(
      EstimateDraftInput(
        documentKind: WorkRecordKind.quote,
        creatorId: owner.permissions.actorEmployeeId,
        number: 'Quote ${4101 + i}',
        baseStorageRevision: 0,
        title: i == 0
            ? '[Demo] Quarterly window cleaning'
            : '[Demo] Office network setup',
        discount: '0',
        tax: '0',
        terms:
            'Fictional fixed-price demonstration. Extra work requires approval.',
        client: client.name,
        customerSnapshot: client,
        pricing: WorkPricingModel.flatRate,
        template: 'Service standard',
        createdOn: today,
        items: const [],
        servicePrice: i == 0 ? '180' : '525',
        baseRecord: null,
        estimateId: 'demo-quote-${i + 1}',
        scope: i == 0
            ? 'Clean twelve ground-floor windows inside and out, including sills.'
            : 'Install the supplied router, connect six workstations and test the office network.',
        expiresOn: today.add(const Duration(days: 30)),
        followUpOn: null,
        proposedServiceOn: null,
        pendingLineItems: const {},
        pendingPhotos: null,
        sitePhotos: const [],
      ),
    );
    final quote = await form.confirm();
    expect(quote, isNotNull, reason: owner.failureMessage);
    await form.session.close();
    if (i == 1) {
      final approval = await owner.openEstimateApprovalDraft(quote!.id);
      approval.updateInput(
        EstimateApprovalInput(
          base: quote,
          baseRevision: approval.input.baseRevision,
          name: client.name,
          method: CustomerApprovalMethod.verbal,
          accepted: true,
          note: 'Fictional demo approval only. No real conversation occurred.',
        ),
      );
      expect(await approval.confirm(), isNotNull, reason: owner.failureMessage);
      await approval.session.close();
    }
  }
  for (final id in ['demo-estimate-1', 'demo-quote-2']) {
    final source = owner.records.singleWhere((r) => r.id == id);
    final client = source.customerSnapshot!;
    final form = await owner.openJobDraft(sourceEstimateId: id);
    final index = id == 'demo-estimate-1' ? 1 : 2;
    form.updateInput(
      JobDraftInput(
        jobId: 'demo-job-$index',
        number: 'Job ${5100 + index}',
        sourceEstimate: source,
        sourceStorageRevision: owner.storageRevisionFor(id),
        scheduledStart: today.add(Duration(days: index - 1, hours: 9)),
        scheduledEnd: today.add(Duration(days: index - 1, hours: 11)),
        client: client.name,
        location: client.billingAddress,
        assignee: null,
        vehicle: null,
        pricing: source.pricing,
        items: source.items,
        pendingLineItem: null,
        title: source.title,
        scope: source.detail,
        notes: 'Fictional scheduled work for layout review.',
      ),
    );
    final job = await form.confirm();
    expect(job, isNotNull, reason: owner.failureMessage);
    await form.session.close();
    await ReusableJobLibrary(owner).save(
      ReusableJob.fromWork(job!, ownerId: owner.permissions.actorEmployeeId),
      expectedRevision: 0,
    );
  }
  final source = owner.records.singleWhere((r) => r.id == 'demo-estimate-3');
  expect(
    await owner.createInvoiceFromApprovedProposal(
      sourceId: source.id,
      expectedSourceStorageRevision: owner.storageRevisionFor(source.id),
      invoiceDate: today,
    ),
    isNotNull,
    reason: owner.failureMessage,
  );

  for (var i = 0; i < 3; i++) {
    final client = clients[i];
    final titles = [
      '[Demo] Equipment inspection',
      '[Demo] Office cleaning visit',
      '[Demo] Garden waste collection',
    ];
    final descriptions = [
      'Inspect the equipment, document condition and provide a maintenance checklist.',
      'Clean reception, kitchenette and restroom after the customer event.',
      'Collect and dispose of two loads of garden waste.',
    ];
    final prices = ['150', '240', '320'];
    final form = await owner.openInvoiceDraft();
    form.updateInput(
      InvoiceDraftInput(
        creatorId: owner.permissions.actorEmployeeId,
        number: 'Invoice ${6101 + i}',
        baseStorageRevision: 0,
        title: titles[i],
        discount: '0',
        tax: '0',
        terms: 'Fictional invoice. No money is actually due.',
        client: client.name,
        customerSnapshot: client,
        pricing: WorkPricingModel.flatRate,
        template: 'Service standard',
        createdOn: today.subtract(const Duration(days: 20)),
        items: const [],
        servicePrice: prices[i],
        existingRecordId: null,
        recordId: 'demo-invoice-${i + 1}',
        summary: descriptions[i],
        issuedOn: today.subtract(const Duration(days: 20)),
        dueOn: i == 0
            ? today.subtract(const Duration(days: 6))
            : today.add(const Duration(days: 7)),
        sourceJobId: null,
        location: client.billingAddress,
        paymentMethod: 'Not selected',
        pendingLineItem: null,
      ),
    );
    final invoice = await form.confirm(issue: true);
    expect(invoice, isNotNull, reason: owner.failureMessage);
    await form.session.close();
    if (i > 0) {
      final payment = await owner.openInvoicePaymentDraft(
        invoiceId: invoice!.id,
        initialDay: today,
      );
      payment.updateInput(
        payment.input.withValues(
          amount: i == 1 ? '100' : prices[i],
          note: 'Fictional demonstration payment. No money collected.',
          method: 'Cash',
          receivedOn: today,
        ),
      );
      expect(await payment.confirm(), isNotNull, reason: owner.failureMessage);
      await payment.session.close();
    }
  }
}
