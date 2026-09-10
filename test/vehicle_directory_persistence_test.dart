import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/work/directory_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/vehicle_directory_profile.dart';
import 'package:ui_lab_2_1/src/data/workday/sqlite_workday_repository.dart';
import 'support/storage/database_harness.dart';

const access = DirectoryPermissions(
  organizationId: 'company',
  actorEmployeeId: 'owner',
  permissionRevision: 'fleet-1',
  canViewVehicles: true,
  canManageVehicles: true,
);
const vehicle = VehicleDirectoryProfile(
  id: 'van',
  name: 'Service van',
  yearMakeModel: '2020 Test Van',
  assignment: 'Crew name',
);
WorkdayAccess workdayAccess() => WorkdayAccess(
  organizationId: 'company',
  actorEmployeeId: 'owner',
  permissionRevision: 'workday-1',
  employeeIds: {'driver'},
  vehicleIds: {'van'},
  canManage: true,
);

void main() {
  test(
    'vehicle and shared odometer survive reopen and are visible to workday repository',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var session = await DirectoryPersistenceSession.open(db, access);
      expect(
        await session.saveVehicle(
          vehicle,
          expectedRevision: 0,
          odometerTenths: 421164,
          expectedOdometerRevision: 0,
        ),
        isTrue,
      );
      final workdays = SqliteWorkdayRepository(db);
      expect(
        (await workdays.odometer('van', workdayAccess())).readingTenths,
        421164,
      );
      expect(await workdays.read(workdayAccess()), isEmpty);
      session.dispose();
      await harness.close(db);
      db = await harness.open();
      session = await DirectoryPersistenceSession.open(db, access);
      addTearDown(session.dispose);
      expect(session.vehicles.single.toJson(), vehicle.toJson());
      expect(session.vehicleOdometer('van')!.readingTenths, 421164);
      expect(session.vehicleOdometer('van')!.revision, 1);
      expect(session.vehicleRevision('van'), 1);
    },
  );

  test(
    'failed odometer write rolls back profile and draft consumption; retry commits together',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final session = await DirectoryPersistenceSession.open(db, access);
      addTearDown(session.dispose);
      final drafts = LocalDraftStore(db);
      await drafts.save(
        organizationId: 'company',
        domain: 'directory/vehicle-editor',
        draftId: 'new-owner',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: {'name': 'Service van', 'odometer': '42,116.'},
        occurredAt: DateTime.now(),
      );
      const checkpoint = LocalDraftCheckpoint(
        domain: 'directory/vehicle-editor',
        draftId: 'new-owner',
        revision: 1,
      );
      Future<List<dynamic>> readDrafts() => drafts.list(
        organizationId: 'company',
        domain: checkpoint.domain,
        ownerId: 'owner',
      );
      await db.customStatement("""
      CREATE TRIGGER fail_vehicle_odo BEFORE INSERT ON local_records
      WHEN NEW.domain = 'workday/odometers'
      BEGIN SELECT RAISE(ABORT, 'injected odometer failure'); END
    """);
      expect(
        await session.saveVehicle(
          vehicle,
          expectedRevision: 0,
          odometerTenths: 1000,
          expectedOdometerRevision: 0,
          draftCheckpoint: checkpoint,
        ),
        isFalse,
      );
      expect(session.vehicles, isEmpty);
      expect(session.vehicleOdometer('van'), isNull);
      expect(await readDrafts(), hasLength(1));
      final observed = await DirectoryPersistenceSession.open(db, access);
      expect(observed.vehicles, isEmpty);
      observed.dispose();
      await db.customStatement('DROP TRIGGER fail_vehicle_odo');
      expect(
        await session.saveVehicle(
          vehicle,
          expectedRevision: 0,
          odometerTenths: 1000,
          expectedOdometerRevision: 0,
          draftCheckpoint: checkpoint,
        ),
        isTrue,
      );
      expect(await readDrafts(), isEmpty);
      await db.verifyIntegrity();
    },
  );

  test(
    'workday advance rejects stale profile odometer and preserves profile configuration',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final session = await DirectoryPersistenceSession.open(db, access);
      addTearDown(session.dispose);
      expect(
        await session.saveVehicle(
          vehicle,
          expectedRevision: 0,
          odometerTenths: 1000,
          expectedOdometerRevision: 0,
        ),
        isTrue,
      );
      final other = await harness.open();
      await SqliteWorkdayRepository(other).start(
        id: 'day',
        employeeId: 'driver',
        vehicleId: 'van',
        odometerTenths: 1100,
        expectedOdometerRevision: 1,
        at: DateTime.utc(2026, 9, 9),
        access: workdayAccess(),
      );
      final changed = VehicleDirectoryProfile.fromJson({
        ...vehicle.toJson(),
        'name': 'Stale name',
      });
      expect(
        await session.saveVehicle(
          changed,
          expectedRevision: 1,
          odometerTenths: 1000,
          expectedOdometerRevision: 1,
        ),
        isFalse,
      );
      expect(session.vehicles.single.name, vehicle.name);
      expect(
        (await SqliteWorkdayRepository(
          db,
        ).odometer('van', workdayAccess())).readingTenths,
        1100,
      );
      final refreshed = await DirectoryPersistenceSession.open(db, access);
      addTearDown(refreshed.dispose);
      expect(
        await refreshed.saveVehicle(
          changed,
          expectedRevision: 1,
          odometerTenths: 1000,
          expectedOdometerRevision: 2,
        ),
        isFalse,
      );
      expect(await refreshed.saveVehicle(changed, expectedRevision: 1), isTrue);
      // Configuration-only changes never roll back or advance mileage.
      expect(
        (await SqliteWorkdayRepository(
          db,
        ).odometer('van', workdayAccess())).revision,
        2,
      );
    },
  );

  test(
    'vehicle permission denial and organization isolation apply to profiles and mileage',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final owner = await DirectoryPersistenceSession.open(db, access);
      addTearDown(owner.dispose);
      expect(
        await owner.saveVehicle(
          vehicle,
          expectedRevision: 0,
          odometerTenths: 1000,
          expectedOdometerRevision: 0,
        ),
        isTrue,
      );
      for (final permissions in [
        const DirectoryPermissions(
          organizationId: 'company',
          actorEmployeeId: 'denied',
          permissionRevision: '1',
        ),
        const DirectoryPermissions(
          organizationId: 'other',
          actorEmployeeId: 'owner',
          permissionRevision: '1',
          canViewVehicles: true,
        ),
      ]) {
        final session = await DirectoryPersistenceSession.open(db, permissions);
        addTearDown(session.dispose);
        expect(session.vehicles, isEmpty);
        expect(session.vehicleOdometer('van'), isNull);
        expect(
          await session.saveVehicle(
            vehicle,
            expectedRevision: 1,
            odometerTenths: 2000,
            expectedOdometerRevision: 1,
          ),
          isFalse,
        );
      }
    },
  );
}
