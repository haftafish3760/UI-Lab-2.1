import 'package:ui_lab_2_1/src/data/work/estimate_action_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_approval_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'manual approval survives reopen and failed atomic commit without approving early',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openSeededTestWorkSession(db);
      final base = work.records.firstWhere((r) => r.id == 'est-1040');
      final originalCount = base.customerApprovals.length;
      var draft = await work.openEstimateApprovalDraft(base.id);
      expect(
        draft.session.input,
        isEmpty,
        reason: 'Simply opening the screen must not manufacture a draft.',
      );
      final initial = draft.input;
      draft.updateInput(
        EstimateApprovalInput(
          base: initial.base,
          baseRevision: initial.baseRevision,
          name: 'Morgan Customer',
          method: CustomerApprovalMethod.verbal,
          note: 'Approved the shelf installation by telephone.',
          accepted: true,
        ),
      );
      await draft.session.flush();
      await draft.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openSeededTestWorkSession(db);
      addTearDown(work.dispose);
      final recovery = EstimateActionDraftRecovery(
        work,
        reviewPermissions: () => const EstimatePermissions.development(),
        customers: () => [],
      );
      final entry = (await recovery.list()).singleWhere(
        (entry) => entry.domain == 'work/estimate-approval',
      );
      draft = ((await recovery.resume(entry)) as ResumedEstimateApproval)
          .controller;
      expect(draft.input.note, 'Approved the shelf installation by telephone.');
      expect(
        work.records
            .firstWhere((r) => r.id == base.id)
            .customerApprovals
            .length,
        originalCount,
      );
      await db.customStatement(
        "CREATE TRIGGER fail_approval BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/estimate-approval' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await draft.confirm(), isNull);
      expect(
        work.records
            .firstWhere((r) => r.id == base.id)
            .customerApprovals
            .length,
        originalCount,
      );
      expect(draft.session.input, isNotEmpty);
      final firstConfirmationTime = draft.input.confirmedAt;
      await db.customStatement('DROP TRIGGER fail_approval');
      final approved = (await draft.confirm())!;
      expect(approved.customerApprovals.length, originalCount + 1);
      expect(approved.customerApprovals.last.customerName, 'Morgan Customer');
      expect(approved.customerSignature, base.customerSignature);
      expect(approved.customerApprovals.last.recordedOn, firstConfirmationTime);
      await expectLater(draft.confirm(), throwsStateError);
      await draft.session.close();
    },
  );

  test(
    'saved manual approval cannot overwrite an estimate changed elsewhere',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openSeededTestWorkSession(await harness.open());
      addTearDown(work.dispose);
      final base = work.records.firstWhere((r) => r.id == 'est-1040');
      final draft = await work.openEstimateApprovalDraft(base.id);
      draft.updateInput(
        EstimateApprovalInput(
          base: base,
          baseRevision: draft.input.baseRevision,
          name: 'Morgan',
          method: CustomerApprovalMethod.verbal,
          accepted: true,
        ),
      );
      expect(
        await work.update(base.copyWith(jobNotes: 'Changed elsewhere')),
        isTrue,
      );
      expect(await draft.confirm(), isNull);
      expect(
        work.records.firstWhere((r) => r.id == base.id).jobNotes,
        'Changed elsewhere',
      );
      expect(draft.session.input, isNotEmpty);
      await draft.session.close();
    },
  );
}
