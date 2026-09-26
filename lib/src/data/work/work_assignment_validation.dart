import '../storage/local_record_store.dart';
import 'employee_directory_profile.dart';
import 'models/work_models.dart';
import 'sqlite_work_repository.dart';
import 'job_schedule_availability.dart';
import 'work_session_permissions.dart';

Future<void> validateWorkAssignment({
  required SqliteWorkRepository repository,
  required WorkSessionPermissions permissions,
  required WorkRecord next,
  required WorkRecord? previous,
}) async {
  if (next.kind != WorkRecordKind.job) return;
  final scheduleChanged =
      next.scheduledStart != previous?.scheduledStart ||
      next.scheduledEnd != previous?.scheduledEnd ||
      next.scheduleBufferMinutes != previous?.scheduleBufferMinutes;
  if (scheduleChanged) {
    if (!permissions.canScheduleJobs) {
      throw StateError('You do not have permission to schedule this job.');
    }
    final start = next.scheduledStart;
    final end = next.scheduledEnd;
    if ((start == null) != (end == null) ||
        (start != null && end != null && !end.isAfter(start))) {
      throw StateError('Choose a job end time after its start time.');
    }
  }
  final ids = next.assignedEmployeeIds;
  final old = previous?.assignedEmployeeIds ?? const <String>[];
  final sameIds = ids.length == old.length && ids.every(old.contains);
  final sameName =
      next.assignee == previous?.assignee ||
      (previous == null &&
          (next.assignee == null || next.assignee == 'Unassigned'));
  final assignmentChanged =
      !sameIds || !sameName || next.vehicle != previous?.vehicle;
  if (!assignmentChanged && !scheduleChanged) return;
  if (next.scheduleBufferMinutes < 0 || next.scheduleBufferMinutes > 1440) {
    throw StateError('Choose a schedule gap from 0 to 1440 minutes.');
  }
  if (assignmentChanged) {
    if (!permissions.canAssignJobs || ids.toSet().length != ids.length) {
      throw StateError('You do not have permission to assign this job.');
    }
    if (ids.isEmpty &&
        next.assignee != null &&
        next.assignee!.trim().isNotEmpty &&
        next.assignee != 'Unassigned') {
      throw StateError(
        'Choose a saved employee, or leave this job unassigned.',
      );
    }
    final store = LocalRecordStore(repository.database);
    final employees = await store.read(
      organizationId: permissions.organizationId,
      domain: 'directory/employees',
      ownerIds: {permissions.organizationId},
      recordIds: ids.toSet(),
    );
    if (employees.length != ids.length ||
        employees.any(
          (row) => !EmployeeDirectoryProfile.fromJson(store.decode(row)).active,
        )) {
      throw StateError('Choose active saved employees for this job.');
    }
  }
  if (next.scheduledStart != null &&
      next.scheduledEnd != null &&
      (next.assignedEmployeeIds.isNotEmpty ||
          (next.vehicle?.trim().isNotEmpty ?? false))) {
    final bookings = await repository.scheduleBookings(
      permissions.organizationId,
    );
    final conflicts = JobScheduleAvailability(bookings).conflicts(
      start: next.scheduledStart!,
      end: next.scheduledEnd!,
      employeeIds: next.assignedEmployeeIds.toSet(),
      vehicle: next.vehicle,
      excludingJobId: next.id,
      bufferMinutes: next.scheduleBufferMinutes,
    );
    if (conflicts.isNotEmpty) {
      throw StateError(
        'That time is too close to another booking for this employee or vehicle. Choose another time or change the gap.',
      );
    }
  }
}
