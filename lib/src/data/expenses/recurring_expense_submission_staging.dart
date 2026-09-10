part of 'local_recurring_expense_repository.dart';

extension RecurringExpenseSubmissionStaging on LocalRecurringExpenseRepository {
  /// Acquire Expense before Recurring when composing a payment command.
  Future<R> withStagedWrites<R>(
    Future<R> Function(StagedDomainMutation<LocalRecurringExpenseRepository>)
    action,
  ) => _writes.run(() async {
    final storage = _snapshotStore;
    if (storage is! SqliteDomainSnapshotStore<RecurringExpenseSnapshotData>) {
      throw const RecurringExpenseStorageException(
        'Atomic payment requires SQLite storage.',
      );
    }
    final buffer = DomainMutationBuffer(storage.value);
    return action(
      StagedDomainMutation(
        repository: LocalRecurringExpenseRepository.withStorage(buffer),
        prepare: () => storage.prepare(buffer.value),
        publishCommitted: () {
          _templates = {
            for (final record in storage.value.templates)
              record.templateId: record,
          };
          _occurrences = {
            for (final record in storage.value.occurrences)
              record.occurrenceId: record,
          };
        },
      ),
    );
  });
}
