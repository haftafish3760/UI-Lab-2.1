import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/work_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/job_assignment_editor_sheet.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('Work Day assignment entry resumes the same job recovery sheet', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final db = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
    final store = PrototypeOperationsStore(workSession: work);
    final scope = OperationalScopeController(view: AppViewMode.admin);
    addTearDown(() async {
      store.dispose();
      work.dispose();
      scope.dispose();
      await harness.dispose();
    });
    final day = DateTime(2038, 1, 4);
    final job = WorkRecord(
      id: 'day-assignment',
      kind: WorkRecordKind.job,
      number: 'JOB-DAY',
      title: 'Future service',
      client: 'Maya Thompson',
      detail: 'Repair',
      pricing: WorkPricingModel.flatRate,
      scheduledStart: day,
      scheduledEnd: day.add(const Duration(hours: 2)),
      status: WorkRecordStatus.scheduled,
    );
    expect(await tester.runAsync(() => work.create(job)), isTrue);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: WorkDayScreen(initialDay: day),
          ),
        ),
      ),
    );
    Future<void> openAssignment() async {
      final button = find.byKey(const ValueKey('assign-day-assignment'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assign job'));
      await tester.pumpAndSettle();
      await waitForNativeSave(
        tester,
        () => find.byKey(const ValueKey('Technician')).evaluate().isNotEmpty,
      );
    }

    await openAssignment();
    await tester.tap(find.byKey(const ValueKey('Technician')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jordan Lee').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep unfinished assignment'));
    await waitForNativeSave(
      tester,
      () => find.byType(JobAssignmentEditorSheet).evaluate().isEmpty,
    );
    expect(
      work.records.singleWhere((record) => record.id == job.id).assignee,
      isNull,
    );
    await openAssignment();
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('Technician')),
          )
          .initialValue,
      'Jordan Lee',
    );
    await tester.tap(find.text('Save assignment'));
    await waitForNativeSave(
      tester,
      () => find.byType(JobAssignmentEditorSheet).evaluate().isEmpty,
    );
    expect(
      work.records.singleWhere((record) => record.id == job.id).assignee,
      'Jordan Lee',
    );
    expect(work.storageRevisionFor(job.id), 2);
    expect(tester.takeException(), isNull);
  });
}
