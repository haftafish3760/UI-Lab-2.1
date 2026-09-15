import 'package:flutter/material.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/employee_directory_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/job_assignment_editor_sheet.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'job assignment recover after reopen; failed save retains dialog and exact draft',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      final directory = (await tester.runAsync(() => openUiLabDirectory(db)))!;
      for (final name in ['Alex Morgan', 'Jordan Lee']) {
        expect(
          await tester.runAsync(
            () => directory.saveEmployee(
              EmployeeDirectoryProfile(
                id: name,
                name: name,
                phone: '',
                emergencyContact: '',
                role: 'Technician',
                pay: '',
                status: 'Available',
              ),
              expectedRevision: 0,
            ),
          ),
          isTrue,
        );
      }
      var store = PrototypeOperationsStore(
        workSession: work,
        directorySession: directory,
      );
      addTearDown(() async {
        store.dispose();
        directory.dispose();
        work.dispose();
        await harness.dispose();
      });
      const job = WorkRecord(
        id: 'assignment-job',
        kind: WorkRecordKind.job,
        number: 'JOB-NOTES',
        title: 'Service',
        client: 'Maya Thompson',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
        assignee: 'Alex Morgan',
        assignedEmployeeIds: ['Alex Morgan'],
        vehicle: 'Transit 12',
      );
      expect(await tester.runAsync(() => work.create(job)), isTrue);
      await tester.runAsync(
        () => db.customStatement(
          "CREATE TRIGGER fail_assignment BEFORE UPDATE ON local_records WHEN NEW.record_id = 'assignment-job' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
        ),
      );
      Future<void> open() async {
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: MaterialApp(
              theme: AppTheme.light,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showModalBottomSheet<WorkRecord>(
                      isScrollControlled: true,
                      context: context,
                      builder: (_) =>
                          JobAssignmentEditorSheet(record: job, work: work),
                    ),
                    child: const Text('Open assignment'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open assignment'));
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => find.byType(CheckboxListTile).evaluate().length == 2,
        );
      }

      await open();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Alex Morgan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Jordan Lee'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep unfinished assignment'));
      await waitForNativeSave(
        tester,
        () => find.byType(JobAssignmentEditorSheet).evaluate().isEmpty,
      );
      expect(
        work.records.singleWhere((r) => r.id == job.id).assignee,
        'Alex Morgan',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      work.dispose();
      await tester.runAsync(() => harness.close(db));
      db = (await tester.runAsync(harness.open))!;
      work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      store = PrototypeOperationsStore(
        workSession: work,
        directorySession: directory,
      );
      await open();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Jordan Lee'),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Alex Morgan'),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.text('Save assignment'));
      await waitForNativeSave(tester, () => work.failureMessage != null);
      expect(find.byType(JobAssignmentEditorSheet), findsOneWidget);
      expect(
        work.records.singleWhere((r) => r.id == job.id).assignee,
        'Alex Morgan',
      );
      final drafts = LocalDraftStore(db);
      final rows = (await tester.runAsync(
        () => drafts.list(
          organizationId: work.permissions.organizationId,
          domain: 'work/job-assignment',
          ownerId: work.permissions.actorEmployeeId,
        ),
      ))!;
      expect(drafts.decode(rows.single)['assignee'], 'Jordan Lee');
      expect(drafts.decode(rows.single)['employeeIds'], ['Jordan Lee']);
      expect(
        work.records.singleWhere((r) => r.id == job.id).vehicle,
        'Transit 12',
      );
      await tester.runAsync(
        () => db.customStatement('DROP TRIGGER fail_assignment'),
      );
      await tester.tap(find.text('Save assignment'));
      await waitForNativeSave(
        tester,
        () => find.byType(JobAssignmentEditorSheet).evaluate().isEmpty,
      );
      expect(
        work.records.singleWhere((r) => r.id == job.id).assignee,
        'Jordan Lee',
      );
      expect(
        await tester.runAsync(
          () => drafts.list(
            organizationId: work.permissions.organizationId,
            domain: 'work/job-assignment',
            ownerId: work.permissions.actorEmployeeId,
          ),
        ),
        isEmpty,
      );
      expect(
        work.records.singleWhere((r) => r.id == job.id).vehicle,
        'Transit 12',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
