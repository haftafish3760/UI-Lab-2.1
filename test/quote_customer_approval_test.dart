import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_approval_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_customer_approval.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_record_revision.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_signature_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'quote_draft_workflow_test.dart' show quoteInput;
import 'support/storage/database_harness.dart';

WorkRecord revised(WorkRecord base, double discount) => base.reviseEstimate(
  title: base.title,
  client: base.client,
  scope: base.detail,
  pricing: base.pricing,
  items: base.items,
  template: base.template,
  terms: base.terms,
  discount: discount,
  tax: base.tax,
  dates: base.estimateDates!,
  changedOn: DateTime.now().toUtc(),
);

void main() {
  test(
    'quote approval survives failed consumption and restart without a signature',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      final base = buildConfirmedEstimate(
        quoteInput(work.permissions.actorEmployeeId),
        now: DateTime.now(),
      );
      expect(await work.create(base), isTrue);
      var draft = await work.openEstimateApprovalDraft(base.id);
      expect(draft.session.domain, 'work/quote-approval');
      draft.updateInput(
        EstimateApprovalInput(
          base: base,
          baseRevision: draft.input.baseRevision,
          name: 'Jamie Morgan',
          method: CustomerApprovalMethod.verbal,
          note: 'Accepted the fixed price by telephone.',
          accepted: true,
        ),
      );
      await db.customStatement(
        "CREATE TRIGGER fail_quote_approval BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/quote-approval' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await draft.confirm(), isNull);
      expect(work.records.single.hasCurrentCustomerApproval, isFalse);
      final approvalTime = draft.input.confirmedAt;
      await draft.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      draft = await work.openEstimateApprovalDraft(base.id);
      expect(draft.input.name, 'Jamie Morgan');
      await db.customStatement('DROP TRIGGER fail_quote_approval');
      final approved = (await draft.confirm())!;
      expect(approved.hasCurrentCustomerApproval, isTrue);
      expect(approved.customerSignature, isNull);
      expect(approved.customerApprovals.single.recordedOn, approvalTime);
      await draft.session.close();
      final changed = revised(approved, 10);
      expect(await work.update(changed), isTrue);
      expect(work.records.single.hasCurrentCustomerApproval, isFalse);
      expect(work.records.single.customerApprovals, hasLength(1));
      final forged = revised(changed, 5).recordCustomerApproval(
        WorkCustomerApproval(
          method: CustomerApprovalMethod.verbal,
          customerName: 'Jamie Morgan',
          recordedByEmployeeId: work.permissions.actorEmployeeId,
          recordedOn: DateTime.now().toUtc(),
          revision: changed.revision + 1,
        ),
      );
      expect(await work.update(forged), isFalse);
    },
  );

  test(
    'signed quote retains old proof after price revision and denies unauthorized approval',
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
      final denied = await WorkPersistenceSession.open(
        work.repository,
        WorkSessionPermissions(
          organizationId: work.permissions.organizationId,
          actorEmployeeId: work.permissions.actorEmployeeId,
          permissionRevision: 'restricted',
          visibleCreatorIds: {work.permissions.actorEmployeeId},
          editableKinds: {WorkRecordKind.quote},
        ),
      );
      addTearDown(denied.dispose);
      await expectLater(
        denied.openEstimateApprovalDraft(base.id),
        throwsStateError,
      );
      await expectLater(
        denied.openEstimateSignatureDraft(base.id),
        throwsStateError,
      );
      final signature = await work.openEstimateSignatureDraft(base.id);
      expect(signature.session.domain, 'work/quote-signature');
      signature.updateName('Jamie Morgan');
      signature.updateInk(
        SignatureInk([
          [(0.1, 0.2), (0.8, 0.7)],
        ]),
      );
      signature.setAccepted(true);
      final signed = (await signature.confirm())!;
      await signature.session.close();
      expect(signed.hasCurrentCustomerApproval, isTrue);
      expect(
        signed.estimateDeliveries.single.method,
        EstimateDeliveryMethod.inPerson,
      );
      expect(await work.update(revised(signed, 20)), isTrue);
      final changed = work.records.single;
      expect(changed.hasCurrentCustomerApproval, isFalse);
      expect(
        changed.customerSignature!.signedOn,
        signed.customerSignature!.signedOn,
      );
      expect(
        changed.customerSignature!.ink!.toJson(),
        signed.customerSignature!.ink!.toJson(),
      );
      expect(changed.estimateDeliveries, hasLength(1));
      expect(
        await work.update(
          decodeWorkRecord({
            ...encodeWorkRecord(changed),
            'estimateDeliveries': [],
          }),
        ),
        isFalse,
      );
      expect(
        await work.update(
          decodeWorkRecord({
            ...encodeWorkRecord(changed),
            'estimateStage': 'approved',
          }),
        ),
        isFalse,
      );
    },
  );
}
