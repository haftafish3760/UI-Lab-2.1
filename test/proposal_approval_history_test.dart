import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_signature_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/proposal_approval_history.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'quote_draft_workflow_test.dart' show quoteInput;
import 'quote_customer_approval_test.dart' show revised;
import 'support/storage/database_harness.dart';

void main() {
  test(
    'old signed price and ink survive a new signed revision and reopening',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      final quote = buildConfirmedEstimate(
        quoteInput(work.permissions.actorEmployeeId),
        now: DateTime.now(),
      );
      expect(await work.create(quote), isTrue);
      for (var i = 0; i < 2; i++) {
        if (i == 1) {
          expect(await work.update(revised(work.records.single, 20)), isTrue);
        }
        final signature = await work.openEstimateSignatureDraft(quote.id);
        signature.updateName('Jamie version ${i + 1}');
        signature.updateInk(
          SignatureInk([
            [(0.1, 0.2), (0.5 + i * 0.1, 0.7)],
          ]),
        );
        signature.setAccepted(true);
        expect(
          await signature.confirm(),
          isNotNull,
          reason: work.failureMessage,
        );
        await signature.session.close();
      }
      for (var i = 0; i < 52; i++) {
        expect(
          await work.update(
            work.records.single.withEstimateStage(
              EstimateStage.approved,
              DateTime.utc(2026, 9, 29, 10, i),
            ),
          ),
          isTrue,
        );
      }
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      final firstPage = await work.approvedProposalHistory(quote.id);
      expect(firstPage.records.length, 30);
      expect(firstPage.nextBefore, isNotNull);
      final secondPage = await work.approvedProposalHistory(
        quote.id,
        beforeStorageRevision: firstPage.nextBefore,
      );
      expect(secondPage.nextBefore, isNull);
      final records = [...firstPage.records, ...secondPage.records];
      final old = records.firstWhere((r) => r.revision == 1);
      final latest = records.firstWhere((r) => r.revision == 2);
      expect(old.total, 245);
      expect(latest.total, 225);
      expect(old.customerSignature!.signedBy, 'Jamie version 1');
      expect(old.customerSignature!.ink!.strokes.single.last.$1, 0.5);
      expect(latest.customerSignature!.ink!.strokes.single.last.$1, 0.6);
      final denied = await WorkPersistenceSession.open(
        work.repository,
        WorkSessionPermissions(
          organizationId: work.permissions.organizationId,
          actorEmployeeId: 'other',
          permissionRevision: 'denied',
          visibleCreatorIds: {'other'},
          editableKinds: {},
        ),
      );
      addTearDown(denied.dispose);
      await expectLater(
        denied.approvedProposalHistory(quote.id),
        throwsStateError,
      );
      final otherCompany = await WorkPersistenceSession.open(
        work.repository,
        WorkSessionPermissions(
          organizationId: 'another-company',
          actorEmployeeId: work.permissions.actorEmployeeId,
          permissionRevision: 'other-company',
          visibleCreatorIds: work.permissions.visibleCreatorIds,
          editableKinds: {},
        ),
      );
      addTearDown(otherCompany.dispose);
      await expectLater(
        otherCompany.approvedProposalHistory(quote.id),
        throwsStateError,
      );
      await db.customStatement(
        "UPDATE local_record_revisions SET payload_hash = 'invalid' WHERE record_id = ? AND revision = 2",
        [quote.id],
      );
      await expectLater(
        work.approvedProposalHistory(quote.id, beforeStorageRevision: 3),
        throwsStateError,
      );
    },
  );
}
