import 'package:drift/drift.dart';
import '../storage/local_record_command.dart';
import '../storage/local_record_identity.dart';
import '../storage/local_record_store.dart';
import 'models/work_models.dart';
import 'models/estimate_models.dart';
import 'sqlite_work_repository.dart';
import 'work_session_permissions.dart';

/// A retained deletion record prevents stale editors from resurrecting drafts.
/// Existing record revisions are preserved; there is no destructive SQL reset.
class WorkDraftRepository {
  const WorkDraftRepository(this.repository);
  final SqliteWorkRepository repository;

  Future<void> delete({
    required WorkSessionPermissions permissions,
    required WorkRecord record,
    required int expectedRevision,
  }) => repository.database.transaction(() async {
    if (!permissions.canDeleteDrafts || !permissions.canEdit(record)) {
      throw StateError('Deleting drafts is not permitted.');
    }
    final current = await repository.find(
      organizationId: permissions.organizationId,
      recordId: record.id,
      visibleCreatorIds: permissions.visibleCreatorIds,
    );
    if (current == null ||
        current.storageRevision != expectedRevision ||
        (current.record.kind == WorkRecordKind.estimate
            ? current.record.resolvedEstimateStage != EstimateStage.draft
            : current.record.status != WorkRecordStatus.draft) ||
        current.record.customerSignature != null ||
        current.record.estimateDeliveries.isNotEmpty) {
      throw const LocalRecordConflict('The draft changed.');
    }
    // Check all organization records, not just the visible UI cache, before
    // removing a source that another record or payment may reference.
    final linked = await repository.database
        .customSelect(
          'SELECT 1 FROM local_records WHERE organization_id = ? AND '
          '((domain = ? AND json_extract(payload, \'\$.sourceId\') = ?) '
          'OR (domain = ? AND json_extract(payload, \'\$.sourceId\') IN (?, ?))) LIMIT 1',
          variables: [
            for (final value in [
              permissions.organizationId,
              'work/records',
              record.id,
              'work/ledger',
              record.id,
              record.number,
            ])
              Variable<String>(value),
          ],
        )
        .get();
    if (linked.isNotEmpty) throw StateError('This draft has linked records.');
    final now = DateTime.now().toUtc();
    await LocalRecordStore(repository.database).commit(
      organizationId: permissions.organizationId,
      commandId: newLocalRecordIdentity('delete-work-draft'),
      occurredAt: now,
      writes: [
        LocalRecordWrite(
          domain: 'work/deleted',
          recordId: record.id,
          ownerId: record.createdByEmployeeId,
          expectedRevision: 0,
          payload: {
            'recordId': record.id,
            'recordRevision': expectedRevision,
            'deletedAt': now.toIso8601String(),
            'mutationActor': permissions.actorEmployeeId,
            'permissionRevision': permissions.permissionRevision,
          },
        ),
      ],
    );
  });
}
