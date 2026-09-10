import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/job_notes_editor_dialog.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'job notes recover after reopen; failed save retains dialog and exact draft',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      addTearDown(() async {
        work.dispose();
        await harness.dispose();
      });
      const job = WorkRecord(
        id: 'notes-job',
        kind: WorkRecordKind.job,
        number: 'JOB-NOTES',
        title: 'Service',
        client: 'Maya Thompson',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
        jobNotes: 'Confirmed note',
      );
      expect(await tester.runAsync(() => work.create(job)), isTrue);
      await tester.runAsync(
        () => db.customStatement(
          "CREATE TRIGGER fail_notes BEFORE UPDATE ON local_records WHEN NEW.record_id = 'notes-job' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
        ),
      );
      Future<void> open() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<WorkRecord>(
                    context: context,
                    builder: (_) =>
                        JobNotesEditorDialog(record: job, work: work),
                  ),
                  child: const Text('Open notes'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open notes'));
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => find.byType(TextField).evaluate().isNotEmpty,
        );
      }

      await open();
      await tester.enterText(find.byType(TextField), '  Check the shutoff ');
      await tester.tap(find.text('Keep unfinished notes'));
      await waitForNativeSave(
        tester,
        () => find.byType(JobNotesEditorDialog).evaluate().isEmpty,
      );
      expect(
        work.records.singleWhere((r) => r.id == job.id).jobNotes,
        'Confirmed note',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      work.dispose();
      await tester.runAsync(() => harness.close(db));
      db = (await tester.runAsync(harness.open))!;
      work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      await open();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '  Check the shutoff ',
      );
      await tester.tap(find.text('Save notes'));
      await waitForNativeSave(tester, () => work.failureMessage != null);
      expect(find.byType(JobNotesEditorDialog), findsOneWidget);
      expect(
        work.records.singleWhere((r) => r.id == job.id).jobNotes,
        'Confirmed note',
      );
      final drafts = LocalDraftStore(db);
      final rows = (await tester.runAsync(
        () => drafts.list(
          organizationId: work.permissions.organizationId,
          domain: 'work/job-notes',
          ownerId: work.permissions.actorEmployeeId,
        ),
      ))!;
      expect(drafts.decode(rows.single)['notes'], '  Check the shutoff ');
      await tester.runAsync(
        () => db.customStatement('DROP TRIGGER fail_notes'),
      );
      await tester.tap(find.text('Save notes'));
      await waitForNativeSave(
        tester,
        () => find.byType(JobNotesEditorDialog).evaluate().isEmpty,
      );
      expect(
        work.records.singleWhere((r) => r.id == job.id).jobNotes,
        'Check the shutoff',
      );
      expect(
        await tester.runAsync(
          () => drafts.list(
            organizationId: work.permissions.organizationId,
            domain: 'work/job-notes',
            ownerId: work.permissions.actorEmployeeId,
          ),
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
