import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../expenses/expense_record.dart';
import '../expenses/expense_ui_lab_policy.dart';
import '../expenses/expense_ui_lab_seed.dart';
import '../expenses/recurring_expense_ui_lab_seed.dart';
import '../expenses/local_expense_repository.dart';
import '../expenses/local_recurring_expense_repository.dart';
import '../expenses/recurring_expense_snapshot_codec.dart';
import '../notifications/local_notification_repository.dart';
import '../notifications/notification_snapshot_codec.dart';
import '../receipts/local_receipt_draft_repository.dart';
import '../receipts/receipt_draft_record.dart';
import '../receipts/receipt_draft_ui_lab_seed.dart';
import 'local_database.dart';
import 'local_installation_guard.dart';
import 'local_draft_store.dart';
import 'sqlite_domain_snapshot_store.dart';
import 'serialized_async_actions.dart';
import 'remove_demo_installation.dart';

/// App-owned lifetime for SQLite and domain adapters. Explicit directory
/// injection is reserved for isolated test/runtime verification environments.
class LocalPersistence {
  LocalPersistence._({
    required this.database,
    required this.expenses,
    required this.recurringExpenses,
    required this.receiptDrafts,
    required this.notifications,
  });

  final LocalDatabase database;
  final LocalExpenseRepository expenses;
  final LocalRecurringExpenseRepository recurringExpenses;
  final LocalReceiptDraftRepository receiptDrafts;
  final LocalNotificationRepository notifications;
  LocalDraftStore get drafts => LocalDraftStore(database);

  static Future<Directory> defaultDirectory() async => Directory.fromUri(
    (await getApplicationSupportDirectory()).uri.resolve(
      'maintainiac_ui_lab/sqlite/',
    ),
  );

  static Future<LocalPersistence> open({
    Directory? directory,
    String Function(String)? resolveRetainedPath,
    bool removeOwnerDemoData = false,
  }) async {
    final root = directory ?? await defaultDirectory();
    await root.create(recursive: true);
    final installation = LocalInstallationGuard(root);
    await installation.verifyBeforeOpen();
    final database = LocalDatabase.file(installation.databaseFile);
    try {
      await database.verifyIntegrity();
      if (removeOwnerDemoData) await removeDemoInstallation(database);
      final expenses =
          await SqliteDomainSnapshotStore.open<List<StoredExpenseRecord>>(
            database: database,
            organizationId: expenseUiLabOrganizationId,
            domain: 'expenses',
            collections: const [
              DomainCollection(
                name: 'records',
                idField: 'expenseId',
                ownerField: 'paidByEmployeeId',
              ),
            ],
            encode: (records) => {
              'records': records.map((r) => r.toJson()).toList(),
            },
            decode: (payload) =>
                _decodeList(payload, StoredExpenseRecord.fromJson),
          );
      final recurring =
          await SqliteDomainSnapshotStore.open<RecurringExpenseSnapshotData>(
            database: database,
            organizationId: expenseUiLabOrganizationId,
            domain: 'recurring-expenses',
            collections: const [
              DomainCollection(
                name: 'templates',
                idField: 'templateId',
                ownerField: 'assignedEmployeeId',
              ),
              DomainCollection(
                name: 'occurrences',
                idField: 'occurrenceId',
                ownerField: 'assignedEmployeeId',
              ),
            ],
            encode: (snapshot) => snapshot.toJson(),
            decode: RecurringExpenseSnapshotData.fromJson,
          );
      final receipts =
          await SqliteDomainSnapshotStore.open<List<StoredReceiptDraft>>(
            database: database,
            organizationId: expenseUiLabOrganizationId,
            domain: 'receipt-drafts',
            collections: const [
              DomainCollection(
                name: 'records',
                idField: 'draftId',
                ownerField: 'ownerEmployeeId',
              ),
            ],
            encode: (records) => {
              'records': records.map((r) => r.toJson()).toList(),
            },
            decode: (payload) =>
                _decodeList(payload, StoredReceiptDraft.fromJson),
          );
      final notifications =
          await SqliteDomainSnapshotStore.open<NotificationSnapshotData>(
            database: database,
            organizationId: expenseUiLabOrganizationId,
            domain: 'notifications',
            collections: const [
              DomainCollection(
                name: 'events',
                idField: 'notificationId',
                ownerField: 'recipientEmployeeId',
              ),
              DomainCollection(
                name: 'deliveries',
                idField: 'deliveryId',
                ownerField: 'recipientEmployeeId',
              ),
            ],
            encode: (snapshot) => snapshot.toJson(),
            decode: NotificationSnapshotData.fromJson,
          );
      await installation.markEstablished();
      return LocalPersistence._(
        database: database,
        expenses: LocalExpenseRepository.withStorage(expenses),
        recurringExpenses: LocalRecurringExpenseRepository.withStorage(
          recurring,
        ),
        receiptDrafts: LocalReceiptDraftRepository.withStorage(
          receipts,
          Directory.fromUri(root.uri.resolve('receipt_evidence/')),
          resolveRetainedPath: resolveRetainedPath,
        ),
        notifications: LocalNotificationRepository.withStorage(notifications),
      );
    } on Object {
      await database.close();
      rethrow;
    }
  }

  /// Call after pausing application command sources. Match the existing atomic
  /// submission lock order so an admitted cross-domain command can finish.
  Future<AsyncActionPause> pauseOperations() => pauseOperationSources([
    expenses.pauseOperations,
    recurringExpenses.pauseOperations,
    receiptDrafts.pauseOperations,
    notifications.pauseOperations,
  ]);

  Future<void> close() => database.close();

  /// Fixture bootstrap is a single transaction and runs once, including when
  /// the user later removes every demo record. Old JSON fixtures are untouched.
  Future<void> seedDemoIfNew() async {
    if (!expenseUiLabDemoDataEnabled) return;
    await database.transaction(() async {
      final seeded =
          await (database.select(database.localMetadata)
                ..where((row) => row.metadataKey.equals('ui-lab-demo-seed')))
              .getSingleOrNull();
      if (seeded != null) return;
      await seedExpenseUiLabDemoDataIfEmpty(expenses);
      await seedRecurringExpenseUiLabDemoDataIfEmpty(recurringExpenses);
      await seedReceiptDraftUiLabDemoDataIfEmpty(receiptDrafts);
      await database
          .into(database.localMetadata)
          .insert(
            LocalMetadataCompanion.insert(
              metadataKey: 'ui-lab-demo-seed',
              value: '1',
            ),
          );
    });
  }
}

List<T> _decodeList<T>(
  Map<String, Object?> payload,
  T Function(Map<String, Object?>) decode,
) {
  final values = payload['records'];
  if (values is! List) {
    throw const FormatException('Invalid stored record list.');
  }
  return List.unmodifiable(
    values.map((item) => decode((item as Map).cast<String, Object?>())),
  );
}
