import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_activity_reader.dart';
import 'package:ui_lab_2_1/src/data/work/work_export_audit.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'support/storage/database_harness.dart';

WorkSessionPermissions access({
  String actor = 'creator',
  String company = 'company',
  Set<String> visible = const {'creator'},
  bool share = true,
}) => WorkSessionPermissions(
  organizationId: company,
  actorEmployeeId: actor,
  permissionRevision: 'test',
  visibleCreatorIds: visible,
  editableKinds: WorkRecordKind.values.toSet(),
  canManageOtherCreators: true,
  canShareDocuments: share,
  canIssueInvoices: true,
);

const record = WorkRecord(
  id: 'invoice',
  kind: WorkRecordKind.invoice,
  number: 'Invoice 25',
  title: 'Repair',
  client: 'Avery Wilson',
  detail: 'Repair work',
  pricing: WorkPricingModel.flatRate,
  createdByEmployeeId: 'creator',
);

void main() {
  test(
    'activity rejects a missing newest snapshot rather than showing incomplete history',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final work = await WorkPersistenceSession.open(
        SqliteWorkRepository(db),
        access(),
      );
      addTearDown(work.dispose);
      expect(await work.create(record), isTrue);
      expect(await work.update(record.copyWith(jobNotes: 'Changed')), isTrue);
      await db.customStatement(
        "DELETE FROM local_record_revisions WHERE record_id = 'invoice' AND revision = 2",
      );
      await expectLater(
        WorkActivityReader(work).read(record.id),
        throwsStateError,
      );
    },
  );

  test(
    'activity rechecks durable deletion even when another session still has the record cached',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = SqliteWorkRepository(db);
      final creator = await WorkPersistenceSession.open(repository, access());
      addTearDown(creator.dispose);
      expect(await creator.create(record), isTrue);
      final deleter = await WorkPersistenceSession.open(
        repository,
        WorkSessionPermissions(
          organizationId: 'company',
          actorEmployeeId: 'creator',
          permissionRevision: 'delete',
          visibleCreatorIds: {'creator'},
          editableKinds: {WorkRecordKind.invoice},
          canDeleteDrafts: true,
        ),
      );
      addTearDown(deleter.dispose);
      expect(await deleter.deleteDraft(deleter.records.single), isTrue);
      expect(creator.records, hasLength(1));
      await expectLater(
        WorkActivityReader(creator).read(record.id),
        throwsStateError,
      );
    },
  );

  test(
    'saved history preserves the actual editor independently from creator across restart',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = SqliteWorkRepository(db);
      final creator = await WorkPersistenceSession.open(repository, access());
      addTearDown(creator.dispose);
      expect(await creator.create(record), isTrue);
      final editor = await WorkPersistenceSession.open(
        repository,
        access(actor: 'office'),
      );
      addTearDown(editor.dispose);
      expect(
        await editor.update(
          record.copyWith(jobNotes: 'Office reviewed the work'),
        ),
        isTrue,
      );
      final reopened = await WorkPersistenceSession.open(repository, access());
      addTearDown(reopened.dispose);
      final entries = (await WorkActivityReader(
        reopened,
      ).read(record.id)).entries;
      expect(entries.map((e) => e.actorId), ['office', 'creator']);
      expect(entries.first.changes, contains('Job notes changed'));
      expect(entries.last.changes, ['Created document']);
      expect(reopened.records.single.createdByEmployeeId, 'creator');
      expect(entries.every((e) => e.at.isUtc), isTrue);
      await db.verifyIntegrity();
    },
  );

  test(
    'history pagination neither drops nor duplicates saved versions',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await WorkPersistenceSession.open(
        SqliteWorkRepository(await harness.open()),
        access(),
      );
      addTearDown(work.dispose);
      expect(await work.create(record), isTrue);
      for (var i = 0; i < 34; i++) {
        expect(
          await work.update(work.records.single.copyWith(jobNotes: 'Note $i')),
          isTrue,
        );
      }
      final reader = WorkActivityReader(work);
      final first = await reader.read(record.id);
      final second = await reader.read(
        record.id,
        beforeRevision: first.nextBeforeRevision,
      );
      expect(first.entries, hasLength(30));
      expect(second.entries, hasLength(5));
      expect(second.nextBeforeRevision, isNull);
      expect(
        [...first.entries, ...second.entries].map((e) => e.revision).toSet(),
        hasLength(35),
      );
      expect(second.entries.last.changes, ['Created document']);
    },
  );

  test(
    'history rejects another company, invisible owner and corrupt revision',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = SqliteWorkRepository(db);
      final owner = await WorkPersistenceSession.open(repository, access());
      addTearDown(owner.dispose);
      expect(await owner.create(record), isTrue);
      for (final permission in [
        access(company: 'other'),
        access(visible: {'other'}),
      ]) {
        final denied = await WorkPersistenceSession.open(
          repository,
          permission,
        );
        addTearDown(denied.dispose);
        await expectLater(
          WorkActivityReader(denied).read(record.id),
          throwsStateError,
        );
      }
      await db.customStatement(
        "UPDATE local_record_revisions SET payload_hash = 'bad' WHERE record_id = 'invoice'",
      );
      await expectLater(
        WorkActivityReader(owner).read(record.id),
        throwsStateError,
      );
    },
  );

  test(
    'export audit preserves attempts and explicit cancellation without claiming delivery',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = SqliteWorkRepository(db);
      final work = await WorkPersistenceSession.open(repository, access());
      addTearDown(work.dispose);
      expect(await work.create(record), isTrue);
      final audit = WorkExportAudit(work);
      final cancelled = await audit.begin(record.id, 1, 'share');
      expect(
        (await audit.read(record.id)).single.changes.single,
        contains('result not recorded'),
      );
      await audit.finish(cancelled, 'cancelled');
      await audit.finish(cancelled, 'cancelled');
      final attempt = await audit.begin(record.id, 1, 'share');
      await audit.finish(attempt, 'completed');
      final reopened = await WorkPersistenceSession.open(repository, access());
      addTearDown(reopened.dispose);
      final entries = await WorkExportAudit(reopened).read(record.id);
      expect(entries, hasLength(2));
      expect(
        entries.map((e) => e.changes.single),
        contains('Sharing cancelled'),
      );
      expect(
        entries.map((e) => e.changes.single),
        contains('Shared with another app; customer delivery not confirmed'),
      );
      expect(
        entries.every((e) => e.actorId == 'creator' && e.revision == 1),
        isTrue,
      );
      expect(reopened.records.single.status, WorkRecordStatus.draft);
      await db.verifyIntegrity();
    },
  );

  test(
    'export audit rejects stale documents, denied sharing, and forged attempts',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final repository = SqliteWorkRepository(await harness.open());
      final owner = await WorkPersistenceSession.open(repository, access());
      addTearDown(owner.dispose);
      expect(await owner.create(record), isTrue);
      final stale = await WorkPersistenceSession.open(repository, access());
      addTearDown(stale.dispose);
      expect(await owner.update(record.copyWith(jobNotes: 'changed')), isTrue);
      await expectLater(
        WorkExportAudit(stale).begin(record.id, 1, 'share'),
        throwsStateError,
      );
      final denied = await WorkPersistenceSession.open(
        repository,
        access(share: false),
      );
      addTearDown(denied.dispose);
      await expectLater(
        WorkExportAudit(denied).begin(record.id, 2, 'share'),
        throwsStateError,
      );
      final audit = WorkExportAudit(owner);
      final attempt = await audit.begin(record.id, 2, 'share');
      await expectLater(
        audit.finish(
          WorkExportAttempt(
            attempt.id,
            attempt.recordId,
            attempt.ownerId,
            attempt.revision,
            attempt.actorId,
            'print',
          ),
          'completed',
        ),
        throwsStateError,
      );
      expect(
        (await audit.read(record.id)).single.changes.single,
        contains('result not recorded'),
      );
    },
  );
}
