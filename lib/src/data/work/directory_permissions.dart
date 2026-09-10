class DirectoryPermissions {
  const DirectoryPermissions({
    required this.organizationId,
    required this.actorEmployeeId,
    required this.permissionRevision,
    this.canViewCustomers = false,
    this.canManageCustomers = false,
    this.canViewCompany = false,
    this.canViewEmployees = false,
    this.canManageEmployees = false,
    this.canManageCompany = false,
    this.canViewVehicles = false,
    this.canManageVehicles = false,
  });
  final String organizationId;
  final String actorEmployeeId;
  final String permissionRevision;
  final bool canViewCustomers;
  final bool canManageCustomers;
  final bool canViewCompany;
  final bool canViewEmployees;
  final bool canManageEmployees;
  final bool canManageCompany;
  final bool canViewVehicles;
  final bool canManageVehicles;
}
