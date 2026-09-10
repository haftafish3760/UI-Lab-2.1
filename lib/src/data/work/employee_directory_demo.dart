import 'employee_directory_profile.dart';

const demoEmployeeDirectoryProfiles = <EmployeeDirectoryProfile>[
  EmployeeDirectoryProfile(
    id: 'alex',
    name: 'Alex Morgan',
    phone: '(555) 014-2904',
    emergencyContact: 'Morgan Household · (555) 014-8732',
    role: 'Technician',
    pay: r'$28.00 per hour',
    status: 'On a job',
  ),
  EmployeeDirectoryProfile(
    id: 'jordan',
    name: 'Jordan Lee',
    phone: '(555) 014-6671',
    emergencyContact: 'Lee Household · (555) 014-1905',
    role: 'Technician',
    pay: r'$26.50 per hour',
    status: 'Available',
    canCreateEstimates: true,
  ),
  EmployeeDirectoryProfile(
    id: 'riley',
    name: 'Riley Chen',
    phone: '(555) 014-8055',
    emergencyContact: 'Chen Household · (555) 014-2240',
    role: 'Supervisor',
    pay: r'$33.00 per hour',
    status: 'Driving',
    canCreateEstimates: true,
    canApproveEstimates: true,
    canViewCompanyReports: true,
  ),
];
