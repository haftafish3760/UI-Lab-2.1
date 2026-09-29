import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/reusable_job.dart';
import 'package:ui_lab_2_1/src/data/work/reusable_job_library.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'support/storage/database_harness.dart';

WorkSessionPermissions reusableAccess({
  String company = 'company',
  String actor = 'owner',
  bool edit = true,
  bool manage = false,
  bool schedule = false,
}) => WorkSessionPermissions(
  organizationId: company,
  actorEmployeeId: actor,
  permissionRevision: '1',
  visibleCreatorIds: {'owner', actor},
  editableKinds: edit ? {WorkRecordKind.job} : {},
  canManageOtherCreators: manage,
  canScheduleJobs: schedule,
);

const reusableSource = WorkRecord(
  id: 'old-job',
  kind: WorkRecordKind.job,
  number: 'JOB-99',
  title: 'Replace faucet',
  client: 'PRIVATE CUSTOMER',
  detail: 'Replace a standard faucet',
  total: 200,
  pricing: WorkPricingModel.flatRate,
  createdByEmployeeId: 'owner',
  assignee: 'PRIVATE EMPLOYEE',
  vehicle: 'PRIVATE VEHICLE',
  serviceLocation: 'PRIVATE ADDRESS',
  jobNotes: 'PRIVATE NOTES',
  sourceId: 'PRIVATE ESTIMATE',
  status: WorkRecordStatus.completed,
  items: [
    WorkLineItem(
      id: 'old-item',
      type: WorkLineItemType.material,
      name: 'Faucet',
      quantity: 1,
      unit: 'each',
      customerPrice: 200,
      sourceExpenseId: 'PRIVATE EXPENSE',
      sourceReceiptId: 'PRIVATE RECEIPT',
      sourceStockId: 'PRIVATE STOCK',
      internalUnitCost: 100,
      isJobAddition: true,
    ),
  ],
);

void main() {
  test(
    'reusable writes respect Work backup pause without losing saved work',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await WorkPersistenceSession.open(
        SqliteWorkRepository(await harness.open()),
        reusableAccess(),
      );
      addTearDown(work.dispose);
      final library = ReusableJobLibrary(work);
      final job = ReusableJob.fromWork(reusableSource, ownerId: 'owner');
      await library.save(job, expectedRevision: 0);
      final pause = await work.pauseOperations();
      try {
        await expectLater(
          library.save(job, expectedRevision: 1),
          throwsStateError,
        );
        expect(work.isSaving, isFalse);
        expect((await library.list()).single.revision, 1);
      } finally {
        pause.release();
      }
      await library.save(job, expectedRevision: 1);
      expect((await library.list()).single.revision, 2);
    },
  );

  test(
    'reusable copy excludes prior-client operational information and regenerates item IDs',
    () {
      final reusable = ReusableJob.fromWork(reusableSource, ownerId: 'owner');
      expect(jsonEncode(reusable.toJson()), isNot(contains('PRIVATE')));
      expect(reusable.items.single.sourceExpenseId, isNull);
      expect(reusable.items.single.internalUnitCost, isNull);
      expect(reusable.items.single.isJobAddition, isFalse);
      expect(reusable.items.single.customerPrice, 200);
      final first = reusable.itemsForNewJob('job-new-1');
      final second = reusable.itemsForNewJob('job-new-2');
      expect(first.single.id, isNot(second.single.id));
      expect(first.single.id, isNot(reusableSource.items.single.id));
      expect(() => reusable.items.clear(), throwsUnsupportedError);
      expect(reusableSource.client, 'PRIVATE CUSTOMER');
    },
  );

  test(
    'library persists, scopes access, rejects stale changes and preserves recovery',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = SqliteWorkRepository(db);
      final work = await WorkPersistenceSession.open(
        repository,
        reusableAccess(),
      );
      addTearDown(work.dispose);
      final library = ReusableJobLibrary(work);
      expect(await library.list(), isEmpty);
      var job = ReusableJob.fromWork(reusableSource, ownerId: 'owner');
      await library.save(job, expectedRevision: 0);
      final reopened = await WorkPersistenceSession.open(
        repository,
        reusableAccess(),
      );
      addTearDown(reopened.dispose);
      final other = ReusableJobLibrary(reopened);
      expect((await other.list()).single.job.toJson(), job.toJson());
      expect((await other.forUse(job.id, 1)).title, 'Replace faucet');
      final draft = await other.openInput();
      draft.replaceInput({
        'id': job.id,
        'ownerId': job.ownerId,
        'baseRevision': 1,
        'title': 'unfinished',
        'price': '12.',
        'itemEditor': {'raw': 'unfinished'},
      });
      await draft.flush();
      final inputId = draft.draftId;
      await draft.close();
      final recovered = await other.openInput(draftId: inputId);
      expect(recovered.input['price'], '12.');
      job = ReusableJob(
        id: job.id,
        ownerId: job.ownerId,
        title: 'Replace tap',
        description: job.description,
        pricing: job.pricing,
        items: job.items,
      );
      await library.save(job, expectedRevision: 1);
      await expectLater(other.forUse(job.id, 1), throwsA(isA<Exception>()));
      await expectLater(
        recovered.confirm((checkpoint) async {
          await other.save(job, expectedRevision: 1, checkpoint: checkpoint);
          return true;
        }),
        throwsA(isA<Exception>()),
      );
      expect((await other.unfinished()).single.draftId, inputId);
      expect((await other.list()).single.revision, 2);
      await recovered.close();
      final denied = await WorkPersistenceSession.open(
        repository,
        reusableAccess(edit: false),
      );
      addTearDown(denied.dispose);
      await expectLater(ReusableJobLibrary(denied).list(), throwsStateError);
      final employee = await WorkPersistenceSession.open(
        repository,
        reusableAccess(actor: 'employee'),
      );
      addTearDown(employee.dispose);
      expect((await ReusableJobLibrary(employee).list()).single.job.id, job.id);
      await expectLater(
        ReusableJobLibrary(employee).save(job, expectedRevision: 2),
        throwsStateError,
      );
      final isolated = await WorkPersistenceSession.open(
        repository,
        reusableAccess(company: 'other-company'),
      );
      addTearDown(isolated.dispose);
      expect(await ReusableJobLibrary(isolated).list(), isEmpty);
      expect(await ReusableJobLibrary(isolated).unfinished(), isEmpty);
      expect(
        work.records,
        isEmpty,
      ); // Library entries are not scheduled/finished jobs.
      await db.verifyIntegrity();
    },
  );

  test(
    'confirm consumes only matching recovery input after the record commits',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await WorkPersistenceSession.open(
        SqliteWorkRepository(await harness.open()),
        reusableAccess(),
      );
      addTearDown(work.dispose);
      final library = ReusableJobLibrary(work);
      final job = ReusableJob.fromWork(reusableSource, ownerId: 'owner');
      final draft = await library.openInput();
      draft.replaceInput({
        'id': 'different',
        'ownerId': job.ownerId,
        'baseRevision': 0,
      });
      await expectLater(
        draft.confirm((checkpoint) async {
          await library.save(job, expectedRevision: 0, checkpoint: checkpoint);
          return true;
        }),
        throwsA(isA<Exception>()),
      );
      expect(await library.list(), isEmpty);
      expect(await library.unfinished(), hasLength(1));
      draft.replaceInput({
        'id': job.id,
        'ownerId': job.ownerId,
        'baseRevision': 0,
      });
      expect(
        await draft.confirm((checkpoint) async {
          await library.save(job, expectedRevision: 0, checkpoint: checkpoint);
          return true;
        }),
        isTrue,
      );
      expect(await library.list(), hasLength(1));
      expect(await library.unfinished(), isEmpty);
      await draft.close();
    },
  );
}
