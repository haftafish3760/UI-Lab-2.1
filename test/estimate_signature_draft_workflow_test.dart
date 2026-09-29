import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_signature_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'business signature is durable and does not grant customer approval',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openSeededTestWorkSession(await harness.open());
      addTearDown(work.dispose);
      final base = work.records.singleWhere(
        (record) => record.id == 'est-1040',
      );
      final workflow = await work.openEstimateSignatureDraft(
        base.id,
        forBusiness: true,
      );
      workflow.updateName('Business owner');
      workflow.updateInk(
        SignatureInk([
          [(0.1, 0.2), (0.8, 0.7)],
        ]),
      );
      workflow.setAccepted(true);
      final saved = (await workflow.confirm())!;
      expect(saved.businessSignature!.signedBy, 'Business owner');
      expect(saved.customerSignature, base.customerSignature);
      expect(saved.hasCurrentCustomerApproval, base.hasCurrentCustomerApproval);
      expect(saved.resolvedEstimateStage, base.resolvedEstimateStage);
      await workflow.session.close();
    },
  );

  test(
    'normalized signature and first approval time survive failed consumption and reopen',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openSeededTestWorkSession(db);
      final base = work.records.singleWhere((r) => r.id == 'est-1040');
      final revision = work.storageRevisionFor(base.id);
      var workflow = await work.openEstimateSignatureDraft(base.id);
      await expectLater(workflow.confirm(), throwsStateError);
      workflow.updateName('  Morgan Customer  ');
      final points = <(double, double)>[(0.1, 0.2), (0.8, 0.7)];
      workflow.updateInk(SignatureInk([points], strokeWidth: 4));
      points.clear();
      workflow.setAccepted(true);
      await db.customStatement(
        "CREATE TRIGGER fail_signature BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/estimate-signature' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isNull);
      final raw = workflow.session.input;
      final at = workflow.input.confirmedAt!;
      expect(work.storageRevisionFor(base.id), revision);
      expect(
        work.records.singleWhere((r) => r.id == base.id).customerSignature,
        base.customerSignature,
      );
      await workflow.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openSeededTestWorkSession(db);
      addTearDown(work.dispose);
      workflow = await work.openEstimateSignatureDraft(base.id);
      expect(workflow.session.input, raw);
      expect(workflow.input.ink.strokeWidth, 4);
      expect(workflow.input.ink.strokes.single, [(0.1, 0.2), (0.8, 0.7)]);
      await db.customStatement('DROP TRIGGER fail_signature');
      final saved = (await workflow.confirm())!;
      expect(saved.customerSignature!.signedBy, 'Morgan Customer');
      expect(saved.customerSignature!.signedOn, at);
      expect(
        saved.customerSignature!.ink!.toJson(),
        workflow.input.ink.toJson(),
      );
      expect(work.storageRevisionFor(base.id), revision + 1);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );

  test(
    'signature mutations invalidate acceptance and stale approval cannot overwrite another edit',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openSeededTestWorkSession(await harness.open());
      addTearDown(work.dispose);
      final base = work.records.singleWhere((r) => r.id == 'est-1040');
      final workflow = await work.openEstimateSignatureDraft(base.id);
      workflow.updateInk(
        SignatureInk([
          [(0.0, 0.0), (1.0, 1.0)],
        ]),
      );
      workflow.setAccepted(true);
      workflow.updateName('Another customer');
      expect(workflow.input.accepted, isFalse);
      await expectLater(workflow.confirm(), throwsStateError);
      workflow.setAccepted(true);
      expect(
        await work.update(base.copyWith(jobNotes: 'Concurrent change')),
        isTrue,
      );
      expect(await workflow.confirm(), isNull);
      expect(workflow.input.confirmedAt, isNotNull);
      workflow.updateInk(SignatureInk(const []));
      expect(workflow.input.accepted, isFalse);
      expect(workflow.input.confirmedAt, isNull);
      workflow.setAccepted(true);
      await expectLater(workflow.confirm(), throwsStateError);
      expect(
        work.records.singleWhere((r) => r.id == base.id).jobNotes,
        'Concurrent change',
      );
      await workflow.session.close();
      await expectLater(
        work.openEstimateSignatureDraft('missing'),
        throwsStateError,
      );
    },
  );
}
