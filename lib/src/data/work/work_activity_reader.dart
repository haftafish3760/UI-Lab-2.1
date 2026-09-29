import 'models/work_models.dart';
import 'work_record_codec.dart';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../storage/local_record_command.dart';
import 'work_persistence_session.dart';

class WorkActivityEntry {
  const WorkActivityEntry({
    required this.revision,
    required this.at,
    required this.actorId,
    required this.changes,
    this.record,
  });
  final int revision;
  final DateTime at;
  final String actorId;
  final List<String> changes;

  /// Verified snapshot for a document save; export-attempt entries have none.
  final WorkRecord? record;
}

class WorkActivityPage {
  const WorkActivityPage(this.entries, this.nextBeforeRevision);
  final List<WorkActivityEntry> entries;
  final int? nextBeforeRevision;
}

/// A projection of existing committed revisions. No second change-history store.
class WorkActivityReader {
  const WorkActivityReader(this.work);
  final WorkPersistenceSession work;

  void authorize(String recordId) {
    work.requireActiveDraftOwner();
    if (!work.records.any(
      (r) =>
          r.id == recordId &&
          work.permissions.visibleCreatorIds.contains(r.createdByEmployeeId),
    )) {
      throw StateError('This work record is no longer available.');
    }
  }

  Future<WorkActivityPage> read(String recordId, {int? beforeRevision}) async {
    authorize(recordId);
    final current = await work.repository.find(
      organizationId: work.permissions.organizationId,
      recordId: recordId,
      visibleCreatorIds: work.permissions.visibleCreatorIds,
    );
    if (current == null) {
      throw StateError('This work record is no longer available.');
    }
    final db = work.repository.database;
    final rows =
        await (db.select(db.localRecordRevisions)
              ..where(
                (r) =>
                    r.organizationId.equals(work.permissions.organizationId) &
                    r.domain.equals('work/records') &
                    r.recordId.equals(recordId) &
                    r.ownerId.isIn(work.permissions.visibleCreatorIds) &
                    (beforeRevision == null
                        ? const Constant(true)
                        : r.revision.isSmallerThanValue(beforeRevision)),
              )
              ..orderBy([(r) => OrderingTerm.desc(r.revision)])
              ..limit(31))
            .get();
    authorize(recordId);
    if ((beforeRevision == null &&
            (rows.isEmpty || rows.first.revision != current.storageRevision)) ||
        await work.repository.find(
              organizationId: work.permissions.organizationId,
              recordId: recordId,
              visibleCreatorIds: work.permissions.visibleCreatorIds,
            ) ==
            null) {
      throw StateError('The current document history could not be verified.');
    }
    work.requireActiveDraftOwner();
    final payloads = <Map<String, Object?>>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.payloadVersion != 1 ||
          payloadDigest(row.payload) != row.payloadHash ||
          (i > 0 && rows[i - 1].revision != row.revision + 1)) {
        throw StateError('The saved activity history could not be verified.');
      }
      final data = Map<String, Object?>.from(jsonDecode(row.payload) as Map);
      if (data['id'] != recordId ||
          data['createdByEmployeeId'] != row.ownerId ||
          data['kind'] != current.record.kind.name ||
          data['mutationActor'] is! String ||
          (data['mutationActor'] as String).isEmpty) {
        throw StateError('The saved activity identity could not be verified.');
      }
      payloads.add(data);
    }
    if (rows.isNotEmpty && rows.length <= 30 && rows.last.revision != 1) {
      throw StateError('Earlier activity is missing.');
    }
    final count = rows.length > 30 ? 30 : rows.length;
    return WorkActivityPage(
      List.unmodifiable([
        for (var i = 0; i < count; i++)
          WorkActivityEntry(
            revision: rows[i].revision,
            record: decodeWorkRecord(payloads[i]),
            at: DateTime.fromMicrosecondsSinceEpoch(
              rows[i].updatedAtUs,
              isUtc: true,
            ),
            actorId: payloads[i]['mutationActor'] as String,
            changes: rows[i].revision == 1
                ? const ['Created document']
                : _changes(payloads[i + 1], payloads[i]),
          ),
      ]),
      rows.length > 30 ? rows[29].revision : null,
    );
  }

  List<String> _changes(
    Map<String, Object?> old,
    Map<String, Object?> current,
  ) {
    final labels = <String>{};
    for (final key in {...old.keys, ...current.keys}) {
      if (const {
        'revision',
        'mutationActor',
        'permissionRevision',
        'estimateRevisionHistory',
      }.contains(key)) {
        continue;
      }
      if (canonicalJson(old[key]) != canonicalJson(current[key])) {
        labels.add(_labels[key] ?? 'Document information changed');
      }
    }
    return List.unmodifiable(labels.isEmpty ? ['Saved document'] : labels);
  }

  static const _labels = {
    'title': 'Work title changed',
    'detail': 'Work description changed',
    'client': 'Customer changed',
    'number': 'Document number changed',
    'purchaseOrderNumber': 'Purchase order number changed',
    'assignedEmployeeIds': 'Assigned employees changed',
    'assignee': 'Assigned employees changed',
    'scheduledStart': 'Schedule changed',
    'scheduledEnd': 'Schedule changed',
    'completedOn': 'Completion date changed',
    'status': 'Status changed',
    'items': 'Items changed',
    'tax': 'Tax changed',
    'discount': 'Discount changed',
    'total': 'Total changed',
    'terms': 'Terms changed',
    'template': 'Template changed',
    'estimateStage': 'Estimate status changed',
    'estimateDates': 'Estimate dates updated',
    'estimateDeliveries': 'Estimate delivery information recorded',
    'customerSignature': 'Customer approval changed',
    'estimateCompanyReviewStatus': 'Company approval changed',
    'estimateCompanyReviewHistory': 'Company review recorded',
    'estimateCompanyReviewNote': 'Company review note changed',
    'requiresCompanyReview': 'Company approval requirement changed',
    'sitePhotos': 'Photos changed',
    'linkedExpenseIds': 'Linked purchases changed',
    'sourceId': 'Linked work changed',
    'jobNotes': 'Job notes changed',
    'serviceLocation': 'Service address changed',
    'vehicle': 'Assigned vehicle changed',
    'issuedOn': 'Issue date changed',
    'dueOn': 'Due date changed',
    'paymentMethod': 'Payment instructions changed',
  };
}
