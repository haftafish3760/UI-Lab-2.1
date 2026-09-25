import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_items_draft_input.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/database_harness.dart';
import 'work_draft_controller_compatibility_test.dart'
    show legacyInput, legacyItemsWorkspace;

void main() {
  test(
    'workspace snapshots retain raw unfinished lines without mutable aliases',
    () {
      final raw = legacyItemsWorkspace();
      final input = WorkItemsDraftInput.fromPayload(raw);
      expect(input.pendingItems, hasLength(1));
      expect(input.pendingItem!.lineId, 'pending-line');
      expect(
        WorkItemsDraftInput.fromPayload(
          input.toPayload(),
        ).pendingItem!.quantity,
        '1.',
      );
      (raw['pendingItem'] as Map)['quantity'] = 'Changed elsewhere';
      expect(input.pendingItem!.quantity, '1.');
      expect(() => input.items.clear(), throwsUnsupportedError);
      final output = input.toPayload();
      ((output['pendingItems'] as List).single as Map)['name'] =
          'Changed output';
      expect(input.pendingItem!.name, 'Unfinished item');
    },
  );
  test(
    'malformed legacy nested workspace fails without rewriting the saved draft',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final store = LocalDraftStore(db);
      final raw = legacyInput('invoice')..['itemEditor'] = {'quantity': '1.'};
      await store.save(
        organizationId: 'business',
        domain: 'work/invoice-editor',
        draftId: 'malformed-workspace',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: raw,
        occurredAt: DateTime.utc(2026, 9, 10),
      );
      final session = DraftAutosaveSession(
        store: store,
        organizationId: 'business',
        domain: 'work/invoice-editor',
        draftId: 'malformed-workspace',
        ownerId: 'owner',
      );
      await session.initialize();
      expect(
        () => InvoiceDraftController(session).recoveredInput,
        throwsA(isA<TypeError>()),
      );
      await session.close();
      final saved = (await store.find(
        organizationId: 'business',
        domain: 'work/invoice-editor',
        draftId: 'malformed-workspace',
        ownerId: 'owner',
      ))!;
      expect(store.decode(saved), raw);
      expect(session.savedRevision, 1);
    },
  );
}
