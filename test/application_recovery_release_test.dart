import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_hub.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_primary_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/shared/application_recovery_release.dart';
import 'estimate_draft_workflow_test.dart' show inputFor;
import 'support/storage/database_harness.dart';

void main() {
  test(
    'application release preserves late recovered input when view disappears',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final actor = work.permissions.actorEmployeeId;
      final draft = await work.openEstimateDraft(creatorId: actor);
      draft.updateInput(inputFor(actor));
      await draft.session.close();
      final recovery = WorkPrimaryDraftRecovery(work);
      final result = Completer<Object>();
      final controller = createApplicationRecoveryController(
        DraftRecoveryHub<Object>([
          DraftRecoveryProvider<Object>(
            id: 'work',
            label: 'Work',
            list: recovery.list,
            resume: (_) => result.future,
            discard: recovery.discard,
          ),
        ]),
      );
      await controller.refresh();
      final pending = controller.resume(controller.listing!.entries.single);
      controller.dispose();
      final resumed = await recovery.resume((await recovery.list()).single);
      result.complete(resumed);
      expect(await pending, isNull);
      // The production release callback has completed, not merely been invoked.
      final saved = await work.drafts.find(
        organizationId: draft.session.organizationId,
        domain: draft.session.domain,
        draftId: draft.session.draftId,
        ownerId: actor,
      );
      expect(jsonDecode(saved!.payload)['discount'], '0.');
      expect(work.records.where((r) => r.id == 'workflow-estimate'), isEmpty);
      final reopened = await work.openEstimateDraft(
        creatorId: actor,
        recoveryDraftId: draft.session.draftId,
      );
      expect(reopened.recoveredInput!.discount, '0.');
      await reopened.session.close();
    },
  );
  test('unsupported recovery release fails explicitly', () async {
    await expectLater(
      releaseApplicationRecovery(Object()),
      throwsArgumentError,
    );
  });
}
