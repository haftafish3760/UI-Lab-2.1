import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'job plan survives reopen and never retains stale date or scope copies',
    () async {
      final harness = await DatabaseHarness.create();
      var db = await harness.open();
      var work = await openSeededTestWorkSession(db);
      var store = PrototypeOperationsStore(workSession: work);
      final original = work.records.singleWhere(
        (record) => record.id == 'job-1038',
      );
      final oldDay = original.scheduledStart!;
      final newDay = DateTime(2035, 3, 8, 14, 25);
      List<PlanItem> plans(DateTime day, {String? employee = 'alex'}) => store
          .dashboardDay(
            day: day,
            contextId: employee ?? 'company',
            employeeId: employee,
          )
          .plan
          .where((item) => item.kind == PlanItemKind.jobStop)
          .toList();
      try {
        expect(
          plans(oldDay).singleWhere((item) => item.id == original.id).status,
          'Scheduled',
        );
        final cached = store.dashboardDay(
          day: oldDay,
          contextId: 'alex',
          employeeId: 'alex',
        );
        store.updateDashboardDay(day: oldDay, contextId: 'alex', data: cached);
        final updated = original.copyWith(
          scheduledStart: newDay,
          scheduledEnd: newDay.add(const Duration(hours: 2)),
          status: WorkRecordStatus.arrived,
        );
        await db.customStatement(
          "CREATE TRIGGER fail_schedule BEFORE UPDATE ON local_records WHEN NEW.record_id = 'job-1038' BEGIN SELECT RAISE(ABORT, 'fail'); END",
        );
        expect(await store.updateWorkRecord(updated), isFalse);
        expect(plans(oldDay).any((item) => item.id == original.id), isTrue);
        expect(plans(newDay), isEmpty);
        await db.customStatement('DROP TRIGGER fail_schedule');
        expect(await store.updateWorkRecord(updated), isTrue);
        expect(plans(oldDay).any((item) => item.id == original.id), isFalse);
        expect(plans(newDay).single.status, 'Arrived');
        expect(plans(newDay).single.time, '2:25 PM');
        expect(plans(newDay, employee: 'jordan'), isEmpty);
        expect(plans(newDay, employee: 'unknown'), isEmpty);
        expect(
          plans(newDay, employee: null).single.sourceRecordId,
          original.id,
        );
        final projected = store.dashboardDay(
          day: newDay,
          contextId: 'alex',
          employeeId: 'alex',
        );
        store.updateDashboardDay(
          day: newDay,
          contextId: 'jordan',
          data: projected,
        );
        expect(plans(newDay, employee: 'jordan'), isEmpty);
        store.updateDashboardDay(
          day: newDay,
          contextId: 'alex',
          data: projected,
        );
        expect(plans(newDay), hasLength(1));
        store.dispose();
        work.dispose();
        await harness.close(db);
        db = await harness.open();
        work = await openSeededTestWorkSession(db);
        store = PrototypeOperationsStore(workSession: work);
        expect(plans(oldDay).any((item) => item.id == original.id), isFalse);
        expect(plans(newDay).single.status, 'Arrived');
        expect(plans(newDay).single.time, '2:25 PM');
        expect(plans(newDay, employee: 'jordan'), isEmpty);
        final restricted = await WorkPersistenceSession.open(
          work.repository,
          WorkSessionPermissions(
            organizationId: work.permissions.organizationId,
            actorEmployeeId: 'jordan',
            permissionRevision: 'restricted-test',
            visibleCreatorIds: {},
            editableKinds: {},
          ),
        );
        final restrictedStore = PrototypeOperationsStore(
          workSession: restricted,
        );
        try {
          restrictedStore.updateDashboardDay(
            day: newDay,
            contextId: 'company',
            data: projected,
          );
          expect(
            restrictedStore
                .dashboardDay(day: newDay, contextId: 'company')
                .plan
                .where((item) => item.kind == PlanItemKind.jobStop),
            isEmpty,
          );
        } finally {
          restrictedStore.dispose();
          restricted.dispose();
        }
      } finally {
        store.dispose();
        work.dispose();
        await harness.dispose();
      }
    },
  );
}
