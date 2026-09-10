import '../expenses/expense_ui_lab_policy.dart';
import '../storage/local_database.dart';
import 'sqlite_workday_repository.dart';
import 'workday_persistence_session.dart';

/// Explicit development authority, not production authentication. Starting the
/// app never creates a confirmed workday or assumes a physical odometer reading.
Future<WorkdayPersistenceSession> openUiLabWorkdaySession(
  LocalDatabase database,
) => WorkdayPersistenceSession.open(
  SqliteWorkdayRepository(database),
  WorkdayAccess(
    organizationId: expenseUiLabOrganizationId,
    actorEmployeeId: expenseUiLabOwnerEmployeeId,
    permissionRevision: 'ui-lab-workday-owner-permissions-1',
    employeeIds: {'alex', 'jordan'},
    vehicleIds: {'transit-12', 'service-van-4', 'pickup-2'},
    canManage: true,
  ),
);
