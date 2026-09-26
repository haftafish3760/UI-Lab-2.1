import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/employee_work_status.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/workday/stored_workday_record.dart';

void main() {
  final now = DateTime.utc(2026, 9, 26, 16);
  WorkRecord job(WorkRecordStatus status, {DateTime? end}) => WorkRecord(
    id: 'job-1',
    kind: WorkRecordKind.job,
    number: 'JOB-1',
    title: 'Repair',
    client: 'Customer',
    detail: 'Repair faucet',
    pricing: WorkPricingModel.flatRate,
    assignedEmployeeIds: const ['alex'],
    status: status,
    scheduledStart: DateTime.utc(2026, 9, 26, 14),
    scheduledEnd: end ?? DateTime.utc(2026, 9, 26, 17),
  );

  test('employee status follows saved job state and planned end', () {
    final driving = employeeWorkStatus(
      employeeId: 'alex',
      visibleJobs: [job(WorkRecordStatus.enRoute)],
      visibleWorkdays: const [],
      now: now,
    );
    expect(driving.label, 'Driving to a job');
    expect(driving.currentJob?.number, 'JOB-1');
    expect(driving.runningLate, isFalse);

    final late = employeeWorkStatus(
      employeeId: 'alex',
      visibleJobs: [
        job(WorkRecordStatus.inProgress, end: DateTime.utc(2026, 9, 26, 15)),
      ],
      visibleWorkdays: const [],
      now: now,
    );
    expect(late.label, 'On a job');
    expect(late.runningLate, isTrue);

    final other = employeeWorkStatus(
      employeeId: 'jordan',
      visibleJobs: [job(WorkRecordStatus.enRoute)],
      visibleWorkdays: const [],
      now: now,
    );
    expect(other.currentJob, isNull);
    expect(other.jobs, isEmpty);
  });

  test('workday time comes from confirmed records, not profile text', () {
    final workday = StoredWorkdayRecord.start(
      id: 'workday-1',
      organizationId: 'business',
      employeeId: 'alex',
      vehicleId: 'truck',
      at: DateTime.utc(2026, 9, 26, 14),
      odometerTenths: 1000,
    );
    final status = employeeWorkStatus(
      employeeId: 'alex',
      visibleJobs: const [],
      visibleWorkdays: [workday],
      now: now,
    );
    expect(status.label, 'No active job recorded');
    expect(status.recordedTime, const Duration(hours: 2));
  });
}
