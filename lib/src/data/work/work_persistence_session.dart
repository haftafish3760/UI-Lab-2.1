import 'invoice_approval_content.dart';
import 'quote_approval_content.dart';
import '../storage/draft_recovery_query.dart';
import 'dart:io';
import '../storage/local_attachment_store.dart';
import '../storage/draft_repository.dart';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'models/work_models.dart';
import 'models/estimate_models.dart';

import '../prototype_financial_models.dart';
import '../storage/local_record_command.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_identity.dart';
import '../storage/serialized_async_actions.dart';
import 'sqlite_work_repository.dart';
import 'work_financial_codec.dart';
import 'work_record_codec.dart';
import 'work_record_detail_codec.dart';
import 'work_session_permissions.dart';
import 'work_status_history.dart';
import 'work_draft_repository.dart';
import 'work_assignment_validation.dart';
import 'work_document_numbering.dart';
import 'work_payment_allocation.dart';

part 'work_job_conversion.dart';
part 'work_proposal_invoice_conversion.dart';
part 'work_customer_approval_validation.dart';
part 'work_draft_deletion.dart';
part 'work_financial_validation.dart';
part 'invoice_approval_validation.dart';
part 'quote_approval_validation.dart';
part 'quote_customer_approval_validation.dart';

/// The single Work read-model cache for an app session. SQLite is authoritative;
/// listeners see committed changes only. Failed commands preserve this cache.
class WorkPersistenceSession extends ChangeNotifier {
  WorkPersistenceSession._(
    this.repository,
    this.permissions,
    List<PersistedWorkRecord> records,
    List<PrototypeFinancialEntry> entries,
    this._statusEvents,
  ) : _records = {for (final item in records) item.record.id: item.record},
      _versions = {
        for (final item in records) item.record.id: item.storageRevision,
      },
      _entries = {for (final entry in entries) entry.id: entry};

  final SqliteWorkRepository repository;
  DraftRepository get drafts {
    requireActiveDraftOwner();
    return repository.drafts;
  }

  /// Recheck after asynchronous draft loading before handing state to a UI.
  void requireActiveDraftOwner() {
    if (_disposed) throw StateError('The Work session is no longer active.');
  }

  final WorkSessionPermissions permissions;
  final Map<String, WorkRecord> _records;
  final Map<String, int> _versions;
  final Map<String, PrototypeFinancialEntry> _entries;
  final List<WorkStatusEvent> _statusEvents;
  UnmodifiableListView<WorkStatusEvent> get statusEvents =>
      UnmodifiableListView(_statusEvents);
  final _writes = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _writes.pauseAndDrain();

  /// Library records share Work's write queue and backup/switch pause boundary.
  Future<void> runReusableJobWrite(Future<void> Function() action) {
    requireActiveDraftOwner();
    _pendingWrites++;
    _notify();
    return _writes
        .run(() async {
          requireActiveDraftOwner();
          await action();
        })
        .whenComplete(() {
          _pendingWrites--;
          _notify();
        });
  }

  int _pendingWrites = 0;
  String? _failureMessage;
  bool _disposed = false;

  UnmodifiableListView<WorkRecord> get records =>
      UnmodifiableListView(_records.values);
  UnmodifiableListView<PrototypeFinancialEntry> get financialEntries =>
      UnmodifiableListView(_entries.values);
  bool get isSaving => _pendingWrites > 0;
  String? get failureMessage => _failureMessage;
  int storageRevisionFor(String recordId) => _versions[recordId] ?? 0;

  Future<String> nextDocumentNumber(WorkRecordKind kind) async {
    requireActiveDraftOwner();
    if (!permissions.editableKinds.contains(kind) ||
        kind == WorkRecordKind.job) {
      throw StateError('Document numbering is unavailable.');
    }
    return WorkDocumentNumbering(
      repository,
    ).previewNext(organizationId: permissions.organizationId, kind: kind);
  }

  DraftRecoveryQuery recoveryFor(WorkRecordKind kind) {
    if (_disposed || !permissions.editableKinds.contains(kind)) {
      throw StateError('Recovery for this Work kind is unavailable.');
    }
    final (domain, parent, label) = switch (kind) {
      WorkRecordKind.estimate => (
        'work/estimate-editor',
        'baseRecord',
        'Untitled estimate',
      ),
      WorkRecordKind.invoice => (
        'work/invoice-editor',
        'existingRecordId',
        'Untitled invoice',
      ),
      WorkRecordKind.job => ('work/job-editor', 'source', 'Untitled job'),
      WorkRecordKind.quote => (
        'work/quote-editor',
        'baseRecord',
        'Untitled quote',
      ),
    };
    return DraftRecoveryQuery(
      canList: () => !_disposed && permissions.editableKinds.contains(kind),
      repository: drafts,
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      domain: domain,
      parentField: parent,
      labelField: 'title',
      emptyLabel: label,
    );
  }

  Future<String> retainEstimatePhoto(
    String path, {
    WorkRecord? baseRecord,
  }) async {
    if (!permissions.editableKinds.contains(WorkRecordKind.estimate) ||
        (baseRecord != null && !permissions.canEdit(baseRecord))) {
      throw StateError('Photo retention is unavailable.');
    }
    final file = await LocalAttachmentStore(repository.database).retain(
      source: File(path),
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
    );
    return file.path;
  }

  static Future<WorkPersistenceSession> open(
    SqliteWorkRepository repository,
    WorkSessionPermissions permissions,
  ) => repository.database.transaction(() async {
    final records = await repository.query(
      organizationId: permissions.organizationId,
      visibleCreatorIds: permissions.visibleCreatorIds,
    );
    final entries = await repository.queryFinancialEntries(
      organizationId: permissions.organizationId,
      visibleActorIds: permissions.visibleCreatorIds,
    );
    final events = await readWorkStatusHistory(
      repository.database,
      organizationId: permissions.organizationId,
      visibleCreatorIds: permissions.visibleCreatorIds,
    );
    return WorkPersistenceSession._(repository, permissions, records, entries, [
      ...events,
    ]);
  });

  Future<bool> create(WorkRecord record) {
    final current = _records[record.id];
    if (current != null &&
        canonicalJson(encodeWorkRecord(current)) !=
            canonicalJson(encodeWorkRecord(record))) {
      return _reject('That Work record already exists.');
    }
    return save(records: [record]);
  }

  Future<bool> update(WorkRecord record) {
    if (!_records.containsKey(record.id)) {
      return _reject('That Work record is no longer available.');
    }
    return save(records: [record]);
  }

  /// The captured revisions belong to this submitted proposal, not to whatever
  /// a preceding queued command may have changed by the time it executes.
  Future<bool> save({
    List<WorkRecord> records = const [],
    List<PrototypeFinancialEntry> financialEntries = const [],
    Map<String, int>? expectedStorageRevisions,
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    if (_disposed) return _reject('This session is no longer active.');
    final proposed = records
        .map((record) => decodeWorkRecord(encodeWorkRecord(record)))
        .toList();
    final financial = financialEntries
        .map((entry) => decodeFinancialEntry(encodeFinancialEntry(entry)))
        .toList();
    final expected = {
      for (final record in proposed)
        record.id:
            expectedStorageRevisions?[record.id] ?? _versions[record.id] ?? 0,
    };
    final commandId = newLocalRecordIdentity('work-command');
    _pendingWrites++;
    _notify();
    return _writes.run(() async {
      try {
        final changes = <WorkRecordMutation>[];
        for (final record in proposed) {
          if (!permissions.canEdit(record)) {
            throw StateError(
              'You do not have permission to change that Work record.',
            );
          }
          final current = _records[record.id];
          if (current != null && current.kind != record.kind) {
            throw StateError('The document type cannot be changed.');
          }
          if (record.kind == WorkRecordKind.quote) {
            if ((permissions.requiresQuoteApproval ||
                    current?.requiresCompanyReview == true) &&
                !record.requiresCompanyReview) {
              throw StateError('Required quote approval cannot be bypassed.');
            }
            if (record.pricing != WorkPricingModel.flatRate ||
                !record.total.isFinite ||
                record.total < 0 ||
                record.requiredDepositCents < 0 ||
                record.requiredDepositCents > (record.total * 100).round()) {
              throw StateError('Enter a valid fixed quote price and deposit.');
            }
            _validateQuoteCustomerApproval(record, current);
          }
          _validateCustomerApprovalChanges(record, current);
          _validateQuoteApproval(record, current);
          _validateInvoiceApproval(record, current);
          if (current != null &&
              current.createdByEmployeeId != record.createdByEmployeeId) {
            throw StateError('The record creator cannot be rewritten.');
          }
          if ((_versions[record.id] ?? 0) != expected[record.id]) {
            throw const LocalRecordConflict(
              'The record changed while this save was waiting. Reopen it before retrying.',
            );
          }
          if (current != null &&
              canonicalJson(encodeWorkRecord(current)) ==
                  canonicalJson(encodeWorkRecord(record))) {
            continue;
          }
          if (current != null &&
              (record.revision < current.revision ||
                  record.revision > current.revision + 1)) {
            throw const LocalRecordConflict(
              'The document revision changed. Review its latest saved version.',
            );
          }
          if (current != null &&
              record.kind == WorkRecordKind.job &&
              canonicalJson(
                    record.sitePhotos.map(encodeWorkSitePhoto).toList(),
                  ) !=
                  canonicalJson(
                    current.sitePhotos.map(encodeWorkSitePhoto).toList(),
                  ) &&
              !permissions.canAttachJobPhotos) {
            throw StateError(
              'You do not have permission to change job photos.',
            );
          }
          changes.add(
            WorkRecordMutation(
              record: record,
              expectedStorageRevision: expected[record.id]!,
            ),
          );
        }
        _validateJobConversions(proposed);
        final newEntries = _validateFinancial(financial, proposed);
        _appendInvoicePaymentRevisions(changes, newEntries);
        _validateInvoiceTransitions(
          changes.map((change) => change.record).toList(),
          newEntries,
        );
        if (proposed.isNotEmpty ||
            changes.isNotEmpty ||
            newEntries.isNotEmpty ||
            draftCheckpoint != null) {
          final occurredAt = DateTime.now().toUtc();
          await repository.commit(
            organizationId: permissions.organizationId,
            commandId: commandId,
            actorEmployeeId: permissions.actorEmployeeId,
            permissionRevision: permissions.permissionRevision,
            occurredAt: occurredAt,
            mutations: changes,
            validateBeforeCommit: () async {
              await _validatePaymentAllocationsBeforeCommit(newEntries);
              for (final change in changes) {
                final saved = await repository.find(
                  organizationId: permissions.organizationId,
                  recordId: change.record.id,
                  visibleCreatorIds: permissions.visibleCreatorIds,
                );
                await _validateApprovalEvidence(change.record, saved?.record);
                await validateWorkAssignment(
                  repository: repository,
                  permissions: permissions,
                  next: change.record,
                  previous: saved?.record,
                );
              }
            },
            unchangedRecords: [
              for (final record in proposed)
                if (!changes.any((change) => change.record.id == record.id))
                  WorkRecordMutation(
                    record: record,
                    expectedStorageRevision: expected[record.id]!,
                  ),
            ],
            financialEntries: newEntries,
            draftCheckpoint: draftCheckpoint,
          );
          for (final change in changes) {
            final event = workStatusTransition(
              previous: _records[change.record.id],
              current: change.record,
              revision: change.expectedStorageRevision + 1,
              at: occurredAt,
              actorId: permissions.actorEmployeeId,
            );
            if (event != null) _statusEvents.add(event);
            _records[change.record.id] = change.record;
            _versions[change.record.id] = change.expectedStorageRevision + 1;
          }
          for (final entry in newEntries) {
            _entries[entry.id] = entry;
          }
        }
        _failureMessage = null;
        return true;
      } on LocalRecordConflict catch (error) {
        _failureMessage = error.message;
        return false;
      } on StateError catch (error) {
        _failureMessage = error.message.toString();
        return false;
      } on Object {
        _failureMessage =
            'Work changes were not saved. Your last saved records are unchanged. Keep the draft and try again.';
        return false;
      } finally {
        _pendingWrites--;
        _notify();
      }
    });
  }

  Future<bool> _reject(String message) {
    _failureMessage = message;
    _notify();
    return Future.value(false);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
