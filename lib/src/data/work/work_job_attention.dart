import 'models/work_models.dart';

/// Read-only facts from an authorized Job. Reminder lead times do not alter
/// whether a saved schedule date has passed. The caller supplies the clock.
class WorkJobAttention {
  WorkJobAttention(WorkRecord job, DateTime now)
    : isOpen =
          job.kind == WorkRecordKind.job &&
          const {
            WorkRecordStatus.ready,
            WorkRecordStatus.scheduled,
            WorkRecordStatus.enRoute,
            WorkRecordStatus.arrived,
            WorkRecordStatus.inProgress,
            WorkRecordStatus.paused,
            WorkRecordStatus.needsReturnVisit,
          }.contains(job.status),
      scheduleDate = job.scheduledEnd ?? job.scheduledStart,
      unassigned =
          job.assignedEmployeeIds.isEmpty &&
          (job.assignee == null ||
              job.assignee!.trim().isEmpty ||
              job.assignee == 'Unassigned'),
      paused = job.status == WorkRecordStatus.paused,
      returnVisit = job.status == WorkRecordStatus.needsReturnVisit,
      today = DateTime(now.year, now.month, now.day);

  final bool isOpen, unassigned, paused, returnVisit;
  final DateTime? scheduleDate;
  final DateTime today;
  bool get overdue =>
      isOpen && scheduleDate != null && scheduleDate!.isBefore(today);
  List<String> get issues => !isOpen
      ? const []
      : [
          if (overdue) 'Scheduled work date has passed',
          if (returnVisit) 'Needs a return visit',
          if (paused) 'Work is paused',
          if (unassigned) 'No employees assigned',
          if (scheduleDate == null) 'No work date scheduled',
        ];

  /// Mutually exclusive: each open Job appears in one action queue.
  String? get primaryQueue => !isOpen
      ? null
      : overdue
      ? 'Overdue jobs'
      : returnVisit || paused
      ? 'Paused or return visit'
      : unassigned
      ? 'Needs employees'
      : scheduleDate == null
      ? 'Needs a work date'
      : 'Other active jobs';
}
