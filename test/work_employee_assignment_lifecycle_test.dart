import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/employee_directory_profile.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/job_assignment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/work_dashboard_projection.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'support/storage/database_harness.dart';

void main() {
  test('new saved employees receive a converted job after restart', () async {
    final harness = await DatabaseHarness.create();
    addTearDown(harness.dispose);
    final db = await harness.open();
    final directory = await openUiLabDirectory(db);
    final work = await openUiLabWorkSession(db);
    addTearDown(directory.dispose);
    addTearDown(work.dispose);
    for (final id in ['new-employee-one', 'new-employee-two']) {
      expect(
        await directory.saveEmployee(
          EmployeeDirectoryProfile(
            id: id,
            name: id,
            phone: '',
            emergencyContact: '',
            role: 'Technician',
            pay: '',
            status: 'Available',
          ),
          expectedRevision: 0,
        ),
        isTrue,
      );
    }
    final day = DateTime(2026, 9, 15);
    final estimate = WorkRecord(
      id: 'estimate',
      kind: WorkRecordKind.estimate,
      number: 'Estimate 1',
      title: 'Repair',
      client: 'Customer',
      detail: 'Repair',
      pricing: WorkPricingModel.flatRate,
      total: 50,
      status: WorkRecordStatus.accepted,
      estimateStage: EstimateStage.approved,
      customerSignature: WorkCustomerSignature(
        signedBy: 'Customer',
        signedOn: day,
        signedRevision: 1,
      ),
    );
    expect(await work.create(estimate), isTrue);
    final job = WorkRecord(
      id: 'job',
      kind: WorkRecordKind.job,
      number: 'Job 1',
      title: 'Repair',
      client: 'Customer',
      detail: 'Repair',
      sourceId: estimate.id,
      pricing: WorkPricingModel.flatRate,
      total: 50,
      status: WorkRecordStatus.scheduled,
      scheduledStart: day.add(const Duration(hours: 9)),
      scheduledEnd: day.add(const Duration(hours: 11)),
      assignedEmployeeIds: const ['new-employee-one', 'new-employee-two'],
    );
    expect(
      await work.createJobFromApprovedEstimate(
        job: job,
        expectedSourceStorageRevision: work.storageRevisionFor(estimate.id),
        expectedSourceDocumentRevision: 1,
      ),
      isTrue,
    );
    final reopened = await openUiLabWorkSession(await harness.open());
    addTearDown(reopened.dispose);
    final savedJob = reopened.records.singleWhere((r) => r.id == job.id);
    expect(savedJob.assignedEmployeeIds, [
      'new-employee-one',
      'new-employee-two',
    ]);
    for (final employee in savedJob.assignedEmployeeIds) {
      expect(
        withWorkPlanProjections(
          data: const DashboardDayData(),
          records: reopened.records,
          day: day,
          employeeId: employee,
        ).plan.single.sourceRecordId,
        job.id,
      );
    }
    expect(
      withWorkPlanProjections(
        data: const DashboardDayData(),
        records: reopened.records,
        day: day,
        employeeId: 'unassigned-person',
      ).plan,
      isEmpty,
    );
    final assignment = await reopened.openJobAssignmentDraft(job.id);
    assignment.updateAssignment(
      assignee: 'First employee',
      vehicle: 'No vehicle assigned',
      employeeIds: ['new-employee-one'],
    );
    expect(await assignment.confirm(), isNotNull);
    await assignment.session.close();
    expect(
      reopened.records.singleWhere((r) => r.id == job.id).assignedEmployeeIds,
      ['new-employee-one'],
    );
  });
  test(
    'assignment rejects missing, inactive and unauthorized employees',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final work = await openUiLabWorkSession(db);
      final directory = await openUiLabDirectory(db);
      addTearDown(work.dispose);
      addTearDown(directory.dispose);
      const job = WorkRecord(
        id: 'job',
        kind: WorkRecordKind.job,
        number: 'Job 2',
        title: 'Repair',
        client: 'Customer',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
        total: 50,
        status: WorkRecordStatus.scheduled,
      );
      expect(await work.create(job), isTrue);
      expect(
        await work.update(job.copyWith(assignedEmployeeIds: ['missing'])),
        isFalse,
      );
      expect(
        await directory.saveEmployee(
          const EmployeeDirectoryProfile(
            id: 'inactive',
            name: 'Inactive employee',
            phone: '',
            emergencyContact: '',
            role: 'Technician',
            pay: '',
            status: 'Unavailable',
            active: false,
          ),
          expectedRevision: 0,
        ),
        isTrue,
      );
      expect(
        await work.update(job.copyWith(assignedEmployeeIds: ['inactive'])),
        isFalse,
      );
      final restricted = await WorkPersistenceSession.open(
        SqliteWorkRepository(db),
        WorkSessionPermissions(
          organizationId: work.permissions.organizationId,
          actorEmployeeId: work.permissions.actorEmployeeId,
          permissionRevision: 'no-assignment',
          visibleCreatorIds: work.permissions.visibleCreatorIds,
          editableKinds: {WorkRecordKind.job},
        ),
      );
      addTearDown(restricted.dispose);
      await expectLater(
        restricted.openJobAssignmentDraft(job.id),
        throwsStateError,
      );
      expect(
        await restricted.update(job.copyWith(assignee: 'Name-only bypass')),
        isFalse,
      );
      expect(work.records.singleWhere((r) => r.id == job.id).assignedEmployeeIds, isEmpty);
      await db.verifyIntegrity();
    },
  );
}
