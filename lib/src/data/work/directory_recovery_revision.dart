import '../storage/local_record_store.dart';
import '../workday/sqlite_workday_repository.dart';
import 'directory_persistence_session.dart';
import 'employee_directory_profile.dart';
import 'vehicle_directory_profile.dart';
import 'work_contact_codec.dart';

enum DirectoryProfileKind { company, customer, employee, vehicle }

/// Minimal current state needed by recovery; no SQL rows or profile payloads.
class DirectoryRecoveryRevision {
  const DirectoryRecoveryRevision(
    this.profileRevision, {
    this.odometerRevision,
  });
  final int profileRevision;
  final int? odometerRevision;
}

extension DirectoryRecoveryRead on DirectoryPersistenceSession {
  Future<DirectoryRecoveryRevision> recoveryRevisionFor(
    DirectoryProfileKind kind,
    String recordId,
  ) async {
    final p = permissions;
    final allowed = switch (kind) {
      DirectoryProfileKind.company => p.canViewCompany && p.canManageCompany,
      DirectoryProfileKind.customer =>
        p.canViewCustomers && p.canManageCustomers,
      DirectoryProfileKind.employee =>
        p.canViewEmployees && p.canManageEmployees,
      DirectoryProfileKind.vehicle => p.canViewVehicles && p.canManageVehicles,
    };
    if (!allowed ||
        recordId.trim().isEmpty ||
        (kind == DirectoryProfileKind.company && recordId != 'company')) {
      throw StateError('Directory recovery is unavailable.');
    }
    final domain = switch (kind) {
      DirectoryProfileKind.company => 'directory/company',
      DirectoryProfileKind.customer => 'directory/customers',
      DirectoryProfileKind.employee => 'directory/employees',
      DirectoryProfileKind.vehicle => 'directory/vehicles',
    };
    return database.transaction(() async {
      final store = LocalRecordStore(database);
      final rows = await store.read(
        organizationId: p.organizationId,
        domain: domain,
        ownerIds: {p.organizationId},
        recordIds: {recordId},
      );
      final row = rows.singleOrNull;
      if (row != null) {
        final payload = store.decode(row);
        final decodedId = switch (kind) {
          DirectoryProfileKind.company => () {
            decodeWorkCompanyProfile(payload);
            return 'company';
          }(),
          DirectoryProfileKind.customer => decodeWorkCustomerProfile(
            payload,
          ).id,
          DirectoryProfileKind.employee => EmployeeDirectoryProfile.fromJson(
            payload,
          ).id,
          DirectoryProfileKind.vehicle => VehicleDirectoryProfile.fromJson(
            payload,
          ).id,
        };
        if (decodedId != recordId) {
          throw StateError('Stored profile identity is inconsistent.');
        }
      }
      int? odometerRevision;
      if (kind == DirectoryProfileKind.vehicle) {
        final readings = await store.read(
          organizationId: p.organizationId,
          domain: SqliteWorkdayRepository.odometersDomain,
          ownerIds: {recordId},
          recordIds: {recordId},
        );
        final reading = readings.singleOrNull;
        if (reading != null &&
            (reading.ownerId != recordId ||
                (store.decode(reading)['readingTenths'] as int) < 0)) {
          throw StateError('Stored mileage identity or reading is invalid.');
        }
        odometerRevision = reading?.revision ?? 0;
      }
      return DirectoryRecoveryRevision(
        row?.revision ?? 0,
        odometerRevision: odometerRevision,
      );
    });
  }
}
