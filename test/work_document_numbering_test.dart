import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_document_numbering.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';

import 'support/storage/database_harness.dart';

void main() {
  test(
    'custom first estimate counts upward; invoices count separately',
    () async {
      final harness = await DatabaseHarness.create();
      final database = await harness.open();
      final repository = SqliteWorkRepository(database);
      final numbering = WorkDocumentNumbering(repository);
      addTearDown(() async => harness.dispose());
      WorkRecord document(
        String id,
        WorkRecordKind kind,
        String number, {
        String creator = 'alex',
      }) => WorkRecord(
        id: id,
        kind: kind,
        number: number,
        title: 'Repair',
        client: 'Customer',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
        createdByEmployeeId: creator,
      );
      Future<void> save(String command, WorkRecord record) => repository.commit(
        organizationId: 'business',
        commandId: command,
        actorEmployeeId: record.createdByEmployeeId,
        permissionRevision: 'test-1',
        occurredAt: DateTime.utc(2030, 1, 1),
        mutations: [
          WorkRecordMutation(record: record, expectedStorageRevision: 0),
        ],
      );

      expect(
        await numbering.previewNext(
          organizationId: 'business',
          kind: WorkRecordKind.estimate,
        ),
        'Estimate 1',
      );
      await save(
        'estimate-777',
        document('e1', WorkRecordKind.estimate, '777'),
      );
      await save(
        'estimate-777',
        document('e1', WorkRecordKind.estimate, '777'),
      );
      expect(
        await numbering.previewNext(
          organizationId: 'business',
          kind: WorkRecordKind.estimate,
        ),
        'Estimate 778',
      );
      expect(
        await numbering.previewNext(
          organizationId: 'business',
          kind: WorkRecordKind.invoice,
        ),
        'Invoice 1',
      );
      await save('invoice-777', document('i1', WorkRecordKind.invoice, '777'));
      expect(
        await numbering.previewNext(
          organizationId: 'business',
          kind: WorkRecordKind.invoice,
        ),
        'Invoice 778',
      );

      await expectLater(
        save(
          'duplicate-estimate',
          document(
            'e2',
            WorkRecordKind.estimate,
            'Estimate 777',
            creator: 'jordan',
          ),
        ),
        throwsStateError,
      );
      expect(
        await repository.query(
          organizationId: 'business',
          visibleCreatorIds: {'alex', 'jordan'},
        ),
        hasLength(2),
      );
      await save(
        'estimate-778',
        document('e3', WorkRecordKind.estimate, 'Estimate 778'),
      );
      await expectLater(
        save('stale-778', document('e4', WorkRecordKind.estimate, '778')),
        throwsStateError,
      );
      await save(
        'different-custom-prefix',
        document('e5', WorkRecordKind.estimate, 'EST-777'),
      );
      await save(
        'different-year-prefix',
        document('e6', WorkRecordKind.estimate, '2027-777'),
      );
    },
  );

  test('legacy saved number cannot be claimed by a new estimate', () async {
    final harness = await DatabaseHarness.create();
    final database = await harness.open();
    final repository = SqliteWorkRepository(database);
    addTearDown(() async => harness.dispose());
    const original = WorkRecord(
      id: 'legacy',
      kind: WorkRecordKind.estimate,
      number: 'Estimate 39800',
      title: 'Repair',
      client: 'Customer',
      detail: 'Repair',
      pricing: WorkPricingModel.flatRate,
      createdByEmployeeId: 'alex',
    );
    // Simulate a record saved before number claims were introduced.
    await repository.database.customStatement(
      'INSERT INTO local_records '
      '(organization_id, domain, record_id, owner_id, revision, payload_version, payload, updated_at_us) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        'business',
        'work/records',
        original.id,
        'alex',
        1,
        1,
        '{"id":"legacy","kind":"estimate","number":"Estimate 39800","createdByEmployeeId":"alex"}',
        1,
      ],
    );
    final numbering = WorkDocumentNumbering(repository);
    expect(
      await numbering.previewNext(
        organizationId: 'business',
        kind: WorkRecordKind.estimate,
      ),
      'Estimate 1',
    );
    await expectLater(
      repository.commit(
        organizationId: 'business',
        commandId: 'duplicate-legacy',
        actorEmployeeId: 'alex',
        permissionRevision: 'test-1',
        occurredAt: DateTime.utc(2030, 1, 1),
        mutations: [
          WorkRecordMutation(
            record: const WorkRecord(
              id: 'new',
              kind: WorkRecordKind.estimate,
              number: '39800',
              title: 'Repair',
              client: 'Customer',
              detail: 'Repair',
              pricing: WorkPricingModel.flatRate,
              createdByEmployeeId: 'alex',
            ),
            expectedStorageRevision: 0,
          ),
        ],
      ),
      throwsStateError,
    );
  });
}
