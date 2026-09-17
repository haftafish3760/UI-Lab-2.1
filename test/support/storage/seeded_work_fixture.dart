import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';

/// Explicit regression fixtures, never a production demo-data setting.
/// The test owns this database. Reopening must preserve edits and deletions.
Future<WorkPersistenceSession> openSeededTestWorkSession(
  LocalDatabase database,
) async {
  const key = 'test-work-fixture-v1';
  await database.transaction(() async {
    final marker = await (database.select(
      database.localMetadata,
    )..where((row) => row.metadataKey.equals(key))).getSingleOrNull();
    if (marker != null) return;
    await SqliteWorkRepository(database).commit(
      organizationId: expenseUiLabOrganizationId,
      commandId: key,
      actorEmployeeId: expenseUiLabOwnerEmployeeId,
      permissionRevision: 'test-work-permissions-v1',
      occurredAt: DateTime.utc(2026, 9, 1),
      mutations: [
        for (final record in prototypeDemoWorkRecords())
          WorkRecordMutation(record: record, expectedStorageRevision: 0),
      ],
      financialEntries: prototypeDemoFinancialEntries(),
    );
    await database
        .into(database.localMetadata)
        .insert(LocalMetadataCompanion.insert(metadataKey: key, value: '1'));
  });
  return openUiLabWorkSession(database);
}
