import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_day_screen.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_plan.dart';
import 'package:ui_lab_2_1/src/screens/work/job_schedule_editor_sheet.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final calendar in [false, true]) {
    testWidgets(
      'schedule input reopens and commits atomically from ${calendar ? 'Calendar Day' : 'Dashboard'}',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1100);
        tester.view.devicePixelRatio = 1;
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        var db = (await tester.runAsync(harness.open))!;
        var work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
        final original = work.records.singleWhere(
          (item) => item.id == 'job-1038',
        );
        Finder field(String label) => find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == label,
        );
        Future<void> open() async {
          await tester.pumpWidget(UiLabApp(workSession: work));
          await tester.pumpAndSettle();
          if (calendar) {
            Navigator.of(tester.element(find.byType(DashboardScreen))).push(
              MaterialPageRoute<void>(
                builder: (_) => DashboardDayScreen(initialDay: dashboardToday),
              ),
            );
            await tester.pumpAndSettle();
          }
          final menu = find.byKey(const ValueKey('plan-actions-job-1038')).last;
          await tester.ensureVisible(menu);
          await tester.tap(menu);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Reschedule'));
          await tester.pumpAndSettle();
          await waitForNativeSave(
            tester,
            () => field('Hour').evaluate().isNotEmpty,
          );
        }

        try {
          await open();
          await tester.enterText(field('Hour'), '1');
          await tester.enterText(field('Minutes'), '');
          await tester.tap(find.text('Keep unfinished schedule'));
          await waitForNativeSave(
            tester,
            () => find.byType(JobScheduleEditorSheet).evaluate().isEmpty,
          );
          await tester.pumpWidget(const SizedBox.shrink());
          work.dispose();
          await tester.runAsync(() => harness.close(db));
          db = (await tester.runAsync(harness.open))!;
          work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
          await open();
          expect(tester.widget<TextField>(field('Hour')).controller!.text, '1');
          expect(
            tester.widget<TextField>(field('Minutes')).controller!.text,
            '',
          );
          await tester.enterText(field('Minutes'), '45');
          await tester.tap(find.text('Keep unfinished schedule'));
          await waitForNativeSave(
            tester,
            () => find.byType(JobScheduleEditorSheet).evaluate().isEmpty,
          );
          // Wait for the draft before injecting failure in its atomic consumption.
          await tester.runAsync(
            () => db.customStatement(
              "CREATE TRIGGER fail_schedule_draft BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/job-schedule' BEGIN SELECT RAISE(ABORT, 'fail'); END",
            ),
          );
          final menu = find.byKey(const ValueKey('plan-actions-job-1038')).last;
          await tester.ensureVisible(menu);
          await tester.tap(menu);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Reschedule'));
          await tester.pumpAndSettle();
          await waitForNativeSave(
            tester,
            () => field('Hour').evaluate().isNotEmpty,
          );
          await tester.tap(find.text('Save schedule'));
          await waitForNativeSave(
            tester,
            () => work.failureMessage != null && !work.isSaving,
          );
          expect(find.byType(JobScheduleEditorSheet), findsOneWidget);
          expect(
            work.records
                .singleWhere((item) => item.id == original.id)
                .scheduledStart,
            original.scheduledStart,
          );
          await tester.runAsync(
            () => db.customStatement('DROP TRIGGER fail_schedule_draft'),
          );
          await tester.tap(find.text('Save schedule'));
          await waitForNativeSave(
            tester,
            () => find.byType(JobScheduleEditorSheet).evaluate().isEmpty,
          );
          final saved = work.records.singleWhere(
            (item) => item.id == original.id,
          );
          expect(saved.scheduledStart!.hour, 1);
          expect(saved.scheduledStart!.minute, 45);
          expect(
            saved.scheduledEnd!.difference(saved.scheduledStart!),
            original.scheduledEnd!.difference(original.scheduledStart!),
          );
          expect(
            tester
                .widget<TodayPlan>(find.byType(TodayPlan).last)
                .items
                .singleWhere((item) => item.id == original.id)
                .time,
            '1:45 AM',
          );
          expect(
            await tester.runAsync(
              () => LocalDraftStore(db).list(
                organizationId: work.permissions.organizationId,
                domain: 'work/job-schedule',
                ownerId: work.permissions.actorEmployeeId,
              ),
            ),
            isEmpty,
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
