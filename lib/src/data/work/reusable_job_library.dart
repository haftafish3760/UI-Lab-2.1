import '../storage/draft_autosave_session.dart';
import '../storage/draft_repository.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_command.dart';
import '../storage/local_record_identity.dart';
import '../storage/local_record_store.dart';
import 'models/work_models.dart';
import 'reusable_job.dart';
import 'work_persistence_session.dart';

class SavedReusableJob {
  const SavedReusableJob(this.job, this.revision);
  final ReusableJob job;
  final int revision;
}

/// Reuses the same durable record/revision and recovery stores as Work.
class ReusableJobLibrary {
  const ReusableJobLibrary(this.work);
  final WorkPersistenceSession work;
  static const domain = 'work/reusable-jobs';
  static const draftDomain = 'work/reusable-job-editor';

  void _authorize([String? ownerId]) {
    work.requireActiveDraftOwner();
    final p = work.permissions;
    if (!p.editableKinds.contains(WorkRecordKind.job) ||
        !p.visibleCreatorIds.contains(ownerId ?? p.actorEmployeeId) ||
        (ownerId != null &&
            ownerId != p.actorEmployeeId &&
            !p.canManageOtherCreators)) {
      throw StateError('Your access does not allow managing reusable jobs.');
    }
  }

  Future<List<SavedReusableJob>> list() async {
    _authorize();
    final rows = await LocalRecordStore(work.repository.database).read(
      organizationId: work.permissions.organizationId,
      domain: domain,
      ownerIds: work.permissions.visibleCreatorIds,
    );
    _authorize();
    final result =
        rows.map((row) {
          final job = ReusableJob.fromJson(
            LocalRecordStore(work.repository.database).decode(row),
          );
          if (job.id != row.recordId || job.ownerId != row.ownerId) {
            throw StateError('Saved reusable job identity is inconsistent.');
          }
          return SavedReusableJob(job, row.revision);
        }).toList()..sort(
          (a, b) =>
              a.job.title.toLowerCase().compareTo(b.job.title.toLowerCase()),
        );
    return List.unmodifiable(result);
  }

  Future<ReusableJob> forUse(String id, int revision) async {
    final matches = (await list()).where((item) => item.job.id == id);
    if (matches.length != 1 || matches.single.revision != revision) {
      throw const LocalRecordConflict(
        'This reusable job changed. Reopen it before using it.',
      );
    }
    return matches.single.job;
  }

  Future<void> save(
    ReusableJob job, {
    required int expectedRevision,
    LocalDraftCheckpoint? checkpoint,
  }) async {
    _authorize(job.ownerId);
    final proposed = ReusableJob.fromJson(job.toJson());
    final p = work.permissions;
    if (p.permissionRevision.trim().isEmpty ||
        p.actorEmployeeId.trim().isEmpty) {
      throw StateError('Reusable jobs need an active authorized account.');
    }
    await work.runReusableJobWrite(
      () => work.repository.database.transaction(() async {
        _authorize(proposed.ownerId);
        final store = LocalRecordStore(work.repository.database);
        final existing = await store.read(
          organizationId: p.organizationId,
          domain: domain,
          ownerIds: p.visibleCreatorIds,
          recordIds: {proposed.id},
        );
        if ((expectedRevision == 0 && existing.isNotEmpty) ||
            (expectedRevision > 0 &&
                (existing.length != 1 ||
                    existing.single.ownerId != proposed.ownerId ||
                    existing.single.revision != expectedRevision))) {
          throw const LocalRecordConflict(
            'This reusable job changed. Your unfinished input has been kept.',
          );
        }
        if (checkpoint != null) {
          final input = await work.drafts.find(
            organizationId: p.organizationId,
            domain: draftDomain,
            draftId: checkpoint.draftId,
            ownerId: p.actorEmployeeId,
          );
          final payload = input == null ? null : work.drafts.decode(input);
          if (payload == null ||
              payload['id'] != proposed.id ||
              payload['ownerId'] != proposed.ownerId ||
              payload['baseRevision'] != expectedRevision) {
            throw const LocalRecordConflict(
              'This input belongs to another reusable job.',
            );
          }
          if (checkpoint.domain != draftDomain ||
              !await work.drafts.consumeIfUnchanged(
                organizationId: p.organizationId,
                domain: draftDomain,
                draftId: checkpoint.draftId,
                ownerId: p.actorEmployeeId,
                expectedRevision: checkpoint.revision,
              )) {
            throw const LocalRecordConflict(
              'The unfinished reusable job changed. Reopen it.',
            );
          }
        }
        _authorize(proposed.ownerId);
        await store.commit(
          organizationId: p.organizationId,
          commandId: newLocalRecordIdentity('save-reusable-job'),
          occurredAt: DateTime.now().toUtc(),
          writes: [
            LocalRecordWrite(
              domain: domain,
              recordId: proposed.id,
              ownerId: proposed.ownerId,
              expectedRevision: expectedRevision,
              payload: {
                ...proposed.toJson(),
                'mutationActor': p.actorEmployeeId,
                'permissionRevision': p.permissionRevision,
              },
            ),
          ],
        );
      }),
    );
  }

  Future<List<SavedDraft>> unfinished() async {
    _authorize();
    final rows = await work.drafts.list(
      organizationId: work.permissions.organizationId,
      domain: draftDomain,
      ownerId: work.permissions.actorEmployeeId,
    );
    _authorize();
    return rows;
  }

  Future<DraftAutosaveSession> openInput({String? draftId}) async {
    _authorize();
    final session = DraftAutosaveSession(
      store: work.drafts,
      organizationId: work.permissions.organizationId,
      domain: draftDomain,
      draftId: draftId ?? newLocalRecordIdentity('reusable-job-input'),
      ownerId: work.permissions.actorEmployeeId,
    );
    try {
      await session.initialize();
      _authorize();
      return session;
    } catch (_) {
      await session.close();
      rethrow;
    }
  }
}
