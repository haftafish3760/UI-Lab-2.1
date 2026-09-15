import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'support/storage/database_harness.dart';

void main() {
  const record = WorkRecord(
    id: 'draft',
    kind: WorkRecordKind.invoice,
    number: 'Invoice 1',
    title: 'Repair',
    client: 'Customer',
    detail: 'Repair',
    pricing: WorkPricingModel.flatRate,
    createdByEmployeeId: 'owner',
  );
  WorkSessionPermissions access({bool delete = true}) => WorkSessionPermissions(
    organizationId: 'business',
    actorEmployeeId: 'owner',
    permissionRevision: '1',
    visibleCreatorIds: {'owner'},
    editableKinds: WorkRecordKind.values.toSet(),
    canDeleteDrafts: delete,
  );

  test(
    'deleted draft stays deleted after restart and rejects a stale editor',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final repository = SqliteWorkRepository(await harness.open());
      final work = await WorkPersistenceSession.open(repository, access());
      addTearDown(work.dispose);
      expect(await work.create(record), isTrue);
      final stale = await WorkPersistenceSession.open(repository, access());
      addTearDown(stale.dispose);
      expect(await work.deleteDraft(record), isTrue);
      expect(work.records, isEmpty);
      expect(await stale.update(record), isFalse);
      final reopened = await WorkPersistenceSession.open(
        SqliteWorkRepository(await harness.open()),
        access(),
      );
      addTearDown(reopened.dispose);
      expect(reopened.records, isEmpty);
      await repository.database.verifyIntegrity();
    },
  );

  test(
    'delete requires its own permission and rejects linked drafts',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final repository = SqliteWorkRepository(await harness.open());
      final owner = await WorkPersistenceSession.open(repository, access());
      addTearDown(owner.dispose);
      expect(await owner.create(record), isTrue);
      final restricted = await WorkPersistenceSession.open(
        repository,
        access(delete: false),
      );
      addTearDown(restricted.dispose);
      expect(await restricted.deleteDraft(record), isFalse);
      // Repository checks relationships independently of a stale session cache.
      await repository.commit(
        organizationId: 'business',
        commandId: 'link',
        actorEmployeeId: 'owner',
        permissionRevision: '1',
        occurredAt: DateTime.now(),
        mutations: [
          WorkRecordMutation(
            record: WorkRecord(
              id: 'child',
              kind: WorkRecordKind.invoice,
              number: 'Invoice 2',
              title: 'Linked',
              client: 'Customer',
              detail: 'Linked',
              pricing: WorkPricingModel.flatRate,
              sourceId: record.id,
              createdByEmployeeId: 'owner',
            ),
            expectedStorageRevision: 0,
          ),
        ],
      );
      expect(await owner.deleteDraft(record), isFalse);
      expect(owner.records.single.id, record.id);
    },
  );

  test(
    'estimate draft stage controls deletion even when legacy status differs',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final repository = SqliteWorkRepository(await harness.open());
      final work = await WorkPersistenceSession.open(repository, access());
      addTearDown(work.dispose);
      const estimate = WorkRecord(
        id: 'legacy-estimate',
        kind: WorkRecordKind.estimate,
        number: 'Estimate 10',
        title: 'Repair',
        client: 'Customer',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
        createdByEmployeeId: 'owner',
        status: WorkRecordStatus.ready,
        estimateStage: EstimateStage.draft,
      );
      expect(await work.create(estimate), isTrue);
      expect(work.canDeleteDraft(estimate), isTrue);
      expect(await work.deleteDraft(estimate), isTrue);
      expect(work.records, isEmpty);
    },
  );
}
