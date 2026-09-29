import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/local_record_command.dart';
import 'estimate_draft_controller.dart';
import 'estimate_draft_workflow.dart';
import 'invoice_draft_controller.dart';
import 'invoice_draft_workflow.dart';
import 'job_draft_controller.dart';
import 'job_draft_workflow.dart';
import 'models/work_models.dart';
import 'models/estimate_models.dart';
import 'work_persistence_session.dart';

sealed class ResumedWorkDraft {
  const ResumedWorkDraft();
}

class ResumedEstimateDraft extends ResumedWorkDraft {
  const ResumedEstimateDraft(this.controller);
  final EstimateDraftController controller;
}

class ResumedQuoteDraft extends ResumedWorkDraft {
  const ResumedQuoteDraft(this.controller);
  final EstimateDraftController controller;
}

class ResumedInvoiceDraft extends ResumedWorkDraft {
  const ResumedInvoiceDraft(this.controller);
  final InvoiceDraftController controller;
}

class ResumedJobDraft extends ResumedWorkDraft {
  const ResumedJobDraft(this.controller);
  final JobDraftController controller;
}

/// Registers primary Work editors without introducing navigation/widget keys.
/// Sub-workflows (signature, delivery, assignment, etc.) register separately.
class WorkPrimaryDraftRecovery {
  WorkPrimaryDraftRecovery(this._work) {
    _catalog = DraftRecoveryCatalog(
      repository: _work.drafts,
      organizationId: _work.permissions.organizationId,
      ownerId: _work.permissions.actorEmployeeId,
      handlers: handlers,
    );
  }
  final WorkPersistenceSession _work;
  late final DraftRecoveryCatalog _catalog;
  static const _kinds = {
    'work/estimate-editor': WorkRecordKind.estimate,
    'work/quote-editor': WorkRecordKind.quote,
    'work/invoice-editor': WorkRecordKind.invoice,
    'work/job-editor': WorkRecordKind.job,
  };
  Iterable<DraftRecoveryHandler> get handlers => _kinds.entries.map(
    (entry) => DraftRecoveryHandler(
      domain: entry.key,
      workflowLabel: switch (entry.value) {
        WorkRecordKind.estimate => 'Estimate',
        WorkRecordKind.quote => 'Quote',
        WorkRecordKind.invoice => 'Invoice',
        WorkRecordKind.job => 'Job',
      },
      canList: () => _canList(entry.value),
      inspect: (input) => _inspect(entry.value, input),
      // Only this actor's retained drafts reach the catalog. Record-level denial
      // hides decoded entries before any discard action can be selected.
      canDiscard: (_) async => _canList(entry.value),
    ),
  );
  bool _canList(WorkRecordKind kind) {
    final p = _work.permissions;
    return p.editableKinds.contains(kind) &&
        (p.visibleCreatorIds.contains(p.actorEmployeeId) ||
            (kind != WorkRecordKind.job &&
                p.canManageOtherCreators &&
                p.visibleCreatorIds.isNotEmpty));
  }

  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);

  Future<DraftRecoveryPreview?> _inspect(
    WorkRecordKind kind,
    Map<String, Object?> raw,
  ) async {
    late String title;
    late String creator;
    late String recordId;
    String? parentId;
    late int revision;
    var parentKind = kind;
    try {
      switch (kind) {
        case WorkRecordKind.quote:
        case WorkRecordKind.estimate:
          final input = EstimateDraftInput.fromPayload(raw);
          if (input.documentKind != kind) {
            throw StateError(
              'Saved document type does not match this workflow.',
            );
          }
          title = input.title.trim().isNotEmpty
              ? input.title
              : (input.client ?? '');
          creator = input.creatorId;
          recordId = input.estimateId;
          parentId = input.baseRecord?.id;
          revision = input.baseStorageRevision;
          if (input.baseRecord != null &&
              (input.baseRecord!.kind != kind ||
                  input.baseRecord!.id != recordId ||
                  input.baseRecord!.createdByEmployeeId != creator)) {
            throw StateError('Estimate base identity is inconsistent.');
          }
        case WorkRecordKind.invoice:
          final input = InvoiceDraftInput.fromPayload(raw);
          title = input.title.trim().isNotEmpty
              ? input.title
              : (input.client ?? '');
          creator = input.creatorId;
          recordId = input.recordId;
          parentId = input.existingRecordId;
          revision = input.baseStorageRevision;
          if (parentId != null && parentId != recordId) {
            throw StateError('Invoice identity is inconsistent.');
          }
        case WorkRecordKind.job:
          final input = JobDraftInput.fromPayload(raw);
          title = input.title.trim().isNotEmpty
              ? input.title
              : (input.client ?? '');
          creator =
              input.sourceEstimate?.createdByEmployeeId ??
              _work.permissions.actorEmployeeId;
          recordId = input.jobId;
          parentId = input.sourceEstimate?.id;
          revision = input.sourceStorageRevision;
          parentKind = input.sourceEstimate?.kind ?? WorkRecordKind.estimate;
          if (input.sourceEstimate != null &&
              !input.sourceEstimate!.isProposal) {
            throw StateError('Job source is inconsistent.');
          }
      }
      if (recordId.isEmpty ||
          (parentId == null ? revision != 0 : revision < 1)) {
        throw StateError('Draft identity or base revision is invalid.');
      }
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved Work input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    final permissions = _work.permissions;
    if (!permissions.visibleCreatorIds.contains(creator) ||
        (creator != permissions.actorEmployeeId &&
            !permissions.canManageOtherCreators)) {
      return null;
    }
    var availability = DraftRecoveryAvailability.recoverable;
    if (parentId != null) {
      final parent = await _work.repository.find(
        organizationId: permissions.organizationId,
        recordId: parentId,
        visibleCreatorIds: permissions.visibleCreatorIds,
      );
      if (parent == null || parent.record.kind != parentKind) {
        return DraftRecoveryPreview(
          title: 'Saved input — original record unavailable',
          availability: DraftRecoveryAvailability.parentUnavailable,
          recordId: recordId,
        );
      }
      if (!permissions.canEdit(parent.record)) return null;
      if (parent.storageRevision != revision) {
        availability = DraftRecoveryAvailability.conflict;
      } else if (kind == WorkRecordKind.job &&
          parent.record.resolvedEstimateStage != EstimateStage.approved) {
        availability = DraftRecoveryAvailability.parentUnavailable;
      }
    }
    if (parentId == null) {
      final existing = await _work.repository.find(
        organizationId: permissions.organizationId,
        recordId: recordId,
        visibleCreatorIds: permissions.visibleCreatorIds,
      );
      if (existing != null) availability = DraftRecoveryAvailability.conflict;
    }
    return DraftRecoveryPreview(
      title: title.trim().isEmpty ? 'Untitled ${kind.name}' : title,
      availability: availability,
      recordId: recordId,
    );
  }

  Future<ResumedWorkDraft> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError('This saved input requires review before resuming.');
    }
    final saved = await _work.drafts.find(
      organizationId: _work.permissions.organizationId,
      ownerId: _work.permissions.actorEmployeeId,
      domain: current.domain,
      draftId: current.draftId,
    );
    if (saved == null || saved.revision != current.revision) {
      throw const LocalRecordConflict(
        'Selected input changed; refresh recovery.',
      );
    }
    final raw = _work.drafts.decode(saved);
    final selection = DraftRecoverySelection(
      domain: current.domain,
      draftId: current.draftId,
      revision: current.revision,
    );
    switch (_kinds[current.domain]!) {
      case WorkRecordKind.quote:
      case WorkRecordKind.estimate:
        final input = EstimateDraftInput.fromPayload(raw);
        final controller = await _work.openEstimateDraft(
          documentKind: _kinds[current.domain]!,
          creatorId: input.creatorId,
          existingRecordId: input.baseRecord?.id,
          recoverySelection: selection,
        );
        return _kinds[current.domain] == WorkRecordKind.quote
            ? ResumedQuoteDraft(controller)
            : ResumedEstimateDraft(controller);
      case WorkRecordKind.invoice:
        final input = InvoiceDraftInput.fromPayload(raw);
        return ResumedInvoiceDraft(
          await _work.openInvoiceDraft(
            existingRecordId: input.existingRecordId,
            recoverySelection: selection,
          ),
        );
      case WorkRecordKind.job:
        final input = JobDraftInput.fromPayload(raw);
        return ResumedJobDraft(
          await _work.openJobDraft(
            sourceEstimateId: input.sourceEstimate?.id,
            recoverySelection: selection,
          ),
        );
    }
  }
}
