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

part 'work_job_conversion.dart';
part 'work_customer_approval_validation.dart';
part 'work_draft_deletion.dart';

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
          _validateCustomerApprovalChanges(record, current);
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
              for (final change in changes) {
                final saved = await repository.find(
                  organizationId: permissions.organizationId,
                  recordId: change.record.id,
                  visibleCreatorIds: permissions.visibleCreatorIds,
                );
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

  List<PrototypeFinancialEntry> _validateFinancial(
    List<PrototypeFinancialEntry> requested,
    List<WorkRecord> proposed,
  ) {
    final available = {
      ..._records,
      for (final record in proposed) record.id: record,
    };
    final accepted = <PrototypeFinancialEntry>[];
    final seen = <String>{};
    for (final entry in requested) {
      if (!seen.add(entry.id)) {
        throw StateError(
          'A financial entry cannot be submitted twice in one command.',
        );
      }
      final existing = _entries[entry.id];
      if (existing != null) {
        if (canonicalJson(encodeFinancialEntry(existing)) !=
            canonicalJson(encodeFinancialEntry(entry))) {
          throw const LocalRecordConflict(
            'This financial entry was already saved with different values.',
          );
        }
        continue;
      }
      final permitted = entry.kind == PrototypeFinancialKind.invoiceIssued
          ? permissions.canIssueInvoices
          : permissions.canRecordPayments;
      if (!permitted) {
        throw StateError(
          'You do not have permission to record this financial action.',
        );
      }
      final invoices = available.values
          .where(
            (record) =>
                record.kind == WorkRecordKind.invoice &&
                (record.id == entry.sourceId ||
                    record.number == entry.sourceId),
          )
          .toList();
      if (invoices.length != 1 || entry.amountCents <= 0) {
        throw StateError(
          'The financial entry needs one valid invoice and a positive amount.',
        );
      }
      final invoice = invoices.single;
      if (!permissions.visibleCreatorIds.contains(
            invoice.createdByEmployeeId,
          ) ||
          invoice.status == WorkRecordStatus.draft) {
        throw StateError('That invoice cannot receive this financial entry.');
      }
      final related = [..._entries.values, ...accepted].where(
        (item) =>
            item.sourceId == invoice.id || item.sourceId == invoice.number,
      );
      final totalCents = (invoice.total * 100).round();
      if (entry.kind == PrototypeFinancialKind.invoiceIssued) {
        if (entry.amountCents != totalCents ||
            related.any(
              (item) => item.kind == PrototypeFinancialKind.invoiceIssued,
            )) {
          throw StateError(
            'The invoice has already been issued or its amount changed.',
          );
        }
      } else {
        final paid = related
            .where(
              (item) => item.kind == PrototypeFinancialKind.paymentReceived,
            )
            .fold(0, (sum, item) => sum + item.amountCents);
        if (entry.amountCents > totalCents - paid) {
          throw StateError('The payment exceeds the current invoice balance.');
        }
      }
      accepted.add(entry);
    }
    return accepted;
  }

  void _validateInvoiceTransitions(
    List<WorkRecord> proposed,
    List<PrototypeFinancialEntry> entries,
  ) {
    for (final next in proposed) {
      final previous = _records[next.id];
      if (previous != null && previous.kind != next.kind) {
        throw StateError('A Work record cannot change its record type.');
      }
      if (next.kind != WorkRecordKind.invoice) continue;
      if (previous == null && next.status != WorkRecordStatus.draft) {
        throw StateError('A new invoice must begin as a draft.');
      }
      final related = entries.where(
        (entry) => entry.sourceId == next.id || entry.sourceId == next.number,
      );
      if (previous?.status == WorkRecordStatus.draft &&
          next.status != WorkRecordStatus.draft) {
        if (!permissions.canIssueInvoices ||
            next.status != WorkRecordStatus.due ||
            !related.any(
              (entry) => entry.kind == PrototypeFinancialKind.invoiceIssued,
            )) {
          throw StateError(
            'Issue the invoice through its authorized financial command.',
          );
        }
      }
      if (previous != null && previous.status != WorkRecordStatus.draft) {
        final before = encodeWorkRecord(previous)..remove('status');
        final after = encodeWorkRecord(next)..remove('status');
        if (canonicalJson(before) != canonicalJson(after)) {
          throw StateError('An issued invoice cannot be silently rewritten.');
        }
        if (next.status != previous.status &&
            next.status != WorkRecordStatus.paid) {
          throw StateError('Use an explicit invoice correction workflow.');
        }
      }
      if (next.status == WorkRecordStatus.paid &&
          previous?.status != WorkRecordStatus.paid) {
        final paid = [..._entries.values, ...entries]
            .where(
              (entry) =>
                  entry.kind == PrototypeFinancialKind.paymentReceived &&
                  (entry.sourceId == next.id || entry.sourceId == next.number),
            )
            .fold(0, (sum, entry) => sum + entry.amountCents);
        if (!permissions.canRecordPayments ||
            paid != (next.total * 100).round()) {
          throw StateError(
            'Only confirmed payments can mark this invoice paid.',
          );
        }
      }
    }
  }

  void _appendInvoicePaymentRevisions(
    List<WorkRecordMutation> changes,
    List<PrototypeFinancialEntry> entries,
  ) {
    for (final entry in entries.where(
      (entry) => entry.kind == PrototypeFinancialKind.paymentReceived,
    )) {
      final invoice = _records.values.singleWhere(
        (record) =>
            record.kind == WorkRecordKind.invoice &&
            (record.id == entry.sourceId || record.number == entry.sourceId),
      );
      final paid = [..._entries.values, ...entries]
          .where(
            (item) =>
                item.kind == PrototypeFinancialKind.paymentReceived &&
                (item.sourceId == invoice.id ||
                    item.sourceId == invoice.number),
          )
          .fold(0, (sum, item) => sum + item.amountCents);
      // Even a partial payment advances this shared invoice revision. Separate
      // sessions must not both post against the same stale balance snapshot.
      if (!changes.any((change) => change.record.id == invoice.id)) {
        changes.add(
          WorkRecordMutation(
            record: paid == (invoice.total * 100).round()
                ? invoice.copyWith(status: WorkRecordStatus.paid)
                : invoice,
            expectedStorageRevision: _versions[invoice.id]!,
          ),
        );
      }
    }
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
