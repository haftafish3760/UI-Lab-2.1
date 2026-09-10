part of 'directory_persistence_session.dart';

extension EmployeeDirectoryPersistence on DirectoryPersistenceSession {
  List<EmployeeDirectoryProfile> get employees => permissions.canViewEmployees
      ? List.unmodifiable(_employees.values)
      : const [];
  int employeeRevision(String id) =>
      permissions.canViewEmployees ? _employeeVersions[id] ?? 0 : 0;

  Future<void> _loadEmployees() async {
    if (!permissions.canViewEmployees) return;
    final store = LocalRecordStore(database);
    for (final row in await store.read(
      organizationId: permissions.organizationId,
      domain: 'directory/employees',
      ownerIds: {permissions.organizationId},
    )) {
      final profile = EmployeeDirectoryProfile.fromJson(store.decode(row));
      if (profile.id != row.recordId) {
        throw StateError('Saved employee identity is inconsistent.');
      }
      _employees[profile.id] = profile;
      _employeeVersions[profile.id] = row.revision;
    }
  }

  Future<bool> saveEmployee(
    EmployeeDirectoryProfile profile, {
    required int expectedRevision,
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    if (_disposed) return _reject('This session is no longer active.');
    if (!permissions.canViewEmployees || !permissions.canManageEmployees) {
      return _reject('You do not have permission to change employee records.');
    }
    return _writes.run(() async {
      try {
        final proposed = EmployeeDirectoryProfile.fromJson(profile.toJson());
        if (employeeRevision(profile.id) != expectedRevision) {
          throw const LocalRecordConflict(
            'Employee information changed. Reopen the saved profile before retrying.',
          );
        }
        // Keep the SQL CAS check even when the submitted fields appear equal:
        // another open session may already have advanced this record.
        await _commit([
          _write(
            'directory/employees',
            profile.id,
            expectedRevision,
            proposed.toJson(),
          ),
        ], draftCheckpoint);
        _employees[profile.id] = proposed;
        _employeeVersions[profile.id] = expectedRevision + 1;
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
}
