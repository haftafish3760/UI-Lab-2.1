import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/local_record_command.dart';
import 'job_notes_draft_workflow.dart';
import 'job_photos_draft_workflow.dart';
import 'job_material_permissions.dart';
import 'job_schedule_draft_workflow.dart';
import 'job_assignment_draft_workflow.dart';
import 'job_materials_draft_workflow.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';

sealed class ResumedJobAction {
  const ResumedJobAction();
}

class ResumedJobPhotos extends ResumedJobAction {
  const ResumedJobPhotos(this.controller);
  final JobPhotosDraftController controller;
}

class ResumedJobNotes extends ResumedJobAction {
  const ResumedJobNotes(this.controller);
  final JobNotesDraftController controller;
}

class ResumedJobSchedule extends ResumedJobAction {
  const ResumedJobSchedule(this.controller);
  final JobScheduleDraftController controller;
}

class ResumedJobAssignment extends ResumedJobAction {
  const ResumedJobAssignment(this.controller);
  final JobAssignmentDraftController controller;
}

class ResumedJobMaterials extends ResumedJobAction {
  const ResumedJobMaterials(this.controller);
  final JobMaterialsDraftController controller;
}

/// Job input recovery independent of route, dialog and responsive composition.
/// Materials confirmation retains the existing workflow contract; inventory
/// stock transactions belong to the separately authorized inventory migration.
class JobActionDraftRecovery {
  JobActionDraftRecovery(this._work, {required this.materialPermissions}) {
    _catalog = DraftRecoveryCatalog(
      repository: _work.drafts,
      organizationId: _work.permissions.organizationId,
      ownerId: _work.permissions.actorEmployeeId,
      handlers: handlers,
    );
  }
  final WorkPersistenceSession _work;
  final JobWorkspacePermissions Function() materialPermissions;
  late final DraftRecoveryCatalog _catalog;
  static const _labels = {
    'work/job-notes': 'Job notes',
    'work/job-photos': 'Job photos',
    'work/job-schedule': 'Job schedule',
    'work/job-assignment': 'Job assignment',
    'work/job-materials': 'Job materials',
  };
  bool _canList(String domain) {
    final p = _work.permissions;
    return (domain != 'work/job-photos' || p.canAttachJobPhotos) &&
        p.editableKinds.contains(WorkRecordKind.job) &&
        (p.visibleCreatorIds.contains(p.actorEmployeeId) ||
            (p.canManageOtherCreators && p.visibleCreatorIds.isNotEmpty)) &&
        (domain != 'work/job-materials' ||
            materialPermissions().canAddMaterials);
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
      case 'work/job-photos':
        final input = JobPhotosDraftInput.fromPayload(raw);
        return (input.base, input.baseRevision);
      case 'work/job-notes':
        final input = JobNotesInput.fromPayload(raw);
        return (input.base, input.baseRevision);
      case 'work/job-schedule':
        final input = JobScheduleInput.fromPayload(raw);
        return (input.base, input.baseRevision);
      case 'work/job-assignment':
        final input = JobAssignmentInput.fromPayload(raw);
        return (input.base, input.baseRevision);
      case 'work/job-materials':
        final input = JobMaterialsDraftInput.fromPayload(raw);
        return (input.base, input.baseRevision);
      default:
        throw StateError('Unknown job workflow.');
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
      if (base.kind != WorkRecordKind.job || revision < 1) {
        throw StateError('Invalid job base.');
      }
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved job input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    if (!_work.permissions.canEdit(base)) return null;
    final parent = await _work.repository.find(
      organizationId: _work.permissions.organizationId,
      recordId: base.id,
      visibleCreatorIds: _work.permissions.visibleCreatorIds,
    );
    if (parent == null || parent.record.kind != WorkRecordKind.job) {
      return DraftRecoveryPreview(
        title: 'Saved input — original job unavailable',
        availability: DraftRecoveryAvailability.parentUnavailable,
        recordId: base.id,
      );
    }
    if (!_work.permissions.canEdit(parent.record)) return null;
    return DraftRecoveryPreview(
      title: base.title.trim().isEmpty ? base.number : base.title,
      availability: parent.storageRevision == revision
          ? DraftRecoveryAvailability.recoverable
          : DraftRecoveryAvailability.conflict,
      recordId: base.id,
    );
  }

  Future<ResumedJobAction> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError('Saved job input requires review before resuming.');
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
    final (base, _) = _base(current.domain, _work.drafts.decode(saved));
    final selection = DraftRecoverySelection(
      domain: current.domain,
      draftId: current.draftId,
      revision: current.revision,
    );
    switch (current.domain) {
      case 'work/job-photos':
        return ResumedJobPhotos(
          await _work.openJobPhotosDraft(base.id, recoverySelection: selection),
        );
      case 'work/job-notes':
        return ResumedJobNotes(
          await _work.openJobNotesDraft(base.id, recoverySelection: selection),
        );
      case 'work/job-schedule':
        return ResumedJobSchedule(
          await _work.openJobScheduleDraft(
            base.id,
            recoverySelection: selection,
          ),
        );
      case 'work/job-assignment':
        return ResumedJobAssignment(
          await _work.openJobAssignmentDraft(
            base.id,
            recoverySelection: selection,
          ),
        );
      case 'work/job-materials':
        return ResumedJobMaterials(
          await _work.openJobMaterialsDraft(
            base.id,
            materialPermissions: materialPermissions(),
            recoverySelection: selection,
          ),
        );
      default:
        throw StateError('Unknown job workflow.');
    }
  }
}
