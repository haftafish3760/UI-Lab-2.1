import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/workday/sqlite_workday_repository.dart';
import 'package:ui_lab_2_1/src/data/workday/stored_workday_record.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_persistence_session.dart';

class _RefreshFailureRepository extends SqliteWorkdayRepository {
  _RefreshFailureRepository(super.database);
  bool failReads = false;
  @override
  Future<List<WorkdaySnapshot>> read(WorkdayAccess access) {
    if (failReads) throw StateError('injected refresh failure');
    return super.read(access);
  }
}

void main() {
  late Directory directory;
  late LocalDatabase db;
  late _RefreshFailureRepository repo;
  late WorkdayPersistenceSession session;
  final at = DateTime.utc(2030, 1, 1, 8);
  final access = WorkdayAccess(
    organizationId: 'company',
    actorEmployeeId: 'alex',
    permissionRevision: 'test',
    employeeIds: {'alex'},
    vehicleIds: {'van'},
    canManage: true,
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('workday-session-');
    db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
    repo = _RefreshFailureRepository(db);
    session = await WorkdayPersistenceSession.open(repo, access);
  });
  tearDown(() async {
    session.dispose();
    await db.close();
    await directory.delete(recursive: true);
  });
  Future<WorkdayCommandResult> start() => session.start(
    id: 'day',
    employeeId: 'alex',
    vehicleId: 'van',
    odometerTenths: 100,
    expectedOdometerRevision: 0,
    at: at,
  );

  test(
    'failed write leaves committed projections unchanged and retry recovers',
    () async {
      await db.customStatement(
        "CREATE TRIGGER fail_workday BEFORE INSERT ON local_records WHEN NEW.domain = 'workday/records' BEGIN SELECT RAISE(ABORT, 'fail'); END",
      );
      final pending = start();
      expect(session.isSaving, isTrue);
      expect((await pending).committed, isFalse);
      expect(session.isSaving, isFalse);
      expect(session.activeFor('alex'), isNull);
      expect(session.odometerFor('van')!.revision, 0);
      await db.customStatement('DROP TRIGGER fail_workday');
      expect((await start()).committed, isTrue);
      expect(session.activeFor('alex')!.revision, 1);
      expect(session.odometerFor('van')!.readingTenths, 100);
      session.dispose();
      await db.close();
      db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
      repo = _RefreshFailureRepository(db);
      session = await WorkdayPersistenceSession.open(repo, access);
      expect(session.activeFor('alex')!.record.id, 'day');
      expect(session.odometerFor('van')!.readingTenths, 100);
    },
  );

  test('old retry acknowledgment cannot replace current ended state', () async {
    await start();
    expect(
      (await session.change(
        id: 'day',
        expectedRevision: 1,
        at: at.add(const Duration(hours: 1)),
        status: StoredWorkdayStatus.ended,
        endingOdometerTenths: 110,
        expectedOdometerRevision: 1,
      )).committed,
      isTrue,
    );
    expect((await start()).committed, isTrue);
    expect(session.activeFor('alex'), isNull);
    expect(session.records.single.record.status, StoredWorkdayStatus.ended);
    expect(session.odometerFor('van')!.readingTenths, 110);
    expect(await db.select(db.localCommands).get(), hasLength(2));
  });

  test(
    'committed save with failed refresh is reported saved, then reload recovers',
    () async {
      repo.failReads = true;
      final result = await start();
      expect(result.committed, isTrue);
      expect(result.message, contains('was saved'));
      expect(session.isReady, isFalse);
      expect(session.records, isEmpty);
      expect(session.odometerFor('van'), isNull);
      expect(await db.select(db.localCommands).get(), hasLength(1));
      repo.failReads = false;
      expect(await session.reload(), isTrue);
      expect(session.isReady, isTrue);
      expect(session.error, isNull);
      expect(session.activeFor('alex')!.record.id, 'day');
    },
  );
}
