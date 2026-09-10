import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/workday/sqlite_workday_repository.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_persistence_session.dart';
import 'support/storage/native_widget_pump.dart';

class _FailedRefreshRepository extends SqliteWorkdayRepository {
  _FailedRefreshRepository(super.database);
  bool fail = false;
  @override
  Future<List<WorkdaySnapshot>> read(WorkdayAccess access) {
    if (fail) throw StateError('injected read failure');
    return super.read(access);
  }
}

void main() {
  for (final width in [320.0, 1400.0]) {
    testWidgets('saved workday reloads without false zero at $width LP', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('workday-notice-'),
      ))!;
      late LocalDatabase db;
      late _FailedRefreshRepository repo;
      late WorkdayPersistenceSession session;
      await tester.runAsync(() async {
        db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
        repo = _FailedRefreshRepository(db);
        session = await WorkdayPersistenceSession.open(
          repo,
          WorkdayAccess(
            organizationId: 'company',
            actorEmployeeId: 'alex',
            permissionRevision: 'test',
            employeeIds: {'alex'},
            vehicleIds: {'transit-12'},
            canManage: true,
          ),
        );
      });
      try {
        await tester.pumpWidget(
          UiLabApp(workdaySession: session, draftStore: LocalDraftStore(db)),
        );
        await tester.pumpAndSettle();
        final reading = find.byKey(const ValueKey('dashboard-header-odometer'));
        expect(tester.widget<Text>(reading).data, 'Not recorded');
        repo.fail = true;
        final result = await tester.runAsync(
          () => session.start(
            id: 'day',
            employeeId: 'alex',
            vehicleId: 'transit-12',
            odometerTenths: 0,
            expectedOdometerRevision: 0,
            at: DateTime.now().toUtc(),
          ),
        );
        expect(result!.committed, isTrue);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(reading).data, 'Unavailable');
        expect(find.textContaining('Your workday was saved.'), findsOneWidget);
        expect(find.text('Reload workday'), findsOneWidget);
        await tester.tap(find.text('Reload workday'));
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find.text('Reload workday').evaluate().isNotEmpty,
        );
        expect(tester.widget<Text>(reading).data, 'Unavailable');
        repo.fail = false;
        await tester.tap(find.text('Reload workday'));
        await tester.pump();
        await waitForNativeSave(tester, () => session.isReady);
        expect(tester.widget<Text>(reading).data, '0.0 mi');
        expect(find.text('Reload workday'), findsNothing);
        expect(
          find.byKey(const ValueKey('active-workday-overview')),
          findsOneWidget,
        );
        expect(
          await tester.runAsync(() => db.select(db.localCommands).get()),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        session.dispose();
        await tester.runAsync(db.close);
        await tester.runAsync(() => directory.delete(recursive: true));
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  }
}
