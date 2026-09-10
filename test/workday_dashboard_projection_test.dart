import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/workday/sqlite_workday_repository.dart';
import 'package:ui_lab_2_1/src/data/workday/stored_workday_record.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_persistence_session.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';

void main() {
  test(
    'confirmed entries survive reopen, filter owner/date and never duplicate',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workday-projection-',
      );
      var db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
      final access = WorkdayAccess(
        organizationId: 'company',
        actorEmployeeId: 'alex',
        permissionRevision: 'test',
        employeeIds: {'alex', 'jordan'},
        vehicleIds: {'transit-12'},
        canManage: true,
      );
      var session = await WorkdayPersistenceSession.open(
        SqliteWorkdayRepository(db),
        access,
      );
      var store = PrototypeOperationsStore(workdaySession: session);
      final start = DateTime(2030, 1, 1, 22);
      final end = DateTime(2030, 1, 2, 2);
      List<DayEntry> entries(DateTime day, {String? employee = 'alex'}) => store
          .dashboardDay(
            day: day,
            contextId: employee ?? 'company',
            employeeId: employee,
          )
          .entries
          .where((entry) => entry.kind == DayEntryKind.workday)
          .toList();
      try {
        expect(entries(start), isEmpty);
        expect(
          (await session.start(
            id: 'night',
            employeeId: 'alex',
            vehicleId: 'transit-12',
            odometerTenths: 12345,
            expectedOdometerRevision: 0,
            at: start,
          )).committed,
          isTrue,
        );
        expect(entries(start).single.id, 'workday-night-started');
        expect(entries(start).single.odometer, '1,234.5 mi');
        expect(entries(start, employee: 'jordan'), isEmpty);
        expect(entries(start, employee: null).single.sourceRecordId, 'night');
        // Existing dashboard writers may feed their full projection back in.
        final projected = store.dashboardDay(
          day: start,
          contextId: 'alex',
          employeeId: 'alex',
        );
        store.updateDashboardDay(
          day: start,
          contextId: 'alex',
          data: projected,
        );
        expect(entries(start), hasLength(1));
        expect(
          (await session.change(
            id: 'night',
            expectedRevision: 1,
            at: end,
            status: StoredWorkdayStatus.ended,
            endingOdometerTenths: 12400,
            expectedOdometerRevision: 1,
          )).committed,
          isTrue,
        );
        expect(entries(start).single.title, 'Workday started');
        expect(entries(end).single.title, 'Workday ended');
        store.dispose();
        session.dispose();
        await db.close();
        db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
        session = await WorkdayPersistenceSession.open(
          SqliteWorkdayRepository(db),
          access,
        );
        store = PrototypeOperationsStore(workdaySession: session);
        expect(entries(start).single.id, 'workday-night-started');
        expect(entries(end).single.id, 'workday-night-ended');
        expect(entries(end).single.odometer, '1,240.0 mi');
        expect(entries(end, employee: 'jordan'), isEmpty);
      } finally {
        store.dispose();
        session.dispose();
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
