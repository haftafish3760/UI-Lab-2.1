import 'dart:io';

import '../storage/dual_slot_json_store.dart';
import '../storage/domain_snapshot_store.dart';
import '../storage/serialized_async_actions.dart';
import '../storage/sqlite_domain_snapshot_store.dart';
import '../storage/staged_domain_mutation.dart';
import 'expense_record.dart';
import 'recurring_expense_records.dart';
import 'recurring_expense_repository.dart';
import 'recurring_expense_repository_guards.dart';
import 'recurring_expense_snapshot_codec.dart';
import 'recurring_expense_terms.dart';
import 'recurring_expense_transitions.dart';

part 'local_recurring_expense_persistence.dart';
part 'local_recurring_expense_completion.dart';
part 'recurring_expense_submission_staging.dart';

typedef RecurringExpenseSnapshotWriter = DualSlotSnapshotWriter;

class LocalRecurringExpenseRepository
    implements
        RecurringExpenseRepository,
        RecurringExpenseDraftConfirmationRepository {
  LocalRecurringExpenseRepository._({
    required this._snapshotStore,
    required this._templates,
    required this._occurrences,
  });

  factory LocalRecurringExpenseRepository.withStorage(
    DomainSnapshotStore<RecurringExpenseSnapshotData> storage,
  ) => LocalRecurringExpenseRepository._(
    snapshotStore: storage,
    templates: {
      for (final item in storage.value.templates) item.templateId: item,
    },
    occurrences: {
      for (final item in storage.value.occurrences) item.occurrenceId: item,
    },
  );

  static const int schemaVersion = 1;
  static const String directoryName = 'recurring_expense_records';

  final DomainSnapshotStore<RecurringExpenseSnapshotData> _snapshotStore;
  Map<String, StoredRecurringExpenseTemplate> _templates;
  Map<String, StoredRecurringExpenseOccurrence> _occurrences;
  final _writes = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _writes.pauseAndDrain();

  @override
  bool get supportsDraftConfirmation =>
      _snapshotStore
          is DraftConfirmingDomainSnapshotStore<RecurringExpenseSnapshotData>;

  bool get recoveredFromDamagedSnapshot =>
      _snapshotStore.recoveredFromDamagedSnapshot;

  static Future<LocalRecurringExpenseRepository> open(
    Directory storageDirectory, {
    RecurringExpenseSnapshotWriter? snapshotWriter,
  }) async {
    try {
      final store = await DualSlotJsonStore.open<RecurringExpenseSnapshotData>(
        directory: storageDirectory,
        fileStem: 'recurring-expenses',
        schemaVersion: schemaVersion,
        emptyValue: const RecurringExpenseSnapshotData.empty(),
        encodePayload: (snapshot) => snapshot.toJson(),
        decodePayload: RecurringExpenseSnapshotData.fromJson,
        snapshotWriter: snapshotWriter,
      );
      return LocalRecurringExpenseRepository._(
        snapshotStore: store,
        templates: {
          for (final item in store.value.templates) item.templateId: item,
        },
        occurrences: {
          for (final item in store.value.occurrences) item.occurrenceId: item,
        },
      );
    } on DualSlotSnapshotCorruptionException catch (error) {
      throw RecurringExpenseStorageCorruptionException(error.message);
    }
  }

  @override
  Future<List<StoredRecurringExpenseTemplate>> queryTemplates(
    RecurringExpenseTemplateQuery query,
  ) async {
    final records = _templates.values.where(query.matches).toList()
      ..sort(compareRecurringTemplatesByDueDate);
    return List.unmodifiable(records);
  }

  @override
  Future<StoredRecurringExpenseTemplate?> findTemplate({
    required String templateId,
    required RecurringExpenseAccess access,
  }) async {
    final record = _templates[templateId];
    return record != null && access.allowsTemplate(record) ? record : null;
  }

  @override
  Future<List<StoredRecurringExpenseOccurrence>> queryOccurrences(
    RecurringExpenseOccurrenceQuery query,
  ) async {
    final records = _occurrences.values.where(query.matches).toList()
      ..sort(compareRecurringOccurrencesByDueDate);
    return List.unmodifiable(records);
  }

  @override
  Future<StoredRecurringExpenseOccurrence?> findOccurrence({
    required String occurrenceId,
    required RecurringExpenseAccess access,
  }) async {
    final record = _occurrences[occurrenceId];
    return record != null && access.allowsOccurrence(record) ? record : null;
  }

  @override
  Future<RecurringExpenseMutationResult> createTemplate({
    required StoredRecurringExpenseTemplate template,
    required StoredRecurringExpenseOccurrence initialOccurrence,
    required RecurringExpenseMutationContext context,
  }) => _writes.run(() async {
    if (_templates.containsKey(template.templateId)) {
      throw RecurringExpenseAlreadyExistsException(
        'Recurring expense ${template.templateId} already exists.',
      );
    }
    if (_occurrences.containsKey(initialOccurrence.occurrenceId)) {
      throw RecurringExpenseAlreadyExistsException(
        'Payment ${initialOccurrence.occurrenceId} already exists.',
      );
    }
    validateInitialRecurringOccurrence(template, initialOccurrence);
    final createdTemplate = template.copyWith(
      lifecycle: RecurringExpenseLifecycle(
        revision: 1,
        createdAtUtc: context.occurredAtUtc,
        updatedAtUtc: context.occurredAtUtc,
      ),
      auditTrail: [
        context.auditEvent(
          action: RecurringExpenseAuditAction.templateCreated,
          fromRevision: null,
          toRevision: 1,
        ),
      ],
    );
    final createdOccurrence = initialOccurrence.copyWith(
      lifecycle: RecurringExpenseLifecycle(
        revision: 1,
        createdAtUtc: context.occurredAtUtc,
        updatedAtUtc: context.occurredAtUtc,
      ),
      auditTrail: [
        context.auditEvent(
          action: RecurringExpenseAuditAction.occurrenceCreated,
          fromRevision: null,
          toRevision: 1,
        ),
      ],
    );
    await _persist(
      {..._templates, createdTemplate.templateId: createdTemplate},
      {..._occurrences, createdOccurrence.occurrenceId: createdOccurrence},
      context: context,
      organizationId: template.organizationId,
    );
    return RecurringExpenseMutationResult(
      template: createdTemplate,
      occurrence: createdOccurrence,
    );
  });

  @override
  Future<RecurringExpenseMutationResult> updateTemplateAndOpenOccurrence({
    required StoredRecurringExpenseTemplate template,
    required int expectedTemplateRevision,
    required RecurringExpenseMutationContext context,
  }) => _writes.run(() async {
    final current = requireRecurringTemplate(
      _templates,
      template.templateId,
      expectedTemplateRevision,
    );
    requireRecurringTemplateIdentity(current, template);
    if (current.state == RecurringExpenseState.ended) {
      throw const RecurringExpenseInvalidTransitionException(
        'An ended recurring expense cannot be edited.',
      );
    }
    final open = requireOpenRecurringOccurrence(
      _occurrences.values,
      template.templateId,
    );
    ensureRecurringOccurrenceDateAvailable(
      _occurrences.values,
      template.templateId,
      open.occurrenceId,
      template.nextDueOn,
    );
    final updatedTemplate = template.copyWith(
      lifecycle: current.lifecycle.nextRevision(context.occurredAtUtc),
      auditTrail: [
        ...current.auditTrail,
        context.auditEvent(
          action: RecurringExpenseAuditAction.templateUpdated,
          fromRevision: current.lifecycle.revision,
          toRevision: current.lifecycle.revision + 1,
        ),
      ],
    );
    final updatedOccurrence = open.copyWith(
      assignedEmployeeId: template.assignedEmployeeId,
      dueOn: template.nextDueOn,
      expectedAmount: template.expectedAmount,
      lifecycle: open.lifecycle.nextRevision(context.occurredAtUtc),
      auditTrail: [
        ...open.auditTrail,
        context.auditEvent(
          action: RecurringExpenseAuditAction.occurrenceUpdated,
          fromRevision: open.lifecycle.revision,
          toRevision: open.lifecycle.revision + 1,
        ),
      ],
    );
    await _persist(
      {..._templates, template.templateId: updatedTemplate},
      {..._occurrences, open.occurrenceId: updatedOccurrence},
      context: context,
      organizationId: template.organizationId,
    );
    return RecurringExpenseMutationResult(
      template: updatedTemplate,
      occurrence: updatedOccurrence,
    );
  });

  @override
  Future<RecurringExpenseMutationResult> updateOpenOccurrence({
    required String templateId,
    required StoredRecurringExpenseOccurrence occurrence,
    required int expectedTemplateRevision,
    required int expectedRevision,
    required RecurringExpenseMutationContext context,
  }) => _writes.run(() async {
    final template = requireRecurringTemplate(
      _templates,
      templateId,
      expectedTemplateRevision,
    );
    final current = requireRecurringOccurrence(
      _occurrences,
      occurrence.occurrenceId,
      expectedRevision,
    );
    if (!current.isOpen) {
      throw const RecurringExpenseInvalidTransitionException(
        'Only an unpaid occurrence can be edited.',
      );
    }
    if (current.templateId != template.templateId ||
        occurrence.templateId != current.templateId ||
        occurrence.organizationId != current.organizationId ||
        occurrence.assignedEmployeeId != current.assignedEmployeeId ||
        occurrence.state != RecurringExpenseOccurrenceState.due) {
      throw const RecurringExpenseRevisionConflictException(
        'Occurrence identity, owner, and state cannot be rewritten.',
      );
    }
    ensureRecurringOccurrenceDateAvailable(
      _occurrences.values,
      current.templateId,
      current.occurrenceId,
      occurrence.dueOn,
    );
    final updated = occurrence.copyWith(
      lifecycle: current.lifecycle.nextRevision(context.occurredAtUtc),
      auditTrail: [
        ...current.auditTrail,
        context.auditEvent(
          action: RecurringExpenseAuditAction.occurrenceUpdated,
          fromRevision: current.lifecycle.revision,
          toRevision: current.lifecycle.revision + 1,
        ),
      ],
    );
    final updatedTemplate = template.copyWith(
      nextDueOn: occurrence.dueOn,
      lifecycle: template.lifecycle.nextRevision(context.occurredAtUtc),
      auditTrail: [
        ...template.auditTrail,
        context.auditEvent(
          action: RecurringExpenseAuditAction.templateUpdated,
          fromRevision: template.lifecycle.revision,
          toRevision: template.lifecycle.revision + 1,
        ),
      ],
    );
    await _persist(
      {..._templates, templateId: updatedTemplate},
      {..._occurrences, current.occurrenceId: updated},
      context: context,
      organizationId: template.organizationId,
    );
    return RecurringExpenseMutationResult(
      template: updatedTemplate,
      occurrence: updated,
    );
  });

  @override
  Future<StoredRecurringExpenseTemplate> setTemplateState({
    required String templateId,
    required RecurringExpenseState state,
    required int expectedRevision,
    required RecurringExpenseMutationContext context,
  }) => _writes.run(() async {
    final current = requireRecurringTemplate(
      _templates,
      templateId,
      expectedRevision,
    );
    if (current.state == state) return current;
    if (current.state == RecurringExpenseState.ended) {
      throw const RecurringExpenseInvalidTransitionException(
        'An ended recurring expense cannot be resumed.',
      );
    }
    final action = switch (state) {
      RecurringExpenseState.active =>
        RecurringExpenseAuditAction.templateResumed,
      RecurringExpenseState.paused =>
        RecurringExpenseAuditAction.templatePaused,
      RecurringExpenseState.ended => RecurringExpenseAuditAction.templateEnded,
    };
    final updated = current.copyWith(
      state: state,
      lifecycle: current.lifecycle.nextRevision(context.occurredAtUtc),
      auditTrail: [
        ...current.auditTrail,
        context.auditEvent(
          action: action,
          fromRevision: current.lifecycle.revision,
          toRevision: current.lifecycle.revision + 1,
        ),
      ],
    );
    await _persist({..._templates, templateId: updated}, _occurrences);
    return updated;
  });

  @override
  Future<RecurringExpenseMutationResult> skipOccurrence({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required RecurringExpenseMutationContext context,
  }) => _completeOccurrence(
    templateId: templateId,
    occurrenceId: occurrenceId,
    expectedTemplateRevision: expectedTemplateRevision,
    expectedOccurrenceRevision: expectedOccurrenceRevision,
    action: RecurringExpenseAuditAction.occurrenceSkipped,
    context: context,
  );

  @override
  Future<RecurringExpenseMutationResult> recordPaidOccurrence({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required ExpenseMoney actualAmount,
    required DateTime paidOn,
    required String expenseId,
    required RecurringExpenseMutationContext context,
  }) {
    if (actualAmount.minorUnits <= 0) {
      throw const RecurringExpenseInvalidTransitionException(
        'The paid amount must be above zero.',
      );
    }
    requireRecurringNonEmpty(expenseId, 'expenseId');
    return _completeOccurrence(
      templateId: templateId,
      occurrenceId: occurrenceId,
      expectedTemplateRevision: expectedTemplateRevision,
      expectedOccurrenceRevision: expectedOccurrenceRevision,
      action: RecurringExpenseAuditAction.occurrencePaid,
      context: context,
      actualAmount: actualAmount,
      paidOn: paidOn,
      expenseId: expenseId,
    );
  }
}
