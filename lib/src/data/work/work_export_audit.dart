import 'package:drift/drift.dart' show Variable;
import '../storage/local_record_identity.dart';
import '../storage/local_record_store.dart';
import '../storage/local_record_command.dart';
import 'work_activity_reader.dart';
import 'work_persistence_session.dart';

/// Work owns export audit meaning; the shared PDF engine knows nothing about it.
class WorkExportAudit {
  const WorkExportAudit(this.work);
  final WorkPersistenceSession work;
  static const domain = 'work/document-exports';

  Future<void> assertCurrent(String recordId, int revision) async {
    WorkActivityReader(work).authorize(recordId);
    final record = work.records.firstWhere((r) => r.id == recordId);
    if (!work.permissions.canShareDocuments ||
        !work.permissions.canEdit(record)) {
      throw StateError('You do not have permission to export this document.');
    }
    final store = LocalRecordStore(work.repository.database);
    final rows = await store.read(
      organizationId: work.permissions.organizationId,
      domain: 'work/records',
      ownerIds: work.permissions.visibleCreatorIds,
      recordIds: {recordId},
    );
    if (rows.length != 1 || rows.single.revision != revision) {
      throw StateError(
        'The saved document changed. Review it again before sharing.',
      );
    }
    store.decode(rows.single);
    WorkActivityReader(work).authorize(recordId);
  }

  Future<WorkExportAttempt> begin(
    String recordId,
    int expectedRevision,
    String action,
  ) async {
    if (!const {'share', 'save', 'print'}.contains(action)) {
      throw ArgumentError('Unsupported action.');
    }
    return work.repository.database.transaction(() async {
      await assertCurrent(recordId, expectedRevision);
      final record = work.records.firstWhere((r) => r.id == recordId);
      final attempt = WorkExportAttempt(
        newLocalRecordIdentity('document-export'),
        recordId,
        record.createdByEmployeeId,
        expectedRevision,
        work.permissions.actorEmployeeId,
        action,
      );
      await _write(attempt, 'started', 0);
      return attempt;
    });
  }

  Future<void> finish(WorkExportAttempt attempt, String outcome) async {
    if (!const {
      'completed',
      'cancelled',
      'unconfirmed',
      'failed',
    }.contains(outcome)) {
      throw ArgumentError('Unsupported outcome.');
    }
    WorkActivityReader(work).authorize(attempt.recordId);
    if (attempt.actorId != work.permissions.actorEmployeeId ||
        !work.permissions.canShareDocuments) {
      throw StateError(
        'The export result could not be recorded with this session.',
      );
    }
    await work.repository.database.transaction(() async {
      final store = LocalRecordStore(work.repository.database);
      final rows = await store.read(
        organizationId: work.permissions.organizationId,
        domain: domain,
        ownerIds: work.permissions.visibleCreatorIds,
        recordIds: {attempt.id},
      );
      if (rows.length != 1) {
        throw StateError('Export attempt is unavailable.');
      }
      final data = store.decode(rows.single);
      if (rows.single.ownerId != attempt.ownerId ||
          data['actorId'] != attempt.actorId ||
          data['recordId'] != attempt.recordId ||
          data['sourceRevision'] != attempt.revision ||
          data['action'] != attempt.action) {
        throw StateError('Export attempt identity changed.');
      }
      if (rows.single.revision == 2 && data['outcome'] == outcome) {
        return;
      }
      await _write(attempt, outcome, 1);
    });
  }

  Future<void> _write(WorkExportAttempt attempt, String outcome, int expected) {
    final now = DateTime.now().toUtc();
    return LocalRecordStore(work.repository.database).commit(
      organizationId: work.permissions.organizationId,
      commandId: '${attempt.id}-$outcome',
      occurredAt: now,
      writes: [
        LocalRecordWrite(
          domain: domain,
          recordId: attempt.id,
          ownerId: attempt.ownerId,
          expectedRevision: expected,
          payload: {
            'recordId': attempt.recordId,
            'sourceRevision': attempt.revision,
            'actorId': attempt.actorId,
            'action': attempt.action,
            'outcome': outcome,
            'at': now.toIso8601String(),
          },
        ),
      ],
    );
  }

  Future<List<WorkActivityEntry>> read(
    String recordId, {
    int limit = 100,
  }) async {
    if (limit < 1) {
      throw ArgumentError('A positive page size is required.');
    }
    WorkActivityReader(work).authorize(recordId);
    final db = work.repository.database;
    final store = LocalRecordStore(db);
    final owners = work.permissions.visibleCreatorIds;
    // Record IDs are random, so filter the source in SQLite before materializing.
    final rows = await db
        .customSelect(
          'SELECT record_id FROM local_records WHERE organization_id = ? AND domain = ? AND owner_id IN (${List.filled(owners.length, '?').join(',')}) '
          "AND json_extract(payload, '\$.recordId') = ? ORDER BY updated_at_us DESC, record_id DESC LIMIT ?",
          variables: [
            Variable.withString(work.permissions.organizationId),
            Variable.withString(domain),
            ...owners.map(Variable.withString),
            Variable.withString(recordId),
            Variable.withInt(limit),
          ],
        )
        .get();
    final records = await store.read(
      organizationId: work.permissions.organizationId,
      domain: domain,
      ownerIds: work.permissions.visibleCreatorIds,
      recordIds: rows.map((r) => r.read<String>('record_id')).toSet(),
    );
    WorkActivityReader(work).authorize(recordId);
    final events = records.map((r) {
      final data = store.decode(r);
      return WorkActivityEntry(
        revision: data['sourceRevision'] as int,
        at: DateTime.parse(data['at'] as String),
        actorId: data['actorId'] as String,
        changes: [label(data['action'] as String, data['outcome'] as String)],
      );
    }).toList()..sort((a, b) => b.at.compareTo(a.at));
    return events;
  }

  static String label(String action, String outcome) {
    final verb = switch (action) {
      'share' => 'Sharing',
      'print' => 'Printing',
      _ => 'Saving PDF',
    };
    return switch (outcome) {
      'started' => '$verb started; result not recorded',
      'cancelled' => '$verb cancelled',
      'failed' => '$verb failed',
      'unconfirmed' => '$verb returned without a confirmed result',
      _ =>
        action == 'share'
            ? 'Shared with another app; customer delivery not confirmed'
            : '$verb completed',
    };
  }
}

class WorkExportAttempt {
  const WorkExportAttempt(
    this.id,
    this.recordId,
    this.ownerId,
    this.revision,
    this.actorId,
    this.action,
  );
  final String id, recordId, ownerId, actorId, action;
  final int revision;
}
