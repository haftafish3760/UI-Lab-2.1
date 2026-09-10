import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/workday/sqlite_workday_repository.dart';
import 'package:ui_lab_2_1/src/data/workday/stored_workday_record.dart';

void main() {
  late Directory directory;
  late LocalDatabase db;
  late SqliteWorkdayRepository repo;
  final at = DateTime.utc(2030, 1, 1, 8);
  final access = WorkdayAccess(
    organizationId: 'company',
    actorEmployeeId: 'alex',
    permissionRevision: 'test',
    employeeIds: {'alex'},
    vehicleIds: {'van'},
    canManage: true,
  );
  const draft = LocalDraftCheckpoint(
    domain: 'workday/start',
    draftId: 'input',
    revision: 1,
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sqlite-workday-');
    db = LocalDatabase.file(File('${directory.path}/workday.sqlite'));
    repo = SqliteWorkdayRepository(db);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });
  Future<WorkdaySnapshot> start({LocalDraftCheckpoint? checkpoint}) =>
      repo.start(
        id: 'day',
        employeeId: 'alex',
        vehicleId: 'van',
        odometerTenths: 100001,
        expectedOdometerRevision: 0,
        at: at,
        access: access,
        draft: checkpoint,
      );
  test(
    'exact command retry survives reopen without duplicating effects',
    () async {
      await start();
      await db.close();
      db = LocalDatabase.file(File('${directory.path}/workday.sqlite'));
      repo = SqliteWorkdayRepository(db);
      expect((await start()).revision, 1);
      expect((await repo.odometer('van', access)).revision, 1);
      expect(await db.select(db.localCommands).get(), hasLength(1));
      Future<WorkdaySnapshot> end({int amount = 100100}) => repo.change(
        id: 'day',
        expectedRevision: 1,
        at: at.add(const Duration(hours: 4)),
        access: access,
        status: StoredWorkdayStatus.ended,
        endingOdometerTenths: amount,
        expectedOdometerRevision: 1,
      );
      await end();
      await db.close();
      db = LocalDatabase.file(File('${directory.path}/workday.sqlite'));
      repo = SqliteWorkdayRepository(db);
      expect((await end()).revision, 2);
      expect((await repo.odometer('van', access)).revision, 2);
      expect(await db.select(db.localCommands).get(), hasLength(2));
      await expectLater(end(amount: 100101), throwsA(anything));
      await expectLater(
        repo.change(
          id: 'day',
          expectedRevision: 1,
          at: at.add(const Duration(hours: 4)),
          access: WorkdayAccess(
            organizationId: 'company',
            actorEmployeeId: 'alex',
            permissionRevision: 'test',
            employeeIds: {'alex'},
            vehicleIds: {'van'},
            canManage: false,
          ),
          status: StoredWorkdayStatus.ended,
          endingOdometerTenths: 100100,
          expectedOdometerRevision: 1,
        ),
        throwsStateError,
      );

      // A late start acknowledgment must not reactivate the ended session.
      expect((await start()).record.status, StoredWorkdayStatus.active);
      expect(
        (await repo.read(access)).single.record.status,
        StoredWorkdayStatus.ended,
      );
      expect(await db.select(db.localCommands).get(), hasLength(2));
    },
  );

  test('confirmed retry never consumes newly retained input', () async {
    final drafts = LocalDraftStore(db);
    Future<void> save() async {
      await drafts.save(
        organizationId: 'company',
        domain: draft.domain,
        draftId: draft.draftId,
        ownerId: 'alex',
        expectedRevision: 0,
        payload: {'workdayId': 'day', 'employeeId': 'alex', 'vehicleId': 'van'},
        occurredAt: at,
      );
    }

    await save();
    await start(checkpoint: draft);
    expect((await start(checkpoint: draft)).revision, 1);
    await save();
    await expectLater(start(checkpoint: draft), throwsA(anything));
    expect(
      await drafts.find(
        organizationId: 'company',
        domain: draft.domain,
        draftId: draft.draftId,
        ownerId: 'alex',
      ),
      isNotNull,
    );
    expect(await db.select(db.localCommands).get(), hasLength(1));
  });
  test(
    'start failure rolls back workday, active identity and odometer',
    () async {
      await db.customStatement(
        "CREATE TRIGGER fail_odometer BEFORE INSERT ON local_records WHEN NEW.domain = 'workday/odometers' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      await expectLater(start(), throwsA(anything));
      expect(await repo.read(access), isEmpty);
      expect((await repo.odometer('van', access)).revision, 0);
      expect(await db.select(db.localCommands).get(), isEmpty);
      await db.customStatement('DROP TRIGGER fail_odometer');
      expect((await start()).revision, 1);
      await expectLater(
        repo.start(
          id: 'other',
          employeeId: 'alex',
          vehicleId: 'van',
          odometerTenths: 100001,
          expectedOdometerRevision: 1,
          at: at,
          access: access,
        ),
        throwsStateError,
      );
    },
  );
  test(
    'unrelated draft is retained and rolls back every start write',
    () async {
      final drafts = LocalDraftStore(db);
      await drafts.save(
        organizationId: 'company',
        domain: draft.domain,
        draftId: draft.draftId,
        ownerId: 'alex',
        expectedRevision: 0,
        payload: {
          'workdayId': 'another-day',
          'employeeId': 'alex',
          'vehicleId': 'van',
          'odometer': '10000.',
        },
        occurredAt: at,
      );
      await expectLater(start(checkpoint: draft), throwsA(anything));
      expect(await db.select(db.localRecords).get(), isEmpty);
      expect(await db.select(db.localCommands).get(), isEmpty);
      final retained = await drafts.find(
        organizationId: 'company',
        domain: draft.domain,
        draftId: draft.draftId,
        ownerId: 'alex',
      );
      expect(retained, isNotNull);
      expect(drafts.decode(retained!)['workdayId'], 'another-day');
    },
  );
  test('draft failure retains input and rolls back start', () async {
    final drafts = LocalDraftStore(db);
    await drafts.save(
      organizationId: 'company',
      domain: draft.domain,
      draftId: draft.draftId,
      ownerId: 'alex',
      expectedRevision: 0,
      payload: {
        'odometer': '10000.',
        'workdayId': 'day',
        'employeeId': 'alex',
        'vehicleId': 'van',
      },
      occurredAt: at,
    );
    await db.customStatement(
      "CREATE TRIGGER fail_input BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
    );
    await expectLater(start(checkpoint: draft), throwsA(anything));
    expect(await repo.read(access), isEmpty);
    expect((await repo.odometer('van', access)).revision, 0);
    expect(
      await drafts.list(
        organizationId: 'company',
        domain: draft.domain,
        ownerId: 'alex',
      ),
      hasLength(1),
    );
    await db.customStatement('DROP TRIGGER fail_input');
    await start(checkpoint: draft);
    expect(
      await drafts.list(
        organizationId: 'company',
        domain: draft.domain,
        ownerId: 'alex',
      ),
      isEmpty,
    );
  });
  test(
    'pause and end recover after reopen with exact time and odometer',
    () async {
      await start();
      await repo.change(
        id: 'day',
        expectedRevision: 1,
        at: at.add(const Duration(hours: 2)),
        access: access,
        status: StoredWorkdayStatus.paused,
      );
      await db.close();
      db = LocalDatabase.file(File('${directory.path}/workday.sqlite'));
      repo = SqliteWorkdayRepository(db);
      expect(
        (await repo.read(
          access,
        )).single.record.elapsedAt(at.add(const Duration(hours: 5))),
        const Duration(hours: 2),
      );
      await repo.change(
        id: 'day',
        expectedRevision: 2,
        at: at.add(const Duration(hours: 3)),
        access: access,
        status: StoredWorkdayStatus.active,
      );
      await expectLater(
        repo.change(
          id: 'day',
          expectedRevision: 3,
          at: at.add(const Duration(hours: 4)),
          access: access,
          status: StoredWorkdayStatus.ended,
          endingOdometerTenths: 100100,
          expectedOdometerRevision: 0,
        ),
        throwsA(anything),
      );
      expect((await repo.read(access)).single.revision, 3);
      final ended = await repo.change(
        id: 'day',
        expectedRevision: 3,
        at: at.add(const Duration(hours: 4)),
        access: access,
        status: StoredWorkdayStatus.ended,
        endingOdometerTenths: 100100,
        expectedOdometerRevision: 1,
      );
      expect(
        ended.record.elapsedAt(at.add(const Duration(days: 2))),
        const Duration(hours: 3),
      );
      expect((await repo.odometer('van', access)).readingTenths, 100100);
      await repo.start(
        id: 'next-day',
        employeeId: 'alex',
        vehicleId: 'van',
        odometerTenths: 100100,
        expectedOdometerRevision: 2,
        at: at.add(const Duration(days: 1)),
        access: access,
      );
      expect(await repo.read(access), hasLength(2));
    },
  );
  test(
    'other employee, company and vehicle cannot access or mutate workday',
    () async {
      await start();
      for (final denied in [
        WorkdayAccess(
          organizationId: 'other',
          actorEmployeeId: 'alex',
          permissionRevision: 'test',
          employeeIds: {'alex'},
          vehicleIds: {'van'},
          canManage: true,
        ),
        WorkdayAccess(
          organizationId: 'company',
          actorEmployeeId: 'sam',
          permissionRevision: 'test',
          employeeIds: {'sam'},
          vehicleIds: {'van'},
          canManage: true,
        ),
        WorkdayAccess(
          organizationId: 'company',
          actorEmployeeId: 'alex',
          permissionRevision: 'test',
          employeeIds: {'alex'},
          vehicleIds: {'other'},
          canManage: true,
        ),
      ]) {
        expect(await repo.read(denied), isEmpty);
        await expectLater(
          repo.change(
            id: 'day',
            expectedRevision: 1,
            at: at.add(const Duration(hours: 1)),
            access: denied,
            status: StoredWorkdayStatus.paused,
          ),
          throwsA(anything),
        );
      }
      expect((await repo.read(access)).single.revision, 1);
    },
  );
}
