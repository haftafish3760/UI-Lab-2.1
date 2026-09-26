import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/workday/sqlite_workday_repository.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_persistence_session.dart';
import 'package:ui_lab_2_1/src/screens/work/employee_timesheet_screen.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';

void main() {
  testWidgets('timesheet shows only authorized saved workday time', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final session = (await tester.runAsync(
      () => WorkdayPersistenceSession.open(
        SqliteWorkdayRepository(database),
        WorkdayAccess(
          organizationId: 'business',
          actorEmployeeId: 'alex',
          permissionRevision: 'test-1',
          employeeIds: {'alex'},
          vehicleIds: {'truck'},
          canManage: true,
        ),
      ),
    ))!;
    final started = DateTime.now().toUtc().subtract(const Duration(hours: 2));
    final startedResult = (await tester.runAsync(
      () => session.start(
        id: 'recorded-day',
        employeeId: 'alex',
        vehicleId: 'truck',
        odometerTenths: 100,
        expectedOdometerRevision: 0,
        at: started,
      ),
    ))!;
    expect(startedResult.committed, isTrue, reason: startedResult.message);
    final store = PrototypeOperationsStore(workdaySession: session);
    addTearDown(() async {
      store.dispose();
      session.dispose();
      await harness.dispose();
    });
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EmployeeTimesheetScreen(employeeId: 'alex'),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('timesheet-workday-recorded-day')),
      findsOneWidget,
    );
    expect(find.textContaining('In progress'), findsOneWidget);
    expect(find.textContaining('hr'), findsOneWidget);
    expect(find.text('Edit time'), findsNothing);

    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EmployeeTimesheetScreen(employeeId: 'jordan'),
        ),
      ),
    );
    expect(find.text('Recorded work time is unavailable.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('timesheet-workday-recorded-day')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
