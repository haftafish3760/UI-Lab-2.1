import '../workday/stored_workday_record.dart';
import 'models/work_models.dart';

/// A read-only view of confirmed jobs and workdays. Profile status text is not
/// operational evidence and must not be used to report what a person is doing.
class EmployeeWorkStatus {
  const EmployeeWorkStatus({
    required this.label,
    required this.jobs,
    required this.recordedTime,
    required this.includesTimeOutsideToday,
    required this.runningLate,
    this.currentJob,
    this.workday,
  });

  final String label;
  final List<WorkRecord> jobs;
  final Duration recordedTime;

  /// A whole workday duration cannot be represented as today's hours when it
  /// crosses midnight; pause totals are not stored by calendar day.
  final bool includesTimeOutsideToday;
  final bool runningLate;
  final WorkRecord? currentJob;
  final StoredWorkdayRecord? workday;
}

EmployeeWorkStatus employeeWorkStatus({
  required String employeeId,
  required Iterable<WorkRecord> visibleJobs,
  required Iterable<StoredWorkdayRecord> visibleWorkdays,
  required DateTime now,
}) {
  final localNow = now.toLocal();
  final day = DateTime(localNow.year, localNow.month, localNow.day);
  final nextDay = DateTime(day.year, day.month, day.day + 1);
  final jobs =
      visibleJobs
          .where(
            (job) =>
                job.kind == WorkRecordKind.job &&
                job.assignedEmployeeIds.contains(employeeId) &&
                (job.occursOn(day) || _activeJob(job.status)),
          )
          .toList()
        ..sort(
          (left, right) => (left.scheduledStart ?? DateTime(9999)).compareTo(
            right.scheduledStart ?? DateTime(9999),
          ),
        );
  final workdays = visibleWorkdays
      .where(
        (record) =>
            record.employeeId == employeeId &&
            record.startedAt.toLocal().isBefore(nextDay) &&
            (record.endedAt ?? now).toLocal().isAfter(day),
      )
      .toList();
  final current = jobs.where((job) => _activeJob(job.status)).firstOrNull;
  final activeWorkday = workdays
      .where((record) => record.status != StoredWorkdayStatus.ended)
      .firstOrNull;
  final recordedTime = workdays.fold<Duration>(
    Duration.zero,
    (total, record) => total + record.elapsedAt(now),
  );
  final includesTimeOutsideToday = workdays.any(
    (record) =>
        record.startedAt.toLocal().isBefore(day) ||
        (record.endedAt?.toLocal().isAfter(nextDay) ?? false),
  );
  final runningLate = jobs.any(
    (job) =>
        job.scheduledEnd != null &&
        job.scheduledEnd!.isBefore(now) &&
        job.status != WorkRecordStatus.completed,
  );
  final label = switch (current?.status) {
    WorkRecordStatus.enRoute => 'Driving to a job',
    WorkRecordStatus.arrived || WorkRecordStatus.inProgress => 'On a job',
    WorkRecordStatus.paused => 'Job paused',
    WorkRecordStatus.needsReturnVisit => 'Return visit needed',
    _ =>
      activeWorkday?.status == StoredWorkdayStatus.paused
          ? 'Workday paused'
          : jobs.any((job) => job.status == WorkRecordStatus.scheduled)
          ? 'Job scheduled'
          : workdays.any((record) => record.status == StoredWorkdayStatus.ended)
          ? 'Workday finished'
          : activeWorkday != null
          ? 'No active job recorded'
          : 'No workday recorded',
  };
  return EmployeeWorkStatus(
    label: label,
    jobs: List.unmodifiable(jobs),
    currentJob: current,
    workday: activeWorkday,
    recordedTime: recordedTime,
    includesTimeOutsideToday: includesTimeOutsideToday,
    runningLate: runningLate,
  );
}

bool _activeJob(WorkRecordStatus status) => switch (status) {
  WorkRecordStatus.enRoute ||
  WorkRecordStatus.arrived ||
  WorkRecordStatus.inProgress ||
  WorkRecordStatus.paused ||
  WorkRecordStatus.needsReturnVisit => true,
  _ => false,
};
