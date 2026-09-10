import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/company_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/vehicle_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/employee_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/directory_draft_workflows.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'support/storage/database_harness.dart';
import 'directory_draft_workflows_test.dart' show employeeInput;

VehicleDraftInput vehicleInput(String reading) => VehicleDraftInput(
  vehicleId: 'draft-input-vehicle',
  baseRevision: 0,
  odometerRevision: 0,
  active: true,
  name: '  Truck  ',
  model: '  Model  ',
  odometer: reading,
  assignment: '  Alex  ',
);
void main() {
  test(
    'company confirms recovered raw fields atomically and preserves unedited base fields',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var directory = await openUiLabDirectory(db);
      final input = CompanyDraftInput(
        baseProfile: directory.company,
        baseRevision: directory.companyRevision,
        logoLabel: 'Logo',
        name: '  Confirmed business  ',
        category: '  Service  ',
        phone: '  555  ',
        email: '  a@b.test  ',
        website: '  site.test  ',
        address: '  Address  ',
        terms: '  Terms  ',
      );
      var workflow = await directory.openCompanyDraft();
      workflow.updateInput(input);
      await workflow.session.close();
      directory.dispose();
      await harness.close(db);
      db = await harness.open();
      directory = await openUiLabDirectory(db);
      addTearDown(directory.dispose);
      workflow = await directory.openCompanyDraft();
      expect(workflow.session.input, input.toPayload());
      await db.customStatement(
        "CREATE TRIGGER fail_profile BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isNull);
      expect(directory.company.companyName, input.baseProfile.companyName);
      expect(workflow.session.input, input.toPayload());
      await db.customStatement('DROP TRIGGER fail_profile');
      final confirmed = (await workflow.confirm())!;
      expect(confirmed.companyName, 'Confirmed business');
      expect(confirmed.defaultTerms, 'Terms');
      expect(confirmed.defaultCurrency, input.baseProfile.defaultCurrency);
      expect(directory.companyRevision, input.baseRevision + 1);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );
  test(
    'vehicle confirmation derives exact mileage from saved input and rolls back both records',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var directory = await openUiLabDirectory(db);
      var workflow = await directory.openVehicleDraft();
      workflow.updateInput(vehicleInput('12.'));
      await expectLater(workflow.confirm(), throwsFormatException);
      expect(directory.vehicleRevision('draft-input-vehicle'), 0);
      workflow.updateInput(vehicleInput('1,234.5'));
      await workflow.session.close();
      directory.dispose();
      await harness.close(db);
      db = await harness.open();
      directory = await openUiLabDirectory(db);
      addTearDown(directory.dispose);
      workflow = await directory.openVehicleDraft();
      await db.customStatement(
        "CREATE TRIGGER fail_profile BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isNull);
      expect(directory.vehicleRevision('draft-input-vehicle'), 0);
      expect(directory.vehicleOdometer('draft-input-vehicle'), isNull);
      expect(workflow.recoveredInput!.odometer, '1,234.5');
      await db.customStatement('DROP TRIGGER fail_profile');
      final confirmed = (await workflow.confirm())!;
      expect(confirmed.name, 'Truck');
      expect(confirmed.assignment, 'Alex');
      expect(directory.vehicleOdometer(confirmed.id)!.readingTenths, 12345);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );
  test(
    'domain conversion enforces existing mileage syntax and employee capability consistency',
    () {
      expect(vehicleInput('').confirmedOdometerTenths(), isNull);
      expect(vehicleInput('9,999,999').confirmedOdometerTenths(), 99999990);
      for (final text in [
        '12.',
        '1,23',
        '1e3',
        '-1',
        '1.23',
        '10,000,000',
        '9,999,999.1',
      ]) {
        expect(
          () => vehicleInput(text).confirmedOdometerTenths(),
          throwsFormatException,
          reason: text,
        );
      }
      final invalid = EmployeeDraftInput.fromPayload({
        ...employeeInput().toPayload(),
        'canSeeEstimates': false,
        'canApproveEstimates': true,
      });
      expect(invalid.confirmedProfile, throwsFormatException);
      expect(employeeInput().confirmedProfile().pay, '12.');
    },
  );
}
