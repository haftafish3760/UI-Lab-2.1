import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';

import 'support/storage/database_harness.dart';
import 'work_draft_controller_compatibility_test.dart' show legacyInput;

void main() {
  test(
    'new optional input saves while unchanged legacy input stays intact',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var repository = LocalDraftStore(database);
      final legacy = legacyInput('estimate');
      await repository.save(
        organizationId: 'business',
        domain: 'work/estimate-editor',
        draftId: 'draft',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: legacy,
        occurredAt: DateTime.utc(2026, 9, 1),
      );
      final session = DraftAutosaveSession(
        store: repository,
        organizationId: 'business',
        domain: 'work/estimate-editor',
        draftId: 'draft',
        ownerId: 'owner',
      );
      await session.initialize();
      final controller = EstimateDraftController(session);
      final unchanged = controller.recoveredInput!;
      controller.updateInput(unchanged);
      await session.flush();
      expect(session.savedRevision, 1);
      expect(session.input, legacy);

      controller.updateInput(
        EstimateDraftInput.fromPayload({
          ...legacy,
          'purchaseOrderNumber': 'PO-42',
        }),
      );
      await session.flush();
      expect(session.savedRevision, 2);
      await session.close();
      expect(
        () => controller.updateInput(controller.recoveredInput!),
        throwsStateError,
      );
      await harness.close(database);
      database = await harness.open();
      repository = LocalDraftStore(database);
      final stored = await repository.find(
        organizationId: 'business',
        domain: 'work/estimate-editor',
        draftId: 'draft',
        ownerId: 'owner',
      );
      final recovered = EstimateDraftInput.fromPayload(
        repository.decode(stored!),
      );
      expect(recovered.purchaseOrderNumber, 'PO-42');
      expect(recovered.discount, '12.');
      expect(recovered.toPayload(), {
        ...legacy,
        'purchaseOrderNumber': 'PO-42',
      });
    },
  );
}
