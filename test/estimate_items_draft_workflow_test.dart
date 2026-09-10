import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_items_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_items_draft_input.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'support/storage/database_harness.dart';
import 'work_draft_controller_compatibility_test.dart'
    show legacyItemsWorkspace;

const added = WorkLineItem(
  id: 'added-line',
  type: WorkLineItemType.fee,
  name: 'Extra charge',
  quantity: 1,
  unit: 'item',
  customerPrice: 10,
);
void main() {
  test(
    'item workspace recovers and retries one atomic revision with approval invalidation',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      final approved = work.records
          .singleWhere((r) => r.id == 'est-1040')
          .recordEstimateSignature('Customer', DateTime.utc(2026, 9, 10));
      expect(await work.update(approved), isTrue);
      final revision = work.storageRevisionFor(approved.id);
      var workflow = await work.openEstimateItemsDraft(approved);
      workflow.updateWorkspace(
        WorkItemsDraftInput.fromPayload(legacyItemsWorkspace()),
      );
      await expectLater(workflow.confirm(), throwsStateError);
      expect(workflow.input.workspace.pendingItem!.quantity, '1.');
      workflow.updateWorkspace(
        WorkItemsDraftInput(items: [...approved.items, added]),
      );
      await db.customStatement(
        "CREATE TRIGGER fail_items BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/estimate-items' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isNull);
      final raw = workflow.session.input;
      final at = workflow.input.confirmedAt!;
      expect(work.storageRevisionFor(approved.id), revision);
      expect(
        work.records
            .singleWhere((r) => r.id == approved.id)
            .hasCurrentCustomerSignature,
        isTrue,
      );
      await workflow.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      workflow = await work.openEstimateItemsDraft(
        work.records.singleWhere((r) => r.id == approved.id),
      );
      expect(workflow.session.input, raw);
      await db.customStatement('DROP TRIGGER fail_items');
      final saved = (await workflow.confirm())!;
      expect(saved.items.last.id, added.id);
      expect(saved.revision, approved.revision + 1);
      expect(saved.hasCurrentCustomerSignature, isFalse);
      expect(
        saved.estimateRevisionHistory.length,
        approved.estimateRevisionHistory.length + 1,
      );
      expect(saved.estimateRevisionHistory.last.changedOn, at);
      expect(work.storageRevisionFor(approved.id), revision + 1);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );
  test(
    'stale item workspace retains edits and does not overwrite newer record',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final base = work.records.singleWhere((r) => r.id == 'est-1040');
      final workflow = await work.openEstimateItemsDraft(base);
      workflow.updateWorkspace(
        WorkItemsDraftInput(items: [...base.items, added]),
      );
      expect(
        await work.update(base.copyWith(jobNotes: 'Newer record')),
        isTrue,
      );
      expect(await workflow.confirm(), isNull);
      expect(workflow.input.workspace.items.last.id, added.id);
      expect(workflow.input.confirmedAt, isNotNull);
      workflow.updateWorkspace(WorkItemsDraftInput(items: base.items));
      expect(workflow.input.confirmedAt, isNull);
      expect(
        work.records.singleWhere((r) => r.id == base.id).jobNotes,
        'Newer record',
      );
      await workflow.session.close();
      await expectLater(work.openEstimateItemsDraft(base), throwsStateError);
    },
  );
}
