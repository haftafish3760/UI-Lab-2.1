import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';

void main() {
  for (final kind in ['work', 'customer', 'company', 'employee', 'vehicle']) {
    for (final acceptedFirst in [false, true]) {
      test(
        '$kind ${acceptedFirst ? 'drains accepted' : 'rejects new'} write on disposal',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'write-admission-',
          );
          final persistence = await LocalPersistence.open(directory: root);
          final work = await openUiLabWorkSession(persistence.database);
          final directory = await openUiLabDirectory(persistence.database);
          final target = kind == 'work' ? work : directory;
          Future<bool> submit() => switch (kind) {
            'work' => work.update(
              work.records.first.copyWith(serviceLocation: 'Accepted location'),
            ),
            'customer' => directory.saveCustomer(directory.customers.first),
            'company' => directory.saveCompany(
              directory.company.copyWith(companyName: 'Accepted company'),
            ),
            'employee' => directory.saveEmployee(
              directory.employees.first,
              expectedRevision: directory.employeeRevision(
                directory.employees.first.id,
              ),
            ),
            _ => directory.saveVehicle(
              directory.vehicles.first,
              expectedRevision: directory.vehicleRevision(
                directory.vehicles.first.id,
              ),
            ),
          };
          try {
            final before = await persistence.database
                .customSelect(
                  'SELECT * FROM local_records ORDER BY organization_id, domain, record_id',
                )
                .get();
            if (!acceptedFirst) target.dispose();
            final pending = submit();
            if (acceptedFirst) target.dispose();
            expect(await pending, acceptedFirst);
            if (!acceptedFirst) {
              final after = await persistence.database
                  .customSelect(
                    'SELECT * FROM local_records ORDER BY organization_id, domain, record_id',
                  )
                  .get();
              expect(after.map((r) => r.data), before.map((r) => r.data));
            }
            await persistence.database.verifyIntegrity();
          } finally {
            if (kind == 'work') {
              directory.dispose();
            } else {
              work.dispose();
            }
            await persistence.close();
            await root.delete(recursive: true);
          }
        },
      );
    }
  }
}
