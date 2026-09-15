import '../storage/local_record_store.dart';
import 'employee_directory_profile.dart';
import 'models/work_models.dart';
import 'sqlite_work_repository.dart';
import 'work_session_permissions.dart';

Future<void> validateWorkAssignment({
  required SqliteWorkRepository repository,
  required WorkSessionPermissions permissions,
  required WorkRecord next,
  required WorkRecord? previous,
}) async {
  if (next.kind != WorkRecordKind.job) return;
  final ids = next.assignedEmployeeIds;
  final old = previous?.assignedEmployeeIds ?? const <String>[];
  final sameIds = ids.length == old.length && ids.every(old.contains);
  final sameName =
      next.assignee == previous?.assignee ||
      (previous == null &&
          (next.assignee == null || next.assignee == 'Unassigned'));
  if (sameIds && sameName) return;
  if (!permissions.canAssignJobs || ids.toSet().length != ids.length) {
    throw StateError('You do not have permission to assign this job.');
  }
  if (ids.isEmpty &&
      next.assignee != null &&
      next.assignee!.trim().isNotEmpty &&
      next.assignee != 'Unassigned') {
    throw StateError('Choose a saved employee, or leave this job unassigned.');
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
