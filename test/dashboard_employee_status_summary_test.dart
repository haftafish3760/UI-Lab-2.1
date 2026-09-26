import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_employee_status_summary.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/seeded_directory_fixture.dart';

void main() {
  testWidgets(
    'Dashboard employee status reads the saved job, not profile text',
    (tester) async {
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
        id: 'dashboard-driving-job',
        kind: WorkRecordKind.job,
        number: 'JOB-DRIVING',
        title: 'Repair',
        client: 'Customer',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
        assignedEmployeeIds: ['jordan'],
        status: WorkRecordStatus.enRoute,
        createdByEmployeeId: 'alex',
      );
      expect(
        await tester.runAsync(() => work.create(job)),
        isTrue,
        reason: work.failureMessage,
      );
      final store = PrototypeOperationsStore(
        directorySession: directory,
        workSession: work,
      );
      addTearDown(() async {
        store.dispose();
        work.dispose();
        directory.dispose();
        await harness.dispose();
      });
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: DashboardEmployeeStatusSummary()),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('dashboard-employee-status')),
        findsOneWidget,
      );
      expect(find.text('Driving to a job'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dashboard-employee-jordan')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('employee-work-status-jordan')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
