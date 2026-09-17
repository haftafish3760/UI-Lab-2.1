import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/data/work/work_status_history.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'support/storage/database_harness.dart';

void main() {
  test('status history is atomic, immutable, scoped and recoverable', () async {
    final harness = await DatabaseHarness.create();
    var db = await harness.open();
    var session = await openSeededTestWorkSession(db);
    var store = PrototypeOperationsStore(workSession: session);
    List<DayEntry> entries({String? employee = 'alex'}) => store
        .dashboardDay(
          day: DateTime.now(),
          contextId: employee ?? 'company',
          employeeId: employee,
        )
        .entries
        .where((entry) => entry.kind == DayEntryKind.jobActivity)
        .toList();
    try {
      expect(
        session.statusEvents,
        isEmpty,
      ); // Seeded completions are not transitions.
      final original = session.records.singleWhere(
        (item) => item.id == 'job-1038',
      );
      final arrived = original.copyWith(status: WorkRecordStatus.arrived);
      await db.customStatement(
        "CREATE TRIGGER fail_history BEFORE INSERT ON local_record_revisions WHEN NEW.record_id = 'job-1038' BEGIN SELECT RAISE(ABORT, 'fail'); END",
      );
      expect(await session.update(arrived), isFalse);
      expect(entries(), isEmpty);
      expect(
        (await session.repository.query(
          organizationId: session.permissions.organizationId,
          visibleCreatorIds: {'alex'},
        )).singleWhere((item) => item.record.id == original.id).record.status,
        WorkRecordStatus.scheduled,
      );
      await db.customStatement('DROP TRIGGER fail_history');
      expect(await session.update(arrived), isTrue);
      final firstEvent = session.statusEvents.single;
      expect(entries().single.title, 'Arrived at job');
      expect(
        await session.update(arrived),
        isTrue,
      ); // No-op does not manufacture an event.
      expect(entries(), hasLength(1));
      final completed = arrived.copyWith(status: WorkRecordStatus.completed);
      expect(await session.update(completed), isTrue);
      expect(
        await session.update(completed.copyWith(jobNotes: 'Later edit')),
        isTrue,
      );
      expect(entries().map((entry) => entry.title), [
        'Arrived at job',
        'Job completed',
      ]);
      expect(entries(employee: 'jordan'), isEmpty);
      final projected = store.dashboardDay(
        day: DateTime.now(),
        contextId: 'alex',
        employeeId: 'alex',
      );
      store.updateDashboardDay(
        day: DateTime.now(),
        contextId: 'alex',
        data: projected,
      );
      expect(entries(), hasLength(2));
      expect(
        await readWorkStatusHistory(
          db,
          organizationId: 'another-company',
          visibleCreatorIds: {'alex'},
        ),
        isEmpty,
      );
      expect(
        await readWorkStatusHistory(
          db,
          organizationId: session.permissions.organizationId,
          visibleCreatorIds: {},
        ),
        isEmpty,
      );
      store.dispose();
      session.dispose();
      await harness.close(db);
      db = await harness.open();
      session = await openSeededTestWorkSession(db);
      store = PrototypeOperationsStore(workSession: session);
      expect(entries().map((entry) => entry.title), [
        'Arrived at job',
        'Job completed',
      ]);
      expect(session.statusEvents.first.id, firstEvent.id);
      expect(session.statusEvents.first.at, firstEvent.at);
      expect(session.statusEvents.first.record.jobNotes, original.jobNotes);
      expect(entries(employee: 'jordan'), isEmpty);
      await db.customStatement(
        "UPDATE local_record_revisions SET payload_hash = 'bad' WHERE record_id = 'job-1038' AND revision = 2",
      );
      await expectLater(
        readWorkStatusHistory(
          db,
          organizationId: session.permissions.organizationId,
          visibleCreatorIds: {'alex'},
        ),
        throwsStateError,
      );
    } finally {
      store.dispose();
      session.dispose();
      await harness.dispose();
    }
  });
}
