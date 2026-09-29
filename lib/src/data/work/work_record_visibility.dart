import 'models/work_models.dart';
import 'work_session_permissions.dart';

/// Narrows already-loaded records without turning a presentation selection
/// into authority. Persistent records are matched by stable employee IDs.
bool workRecordIsVisible(
  WorkRecord record, {
  required WorkSessionPermissions permissions,
  required bool technicianView,
  String? selectedEmployeeId,
}) {
  if (!permissions.visibleCreatorIds.contains(record.createdByEmployeeId)) {
    return false;
  }
  final employeeId = technicianView
      ? permissions.actorEmployeeId
      : selectedEmployeeId;
  if (employeeId == null) return true;
  return record.createdByEmployeeId == employeeId ||
      record.assignedEmployeeIds.contains(employeeId);
}
