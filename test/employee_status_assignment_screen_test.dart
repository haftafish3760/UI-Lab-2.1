import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/employee_status_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';
import 'support/storage/seeded_directory_fixture.dart';

void main() {
  testWidgets(
    'assigning from employee status preselects the person and saves the job',
    (tester) async {
      tester.view.physicalSize = const Size(375, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final database = (await tester.runAsync(harness.open))!;
      final directory = (await tester.runAsync(
        () => openSeededTestDirectory(database),
      ))!;
      final work = (await tester.runAsync(
        () => WorkPersistenceSession.open(
          SqliteWorkRepository(database),
          WorkSessionPermissions(
            organizationId: directory.permissions.organizationId,
            actorEmployeeId: 'alex',
            permissionRevision: 'test-1',
            visibleCreatorIds: const {'alex'},
            editableKinds: WorkRecordKind.values.toSet(),
            canAssignJobs: true,
            canScheduleJobs: true,
          ),
        ),
      ))!;
      const job = WorkRecord(
        id: 'assign-from-status',
        kind: WorkRecordKind.job,
        number: 'JOB-ASSIGN',
        title: 'Repair faucet',
        client: 'Customer',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
        createdByEmployeeId: 'alex',
        status: WorkRecordStatus.ready,
      );
      expect(await tester.runAsync(() => work.create(job)), isTrue);
      final store = PrototypeOperationsStore(
        directorySession: directory,
        workSession: work,
      );
      addTearDown(() async {
        store.dispose();
        directory.dispose();
        work.dispose();
        await harness.dispose();
      });
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: MaterialApp(
            theme: AppTheme.light,
            home: EmployeeWorkStatusDetailScreen(
              employee: directory.employees.singleWhere(
                (item) => item.id == 'alex',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('assign-employee-work')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Repair faucet'));
      await waitForNativeSave(
        tester,
        () => find.text('Assign employees').evaluate().isNotEmpty,
      );
      final checkbox = find.widgetWithText(CheckboxListTile, 'Alex Morgan');
      expect(checkbox, findsOneWidget);
      expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);
      await tester.ensureVisible(find.text('Save assignment'));
      await tester.tap(find.text('Save assignment'));
      await waitForNativeSave(
        tester,
        () => work.records
            .singleWhere((record) => record.id == job.id)
            .assignedEmployeeIds
            .contains('alex'),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
