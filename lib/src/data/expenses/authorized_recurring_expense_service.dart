import '../storage/local_draft_checkpoint.dart';
import 'expense_money.dart';
import 'recurring_expense_records.dart';
import 'recurring_expense_repository.dart';
import 'recurring_expense_terms.dart';

class RecurringExpenseCommandPermissions {
  RecurringExpenseCommandPermissions({
    required this.organizationId,
    required this.actorEmployeeId,
    required this.permissionRevision,
    required this.readScope,
    this.teamEmployeeIds = const {},
    this.canManage = false,
    this.canRecordPayment = false,
    this.canManageOtherEmployees = false,
  });

  final String organizationId;
  final String actorEmployeeId;
  final String permissionRevision;
  final RecurringExpenseReadScope? readScope;
  final Set<String> teamEmployeeIds;
  final bool canManage;
  final bool canRecordPayment;
  final bool canManageOtherEmployees;

  RecurringExpenseAccess? get readAccess => switch (readScope) {
    null => null,
    RecurringExpenseReadScope.own => RecurringExpenseAccess.own(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
    ),
    RecurringExpenseReadScope.team => RecurringExpenseAccess.team(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
      teamEmployeeIds: teamEmployeeIds,
    ),
    RecurringExpenseReadScope.company => RecurringExpenseAccess.company(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
    ),
  };

  bool canTargetEmployee(String employeeId) {
    if (employeeId == actorEmployeeId) return true;
    if (!canManageOtherEmployees) return false;
    return switch (readScope) {
      RecurringExpenseReadScope.company => true,
      RecurringExpenseReadScope.team => teamEmployeeIds.contains(employeeId),
      RecurringExpenseReadScope.own || null => false,
    };
  }
}

class AuthorizedRecurringExpenseService {
  const AuthorizedRecurringExpenseService(this._repository);

  final RecurringExpenseRepository _repository;

  Future<StoredRecurringExpenseTemplate?> readCurrentTemplate(
    String id,
    RecurringExpenseCommandPermissions permissions,
  ) async => _repository.findTemplate(
    templateId: id,
    access: _requireReadAccess(permissions),
  );

  Future<StoredRecurringExpenseOccurrence?> readCurrentOccurrence(
    String id,
    RecurringExpenseCommandPermissions permissions,
  ) async => _repository.findOccurrence(
    occurrenceId: id,
    access: _requireReadAccess(permissions),
  );

  Future<List<StoredRecurringExpenseTemplate>> queryTemplates({
    required RecurringExpenseCommandPermissions permissions,
    DateTime? fromInclusive,
    DateTime? toExclusive,
    String? categoryId,
    String? jobId,
    String? vehicleId,
    RecurringExpenseState? state,
  }) async => _repository.queryTemplates(
    RecurringExpenseTemplateQuery(
      access: _requireReadAccess(permissions),
      fromInclusive: fromInclusive,
      toExclusive: toExclusive,
      categoryId: categoryId,
      jobId: jobId,
      vehicleId: vehicleId,
      state: state,
    ),
  );

  Future<List<StoredRecurringExpenseOccurrence>> queryOccurrences({
    required RecurringExpenseCommandPermissions permissions,
    String? templateId,
    DateTime? fromInclusive,
    DateTime? toExclusive,
    RecurringExpenseOccurrenceState? state,
  }) async => _repository.queryOccurrences(
    RecurringExpenseOccurrenceQuery(
      access: _requireReadAccess(permissions),
      templateId: templateId,
      fromInclusive: fromInclusive,
      toExclusive: toExclusive,
      state: state,
    ),
  );

  Future<RecurringExpenseMutationResult> createTemplate({
    required StoredRecurringExpenseTemplate template,
    required StoredRecurringExpenseOccurrence initialOccurrence,
    required RecurringExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    _requireAction(permissions.canManage, 'set up planned expenses');
    if (template.organizationId != permissions.organizationId ||
        initialOccurrence.organizationId != permissions.organizationId) {
      throw const RecurringExpensePermissionDeniedException(
        'The planned expense is outside this company.',
      );
    }
    if (template.createdByEmployeeId != permissions.actorEmployeeId) {
      throw const RecurringExpensePermissionDeniedException(
        'The creator must match the signed-in employee.',
      );
    }
    _requireTarget(template.assignedEmployeeId, permissions);
    _requireTarget(initialOccurrence.assignedEmployeeId, permissions);
    return _repository.createTemplate(
      template: template,
      initialOccurrence: initialOccurrence,
      context: _context(permissions, occurredAtUtc, note, draftCheckpoint),
    );
  }

  Future<RecurringExpenseMutationResult> updateTemplate({
    required StoredRecurringExpenseTemplate template,
    required int expectedRevision,
    required RecurringExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
    LocalDraftCheckpoint? draftCheckpoint,
  }) async {
    _requireAction(permissions.canManage, 'edit planned expenses');
    _requireTarget(
      (await _requireTemplate(
        template.templateId,
        permissions,
      )).assignedEmployeeId,
      permissions,
    );
    _requireTarget(template.assignedEmployeeId, permissions);
    return _repository.updateTemplateAndOpenOccurrence(
      template: template,
      expectedTemplateRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc, note, draftCheckpoint),
    );
  }

  Future<RecurringExpenseMutationResult> updateOccurrence({
    required String templateId,
    required StoredRecurringExpenseOccurrence occurrence,
    required int expectedTemplateRevision,
    required int expectedRevision,
    required RecurringExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
    LocalDraftCheckpoint? draftCheckpoint,
  }) async {
    _requireAction(permissions.canManage, 'edit planned payments');
    final template = await _requireTemplate(templateId, permissions);
    final current = await _requireOccurrence(
      occurrence.occurrenceId,
      permissions,
    );
    if (current.templateId != template.templateId ||
        occurrence.templateId != template.templateId) {
      throw const RecurringExpenseNotFoundException(
        'The planned payment does not belong to that recurring expense.',
      );
    }
    _requireTarget(template.assignedEmployeeId, permissions);
    _requireTarget(current.assignedEmployeeId, permissions);
    _requireTarget(occurrence.assignedEmployeeId, permissions);
    return _repository.updateOpenOccurrence(
      templateId: templateId,
      occurrence: occurrence,
      expectedTemplateRevision: expectedTemplateRevision,
      expectedRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc, note, draftCheckpoint),
    );
  }

  Future<StoredRecurringExpenseTemplate> setTemplateState({
    required String templateId,
    required RecurringExpenseState state,
    required int expectedRevision,
    required RecurringExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
  }) async {
    _requireAction(permissions.canManage, 'change planned expenses');
    final current = await _requireTemplate(templateId, permissions);
    _requireTarget(current.assignedEmployeeId, permissions);
    return _repository.setTemplateState(
      templateId: templateId,
      state: state,
      expectedRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc, note),
    );
  }

  Future<RecurringExpenseMutationResult> skipOccurrence({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required RecurringExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
  }) async {
    _requireAction(permissions.canManage, 'skip planned payments');
    await _requireMatchingTarget(templateId, occurrenceId, permissions);
    return _repository.skipOccurrence(
      templateId: templateId,
      occurrenceId: occurrenceId,
      expectedTemplateRevision: expectedTemplateRevision,
      expectedOccurrenceRevision: expectedOccurrenceRevision,
      context: _context(permissions, occurredAtUtc, note),
    );
  }

  /// Records the durable link after the ordinary Expense command succeeds.
  Future<RecurringExpenseMutationResult> recordPaidOccurrence({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required ExpenseMoney actualAmount,
    required DateTime paidOn,
    required String expenseId,
    required RecurringExpenseCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
  }) async {
    _requireAction(permissions.canRecordPayment, 'record planned payments');
    await _requireMatchingTarget(templateId, occurrenceId, permissions);
    return _repository.recordPaidOccurrence(
      templateId: templateId,
      occurrenceId: occurrenceId,
      expectedTemplateRevision: expectedTemplateRevision,
      expectedOccurrenceRevision: expectedOccurrenceRevision,
      actualAmount: actualAmount,
      paidOn: paidOn,
      expenseId: expenseId,
      context: _context(permissions, occurredAtUtc, note),
    );
  }

  Future<void> _requireMatchingTarget(
    String templateId,
    String occurrenceId,
    RecurringExpenseCommandPermissions permissions,
  ) async {
    final template = await _requireTemplate(templateId, permissions);
    final occurrence = await _requireOccurrence(occurrenceId, permissions);
    if (occurrence.templateId != template.templateId) {
      throw const RecurringExpenseNotFoundException(
        'The planned payment does not belong to that recurring expense.',
      );
    }
    _requireTarget(template.assignedEmployeeId, permissions);
    _requireTarget(occurrence.assignedEmployeeId, permissions);
  }

  Future<StoredRecurringExpenseTemplate> _requireTemplate(
    String templateId,
    RecurringExpenseCommandPermissions permissions,
  ) async {
    final record = await _repository.findTemplate(
      templateId: templateId,
      access: _companyAccess(permissions),
    );
    if (record == null) {
      throw const RecurringExpenseNotFoundException(
        'Recurring expense does not exist.',
      );
    }
    return record;
  }

  Future<StoredRecurringExpenseOccurrence> _requireOccurrence(
    String occurrenceId,
    RecurringExpenseCommandPermissions permissions,
  ) async {
    final record = await _repository.findOccurrence(
      occurrenceId: occurrenceId,
      access: _companyAccess(permissions),
    );
    if (record == null) {
      throw const RecurringExpenseNotFoundException(
        'Recurring payment does not exist.',
      );
    }
    return record;
  }

  RecurringExpenseAccess _requireReadAccess(
    RecurringExpenseCommandPermissions permissions,
  ) {
    final access = permissions.readAccess;
    if (access == null) {
      throw const RecurringExpensePermissionDeniedException(
        'This employee cannot view planned expenses.',
      );
    }
    return access;
  }

  RecurringExpenseAccess _companyAccess(
    RecurringExpenseCommandPermissions permissions,
  ) => RecurringExpenseAccess.company(
    organizationId: permissions.organizationId,
    employeeId: permissions.actorEmployeeId,
  );

  void _requireTarget(
    String employeeId,
    RecurringExpenseCommandPermissions permissions,
  ) {
    if (!permissions.canTargetEmployee(employeeId)) {
      throw const RecurringExpensePermissionDeniedException(
        'This employee cannot change that planned expense.',
      );
    }
  }

  void _requireAction(bool allowed, String action) {
    if (!allowed) {
      throw RecurringExpensePermissionDeniedException(
        'This employee cannot $action.',
      );
    }
  }

  RecurringExpenseMutationContext _context(
    RecurringExpenseCommandPermissions permissions,
    DateTime occurredAtUtc,
    String? note, [
    LocalDraftCheckpoint? draftCheckpoint,
  ]) {
    final repository = _repository;
    if (draftCheckpoint != null &&
        (repository is! RecurringExpenseDraftConfirmationRepository ||
            !repository.supportsDraftConfirmation)) {
      throw const RecurringExpenseStorageException(
        'This storage cannot safely confirm a saved draft.',
      );
    }
    return RecurringExpenseMutationContext(
      actorEmployeeId: permissions.actorEmployeeId,
      occurredAtUtc: occurredAtUtc,
      permissionRevision: permissions.permissionRevision,
      note: note,
      draftCheckpoint: draftCheckpoint,
    );
  }
}
