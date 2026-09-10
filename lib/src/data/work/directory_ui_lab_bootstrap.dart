import 'models/work_contact_models.dart';
import '../expenses/expense_ui_lab_policy.dart';
import '../storage/local_database.dart';
import '../storage/local_record_command.dart';
import '../storage/local_record_store.dart';
import 'directory_permissions.dart';
import 'employee_directory_demo.dart';
import 'vehicle_directory_demo.dart';
import 'directory_persistence_session.dart';
import 'work_contact_codec.dart';

Future<DirectoryPersistenceSession> openUiLabDirectory(
  LocalDatabase database,
) async {
  const organization = expenseUiLabOrganizationId;
  await database.transaction(() async {
    final marker =
        await (database.select(database.localMetadata)..where(
              (row) => row.metadataKey.equals('ui-lab-directory-demo-seed'),
            ))
            .getSingleOrNull();
    if (marker != null) return;
    await LocalRecordStore(database).commit(
      organizationId: organization,
      commandId: 'ui-lab-directory-demo-seed-1',
      occurredAt: DateTime.now().toUtc(),
      writes: [
        for (final customer in demoWorkCustomers)
          LocalRecordWrite(
            domain: 'directory/customers',
            recordId: customer.id,
            ownerId: organization,
            expectedRevision: 0,
            payload: encodeWorkCustomerProfile(customer),
          ),
        LocalRecordWrite(
          domain: 'directory/company',
          recordId: 'company',
          ownerId: organization,
          expectedRevision: 0,
          payload: encodeWorkCompanyProfile(demoWorkCompany),
        ),
      ],
    );
    await database
        .into(database.localMetadata)
        .insert(
          LocalMetadataCompanion.insert(
            metadataKey: 'ui-lab-directory-demo-seed',
            value: '1',
          ),
        );
  });
  await database.transaction(() async {
    const key = 'ui-lab-employee-directory-demo-seed';
    final marker = await (database.select(
      database.localMetadata,
    )..where((row) => row.metadataKey.equals(key))).getSingleOrNull();
    if (marker != null) return;
    await LocalRecordStore(database).commit(
      organizationId: organization,
      commandId: '$key-1',
      occurredAt: DateTime.now().toUtc(),
      writes: [
        for (final employee in demoEmployeeDirectoryProfiles)
          LocalRecordWrite(
            domain: 'directory/employees',
            recordId: employee.id,
            ownerId: organization,
            expectedRevision: 0,
            payload: employee.toJson(),
          ),
      ],
    );
    await database
        .into(database.localMetadata)
        .insert(LocalMetadataCompanion.insert(metadataKey: key, value: '1'));
  });
  await database.transaction(() async {
    const key = 'ui-lab-vehicle-directory-demo-seed';
    final marker = await (database.select(
      database.localMetadata,
    )..where((row) => row.metadataKey.equals(key))).getSingleOrNull();
    if (marker != null) return;
    await LocalRecordStore(database).commit(
      organizationId: organization,
      commandId: '$key-1',
      occurredAt: DateTime.now().toUtc(),
      writes: [
        for (final profile in demoVehicleDirectoryProfiles)
          LocalRecordWrite(
            domain: 'directory/vehicles',
            recordId: profile.id,
            ownerId: organization,
            expectedRevision: 0,
            payload: profile.toJson(),
          ),
      ],
    );
    await database
        .into(database.localMetadata)
        .insert(LocalMetadataCompanion.insert(metadataKey: key, value: '1'));
  });
  // Explicit development authority; this is not production authentication.
  return DirectoryPersistenceSession.open(
    database,
    const DirectoryPermissions(
      organizationId: organization,
      actorEmployeeId: expenseUiLabOwnerEmployeeId,
      permissionRevision: 'ui-lab-directory-owner-1',
      canViewCustomers: true,
      canManageCustomers: true,
      canViewCompany: true,
      canManageCompany: true,
      canViewEmployees: true,
      canManageEmployees: true,
      canViewVehicles: true,
      canManageVehicles: true,
    ),
  );
}
