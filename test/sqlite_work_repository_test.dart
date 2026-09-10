import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_contact_codec.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/screens/work/work_contact_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';

import 'support/storage/database_harness.dart';

void main() {
  late DatabaseHarness harness;
  setUp(() async => harness = await DatabaseHarness.create());
  tearDown(() async => harness.dispose());

  test('every stored Work field has an explicit persistence key', () {
    final source = File(
      'lib/src/data/work/models/work_models.dart',
    ).readAsStringSync();
    final classBody = source
        .split('class WorkRecord {')
        .last
        .split('\n}')
        .first;
    final fields = RegExp(
      r'^  final [\w<>?]+ (\w+);',
      multiLine: true,
    ).allMatches(classBody).map((match) => match.group(1)!).toSet();
    expect(
      fields,
      isNotEmpty,
      reason: 'Inspect the owning WorkRecord declaration.',
    );
    final encoded = encodeWorkRecord(prototypeDemoWorkRecords().first);
    expect(
      encoded.keys.toSet(),
      fields,
      reason: 'New Work fields must not silently disappear during persistence.',
    );
  });

  test(
    'Work records and nested details survive physical database reopening',
    () async {
      var database = await harness.open();
      var repository = SqliteWorkRepository(database);
      final records = prototypeDemoWorkRecords();
      await repository.commit(
        organizationId: 'business',
        commandId: 'initial-work',
        actorEmployeeId: 'owner',
        permissionRevision: 'local-owner-v1',
        occurredAt: DateTime.utc(2026, 9, 9),
        mutations: records
            .map(
              (record) => WorkRecordMutation(
                record: record,
                expectedStorageRevision: 0,
              ),
            )
            .toList(),
      );
      await harness.close(database);
      database = await harness.open();
      repository = SqliteWorkRepository(database);
      final restored = await repository.query(
        organizationId: 'business',
        visibleCreatorIds: records.map((r) => r.createdByEmployeeId).toSet(),
      );
      expect(
        restored.map((r) => r.record.id).toSet(),
        records.map((r) => r.id).toSet(),
      );
      for (final original in records) {
        final saved = restored.singleWhere((r) => r.record.id == original.id);
        expect(saved.storageRevision, 1);
        expect(saved.record.number, original.number);
        expect(saved.record.total, original.total);
        expect(saved.record.createdOn, original.createdOn);
        expect(saved.record.terms, original.terms);
        expect(saved.record.items.length, original.items.length);
        expect(encodeWorkRecord(saved.record), encodeWorkRecord(original));
      }
      expect(
        await repository.query(
          organizationId: 'other',
          visibleCreatorIds: {'alex'},
        ),
        isEmpty,
      );
      expect(
        await repository.find(
          organizationId: 'business',
          recordId: records.first.id,
          visibleCreatorIds: {'unrelated'},
        ),
        isNull,
      );
    },
  );

  test(
    'operational edits preserve document revision and reject stale storage revision',
    () async {
      final database = await harness.open();
      final repository = SqliteWorkRepository(database);
      final original = prototypeDemoWorkRecords().first;
      Future<void> commit(String id, WorkRecord record, int revision) =>
          repository.commit(
            organizationId: 'business',
            commandId: id,
            actorEmployeeId: 'owner',
            permissionRevision: 'local-owner-v1',
            occurredAt: DateTime.utc(2026, 9, 9),
            mutations: [
              WorkRecordMutation(
                record: record,
                expectedStorageRevision: revision,
              ),
            ],
          );
      await commit('create', original, 0);
      await commit('notes', original.copyWith(jobNotes: 'Call on arrival'), 1);
      await expectLater(
        commit('stale', original.copyWith(jobNotes: 'old editor'), 1),
        throwsA(isA<LocalRecordConflict>()),
      );
      final current = await repository.find(
        organizationId: 'business',
        recordId: original.id,
        visibleCreatorIds: {original.createdByEmployeeId},
      );
      expect(current!.storageRevision, 2);
      expect(current.record.revision, original.revision);
      expect(current.record.jobNotes, 'Call on arrival');
    },
  );

  test('customer locations and company document defaults are lossless', () {
    for (final customer in demoWorkCustomers) {
      final restored = decodeWorkCustomerProfile(
        encodeWorkCustomerProfile(customer),
      );
      expect(restored.id, customer.id);
      expect(
        restored.locations.map((l) => l.address),
        customer.locations.map((l) => l.address),
      );
      expect(
        restored.locations.map((l) => l.accessNotes),
        customer.locations.map((l) => l.accessNotes),
      );
      expect(restored.preferredContact, customer.preferredContact);
      expect(
        encodeWorkCustomerProfile(restored),
        encodeWorkCustomerProfile(customer),
      );
    }
    final company = decodeWorkCompanyProfile(
      encodeWorkCompanyProfile(demoWorkCompany),
    );
    expect(company.defaultTerms, demoWorkCompany.defaultTerms);
    expect(company.defaultCurrency, demoWorkCompany.defaultCurrency);
  });

  test(
    'signed revision, approval evidence and material provenance survive storage',
    () async {
      final database = await harness.open();
      final repository = SqliteWorkRepository(database);
      final timestamp = DateTime.utc(2026, 9, 9, 15, 42);
      final record = WorkRecord(
        id: 'estimate-evidence',
        kind: WorkRecordKind.estimate,
        number: 'EST-42',
        title: 'Pump replacement',
        client: 'Customer',
        detail: 'Reviewed scope',
        pricing: WorkPricingModel.timeAndMaterials,
        createdByEmployeeId: 'owner',
        revision: 3,
        total: 281.25,
        discount: 5.25,
        tax: 12.50,
        customerSignature: WorkCustomerSignature(
          signedBy: 'Customer',
          signedOn: timestamp,
          signedRevision: 2,
          invalidatedOn: timestamp.add(const Duration(minutes: 5)),
          invalidationReason: 'Scope changed',
        ),
        estimateCompanyReviewHistory: [
          EstimateCompanyReviewEvent(
            decision: EstimateCompanyReviewDecision.approved,
            actor: 'Owner',
            occurredOn: timestamp,
            revision: 3,
            note: 'Reviewed internal costs',
          ),
        ],
        estimateDeliveries: [
          EstimateDeliveryRecord(
            method: EstimateDeliveryMethod.inPerson,
            recipient: 'Customer',
            occurredOn: timestamp,
            revision: 2,
            description: 'Reviewed together',
          ),
        ],
        estimateRevisionHistory: [
          EstimateRevisionRecord(
            revision: 2,
            changedOn: timestamp,
            total: 199.99,
            description: 'Previous scope',
            customerApproved: true,
          ),
        ],
        items: const [
          WorkLineItem(
            id: 'line-1',
            type: WorkLineItemType.material,
            name: 'Pump',
            quantity: 1.25,
            unit: 'each',
            customerPrice: 219.20,
            internalUnitCost: 121.375,
            sourceExpenseId: 'expense-4',
            sourceExpenseLineId: 'receipt-line-3',
            sourceReceiptId: 'receipt-8',
            sourceStockId: 'stock-2',
            isJobAddition: true,
            jobMaterialBillingTreatment:
                JobMaterialBillingTreatment.invoiceCandidate,
          ),
        ],
        sitePhotos: [
          WorkSitePhoto(
            id: 'photo-1',
            path: '/test/reference-only.jpg',
            name: 'Pump label',
            source: WorkSitePhotoSource.camera,
            addedOn: timestamp,
            note: 'Model number',
          ),
        ],
        linkedExpenseIds: const ['expense-4'],
      );
      await repository.commit(
        organizationId: 'business',
        commandId: 'evidence',
        actorEmployeeId: 'owner',
        permissionRevision: 'owner-v1',
        occurredAt: timestamp,
        mutations: [
          WorkRecordMutation(record: record, expectedStorageRevision: 0),
        ],
      );
      await harness.close(database);
      final reopened = SqliteWorkRepository(await harness.open());
      final saved = (await reopened.find(
        organizationId: 'business',
        recordId: record.id,
        visibleCreatorIds: {'owner'},
      ))!.record;
      expect(saved.customerSignature!.signedRevision, 2);
      expect(saved.customerSignature!.invalidationReason, 'Scope changed');
      expect(saved.hasCurrentCustomerSignature, isFalse);
      expect(
        saved.estimateCompanyReviewHistory.single.note,
        'Reviewed internal costs',
      );
      expect(saved.estimateDeliveries.single.revision, 2);
      expect(saved.estimateRevisionHistory.single.total, 199.99);
      expect(saved.items.single.quantity, 1.25);
      expect(saved.items.single.internalUnitCost, 121.375);
      expect(saved.items.single.sourceExpenseLineId, 'receipt-line-3');
      expect(saved.items.single.sourceStockId, 'stock-2');
      expect(
        saved.items.single.jobMaterialBillingTreatment,
        JobMaterialBillingTreatment.invoiceCandidate,
      );
      expect(saved.sitePhotos.single.note, 'Model number');
      expect(saved.linkedExpenseIds, ['expense-4']);
    },
  );
}
