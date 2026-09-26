import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/job_schedule_editor_sheet.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'partial schedule recovers; failed save preserves duration and retry handles overnight end',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      addTearDown(() async {
        work.dispose();
        await harness.dispose();
      });
      final start = DateTime(2030, 1, 4, 9);
      final job = WorkRecord(
        id: 'schedule-job',
        kind: WorkRecordKind.job,
        number: 'JOB-SCHEDULE',
        title: 'Repair',
        client: 'Maya Thompson',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
        scheduledStart: start,
        scheduledEnd: start.add(const Duration(hours: 3, minutes: 15)),
        status: WorkRecordStatus.needsReturnVisit,
        jobNotes: 'Keep this note',
      );
      expect(await tester.runAsync(() => work.create(job)), isTrue);
      await tester.runAsync(
        () => db.customStatement(
          "CREATE TRIGGER fail_schedule BEFORE UPDATE ON local_records WHEN NEW.record_id = 'schedule-job' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
        ),
      );
      Finder field(String label) => find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
      Future<void> open() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showModalBottomSheet<WorkRecord>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        JobScheduleEditorSheet(record: job, work: work),
                  ),
                  child: const Text('Open schedule'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open schedule'));
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => field('Hour').evaluate().isNotEmpty,
        );
      }

      await open();
      await tester.tap(find.text('Choose arrival date'));
      await tester.pumpAndSettle();
      final chosenDay = find.byKey(
        const ValueKey('work-calendar-day-2030-1-6'),
      );
      await tester.ensureVisible(chosenDay);
      await tester.pumpAndSettle();
      await tester.tap(chosenDay);
      await tester.ensureVisible(find.text('Choose arrival date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose arrival date'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Hour'), '10');
      await tester.enterText(field('Minutes'), '');
      await tester.tap(find.text('PM'));
      await tester.ensureVisible(find.text('Save schedule'));
      await tester.tap(find.text('Save schedule'));
      await waitForNativeSave(
        tester,
        () => find
            .text('Enter an hour from 1 to 12 and minutes from 00 to 59.')
            .evaluate()
            .isNotEmpty,
      );
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
      expect(tester.widget<TextField>(field('Hour')).controller!.text, '10');
      expect(tester.widget<TextField>(field('Minutes')).controller!.text, '');
      await tester.enterText(field('Minutes'), '30');
      await tester.ensureVisible(find.text('Save schedule'));
      await tester.tap(find.text('Save schedule'));
      await waitForNativeSave(tester, () => work.failureMessage != null);
      expect(find.byType(JobScheduleEditorSheet), findsOneWidget);
      expect(
        work.records
            .singleWhere((record) => record.id == job.id)
            .scheduledStart,
        start,
      );
      await tester.runAsync(
        () => db.customStatement('DROP TRIGGER fail_schedule'),
      );
      await tester.ensureVisible(find.text('Save schedule'));
      await tester.tap(find.text('Save schedule'));
      await waitForNativeSave(
        tester,
        () => find.byType(JobScheduleEditorSheet).evaluate().isEmpty,
      );
      final saved = work.records.singleWhere((record) => record.id == job.id);
      expect(saved.scheduledStart, DateTime(2030, 1, 6, 22, 30));
      expect(saved.scheduledEnd, DateTime(2030, 1, 7, 1, 45));
      expect(saved.jobNotes, 'Keep this note');
      expect(saved.status, WorkRecordStatus.scheduled);
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
    },
  );
}
