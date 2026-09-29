import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_delivery_draft_workflow.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';

WorkCustomerProfile client(String id, String email, String address) =>
    WorkCustomerProfile(
      id: id,
      name: 'Alex Morgan',
      companyName: '',
      phone: '5551234567',
      email: email,
      preferredContact: 'Email',
      billingAddress: address,
      locations: const [],
      notes: '',
      linkedRecordCount: 0,
    );

void main() {
  final first = client('client-a', 'first@example.test', '1 First Street');
  final second = client('client-b', 'second@example.test', '2 Second Street');
  WorkRecord record({
    String name = 'Alex Morgan',
    WorkCustomerProfile? snapshot,
  }) => WorkRecord(
    id: 'estimate',
    kind: WorkRecordKind.estimate,
    number: 'EST-1',
    title: 'Office cleaning',
    client: name,
    customerSnapshot: snapshot,
    detail: 'Clean the office',
    pricing: WorkPricingModel.flatRate,
    total: 100,
  );
  final legacy = record();
  test(
    'ambiguous legacy name does not select either email, phone, or billing address',
    () {
      expect(legacy.customerSnapshot, isNull);
      for (final directory in [
        [first, second],
        [second, first],
      ]) {
        final selected = resolveWorkDocumentCustomer(legacy, directory);
        expect(selected, isNull);
        expect(
          estimateDeliveryRecipient(
            legacy,
            EstimateDeliveryMethod.email,
            directory,
          ),
          isEmpty,
        );
        expect(
          estimateDeliveryRecipient(
            legacy,
            EstimateDeliveryMethod.textMessage,
            directory,
          ),
          isEmpty,
        );
        final pdf = workCustomerDocument(legacy, demoWorkCompany, selected);
        expect(pdf.customerDetails, isNot(contains('First Street')));
        expect(pdf.customerDetails, isNot(contains('Second Street')));
      }
    },
  );
  test(
    'saved snapshot stays authoritative after directory edits and with duplicate names',
    () {
      final saved = record(snapshot: second);
      final directory = [first, second.copyWith(email: 'changed@example.test')];
      expect(resolveWorkDocumentCustomer(saved, directory), same(second));
      expect(
        estimateDeliveryRecipient(
          saved,
          EstimateDeliveryMethod.email,
          directory,
        ),
        'second@example.test',
      );
      expect(
        workCustomerDocument(saved, demoWorkCompany, first).customerDetails,
        contains('2 Second Street'),
      );
    },
  );
  test('unique exact-name legacy match remains available', () {
    expect(resolveWorkDocumentCustomer(legacy, [first]), same(first));
    expect(
      estimateDeliveryRecipient(legacy, EstimateDeliveryMethod.email, [first]),
      'first@example.test',
    );
    expect(resolveWorkDocumentCustomer(record(name: ''), [first]), isNull);
  });
}
