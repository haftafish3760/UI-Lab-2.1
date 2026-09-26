import 'models/work_models.dart';

/// An explicit search window, supplied by the user or saved working hours.
/// Empty calendar space alone is not proof of employee availability.
class JobScheduleWindow {
  JobScheduleWindow(this.start, this.end) {
    if (!end.isAfter(start)) {
      throw ArgumentError('The search window must end after it starts.');
    }
  }
  final DateTime start;
  final DateTime end;
}

class JobScheduleOpening {
  const JobScheduleOpening(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

/// Checks resource bookings without using employee skills or trade categories.
/// Callers must supply an authorized, complete resource schedule. A filtered
/// personal view must not be treated as the company's complete availability.
class JobScheduleAvailability {
  JobScheduleAvailability(Iterable<WorkRecord> jobs)
    : _jobs = List.unmodifiable(
        jobs.where(
          (job) =>
              job.kind == WorkRecordKind.job &&
              job.status != WorkRecordStatus.completed &&
              job.scheduledStart != null,
        ),
      );

  final List<WorkRecord> _jobs;

  List<WorkRecord> conflicts({
    required DateTime start,
    required DateTime end,
    required Set<String> employeeIds,
    String? vehicle,
    String? excludingJobId,
    int bufferMinutes = 0,
  }) {
    if (!end.isAfter(start)) throw ArgumentError('End must follow start.');
    if (bufferMinutes < 0 || bufferMinutes > 1440) {
      throw ArgumentError('Choose a buffer from 0 to 1440 minutes.');
    }
    for (final job in _jobs.where((job) => job.id != excludingJobId)) {
      final gap = Duration(
        minutes: bufferMinutes > job.scheduleBufferMinutes
            ? bufferMinutes
            : job.scheduleBufferMinutes,
      );
      final legacyAssignment =
          job.assignedEmployeeIds.isEmpty &&
          job.assignee != null &&
          job.assignee!.trim().isNotEmpty &&
          job.assignee != 'Unassigned';
      if (employeeIds.isNotEmpty &&
          legacyAssignment &&
          job.scheduledStart!.isBefore(end.add(gap)) &&
          (job.scheduledEnd == null ||
              job.scheduledEnd!.add(gap).isAfter(start))) {
        throw StateError(
          'An existing booking needs its saved employee assignment updated before openings can be checked.',
        );
      }
      if (_sharesResource(job, employeeIds, vehicle) &&
          (job.scheduledEnd == null ||
              !job.scheduledEnd!.isAfter(job.scheduledStart!))) {
        throw StateError(
          'An existing booking needs a valid end time before openings can be checked.',
        );
      }
    }
    return _jobs.where((job) {
      final gap = Duration(
        minutes: bufferMinutes > job.scheduleBufferMinutes
            ? bufferMinutes
            : job.scheduleBufferMinutes,
      );
      return job.id != excludingJobId &&
          _sharesResource(job, employeeIds, vehicle) &&
          job.scheduledStart!.isBefore(end.add(gap)) &&
          job.scheduledEnd!.add(gap).isAfter(start);
    }).toList()..sort((a, b) => a.scheduledStart!.compareTo(b.scheduledStart!));
  }

  List<JobScheduleOpening> firstOpenings({
    required Iterable<JobScheduleWindow> windows,
    required Duration duration,
    required Set<String> employeeIds,
    String? vehicle,
    String? excludingJobId,
    int bufferMinutes = 0,
    DateTime? notBefore,
    int limit = 3,
  }) {
    if (duration <= Duration.zero || limit < 1) {
      throw ArgumentError('Choose a positive duration and result limit.');
    }
    if (employeeIds.isEmpty && !_hasVehicle(vehicle)) {
      throw ArgumentError('Choose an employee or vehicle to check bookings.');
    }
    final ordered = windows.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final results = <JobScheduleOpening>[];
    for (final window in ordered) {
      var candidate = notBefore != null && notBefore.isAfter(window.start)
          ? notBefore
          : window.start;
      while (!candidate.add(duration).isAfter(window.end)) {
        final busy = conflicts(
          start: candidate,
          end: candidate.add(duration),
          employeeIds: employeeIds,
          vehicle: vehicle,
          excludingJobId: excludingJobId,
          bufferMinutes: bufferMinutes,
        );
        if (busy.isEmpty) {
          if (!results.any((slot) => slot.start == candidate)) {
            results.add(JobScheduleOpening(candidate, candidate.add(duration)));
          }
          if (results.length >= limit) return List.unmodifiable(results);
          candidate = candidate.add(duration);
          continue;
        }
        candidate = busy
            .map(
              (job) => job.scheduledEnd!.add(
                Duration(
                  minutes: bufferMinutes > job.scheduleBufferMinutes
                      ? bufferMinutes
                      : job.scheduleBufferMinutes,
                ),
              ),
            )
            .reduce((a, b) => a.isAfter(b) ? a : b);
      }
    }
    return List.unmodifiable(results);
  }

  bool _sharesResource(
    WorkRecord job,
    Set<String> employees,
    String? vehicle,
  ) =>
      job.assignedEmployeeIds.any(employees.contains) ||
      (_hasVehicle(vehicle) && job.vehicle == vehicle);

  bool _hasVehicle(String? vehicle) =>
      vehicle != null &&
      vehicle.trim().isNotEmpty &&
      vehicle != 'No vehicle assigned';
}
