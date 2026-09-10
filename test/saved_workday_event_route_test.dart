import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/workday/sqlite_workday_repository.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_record_navigation.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/day_entry_details_screen.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final scenario in ['authorized', 'employee', 'vehicle', 'missing-end']) {
    testWidgets('workday event resolves exact scoped source: $scenario', (
      tester,
    ) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('workday-route-'),
      ))!;
      late LocalDatabase db;
      late WorkdayPersistenceSession session;
      final at = DateTime(2029, 1, 2, 12);
      await tester.runAsync(() async {
        db = LocalDatabase.file(File('${directory.path}/data.sqlite'));
        final repo = SqliteWorkdayRepository(db);
        final owner = WorkdayAccess(
          organizationId: 'company',
          actorEmployeeId: 'alex',
          permissionRevision: 'test',
          employeeIds: {'alex'},
          vehicleIds: {'transit-12'},
          canManage: true,
        );
        await repo.start(
          id: 'day',
          employeeId: 'alex',
          vehicleId: 'transit-12',
          odometerTenths: 12345,
          expectedOdometerRevision: 0,
          at: at,
          access: owner,
        );
        session = await WorkdayPersistenceSession.open(
          repo,
          WorkdayAccess(
            organizationId: 'company',
            actorEmployeeId: 'alex',
            permissionRevision: 'test',
            employeeIds: {scenario == 'employee' ? 'sam' : 'alex'},
            vehicleIds: {scenario == 'vehicle' ? 'other' : 'transit-12'},
          ),
        );
      });
      final store = PrototypeOperationsStore(workdaySession: session);
      try {
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => DashboardRecordNavigation.openEntry(
                      context,
                      DayEntry(
                        id: scenario == 'missing-end'
                            ? 'workday-day-ended'
                            : 'workday-day-started',
                        sourceRecordId: 'day',
                        time: '1:00 AM',
                        title: 'Forged caller text',
                        detail: 'forged detail',
                        odometer: '999 mi',
                        kind: DayEntryKind.workday,
                        color: Colors.red,
                      ),
                      date: DateTime(2000),
                      showOdometer: true,
                      onCreateJob: (_) {},
                    ),
                    child: const Text('Open source'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open source'));
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => scenario == 'authorized'
              ? find.byType(DayEntryDetailsScreen).evaluate().isNotEmpty
              : find
                    .text('This workday event is unavailable.')
                    .evaluate()
                    .isNotEmpty,
        );
        expect(find.text('Forged caller text'), findsNothing);
        if (scenario == 'authorized') {
          final details = tester.widget<DayEntryDetailsScreen>(
            find.byType(DayEntryDetailsScreen),
          );
          expect(details.entry.title, 'Workday started');
          expect(details.entry.odometer, '1,234.5 mi');
          expect(details.date, DateTime(2029, 1, 2));
        } else {
          expect(find.byType(DayEntryDetailsScreen), findsNothing);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        store.dispose();
        session.dispose();
        await tester.runAsync(db.close);
        await tester.runAsync(() => directory.delete(recursive: true));
      }
    });
  }
}
