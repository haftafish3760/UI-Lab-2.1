import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'failed confirmation preserves raw input; successful commit consumes exactly that draft',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final database = await harness.open();
      final work = await openUiLabWorkSession(database);
      addTearDown(work.dispose);
      final drafts = LocalDraftStore(database);
      final permissions = work.permissions;
      const invoice = WorkRecord(
        id: 'confirmed-input',
        kind: WorkRecordKind.invoice,
        number: 'INV-INPUT',
        title: 'Repair',
        client: 'Customer',
        detail: 'Service',
        pricing: WorkPricingModel.flatRate,
        total: 50,
      );
      final revision = await drafts.save(
        organizationId: permissions.organizationId,
        domain: 'work/invoice-editor',
        draftId: 'input',
        ownerId: permissions.actorEmployeeId,
        expectedRevision: 0,
        payload: {'title': 'Repair', 'discount': '12.'},
        occurredAt: DateTime.now(),
      );
      final checkpoint = LocalDraftCheckpoint(
        domain: 'work/invoice-editor',
        draftId: 'input',
        revision: revision,
      );
      await database.customStatement("""
      CREATE TRIGGER fail_confirmation BEFORE INSERT ON local_records
      WHEN NEW.record_id = 'confirmed-input'
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END
    """);
      expect(
        await work.save(records: [invoice], draftCheckpoint: checkpoint),
        isFalse,
      );
      expect(
        (await drafts.list(
          organizationId: permissions.organizationId,
          domain: 'work/invoice-editor',
          ownerId: permissions.actorEmployeeId,
        )),
        hasLength(1),
      );
      expect(work.records.where((r) => r.id == invoice.id), isEmpty);
      await database.customStatement('DROP TRIGGER fail_confirmation');
      expect(
        await work.save(records: [invoice], draftCheckpoint: checkpoint),
        isTrue,
      );
      expect(
        (await drafts.list(
          organizationId: permissions.organizationId,
          domain: 'work/invoice-editor',
          ownerId: permissions.actorEmployeeId,
        )),
        isEmpty,
      );
      expect(work.records.singleWhere((r) => r.id == invoice.id).total, 50);
      // Existing caller replay after the editor returns cannot create duplicates.
      expect(await work.create(invoice), isTrue);
      expect(work.records.where((r) => r.id == invoice.id), hasLength(1));
    },
  );
  test(
    'an editor opened before a newer record change cannot consume its recovery draft',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final database = await harness.open();
      final work = await openUiLabWorkSession(database);
      addTearDown(work.dispose);
      const invoice = WorkRecord(
        id: 'stale-editor',
        kind: WorkRecordKind.invoice,
        number: 'INV-STALE-EDITOR',
        title: 'Service',
        client: 'Customer',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
      );
      expect(await work.create(invoice), isTrue);
      final editorRevision = work.storageRevisionFor(invoice.id);
      final drafts = LocalDraftStore(database);
      final permissions = work.permissions;
      final draftRevision = await drafts.save(
        organizationId: permissions.organizationId,
        domain: 'work/invoice-editor',
        draftId: 'stale-input',
        ownerId: permissions.actorEmployeeId,
        expectedRevision: 0,
        payload: {'summary': 'Unfinished older edit'},
        occurredAt: DateTime.now(),
      );
      expect(
        await work.update(
          invoice.copyWith(serviceLocation: 'New saved address'),
        ),
        isTrue,
      );
      expect(
        await work.save(
          records: [invoice],
          expectedStorageRevisions: {invoice.id: editorRevision},
          draftCheckpoint: LocalDraftCheckpoint(
            domain: 'work/invoice-editor',
            draftId: 'stale-input',
            revision: draftRevision,
          ),
        ),
        isFalse,
      );
      expect(
        work.records.singleWhere((r) => r.id == invoice.id).serviceLocation,
        'New saved address',
      );
      expect(
        await drafts.list(
          organizationId: permissions.organizationId,
          domain: 'work/invoice-editor',
          ownerId: permissions.actorEmployeeId,
        ),
        hasLength(1),
      );
      expect(
        await drafts.list(
          organizationId: permissions.organizationId,
          domain: 'work/invoice-editor',
          ownerId: 'another-person',
        ),
        isEmpty,
      );
    },
  );
}
