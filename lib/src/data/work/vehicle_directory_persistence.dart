part of 'directory_persistence_session.dart';

extension VehicleDirectoryPersistence on DirectoryPersistenceSession {
  List<VehicleDirectoryProfile> get vehicles => permissions.canViewVehicles
      ? List.unmodifiable(_vehicles.values)
      : const [];
  int vehicleRevision(String id) =>
      permissions.canViewVehicles ? _vehicleVersions[id] ?? 0 : 0;
  ConfirmedVehicleOdometer? vehicleOdometer(String id) =>
      permissions.canViewVehicles ? _vehicleOdometers[id] : null;

  Future<bool> reloadVehicles() => _writes.run(() async {
    final snapshot = DirectoryPersistenceSession._(database, permissions);
    try {
      await database.transaction(snapshot._loadVehicles);
      _vehicles
        ..clear()
        ..addAll(snapshot._vehicles);
      _vehicleVersions
        ..clear()
        ..addAll(snapshot._vehicleVersions);
      _vehicleOdometers
        ..clear()
        ..addAll(snapshot._vehicleOdometers);
      _failureMessage = null;
      return true;
    } on Object {
      _failureMessage =
          'Vehicle information could not be loaded. Retry opening the directory.';
      return false;
    } finally {
      snapshot.dispose();
      _notify();
    }
  });

  Future<void> _loadVehicles() async {
    if (!permissions.canViewVehicles) return;
    final store = LocalRecordStore(database);
    for (final row in await store.read(
      organizationId: permissions.organizationId,
      domain: 'directory/vehicles',
      ownerIds: {permissions.organizationId},
    )) {
      final profile = VehicleDirectoryProfile.fromJson(store.decode(row));
      if (profile.id != row.recordId) {
        throw StateError('Saved vehicle identity is inconsistent.');
      }
      _vehicles[profile.id] = profile;
      _vehicleVersions[profile.id] = row.revision;
    }
    for (final row in await store.read(
      organizationId: permissions.organizationId,
      domain: SqliteWorkdayRepository.odometersDomain,
      ownerIds: _vehicles.keys.toSet(),
    )) {
      if (row.recordId != row.ownerId) {
        throw StateError('Saved vehicle odometer identity is inconsistent.');
      }
      final reading = store.decode(row)['readingTenths'] as int;
      if (reading < 0) throw StateError('Saved vehicle odometer is invalid.');
      _vehicleOdometers[row.recordId] = ConfirmedVehicleOdometer(
        reading,
        row.revision,
      );
    }
  }

  /// Company fleet management is explicit authority. This does not grant the
  /// current actor a workday, trip, inventory, or employee-assignment capability.
  /// Odometer changes share the workday record and its SQL revision boundary.
  Future<bool> saveVehicle(
    VehicleDirectoryProfile profile, {
    required int expectedRevision,
    int? odometerTenths,
    int? expectedOdometerRevision,
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    if (_disposed) return _reject('This session is no longer active.');
    if (!permissions.canViewVehicles || !permissions.canManageVehicles) {
      return _reject('You do not have permission to change vehicle records.');
    }
    return _writes.run(() async {
      try {
        final proposed = VehicleDirectoryProfile.fromJson(profile.toJson());
        if (vehicleRevision(profile.id) != expectedRevision) {
          throw const LocalRecordConflict(
            'Vehicle information changed. Reopen the saved profile before retrying.',
          );
        }
        if ((odometerTenths == null) != (expectedOdometerRevision == null) ||
            (odometerTenths != null &&
                (odometerTenths < 0 || odometerTenths > 99999990))) {
          throw StateError(
            'Enter a valid odometer reading and its original revision.',
          );
        }
        await database.transaction(() async {
          final writes = [
            _write(
              'directory/vehicles',
              proposed.id,
              expectedRevision,
              proposed.toJson(),
            ),
          ];
          if (odometerTenths != null) {
            final rows = await LocalRecordStore(database).read(
              organizationId: permissions.organizationId,
              domain: SqliteWorkdayRepository.odometersDomain,
              ownerIds: {proposed.id},
            );
            if (rows.length > 1 ||
                (rows.isNotEmpty && rows.single.recordId != proposed.id)) {
              throw StateError(
                'Saved vehicle odometer identity is inconsistent.',
              );
            }
            final current = rows.singleOrNull;
            final reading = current == null
                ? 0
                : LocalRecordStore(database).decode(current)['readingTenths']
                      as int;
            if ((current?.revision ?? 0) != expectedOdometerRevision ||
                odometerTenths < reading) {
              throw const LocalRecordConflict(
                'The confirmed odometer changed or decreased. Reopen the vehicle before retrying.',
              );
            }
            writes.add(
              LocalRecordWrite(
                domain: SqliteWorkdayRepository.odometersDomain,
                recordId: proposed.id,
                ownerId: proposed.id,
                expectedRevision: expectedOdometerRevision!,
                payload: {
                  'readingTenths': odometerTenths,
                  'source': 'vehicle-profile-confirmation',
                  'lastChangedByEmployeeId': permissions.actorEmployeeId,
                  'permissionRevision': permissions.permissionRevision,
                },
              ),
            );
          }
          await _commit(writes, draftCheckpoint);
        });
        _vehicles[proposed.id] = proposed;
        _vehicleVersions[proposed.id] = expectedRevision + 1;
        if (odometerTenths != null) {
          _vehicleOdometers[proposed.id] = ConfirmedVehicleOdometer(
            odometerTenths,
            expectedOdometerRevision! + 1,
          );
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
}
