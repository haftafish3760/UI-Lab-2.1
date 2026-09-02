import 'receipt_draft_record.dart';

enum ReceiptDraftReadScope { own, team, company }

class ReceiptDraftAccess {
  ReceiptDraftAccess.own({
    required this.organizationId,
    required this.employeeId,
  }) : scope = ReceiptDraftReadScope.own,
       visibleEmployeeIds = {employeeId};

  ReceiptDraftAccess.team({
    required this.organizationId,
    required this.employeeId,
    required Set<String> teamEmployeeIds,
  }) : scope = ReceiptDraftReadScope.team,
       visibleEmployeeIds = {...teamEmployeeIds, employeeId};

  ReceiptDraftAccess.company({
    required this.organizationId,
    required this.employeeId,
  }) : scope = ReceiptDraftReadScope.company,
       visibleEmployeeIds = const {};

  final String organizationId;
  final String employeeId;
  final ReceiptDraftReadScope scope;
  final Set<String> visibleEmployeeIds;

  bool allows(StoredReceiptDraft draft) =>
      draft.organizationId == organizationId &&
      (scope == ReceiptDraftReadScope.company ||
          visibleEmployeeIds.contains(draft.ownerEmployeeId));
}

class ReceiptDraftQuery {
  const ReceiptDraftQuery({
    required this.access,
    this.ownerEmployeeId,
    this.includeClosed = false,
  });

  final ReceiptDraftAccess access;
  final String? ownerEmployeeId;
  final bool includeClosed;

  bool matches(StoredReceiptDraft draft) =>
      access.allows(draft) &&
      (includeClosed || draft.state == ReceiptDraftState.inProgress) &&
      (ownerEmployeeId == null || draft.ownerEmployeeId == ownerEmployeeId);
}

class ReceiptEvidenceImport {
  const ReceiptEvidenceImport({
    required this.sourcePath,
    required this.originalName,
    required this.kind,
  });

  final String sourcePath;
  final String originalName;
  final ReceiptDraftEvidenceKind kind;
}

class ReceiptDraftMutationContext {
  ReceiptDraftMutationContext({
    required this.actorEmployeeId,
    required this.permissionRevision,
    required DateTime occurredAtUtc,
  }) : occurredAtUtc = occurredAtUtc.toUtc();

  final String actorEmployeeId;
  final String permissionRevision;
  final DateTime occurredAtUtc;

  ReceiptDraftAuditEvent audit({
    required ReceiptDraftAuditAction action,
    required int? fromRevision,
    required int toRevision,
  }) => ReceiptDraftAuditEvent(
    action: action,
    actorEmployeeId: actorEmployeeId,
    permissionRevision: permissionRevision,
    occurredAtUtc: occurredAtUtc,
    fromRevision: fromRevision,
    toRevision: toRevision,
  );
}

abstract interface class ReceiptDraftRepository {
  Future<List<StoredReceiptDraft>> query(ReceiptDraftQuery query);

  Future<StoredReceiptDraft?> find({
    required String draftId,
    required ReceiptDraftAccess access,
    bool includeClosed = false,
  });

  Future<StoredReceiptDraft> create({
    required StoredReceiptDraft draft,
    required List<ReceiptEvidenceImport> evidence,
    required ReceiptDraftMutationContext context,
  });

  Future<StoredReceiptDraft> update({
    required StoredReceiptDraft draft,
    required List<ReceiptEvidenceImport> addedEvidence,
    required int expectedRevision,
    required ReceiptDraftMutationContext context,
  });

  Future<StoredReceiptDraft> submit({
    required String draftId,
    required String expenseId,
    required int expectedRevision,
    required ReceiptDraftMutationContext context,
  });

  Future<StoredReceiptDraft> discard({
    required String draftId,
    required int expectedRevision,
    required ReceiptDraftMutationContext context,
  });
}

sealed class ReceiptDraftRepositoryException implements Exception {
  const ReceiptDraftRepositoryException(this.message);
  final String message;
  @override
  String toString() => '$runtimeType: $message';
}

class ReceiptDraftNotFoundException extends ReceiptDraftRepositoryException {
  const ReceiptDraftNotFoundException(super.message);
}

class ReceiptDraftAlreadyExistsException
    extends ReceiptDraftRepositoryException {
  const ReceiptDraftAlreadyExistsException(super.message);
}

class ReceiptDraftRevisionConflictException
    extends ReceiptDraftRepositoryException {
  const ReceiptDraftRevisionConflictException(super.message);
}

class ReceiptDraftStorageException extends ReceiptDraftRepositoryException {
  const ReceiptDraftStorageException(super.message);
}

class ReceiptDraftStorageCorruptionException
    extends ReceiptDraftRepositoryException {
  const ReceiptDraftStorageCorruptionException(super.message);
}

class ReceiptDraftPermissionDeniedException
    extends ReceiptDraftRepositoryException {
  const ReceiptDraftPermissionDeniedException(super.message);
}
