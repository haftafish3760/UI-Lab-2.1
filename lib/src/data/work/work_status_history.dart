import 'dart:convert';

import 'package:drift/drift.dart';

import 'models/work_models.dart';
import '../storage/local_database.dart';
import '../storage/local_record_command.dart';
import 'work_record_codec.dart';

class WorkStatusEvent {
  const WorkStatusEvent({
    required this.record,
    required this.revision,
    required this.at,
    required this.actorId,
  });
  final WorkRecord record;
  final int revision;
  final DateTime at;
  final String actorId;
  String get id => 'work-status-${record.id}-$revision';
}

WorkStatusEvent? workStatusTransition({
  required WorkRecord? previous,
  required WorkRecord current,
  required int revision,
  required DateTime at,
  required String actorId,
}) {
  if (previous == null ||
      previous.kind != WorkRecordKind.job ||
      current.kind != WorkRecordKind.job ||
      previous.status == current.status ||
      (current.status != WorkRecordStatus.arrived &&
          current.status != WorkRecordStatus.completed)) {
    return null;
  }
  return WorkStatusEvent(
    record: current,
    revision: revision,
    at: at,
    actorId: actorId,
  );
}

/// Reads existing atomic revision history; never invents events from fixtures
/// or the latest status alone. Reads are scoped before payload decoding.
Future<List<WorkStatusEvent>> readWorkStatusHistory(
  LocalDatabase database, {
  required String organizationId,
  required Set<String> visibleCreatorIds,
}) async {
  if (visibleCreatorIds.isEmpty) return const [];
  final rows =
      await (database.select(database.localRecordRevisions)
            ..where(
              (row) =>
                  row.organizationId.equals(organizationId) &
                  row.domain.equals('work/records') &
                  row.ownerId.isIn(visibleCreatorIds),
            )
            ..orderBy([
              (row) => OrderingTerm.asc(row.recordId),
              (row) => OrderingTerm.asc(row.revision),
            ]))
          .get();
  final previous = <String, WorkRecord>{};
  final revisions = <String, int>{};
  final events = <WorkStatusEvent>[];
  for (final row in rows) {
    if (row.payloadVersion != 1 ||
        payloadDigest(row.payload) != row.payloadHash ||
        row.revision != (revisions[row.recordId] ?? 0) + 1) {
      throw StateError('Saved Work history is inconsistent.');
    }
    final payload = Map<String, Object?>.from(jsonDecode(row.payload) as Map);
    final record = decodeWorkRecord(payload);
    final actor = payload['mutationActor'];
    if (record.id != row.recordId ||
        record.createdByEmployeeId != row.ownerId ||
        actor is! String ||
        actor.trim().isEmpty) {
      throw StateError('Saved Work history identity is inconsistent.');
    }
    final event = workStatusTransition(
      previous: previous[record.id],
      current: record,
      revision: row.revision,
      at: DateTime.fromMicrosecondsSinceEpoch(row.updatedAtUs, isUtc: true),
      actorId: actor,
    );
    if (event != null) events.add(event);
    previous[record.id] = record;
    revisions[record.id] = row.revision;
  }
  events.sort((a, b) {
    final time = a.at.compareTo(b.at);
    return time == 0 ? a.id.compareTo(b.id) : time;
  });
  return List.unmodifiable(events);
}
