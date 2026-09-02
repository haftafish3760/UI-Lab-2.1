import 'receipt_draft_record.dart';
import 'receipt_draft_repository.dart';

class ReceiptDraftCommandPermissions {
  ReceiptDraftCommandPermissions({
    required this.organizationId,
    required this.actorEmployeeId,
    required this.permissionRevision,
    required this.readScope,
    this.teamEmployeeIds = const {},
    this.canCreate = false,
    this.canEditOwn = false,
    this.canEditTeam = false,
    this.canSubmitOwn = false,
    this.canSubmitTeam = false,
    this.canDiscardOwn = false,
    this.canDiscardTeam = false,
  });

  final String organizationId;
  final String actorEmployeeId;
  final String permissionRevision;
  final ReceiptDraftReadScope? readScope;
  final Set<String> teamEmployeeIds;
  final bool canCreate;
  final bool canEditOwn;
  final bool canEditTeam;
  final bool canSubmitOwn;
  final bool canSubmitTeam;
  final bool canDiscardOwn;
  final bool canDiscardTeam;

  ReceiptDraftAccess? get readAccess => switch (readScope) {
    null => null,
    ReceiptDraftReadScope.own => ReceiptDraftAccess.own(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
    ),
    ReceiptDraftReadScope.team => ReceiptDraftAccess.team(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
      teamEmployeeIds: teamEmployeeIds,
    ),
    ReceiptDraftReadScope.company => ReceiptDraftAccess.company(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
    ),
  };

  bool owns(StoredReceiptDraft draft) =>
      draft.ownerEmployeeId == actorEmployeeId;

  bool canTarget(StoredReceiptDraft draft) {
    if (owns(draft)) return true;
    return switch (readScope) {
      ReceiptDraftReadScope.company => true,
      ReceiptDraftReadScope.team => teamEmployeeIds.contains(
        draft.ownerEmployeeId,
      ),
      ReceiptDraftReadScope.own || null => false,
    };
  }
}

class AuthorizedReceiptDraftService {
  const AuthorizedReceiptDraftService(this._repository);

  final ReceiptDraftRepository _repository;

  Future<List<StoredReceiptDraft>> query({
    required ReceiptDraftCommandPermissions permissions,
    String? ownerEmployeeId,
    bool includeClosed = false,
  }) async {
    final access = _requireReadAccess(permissions);
    return _repository.query(
      ReceiptDraftQuery(
        access: access,
        ownerEmployeeId: ownerEmployeeId,
        includeClosed: includeClosed,
      ),
    );
  }

  Future<StoredReceiptDraft?> find({
    required String draftId,
    required ReceiptDraftCommandPermissions permissions,
    bool includeClosed = false,
  }) async => _repository.find(
    draftId: draftId,
    access: _requireReadAccess(permissions),
    includeClosed: includeClosed,
  );

  Future<StoredReceiptDraft> create({
    required StoredReceiptDraft draft,
    required List<ReceiptEvidenceImport> evidence,
    required ReceiptDraftCommandPermissions permissions,
    required DateTime occurredAtUtc,
  }) async {
    _requireAction(permissions.canCreate, 'create receipt drafts');
    _requireOrganization(draft, permissions);
    if (draft.ownerEmployeeId != permissions.actorEmployeeId) {
      throw const ReceiptDraftPermissionDeniedException(
        'A new receipt draft must belong to the signed-in employee.',
      );
    }
    return _repository.create(
      draft: draft,
      evidence: evidence,
      context: _context(permissions, occurredAtUtc),
    );
  }

  Future<StoredReceiptDraft> update({
    required StoredReceiptDraft draft,
    required List<ReceiptEvidenceImport> addedEvidence,
    required int expectedRevision,
    required ReceiptDraftCommandPermissions permissions,
    required DateTime occurredAtUtc,
  }) async {
    final current = await _requireCurrent(draft.draftId, permissions);
    _requireAction(
      permissions.owns(current)
          ? permissions.canEditOwn
          : permissions.canEditTeam,
      'edit this receipt draft',
    );
    return _repository.update(
      draft: draft,
      addedEvidence: addedEvidence,
      expectedRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc),
    );
  }

  Future<StoredReceiptDraft> submit({
    required String draftId,
    required String expenseId,
    required int expectedRevision,
    required ReceiptDraftCommandPermissions permissions,
    required DateTime occurredAtUtc,
  }) async {
    final current = await _requireCurrent(draftId, permissions);
    _requireAction(
      permissions.owns(current)
          ? permissions.canSubmitOwn
          : permissions.canSubmitTeam,
      'submit this receipt draft',
    );
    return _repository.submit(
      draftId: draftId,
      expenseId: expenseId,
      expectedRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc),
    );
  }

  Future<StoredReceiptDraft> discard({
    required String draftId,
    required int expectedRevision,
    required ReceiptDraftCommandPermissions permissions,
    required DateTime occurredAtUtc,
  }) async {
    final current = await _requireCurrent(draftId, permissions);
    _requireAction(
      permissions.owns(current)
          ? permissions.canDiscardOwn
          : permissions.canDiscardTeam,
      'discard this receipt draft',
    );
    return _repository.discard(
      draftId: draftId,
      expectedRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc),
    );
  }

  Future<StoredReceiptDraft> _requireCurrent(
    String draftId,
    ReceiptDraftCommandPermissions permissions,
  ) async {
    final current = await _repository.find(
      draftId: draftId,
      access: ReceiptDraftAccess.company(
        organizationId: permissions.organizationId,
        employeeId: permissions.actorEmployeeId,
      ),
    );
    if (current == null) {
      throw const ReceiptDraftNotFoundException(
        'The receipt draft is no longer available.',
      );
    }
    if (!permissions.canTarget(current)) {
      throw const ReceiptDraftPermissionDeniedException(
        'This employee cannot change that receipt draft.',
      );
    }
    return current;
  }

  ReceiptDraftAccess _requireReadAccess(
    ReceiptDraftCommandPermissions permissions,
  ) {
    final access = permissions.readAccess;
    if (access == null) {
      throw const ReceiptDraftPermissionDeniedException(
        'This employee cannot view receipt drafts.',
      );
    }
    return access;
  }

  void _requireOrganization(
    StoredReceiptDraft draft,
    ReceiptDraftCommandPermissions permissions,
  ) {
    if (draft.organizationId != permissions.organizationId) {
      throw const ReceiptDraftPermissionDeniedException(
        'The receipt draft is outside this company.',
      );
    }
  }

  void _requireAction(bool allowed, String action) {
    if (!allowed) {
      throw ReceiptDraftPermissionDeniedException(
        'This employee cannot $action.',
      );
    }
  }

  ReceiptDraftMutationContext _context(
    ReceiptDraftCommandPermissions permissions,
    DateTime occurredAtUtc,
  ) => ReceiptDraftMutationContext(
    actorEmployeeId: permissions.actorEmployeeId,
    permissionRevision: permissions.permissionRevision,
    occurredAtUtc: occurredAtUtc,
  );
}
