import '../expenses/expense_ui_lab_policy.dart';
import '../storage/local_database.dart';
import 'sqlite_day_note_repository.dart';
import 'day_note_persistence_session.dart';

/// Explicit development authority. No notes are seeded or inferred at startup.
Future<DayNotePersistenceSession> openUiLabDayNotes(LocalDatabase database) =>
    DayNotePersistenceSession.open(
      SqliteDayNoteRepository(database),
      DayNoteAccess(
        organizationId: expenseUiLabOrganizationId,
        actorEmployeeId: expenseUiLabOwnerEmployeeId,
        permissionRevision: 'ui-lab-day-note-owner-1',
        employeeIds: {'alex', 'jordan'},
        canCreate: true,
      ),
    );
