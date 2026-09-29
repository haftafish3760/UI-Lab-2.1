import 'estimate_approval_draft_workflow.dart';
import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/local_record_command.dart';
import 'estimate_signature_draft_workflow.dart';
import 'estimate_delivery_draft_workflow.dart';
import 'estimate_items_draft_workflow.dart';
import 'estimate_review_draft_workflow.dart';
import 'models/estimate_models.dart';
import 'models/work_contact_models.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';

sealed class ResumedEstimateAction {
  const ResumedEstimateAction();
}

class ResumedEstimateApproval extends ResumedEstimateAction {
  const ResumedEstimateApproval(this.controller);
  final EstimateApprovalDraftController controller;
}

class ResumedEstimateSignature extends ResumedEstimateAction {
  const ResumedEstimateSignature(this.controller);
  final EstimateSignatureDraftController controller;
}

class ResumedEstimateDelivery extends ResumedEstimateAction {
  const ResumedEstimateDelivery(this.controller);
  final EstimateDeliveryDraftController controller;
}

class ResumedEstimateItems extends ResumedEstimateAction {
  const ResumedEstimateItems(this.controller);
  final EstimateItemsDraftController controller;
}

class ResumedEstimateReview extends ResumedEstimateAction {
  const ResumedEstimateReview(this.controller);
  final EstimateReviewDraftController controller;
}

/// Domain recovery; composition supplies current review authority and contacts.
/// Nothing here decides navigation, grants a role, sends delivery, or signs work.
class EstimateActionDraftRecovery {
  EstimateActionDraftRecovery(
    this._work, {
    required this.reviewPermissions,
    required this.customers,
  }) {
    _catalog = DraftRecoveryCatalog(
      repository: _work.drafts,
      organizationId: _work.permissions.organizationId,
      ownerId: _work.permissions.actorEmployeeId,
      handlers: handlers,
    );
  }
  final WorkPersistenceSession _work;
  final EstimatePermissions Function() reviewPermissions;
  final Iterable<WorkCustomerProfile> Function() customers;
  late final DraftRecoveryCatalog _catalog;
  static const _labels = {
    'work/quote-approval': 'Quote customer approval',
    'work/quote-signature': 'Quote signature',
    'work/estimate-approval': 'Estimate customer approval',
    'work/estimate-signature': 'Estimate signature',
    'work/quote-delivery': 'Quote delivery preparation',
    'work/estimate-delivery': 'Estimate delivery preparation',
    'work/estimate-items': 'Estimate items',
    'work/estimate-review': 'Estimate company review',
  };
  bool _canList(String domain) {
    final p = _work.permissions;
    return (!domain.endsWith('-delivery') || p.canShareDocuments) &&
        (!domain.endsWith('-approval') || p.canRecordCustomerApproval) &&
        p.editableKinds.contains(
          domain.startsWith('work/quote-')
              ? WorkRecordKind.quote
              : WorkRecordKind.estimate,
        ) &&
        (p.visibleCreatorIds.contains(p.actorEmployeeId) ||
            (p.canManageOtherCreators && p.visibleCreatorIds.isNotEmpty)) &&
        (domain != 'work/estimate-review' ||
            reviewPermissions().canApproveCompanyReview);
  }

  Iterable<DraftRecoveryHandler> get handlers => _labels.entries.map(
    (entry) => DraftRecoveryHandler(
      domain: entry.key,
      workflowLabel: entry.value,
      canList: () => _canList(entry.key),
      inspect: (raw) => _inspect(entry.key, raw),
      canDiscard: (_) async => _canList(entry.key),
    ),
  );
  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);

  (WorkRecord, int) _base(String domain, Map<String, Object?> raw) {
    switch (domain) {
      case 'work/quote-approval':
      case 'work/estimate-approval':
        final input = EstimateApprovalInput.fromPayload(raw);
        return (input.base, input.baseRevision);
      case 'work/quote-signature':
      case 'work/estimate-signature':
        final input = EstimateSignatureInput.fromPayload(raw);
        return (input.base, input.baseRevision);
      case 'work/quote-delivery':
      case 'work/estimate-delivery':
        final input = EstimateDeliveryInput.fromPayload(raw);
        return (input.base, input.baseRevision);
      case 'work/estimate-items':
        final input = EstimateItemsDraftInput.fromPayload(raw);
        return (input.base, input.baseRevision);
      case 'work/estimate-review':
        final input = EstimateReviewInput.fromPayload(raw);
        return (input.base, input.baseRevision);
      default:
        throw StateError('Unknown estimate workflow.');
    }
  }

  Future<DraftRecoveryPreview?> _inspect(
    String domain,
    Map<String, Object?> raw,
  ) async {
    late WorkRecord base;
    late int revision;
    try {
      (base, revision) = _base(domain, raw);
      if (base.kind !=
              (domain.startsWith('work/quote-')
                  ? WorkRecordKind.quote
                  : WorkRecordKind.estimate) ||
          revision < 1) {
        throw StateError('Invalid estimate base.');
      }
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved estimate input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    if (!_work.permissions.canEdit(base)) return null;
    final parent = await _work.repository.find(
      organizationId: _work.permissions.organizationId,
      recordId: base.id,
      visibleCreatorIds: _work.permissions.visibleCreatorIds,
    );
    if (parent == null || parent.record.kind != base.kind) {
      return DraftRecoveryPreview(
        title: 'Saved input — original estimate unavailable',
        availability: DraftRecoveryAvailability.parentUnavailable,
        recordId: base.id,
      );
    }
    if (!_work.permissions.canEdit(parent.record)) return null;
    var state = parent.storageRevision == revision
        ? DraftRecoveryAvailability.recoverable
        : DraftRecoveryAvailability.conflict;
    if (state == DraftRecoveryAvailability.recoverable &&
        domain == 'work/estimate-review') {
      try {
        EstimateReviewInput.fromPayload(
          raw,
        ).validateReview(reviewPermissions());
      } on Object {
        state = DraftRecoveryAvailability.parentUnavailable;
      }
    }
    return DraftRecoveryPreview(
      title: base.title.trim().isEmpty ? base.number : base.title,
      availability: state,
      recordId: base.id,
    );
  }

  Future<ResumedEstimateAction> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError('Saved estimate input requires review before resuming.');
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
    final (base, _) = _base(current.domain, raw);
    final selection = DraftRecoverySelection(
      domain: current.domain,
      draftId: current.draftId,
      revision: current.revision,
    );
    switch (current.domain) {
      case 'work/quote-approval':
      case 'work/estimate-approval':
        return ResumedEstimateApproval(
          await _work.openEstimateApprovalDraft(
            base.id,
            recoverySelection: selection,
          ),
        );
      case 'work/quote-signature':
      case 'work/estimate-signature':
        return ResumedEstimateSignature(
          await _work.openEstimateSignatureDraft(
            base.id,
            recoverySelection: selection,
          ),
        );
      case 'work/quote-delivery':
      case 'work/estimate-delivery':
        return ResumedEstimateDelivery(
          await _work.openEstimateDeliveryDraft(
            base.id,
            customers: customers(),
            recoverySelection: selection,
          ),
        );
      case 'work/estimate-items':
        return ResumedEstimateItems(
          await _work.openEstimateItemsDraft(
            base,
            recoverySelection: selection,
          ),
        );
      case 'work/estimate-review':
        final input = EstimateReviewInput.fromPayload(raw);
        return ResumedEstimateReview(
          await _work.openEstimateReviewDraft(
            base,
            decision: input.decision,
            reviewPermissions: reviewPermissions(),
            recoverySelection: selection,
          ),
        );
      default:
        throw StateError('Unknown estimate workflow.');
    }
  }
}
