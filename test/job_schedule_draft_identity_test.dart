import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/screens/work/job_schedule_editor_sheet.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'schedule draft for a different job is retained but never editable',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final db = (await tester.runAsync(harness.open))!;
      final work = (await tester.runAsync(
        () => openSeededTestWorkSession(db),
      ))!;
      final job = work.records.singleWhere((item) => item.id == 'job-1038');
      final other = work.records.singleWhere((item) => item.id == 'job-1026');
      final drafts = LocalDraftStore(db);
      final permissions = work.permissions;
      final id = 'edit-${permissions.actorEmployeeId}-${job.id}';
      try {
        await tester.runAsync(
          () => drafts.save(
            organizationId: permissions.organizationId,
            domain: 'work/job-schedule',
            draftId: id,
            ownerId: permissions.actorEmployeeId,
            expectedRevision: 0,
            occurredAt: DateTime.now().toUtc(),
            payload: {
              'base': encodeWorkRecord(other),
              'baseRevision': 1,
              'day': DateTime(2030, 1, 5).toIso8601String(),
              'hour': '7',
              'minute': '15',
              'period': 'AM',
            },
          ),
        );
        final before = (await tester.runAsync(
          () => drafts.find(
            organizationId: permissions.organizationId,
            domain: 'work/job-schedule',
            draftId: id,
            ownerId: permissions.actorEmployeeId,
          ),
        ))!;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: JobScheduleEditorSheet(record: job, work: work),
            ),
          ),
        );
        await waitForNativeSave(
          tester,
          () => find
              .textContaining('Saved schedule could not be opened.')
              .evaluate()
              .isNotEmpty,
        );
        expect(find.byType(TextField), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save schedule'),
              )
              .onPressed,
          isNull,
        );
        expect(work.storageRevisionFor(job.id), 1);
        expect(work.storageRevisionFor(other.id), 1);
        final after = (await tester.runAsync(
          () => drafts.find(
            organizationId: permissions.organizationId,
            domain: 'work/job-schedule',
            draftId: id,
            ownerId: permissions.actorEmployeeId,
          ),
        ))!;
        expect(after.payload, before.payload);
        expect(after.revision, before.revision);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        work.dispose();
        await tester.runAsync(harness.dispose);
      }
    },
  );
}
