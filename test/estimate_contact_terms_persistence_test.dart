import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_contact_codec.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'support/storage/database_harness.dart';

void main() {
  test('reusable terms and default survive directory reopen', () async {
    final harness = await DatabaseHarness.create();
    addTearDown(harness.dispose);
    final db = await harness.open();
    final directory = await openUiLabDirectory(db);
    addTearDown(directory.dispose);
    final company = directory.company.copyWith(
      companyName: 'Test Business',
      defaultEstimateTerms: 'Additional work requires prior approval.',
      estimateTermsTemplates: {'Repairs': 'The listed scope only.'},
    );
    expect(await directory.saveCompany(company), isTrue);
    final reopened = await openUiLabDirectory(await harness.open());
    addTearDown(reopened.dispose);
    expect(reopened.company.defaultEstimateTerms, company.defaultEstimateTerms);
    expect(
      reopened.company.estimateTermsTemplates,
      company.estimateTermsTemplates,
    );
    final decoded = decodeWorkCompanyProfile(encodeWorkCompanyProfile(company));
    expect(decoded.defaultEstimateTerms, company.defaultEstimateTerms);
    expect(decoded.estimateTermsTemplates, company.estimateTermsTemplates);
  });
  test('one-off customer remains attached without a directory lookup', () {
    const customer = WorkCustomerProfile(
      id: 'one-off',
      name: 'Alex',
      companyName: '',
      phone: '(202) 555-0101',
      email: 'alex@example.com',
      preferredContact: 'Email',
      billingAddress: '123 Test St',
      locations: [],
      notes: '',
      linkedRecordCount: 0,
    );
    const record = WorkRecord(
      id: 'estimate',
      kind: WorkRecordKind.estimate,
      number: 'EST-1',
      title: 'Shelf',
      client: 'Alex',
      customerSnapshot: customer,
      detail: 'Build shelf',
      pricing: WorkPricingModel.flatRate,
    );
    final restored = decodeWorkRecord(encodeWorkRecord(record));
    expect(restored.customerSnapshot!.email, 'alex@example.com');
    expect(restored.customerSnapshot!.phone, '(202) 555-0101');
    expect(restored.customerSnapshot!.billingAddress, '123 Test St');
  });
}
