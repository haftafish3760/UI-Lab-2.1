import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/job_assignment_editor_sheet.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shell/employee_editor_screen.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'create an employee from assignment and save the selected profile',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final db = (await tester.runAsync(harness.open))!;
      final directory = (await tester.runAsync(() => openUiLabDirectory(db)))!;
      final work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      final store = PrototypeOperationsStore(
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
        id: 'new-team-job',
        kind: WorkRecordKind.job,
        number: 'Job 1',
        title: 'Repair',
        client: 'Customer',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
      );
      expect(await tester.runAsync(() => work.create(job)), isTrue);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showModalBottomSheet<WorkRecord>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        JobAssignmentEditorSheet(record: job, work: work),
                  ),
                  child: const Text('Assign job'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Assign job'));
      await tester.pumpAndSettle();
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('job-add-employee'))
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(find.byKey(const ValueKey('job-add-employee')));
      await waitForNativeSave(
        tester,
        () => find.byType(EmployeeEditorScreen).evaluate().isNotEmpty,
      );
      final name = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Employee name',
      );
      await waitForNativeSave(tester, () => name.evaluate().isNotEmpty);
      await tester.enterText(name, 'New team member');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final saveEmployee = find.byKey(const ValueKey('save-employee-button'));
      await tester.dragUntilVisible(
        saveEmployee,
        find.byType(ListView).last,
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(saveEmployee);
      await tester.pumpAndSettle();
      await tester.tap(saveEmployee);
      await waitForNativeSave(
        tester,
        () => find.byType(EmployeeEditorScreen).evaluate().isEmpty,
      );
      final employee = directory.employees.singleWhere((e) => e.name == 'New team member');
      expect(employee.name, 'New team member');
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, employee.name),
            )
            .value,
        isTrue,
      );
      await tester.ensureVisible(find.text('Save assignment'));
      await tester.tap(find.text('Save assignment'));
      await waitForNativeSave(
        tester,
        () => find.byType(JobAssignmentEditorSheet).evaluate().isEmpty,
      );
      expect(work.records.singleWhere((r) => r.id == job.id).assignedEmployeeIds, [employee.id]);
      await tester.pumpWidget(const SizedBox.shrink());
      final reopened = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      expect(reopened.records.singleWhere((r) => r.id == job.id).assignedEmployeeIds, [employee.id]);
      reopened.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
