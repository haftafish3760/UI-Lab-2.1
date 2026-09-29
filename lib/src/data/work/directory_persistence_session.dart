import '../storage/local_attachment_store.dart';
import '../storage/draft_recovery_query.dart';
import '../storage/draft_repository.dart';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import 'models/work_contact_models.dart';
import '../storage/local_database.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_draft_store.dart';
import '../storage/local_record_command.dart';
import '../storage/local_record_identity.dart';
import '../storage/local_record_store.dart';
import '../storage/serialized_async_actions.dart';
import 'directory_permissions.dart';
import 'employee_directory_profile.dart';
import 'vehicle_directory_profile.dart';
import '../workday/sqlite_workday_repository.dart';

import 'work_contact_codec.dart';

part 'employee_directory_persistence.dart';
part 'vehicle_directory_persistence.dart';

/// Company-scoped contact directory. Confirmed cache changes follow disk commit.
/// UI view/context labels cannot grant read or mutation authority.
class DirectoryPersistenceSession extends ChangeNotifier {
  DirectoryPersistenceSession._(this.database, this.permissions);
  final LocalDatabase database;
  DraftRepository get drafts {
    requireActiveDraftOwner();
    return LocalDraftStore(database);
  }

  /// Recheck after asynchronous loading before publishing recovered state.
  void requireActiveDraftOwner() {
    if (_disposed) {
      throw StateError('The directory session is no longer active.');
    }
  }

  final DirectoryPermissions permissions;
  final _customers = <String, WorkCustomerProfile>{};
  final _employees = <String, EmployeeDirectoryProfile>{};
  final _employeeVersions = <String, int>{};
  final _vehicles = <String, VehicleDirectoryProfile>{};
  final _vehicleVersions = <String, int>{};
  final _vehicleOdometers = <String, ConfirmedVehicleOdometer>{};
  final _versions = <String, int>{};
  final _writes = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _writes.pauseAndDrain();
  WorkCompanyProfile _company = emptyCompanyProfile;
  int _companyRevision = 0;
  String? _failureMessage;
  bool _disposed = false;

  UnmodifiableListView<WorkCustomerProfile> get customers =>
      UnmodifiableListView(_customers.values);
  WorkCompanyProfile get company => _company;
  String? get failureMessage => _failureMessage;
  int customerRevision(String id) => _versions[id] ?? 0;
  int get companyRevision => _companyRevision;

  DraftRecoveryQuery get customerDraftRecovery {
    if (_disposed ||
        !permissions.canViewCustomers ||
        !permissions.canManageCustomers) {
      throw StateError('Customer recovery is unavailable.');
    }
    return DraftRecoveryQuery(
      canList: () =>
          !_disposed &&
          permissions.canViewCustomers &&
          permissions.canManageCustomers,
      repository: drafts,
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      domain: 'directory/customer-editor',
      parentField: 'existingCustomer',
      labelField: 'name',
      emptyLabel: 'Unnamed client',
    );
  }

  static Future<DirectoryPersistenceSession> open(
    LocalDatabase database,
    DirectoryPermissions permissions,
  ) => database.transaction(() async {
    final session = DirectoryPersistenceSession._(database, permissions);
    final records = LocalRecordStore(database);
    if (permissions.canViewCustomers) {
      for (final row in await records.read(
        organizationId: permissions.organizationId,
        domain: 'directory/customers',
        ownerIds: {permissions.organizationId},
      )) {
        final customer = decodeWorkCustomerProfile(records.decode(row));
        if (customer.id != row.recordId) {
          throw StateError('Saved customer identity is inconsistent.');
        }
        session._customers[customer.id] = customer;
        session._versions[customer.id] = row.revision;
      }
    }
    if (permissions.canViewCompany) {
      final rows = await records.read(
        organizationId: permissions.organizationId,
        domain: 'directory/company',
        ownerIds: {permissions.organizationId},
      );
      if (rows.length > 1 ||
          (rows.isNotEmpty && rows.single.recordId != 'company')) {
        throw StateError('Saved company identity is inconsistent.');
      }
      if (rows.isNotEmpty) {
        session._company = decodeWorkCompanyProfile(
          records.decode(rows.single),
        );
        session._companyRevision = rows.single.revision;
      }
    }
    await session._loadEmployees();
    await session._loadVehicles();
    return session;
  });

  Future<bool> saveCustomer(
    WorkCustomerProfile customer, {
    int? expectedRevision,
    LocalDraftCheckpoint? draftCheckpoint,
  }) => saveCustomers(
    [customer],
    expectedRevisions: expectedRevision == null
        ? null
        : {customer.id: expectedRevision},
    draftCheckpoint: draftCheckpoint,
  );

  /// Compatibility callers submit a directory list. Omission is not deletion:
  /// customer removal/merge requires a separate authorized retention workflow.
  Future<bool> saveCustomers(
    List<WorkCustomerProfile> customers, {
    Map<String, int>? expectedRevisions,
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    if (_disposed) return _reject('This session is no longer active.');
    if (!permissions.canViewCustomers || !permissions.canManageCustomers) {
      return _reject('You do not have permission to change customers.');
    }
    final proposed = customers
        .map(
          (value) =>
              decodeWorkCustomerProfile(encodeWorkCustomerProfile(value)),
        )
        .toList();
    final expected = {
      for (final value in proposed)
        value.id: expectedRevisions?[value.id] ?? customerRevision(value.id),
    };
    return _writes.run(() async {
      try {
        if (proposed.map((value) => value.id).toSet().length !=
                proposed.length ||
            proposed.any(
              (value) => value.id.trim().isEmpty || value.name.trim().isEmpty,
            )) {
          throw StateError('Customers need unique identities and a name.');
        }
        final changes = <WorkCustomerProfile>[];
        for (final value in proposed) {
          if (customerRevision(value.id) != expected[value.id]) {
            throw const LocalRecordConflict(
              'This customer changed. Reopen the latest saved record before retrying.',
            );
          }
          final current = _customers[value.id];
          if (current == null ||
              canonicalJson(encodeWorkCustomerProfile(current)) !=
                  canonicalJson(encodeWorkCustomerProfile(value))) {
            changes.add(value);
          }
        }
        await _commit(
          [
            for (final value in changes)
              _write(
                'directory/customers',
                value.id,
                expected[value.id]!,
                encodeWorkCustomerProfile(value),
              ),
          ],
          draftCheckpoint,
          expectedRecords: [
            for (final value in proposed)
              (
                domain: 'directory/customers',
                recordId: value.id,
                revision: expected[value.id]!,
              ),
          ],
        );
        for (final value in changes) {
          _customers[value.id] = value;
          _versions[value.id] = expected[value.id]! + 1;
        }
        _failureMessage = null;
        return true;
      } on Object catch (error) {
        _recordFailure(error);
        return false;
      } finally {
        _notify();
      }
    });
  }

  Future<bool> saveCompany(
    WorkCompanyProfile company, {
    int? expectedRevision,
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    if (_disposed) return _reject('This session is no longer active.');
    if (!permissions.canViewCompany || !permissions.canManageCompany) {
      return _reject(
        'You do not have permission to change company information.',
      );
    }
    final proposed = decodeWorkCompanyProfile(
      encodeWorkCompanyProfile(company),
    );
    final expected = expectedRevision ?? _companyRevision;
    return _writes.run(() async {
      try {
        // Admission above owns the lifecycle check. Disposal must not cancel
        // an already accepted write while it waits behind another operation.
        if (proposed.logoReference.isNotEmpty &&
            proposed.logoReference != _company.logoReference) {
          await LocalAttachmentStore(database).verifiedFiles(
            organizationId: permissions.organizationId,
            ownerIds: {permissions.organizationId},
            attachmentIds: {proposed.logoReference},
          );
        }
        if (proposed.companyName.trim().isEmpty) {
          throw StateError('Enter the company name.');
        }
        if (expected != _companyRevision) {
          throw const LocalRecordConflict(
            'Company information changed. Reopen its latest saved version before retrying.',
          );
        }
        final changed =
            canonicalJson(encodeWorkCompanyProfile(proposed)) !=
            canonicalJson(encodeWorkCompanyProfile(_company));
        await _commit(
          [
            if (changed)
              _write(
                'directory/company',
                'company',
                expected,
                encodeWorkCompanyProfile(proposed),
              ),
          ],
          draftCheckpoint,
          expectedRecords: [
            (
              domain: 'directory/company',
              recordId: 'company',
              revision: expected,
            ),
          ],
        );
        if (changed) {
          _company = proposed;
          _companyRevision = expected + 1;
        }
        _failureMessage = null;
        return true;
      } on Object catch (error) {
        _recordFailure(error);
        return false;
      } finally {
        _notify();
      }
    });
  }

  LocalRecordWrite _write(
    String domain,
    String id,
    int revision,
    Map<String, Object?> payload,
  ) => LocalRecordWrite(
    domain: domain,
    recordId: id,
    ownerId: permissions.organizationId,
    expectedRevision: revision,
    payload: {
      ...payload,
      'mutationActor': permissions.actorEmployeeId,
      'permissionRevision': permissions.permissionRevision,
    },
  );

  Future<void> _commit(
    List<LocalRecordWrite> writes,
    LocalDraftCheckpoint? draft, {
    Iterable<({String domain, String recordId, int revision})> expectedRecords =
        const [],
  }) => database.transaction(() async {
    if (permissions.actorEmployeeId.trim().isEmpty ||
        permissions.permissionRevision.trim().isEmpty) {
      throw StateError('The current account authority is unavailable.');
    }
    // Cached equality does not prove an unchanged database record. Check all
    // confirmed inputs in this same transaction, before consuming any draft.
    for (final expected in expectedRecords) {
      final row =
          await (database.select(database.localRecords)..where(
                (row) =>
                    row.organizationId.equals(permissions.organizationId) &
                    row.domain.equals(expected.domain) &
                    row.recordId.equals(expected.recordId) &
                    row.ownerId.equals(permissions.organizationId),
              ))
              .getSingleOrNull();
      if ((row?.revision ?? 0) != expected.revision) {
        throw const LocalRecordConflict(
          'Saved information changed in another session. Your recovery input has been preserved.',
        );
      }
    }
    if (draft != null &&
        !await LocalDraftStore(database).consumeIfUnchanged(
          organizationId: permissions.organizationId,
          domain: draft.domain,
          draftId: draft.draftId,
          ownerId: permissions.actorEmployeeId,
          expectedRevision: draft.revision,
        )) {
      throw const LocalRecordConflict(
        'The recovery draft changed. Its latest saved input was preserved.',
      );
    }
    if (writes.isNotEmpty) {
      await LocalRecordStore(database).commit(
        organizationId: permissions.organizationId,
        commandId: newLocalRecordIdentity('directory-command'),
        writes: writes,
        occurredAt: DateTime.now().toUtc(),
      );
    }
  });

  void _recordFailure(Object error) {
    _failureMessage = switch (error) {
      LocalRecordConflict() => error.message,
      StateError() => error.message.toString(),
      _ =>
        'The changes were not saved. Your last saved information is unchanged. Please retry.',
    };
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

const emptyCompanyProfile = WorkCompanyProfile(
  companyName: '',
  businessCategory: '',
  phone: '',
  email: '',
  website: '',
  address: '',
  logoLabel: '',
  defaultTerms: '',
  defaultCurrency: '',
);
