import '../expenses/expense_ui_lab_seed.dart';
import 'models/work_models.dart';
import '../expenses/expense_ui_lab_policy.dart';
import '../prototype_operations_demo_data.dart';
import '../storage/local_database.dart';
import 'sqlite_work_repository.dart';
import 'work_persistence_session.dart';
import 'work_session_permissions.dart';

/// Development fixtures and explicit demo authority, never authentication.
/// The marker and all fixture records commit together; reopening cannot replace
/// a user's edits or repopulate records based merely on an empty query.
Future<WorkPersistenceSession> openUiLabWorkSession(
  LocalDatabase database,
) async {
  final repository = SqliteWorkRepository(database);
  if (expenseUiLabDemoDataEnabled) {
    await database.transaction(() async {
      final marker =
          await (database.select(database.localMetadata)..where(
                (row) => row.metadataKey.equals('ui-lab-work-demo-seed'),
              ))
              .getSingleOrNull();
      if (marker != null) return;
      await repository.commit(
        organizationId: expenseUiLabOrganizationId,
        commandId: 'ui-lab-work-demo-seed-1',
        actorEmployeeId: expenseUiLabOwnerEmployeeId,
        permissionRevision: 'ui-lab-work-fixtures-1',
        occurredAt: DateTime.now().toUtc(),
        mutations: [
          for (final record in prototypeDemoWorkRecords())
            WorkRecordMutation(record: record, expectedStorageRevision: 0),
        ],
        financialEntries: prototypeDemoFinancialEntries(),
      );
      await database
          .into(database.localMetadata)
          .insert(
            LocalMetadataCompanion.insert(
              metadataKey: 'ui-lab-work-demo-seed',
              value: '1',
            ),
          );
    });
  }
  return WorkPersistenceSession.open(
    repository,
    WorkSessionPermissions(
      organizationId: expenseUiLabOrganizationId,
      actorEmployeeId: expenseUiLabOwnerEmployeeId,
      permissionRevision: 'ui-lab-work-owner-permissions-1',
      visibleCreatorIds: {'alex', 'jordan'},
      editableKinds: WorkRecordKind.values.toSet(),
      canManageOtherCreators: true,
      canIssueInvoices: true,
      canApproveInvoices: true,
      canApproveQuotes: true,
      canRecordPayments: true,
      canDeleteDrafts: true,
      canAssignJobs: true,
      canScheduleJobs: true,
      canShareDocuments: true,
      canRecordCustomerApproval: true,
      canCollectSignature: true,
      canAttachJobPhotos: true,
    ),
  );
}
