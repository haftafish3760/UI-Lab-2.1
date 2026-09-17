import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/employee_directory_demo.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/vehicle_directory_demo.dart';
import 'package:ui_lab_2_1/src/data/work/work_contact_codec.dart';

/// Explicit test data, independent of the application's demo-data flag.
/// One transaction installs the fixture once; reopen cannot overwrite edits or
/// resurrect a deliberately deleted record. Only use with a test-owned database.
Future<DirectoryPersistenceSession> openSeededTestDirectory(
  LocalDatabase database,
) async {
  const markerKey = 'test-directory-fixture-v1';
  const organization = expenseUiLabOrganizationId;
  await database.transaction(() async {
    final marker = await (database.select(
      database.localMetadata,
    )..where((row) => row.metadataKey.equals(markerKey))).getSingleOrNull();
    if (marker != null) return;
    await LocalRecordStore(database).commit(
      organizationId: organization,
      commandId: markerKey,
      occurredAt: DateTime.utc(2026, 9, 1),
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
        for (final employee in demoEmployeeDirectoryProfiles)
          LocalRecordWrite(
            domain: 'directory/employees',
            recordId: employee.id,
            ownerId: organization,
            expectedRevision: 0,
            payload: employee.toJson(),
          ),
        for (final vehicle in demoVehicleDirectoryProfiles)
          LocalRecordWrite(
            domain: 'directory/vehicles',
            recordId: vehicle.id,
            ownerId: organization,
            expectedRevision: 0,
            payload: vehicle.toJson(),
          ),
      ],
    );
    await database
        .into(database.localMetadata)
        .insert(
          LocalMetadataCompanion.insert(metadataKey: markerKey, value: '1'),
        );
  });
  return openUiLabDirectory(database);
}
