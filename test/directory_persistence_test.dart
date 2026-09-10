import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_contact_codec.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'directory startup preserves customer locations and company defaults across reopen',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var directory = await openUiLabDirectory(database);
      var store = PrototypeOperationsStore(directorySession: directory);
      final source = store.customers.first;
      final changed = decodeWorkCustomerProfile({
        ...encodeWorkCustomerProfile(source),
        'notes': 'Saved access instructions',
        'locations': [
          {
            'label': 'Site one',
            'address': 'First address',
            'accessNotes': 'Gate code retained',
          },
          {
            'label': 'Site two',
            'address': 'Second address',
            'accessNotes': 'Call before arrival',
          },
        ],
      });
      expect(await store.replaceCustomers([changed]), isTrue);
      final count = store.customers.length;
      expect(
        await store.updateCompanyProfile(
          store.companyProfile.copyWith(
            defaultTerms: 'Specific saved terms',
            defaultCurrency: 'CAD',
          ),
        ),
        isTrue,
      );
      store.dispose();
      directory.dispose();
      await harness.close(database);
      database = await harness.open();
      directory = await openUiLabDirectory(database);
      store = PrototypeOperationsStore(directorySession: directory);
      addTearDown(directory.dispose);
      addTearDown(store.dispose);
      expect(store.customers, hasLength(count));
      expect(
        encodeWorkCustomerProfile(
          store.customers.singleWhere((value) => value.id == source.id),
        ),
        encodeWorkCustomerProfile(changed),
      );
      expect(store.companyProfile.defaultTerms, 'Specific saved terms');
      expect(store.companyProfile.defaultCurrency, 'CAD');
    },
  );

  test(
    'permission denial, organization isolation and stale directory writes preserve saved data',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final database = await harness.open();
      final owner = await openUiLabDirectory(database);
      addTearDown(owner.dispose);
      final denied = await DirectoryPersistenceSession.open(
        database,
        DirectoryPermissions(
          organizationId: owner.permissions.organizationId,
          actorEmployeeId: 'restricted',
          permissionRevision: 'denied',
        ),
      );
      addTearDown(denied.dispose);
      expect(denied.customers, isEmpty);
      expect(denied.company.companyName, isEmpty);
      expect(await denied.saveCustomer(owner.customers.first), isFalse);
      expect(await denied.saveCompany(owner.company), isFalse);
      final other = await DirectoryPersistenceSession.open(
        database,
        const DirectoryPermissions(
          organizationId: 'other-company',
          actorEmployeeId: 'owner',
          permissionRevision: 'other',
          canViewCustomers: true,
          canViewCompany: true,
        ),
      );
      addTearDown(other.dispose);
      expect(other.customers, isEmpty);
      expect(other.company.companyName, isEmpty);
      final second = await DirectoryPersistenceSession.open(
        database,
        owner.permissions,
      );
      addTearDown(second.dispose);
      final original = owner.customers.first;
      final first = decodeWorkCustomerProfile({
        ...encodeWorkCustomerProfile(original),
        'name': 'Latest saved name',
      });
      final stale = decodeWorkCustomerProfile({
        ...encodeWorkCustomerProfile(original),
        'name': 'Stale edit',
      });
      expect(await owner.saveCustomer(first), isTrue);
      expect(await second.saveCustomer(stale), isFalse);
      expect(
        owner.customers.singleWhere((value) => value.id == original.id).name,
        'Latest saved name',
      );
      expect(
        second.customers.singleWhere((value) => value.id == original.id).name,
        original.name,
      );
    },
  );
}
