import 'estimate_action_draft_recovery_test.dart' show recoveryFor;
import 'package:ui_lab_2_1/src/data/work/estimate_action_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/work_document_export_authorization.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'quote_customer_approval_test.dart' show revised;
import 'package:ui_lab_2_1/src/data/work/work_export_audit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_delivery_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'quote_draft_workflow_test.dart' show quoteInput;

import 'support/storage/database_harness.dart';

WorkCustomerProfile customer(String name) => WorkCustomerProfile(
  id: 'customer',
  name: name,
  companyName: '',
  phone: '555-1234',
  email: 'customer@example.test',
  preferredContact: 'Email',
  billingAddress: '',
  locations: const [],
  notes: '',
  linkedRecordCount: 0,
);

void main() {
  test(
    'quote export rejects drafts, missing sharing authority and fabricated delivery',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final base = buildConfirmedEstimate(
        quoteInput(work.permissions.actorEmployeeId),
        now: DateTime.now(),
      );
      expect(await work.create(base), isTrue);
      final ready = base.withEstimateStage(
        EstimateStage.readyToSend,
        DateTime.now().toUtc(),
      );
      expect(await work.update(ready), isTrue);
      final p = work.permissions;
      expect(
        () => requireWorkDocumentExport(
          ready.withEstimateStage(EstimateStage.draft, DateTime.now()),
          p,
        ),
        throwsStateError,
      );
      final needsApproval = WorkSessionPermissions(
        organizationId: p.organizationId,
        actorEmployeeId: p.actorEmployeeId,
        permissionRevision: 'approval-required',
        visibleCreatorIds: p.visibleCreatorIds,
        editableKinds: p.editableKinds,
        canShareDocuments: true,
        requiresQuoteApproval: true,
      );
      expect(
        () => requireWorkDocumentExport(ready, needsApproval),
        throwsStateError,
      );
      final limited = await WorkPersistenceSession.open(
        work.repository,
        WorkSessionPermissions(
          organizationId: p.organizationId,
          actorEmployeeId: p.actorEmployeeId,
          permissionRevision: 'no-share',
          visibleCreatorIds: p.visibleCreatorIds,
          editableKinds: p.editableKinds,
        ),
      );
      addTearDown(limited.dispose);
      await expectLater(
        limited.openEstimateDeliveryDraft(base.id, customers: const []),
        throwsStateError,
      );
      await expectLater(
        WorkExportAudit(
          limited,
        ).begin(base.id, work.storageRevisionFor(base.id), 'share'),
        throwsStateError,
      );
      final prepared = ready.recordEstimateDelivery(
        method: EstimateDeliveryMethod.email,
        recipient: 'customer@example.test',
        occurredOn: DateTime.now().toUtc(),
      );
      expect(await limited.update(prepared), isFalse);
      final delivered = ready.recordEstimateDelivery(
        method: EstimateDeliveryMethod.email,
        recipient: 'customer@example.test',
        occurredOn: DateTime.now().toUtc(),
        confirmedDelivered: true,
      );
      expect(await work.update(delivered), isFalse);
      expect(work.records.single.estimateDeliveries, isEmpty);
    },
  );

  test(
    'quote delivery recipients and first preparation time recover after rollback without claiming delivery',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      final original = buildConfirmedEstimate(
        quoteInput(work.permissions.actorEmployeeId),
        now: DateTime.now(),
      );
      expect(await work.create(original), isTrue);
      final ready = original.withEstimateStage(
        EstimateStage.readyToSend,
        DateTime(2026, 9, 10),
      );
      expect(await work.update(ready), isTrue);
      final revision = work.storageRevisionFor(ready.id);
      var workflow = await work.openEstimateDeliveryDraft(
        ready.id,
        customers: [customer(ready.client)],
      );
      expect(workflow.session.domain, 'work/quote-delivery');
      expect(workflow.input.recipient, 'customer@example.test');
      workflow.updateRecipient('  edited@example.test ');
      workflow.setReviewed(true);
      workflow.selectMethod(EstimateDeliveryMethod.textMessage);
      expect(workflow.input.reviewed, isFalse);
      expect(workflow.input.recipient, '555-1234');
      workflow.updateRecipient('  555 9876 ');
      workflow.setReviewed(true);
      await db.customStatement(
        "CREATE TRIGGER reject_delivery BEFORE UPDATE ON local_records WHEN NEW.record_id = 'quote-1' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isNull);
      final at = workflow.input.preparedAt!;
      expect(at.isUtc, isTrue);
      final raw = workflow.session.input;
      expect(work.storageRevisionFor(ready.id), revision);
      expect(
        work.records
            .singleWhere((r) => r.id == ready.id)
            .estimateDeliveries
            .length,
        ready.estimateDeliveries.length,
      );
      await workflow.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      final recovery = recoveryFor(work);
      final entries = await recovery.list();
      final entry = entries.singleWhere(
        (entry) => entry.domain == 'work/quote-delivery',
      );
      workflow = ((await recovery.resume(entry)) as ResumedEstimateDelivery)
          .controller;
      expect(workflow.session.input, raw);
      expect(workflow.input.recipients['email'], '  edited@example.test ');
      await db.customStatement('DROP TRIGGER reject_delivery');
      final saved = (await workflow.confirm())!;
      expect(
        saved.estimateDeliveries.length,
        ready.estimateDeliveries.length + 1,
      );
      expect(saved.estimateDeliveries.last.occurredOn, at);
      expect(saved.estimateDeliveries.last.recipient, '555 9876');
      expect(
        saved.estimateDeliveries.last.description,
        contains('delivery not confirmed'),
      );
      expect(saved.status, ready.status);
      final audit = WorkExportAudit(work);
      final attempt = await audit.begin(
        saved.id,
        work.storageRevisionFor(saved.id),
        'share',
        expectedDocument: saved,
      );
      await audit.finish(attempt, 'cancelled');
      expect(
        (await audit.read(saved.id)).single.changes.single,
        contains('cancel'),
      );
      expect(saved.resolvedEstimateStage, ready.resolvedEstimateStage);
      expect(work.storageRevisionFor(ready.id), revision + 1);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );

  test(
    'stale quote delivery preserves input and recipient changes invalidate review and preparation',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final original = buildConfirmedEstimate(
        quoteInput(work.permissions.actorEmployeeId),
        now: DateTime.now(),
      );
      expect(await work.create(original), isTrue);
      final ready = original.withEstimateStage(
        EstimateStage.readyToSend,
        DateTime(2026, 9, 10),
      );
      expect(await work.update(ready), isTrue);
      final workflow = await work.openEstimateDeliveryDraft(
        ready.id,
        customers: [customer(ready.client)],
      );
      await expectLater(workflow.confirm(), throwsStateError);
      workflow.updateRecipient('first@example.test');
      workflow.setReviewed(true);
      expect(await work.update(revised(ready, 5)), isTrue);
      expect(await workflow.confirm(), isNull);
      expect(workflow.input.preparedAt, isNotNull);
      expect(work.records.singleWhere((r) => r.id == ready.id).discount, 5);
      workflow.updateRecipient('second@example.test');
      expect(workflow.input.reviewed, isFalse);
      expect(workflow.input.preparedAt, isNull);
      workflow.selectMethod(EstimateDeliveryMethod.textMessage);
      workflow.selectMethod(EstimateDeliveryMethod.email);
      expect(workflow.input.recipient, 'second@example.test');
      expect(
        () => workflow.selectMethod(EstimateDeliveryMethod.inPerson),
        throwsStateError,
      );
      expect(workflow.input.method, EstimateDeliveryMethod.email);
      await workflow.session.close();
      await expectLater(
        work.openEstimateDeliveryDraft('missing', customers: const []),
        throwsStateError,
      );
    },
  );
}
