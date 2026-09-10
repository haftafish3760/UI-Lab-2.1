import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/customer_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/customer_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/customer_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';

import 'support/storage/database_harness.dart';

const original = WorkCustomerProfile(
  id: 'workflow-client',
  name: 'Original',
  companyName: '',
  phone: '',
  email: '',
  preferredContact: 'Phone call',
  billingAddress: '',
  notes: '',
  linkedRecordCount: 3,
  locations: [
    WorkServiceLocation(label: 'Main', address: 'First', accessNotes: ''),
    WorkServiceLocation(
      label: 'Warehouse',
      address: 'Second',
      accessNotes: 'Call ahead',
    ),
  ],
);

CustomerDraftInput inputFor({
  bool existing = true,
  String name = ' Changed name ',
}) => CustomerDraftInput(
  customerId: original.id,
  existingCustomer: existing ? original : null,
  baseRevision: existing ? 1 : 0,
  preferredContact: 'Phone call',
  name: name,
  company: '',
  phone: '+1 (',
  email: 'pending@',
  billing: '',
  notes: ' Notes ',
  locationLabel: '',
  locationAddress: ' Changed address ',
  accessNotes: ' Primary instructions ',
);

void main() {
  test(
    'client recovery preserves extra locations through failure, retry and stale submit',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var directory = await openUiLabDirectory(database);
      expect(
        await directory.saveCustomer(original, expectedRevision: 0),
        isTrue,
      );
      var controller = await directory.openCustomerDraft(
        existingCustomerId: original.id,
      );
      final draftId = controller.session.draftId;
      controller.updateInput(inputFor());
      await controller.session.close();
      directory.dispose();
      await harness.close(database);
      database = await harness.open();
      directory = await openUiLabDirectory(database);
      addTearDown(directory.dispose);
      controller = await directory.openCustomerDraft(
        existingCustomerId: original.id,
      );
      expect(controller.session.draftId, draftId);
      expect(controller.recoveredInput!.phone, '+1 (');
      expect(
        controller.recoveredInput!.existingCustomer!.locations,
        hasLength(2),
      );
      final stale = await directory.openCustomerDraft(
        existingCustomerId: original.id,
      );
      await database.customStatement(
        "CREATE TRIGGER reject_client BEFORE UPDATE ON local_records WHEN NEW.record_id = 'workflow-client' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect(await controller.confirm(), isNull);
      expect(directory.customerRevision(original.id), 1);
      expect(controller.recoveredInput!.email, 'pending@');
      await database.customStatement('DROP TRIGGER reject_client');
      final customer = await controller.confirm();
      expect(customer!.name, 'Changed name');
      expect(customer.locations, hasLength(2));
      expect(customer.locations.first.label, 'Primary service location');
      expect(customer.locations.first.address, 'Changed address');
      expect(customer.locations.last.label, 'Warehouse');
      expect(customer.locations.last.accessNotes, 'Call ahead');
      expect(customer.linkedRecordCount, 3);
      await expectLater(controller.confirm(), throwsStateError);
      expect(await stale.confirm(), isNull);
      expect(directory.customerRevision(original.id), 2);
      expect(
        await directory.drafts.find(
          organizationId: directory.permissions.organizationId,
          ownerId: directory.permissions.actorEmployeeId,
          domain: 'directory/customer-editor',
          draftId: draftId,
        ),
        isNull,
      );
      await controller.session.close();
      await stale.session.close();
    },
  );

  test(
    'missing name retains unfinished contact input and allows correction',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final directory = await openUiLabDirectory(await harness.open());
      addTearDown(directory.dispose);
      final controller = await directory.openCustomerDraft();
      controller.updateInput(inputFor(existing: false, name: ''));
      await expectLater(
        controller.confirm(),
        throwsA(isA<CustomerInputValidation>()),
      );
      expect(controller.recoveredInput!.email, 'pending@');
      controller.updateInput(inputFor(existing: false));
      expect((await controller.confirm())!.name, 'Changed name');
      await controller.session.close();
      await expectLater(
        directory.openCustomerDraft(recoveryDraftId: 'missing'),
        throwsStateError,
      );
      await expectLater(
        directory.openCustomerDraft(existingCustomerId: 'missing'),
        throwsStateError,
      );
    },
  );
}
