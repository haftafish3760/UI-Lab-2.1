import 'job_schedule_availability.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';

extension WorkScheduleOpenings on WorkPersistenceSession {
  Future<List<JobScheduleOpening>> findJobOpenings({
    required WorkRecord job,
    required Iterable<JobScheduleWindow> windows,
    DateTime? notBefore,
  }) async {
    requireActiveDraftOwner();
    if (!permissions.canScheduleJobs || !permissions.canEdit(job)) {
      throw StateError('You do not have permission to plan this job.');
    }
    final start = job.scheduledStart;
    final end = job.scheduledEnd;
    if (start == null || end == null || !end.isAfter(start)) {
      throw StateError('Set the job duration before finding an opening.');
    }
    final bookings = await repository.scheduleBookings(
      permissions.organizationId,
    );
    requireActiveDraftOwner();
    return JobScheduleAvailability(bookings).firstOpenings(
      windows: windows,
      duration: end.difference(start),
      employeeIds: job.assignedEmployeeIds.toSet(),
      vehicle: job.vehicle,
      excludingJobId: job.id,
      bufferMinutes: job.scheduleBufferMinutes,
      notBefore: notBefore,
    );
  }
}
