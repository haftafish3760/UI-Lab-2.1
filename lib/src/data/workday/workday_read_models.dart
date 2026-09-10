import 'stored_workday_record.dart';

class WorkdayAccess {
  WorkdayAccess({
    required this.organizationId,
    required this.actorEmployeeId,
    required this.permissionRevision,
    required Set<String> employeeIds,
    required Set<String> vehicleIds,
    this.canManage = false,
  }) : employeeIds = Set.unmodifiable(employeeIds),
       vehicleIds = Set.unmodifiable(vehicleIds);
  final String organizationId;
  final String actorEmployeeId;
  final String permissionRevision;
  final Set<String> employeeIds;
  final Set<String> vehicleIds;
  final bool canManage;
}

class WorkdaySnapshot {
  const WorkdaySnapshot(this.record, this.revision);
  final StoredWorkdayRecord record;
  final int revision;
}

class ConfirmedVehicleOdometer {
  const ConfirmedVehicleOdometer(this.readingTenths, this.revision);
  final int readingTenths;
  final int revision;
}
