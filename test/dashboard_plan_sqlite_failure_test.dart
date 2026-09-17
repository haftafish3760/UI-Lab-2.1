import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_day_screen.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_plan.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final calendar in [false, true]) {
    for (final completed in [false, true]) {
      testWidgets(
        'job ${completed ? 'completion' : 'arrival'} waits for SQLite on ${calendar ? 'Calendar Day' : 'Dashboard'}',
        (tester) async {
          tester.view.physicalSize = const Size(1400, 1100);
          tester.view.devicePixelRatio = 1;
          final harness = (await tester.runAsync(DatabaseHarness.create))!;
          final db = (await tester.runAsync(harness.open))!;
          final work = (await tester.runAsync(
            () => openSeededTestWorkSession(db),
          ))!;
          try {
            await tester.pumpWidget(UiLabApp(workSession: work));
            await tester.pumpAndSettle();
            if (calendar) {
              Navigator.of(tester.element(find.byType(DashboardScreen))).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      DashboardDayScreen(initialDay: dashboardToday),
                ),
              );
              await tester.pumpAndSettle();
            }
            String status() => tester
                .widget<TodayPlan>(find.byType(TodayPlan).last)
                .items
                .singleWhere((item) => item.id == 'job-1038')
                .status;
            final previous = status();
            await tester.runAsync(
              () => db.customStatement(
                "CREATE TRIGGER fail_arrival BEFORE UPDATE ON local_records WHEN NEW.record_id = 'job-1038' BEGIN SELECT RAISE(ABORT, 'fail'); END",
              ),
            );
            Future<void> arrive() async {
              final menu = find
                  .byKey(const ValueKey('plan-actions-job-1038'))
                  .last;
              await tester.ensureVisible(menu);
              await tester.tap(menu);
              await tester.pumpAndSettle();
              await tester.tap(
                find.text(completed ? 'Mark completed' : 'Mark arrived'),
              );
              await tester.pump();
            }

            await arrive();
            await waitForNativeSave(
              tester,
              () => work.failureMessage != null && !work.isSaving,
            );
            expect(
              work.records
                  .singleWhere((record) => record.id == 'job-1038')
                  .status,
              WorkRecordStatus.scheduled,
            );
            expect(status(), previous);
            expect(
              work.statusEvents.where((event) => event.record.id == 'job-1038'),
              isEmpty,
            );

            expect(
              find.text(completed ? 'Job completed' : 'Arrived at job'),
              findsNothing,
            );
            expect(
              find.textContaining('The job could not be saved.'),
              findsOneWidget,
            );
            await tester.runAsync(
              () => db.customStatement('DROP TRIGGER fail_arrival'),
            );
            await arrive();
            await waitForNativeSave(
              tester,
              () =>
                  work.records
                          .singleWhere((record) => record.id == 'job-1038')
                          .status ==
                      (completed
                          ? WorkRecordStatus.completed
                          : WorkRecordStatus.arrived) &&
                  !work.isSaving,
            );
            expect(status(), completed ? 'Completed' : 'Arrived');
            expect(
              work.statusEvents.where((event) => event.record.id == 'job-1038'),
              hasLength(1),
            );
            // Chronological entries collapse after three rows. A late-day event
            // is durable even when it is outside that presentation preview.
            final expand = find.byKey(const ValueKey('entries-expand-button'));
            if (expand.evaluate().isNotEmpty &&
                find
                    .descendant(
                      of: expand,
                      matching: find.textContaining('Show all'),
                    )
                    .evaluate()
                    .isNotEmpty) {
              await tester.ensureVisible(expand);
              await tester.tap(expand);
              await tester.pumpAndSettle();
            }

            expect(
              find.text(completed ? 'Job completed' : 'Arrived at job'),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            work.dispose();
            await tester.runAsync(harness.dispose);
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          }
        },
      );
    }
  }
}
