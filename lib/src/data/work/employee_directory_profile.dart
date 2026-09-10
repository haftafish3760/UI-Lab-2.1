/// Company-private profile and configured access choices. These values do not
/// authenticate an account or independently grant runtime capabilities.
class EmployeeDirectoryProfile {
  const EmployeeDirectoryProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.emergencyContact,
    required this.role,
    required this.pay,
    required this.status,
    this.active = true,
    this.canSeeEstimates = true,
    this.canCreateEstimates = false,
    this.canApproveEstimates = false,
    this.canRecordExpenses = true,
    this.canViewCompanyReports = false,
  });
  final String id;
  final String name;
  final String phone;
  final String emergencyContact;
  final String role;
  final String pay;
  final String status;
  final bool active;
  final bool canSeeEstimates;
  final bool canCreateEstimates;
  final bool canApproveEstimates;
  final bool canRecordExpenses;
  final bool canViewCompanyReports;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'emergencyContact': emergencyContact,
    'role': role,
    'pay': pay,
    'status': status,
    'active': active,
    'canSeeEstimates': canSeeEstimates,
    'canCreateEstimates': canCreateEstimates,
    'canApproveEstimates': canApproveEstimates,
    'canRecordExpenses': canRecordExpenses,
    'canViewCompanyReports': canViewCompanyReports,
  };

  factory EmployeeDirectoryProfile.fromJson(Map<String, Object?> json) {
    final value = EmployeeDirectoryProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      emergencyContact: json['emergencyContact'] as String,
      role: json['role'] as String,
      pay: json['pay'] as String,
      status: json['status'] as String,
      active: json['active'] as bool,
      canSeeEstimates: json['canSeeEstimates'] as bool,
      canCreateEstimates: json['canCreateEstimates'] as bool,
      canApproveEstimates: json['canApproveEstimates'] as bool,
      canRecordExpenses: json['canRecordExpenses'] as bool,
      canViewCompanyReports: json['canViewCompanyReports'] as bool,
    );
    if (value.id.trim().isEmpty ||
        value.name.trim().isEmpty ||
        !const {
          'Helper',
          'Technician',
          'Supervisor',
          'Office',
        }.contains(value.role) ||
        (!value.canSeeEstimates &&
            (value.canCreateEstimates || value.canApproveEstimates))) {
      throw const FormatException('Invalid employee profile.');
    }
    return value;
  }
}
