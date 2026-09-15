import '../expenses/expense_ui_lab_policy.dart';
import 'local_database.dart';

/// Owner-authorized September 14 reset of the existing demo business records.
/// Runs before repositories load, once, and only on marked demo installations.
/// Never runs when opening a database for import inspection or ordinary tests.
Future<void> removeDemoInstallation(
  LocalDatabase database,
) => database.transaction(() async {
  const key = 'owner-demo-removal-2026-09-14';
  final done = await (database.select(
    database.localMetadata,
  )..where((row) => row.metadataKey.equals(key))).getSingleOrNull();
  if (done != null) return;
  final seeds =
      await (database.select(database.localMetadata)..where(
            (row) => row.metadataKey.isIn([
              'ui-lab-demo-seed',
              'ui-lab-work-demo-seed',
              'ui-lab-directory-demo-seed',
            ]),
          ))
          .get();
  if (seeds.isNotEmpty) {
    // The owner explicitly identified all current app business data as
    // dummy data. Settings and other organizations are preserved.
    const predicate =
        "organization_id = ? AND (domain LIKE 'work/%' OR "
        "domain LIKE 'directory/%' OR domain LIKE 'expenses/%' OR "
        "domain LIKE 'recurring-expenses/%' OR domain LIKE 'receipt-drafts/%' OR "
        "domain LIKE 'workday/%' OR domain LIKE 'day-notes/%' OR domain LIKE 'notifications/%')";
    for (final table in [
      'local_record_revisions',
      'local_records',
      'local_drafts',
    ]) {
      await database.customStatement('DELETE FROM $table WHERE $predicate', [
        expenseUiLabOrganizationId,
      ]);
    }
    // Remove journals only when no retained revision uses that command.
    // Seed markers remain and normal startup no longer seeds fixtures.
    await database.customStatement(
      'DELETE FROM local_change_outbox WHERE organization_id = ? AND command_id NOT IN '
      '(SELECT command_id FROM local_record_revisions WHERE organization_id = ?)',
      [expenseUiLabOrganizationId, expenseUiLabOrganizationId],
    );
    await database.customStatement(
      'DELETE FROM local_commands WHERE organization_id = ? AND command_id NOT IN '
      '(SELECT command_id FROM local_record_revisions WHERE organization_id = ?)',
      [expenseUiLabOrganizationId, expenseUiLabOrganizationId],
    );
  }
  await database
      .into(database.localMetadata)
      .insert(
        LocalMetadataCompanion.insert(
          metadataKey: key,
          value: seeds.isEmpty
              ? 'fresh-install'
              : 'owner-authorized-demo-removal',
        ),
      );
  await database.verifyIntegrity();
});
