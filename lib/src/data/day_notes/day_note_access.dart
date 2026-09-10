class DayNoteAccess {
  DayNoteAccess({
    required this.organizationId,
    required this.actorEmployeeId,
    required this.permissionRevision,
    required Set<String> employeeIds,
    this.canCreate = false,
  }) : employeeIds = Set.unmodifiable(employeeIds);
  final String organizationId;
  final String actorEmployeeId;
  final String permissionRevision;
  final Set<String> employeeIds;
  final bool canCreate;
}
