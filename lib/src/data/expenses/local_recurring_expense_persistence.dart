part of 'local_recurring_expense_repository.dart';

// Shared aggregate persistence: templates and occurrences commit together.
extension _RecurringExpensePersistence on LocalRecurringExpenseRepository {
  Future<void> _persist(
    Map<String, StoredRecurringExpenseTemplate> templates,
    Map<String, StoredRecurringExpenseOccurrence> occurrences, {
    RecurringExpenseMutationContext? context,
    String? organizationId,
  }) async {
    final snapshot = RecurringExpenseSnapshotData(
      templates: templates.values.toList()..sort(compareRecurringTemplateIds),
      occurrences: occurrences.values.toList()
        ..sort(compareRecurringOccurrenceIds),
    );
    try {
      final checkpoint = context?.draftCheckpoint;
      final storage = _snapshotStore;
      if (checkpoint == null) {
        await storage.persist(snapshot);
      } else if (storage
              is DraftConfirmingDomainSnapshotStore<
                RecurringExpenseSnapshotData
              > &&
          organizationId != null) {
        await storage.persistWithDraft(
          snapshot,
          organizationId: organizationId,
          ownerId: context!.actorEmployeeId,
          checkpoint: checkpoint,
        );
      } else {
        throw const RecurringExpenseStorageException(
          'This storage cannot safely confirm a saved draft.',
        );
      }
    } on DualSlotSnapshotWriteException catch (error) {
      throw RecurringExpenseStorageException(error.message);
    }
    _templates = templates;
    _occurrences = occurrences;
  }
}
