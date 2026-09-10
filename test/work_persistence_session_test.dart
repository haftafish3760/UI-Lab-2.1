import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';

import 'support/storage/database_harness.dart';

void main() {
  late DatabaseHarness harness;
  late SqliteWorkRepository repository;
  late WorkPersistenceSession session;
  const invoice = WorkRecord(
    id: 'invoice-1',
    kind: WorkRecordKind.invoice,
    number: 'INV-1',
    title: 'Repair',
    client: 'Customer',
    detail: 'Repair pump',
    pricing: WorkPricingModel.flatRate,
    createdByEmployeeId: 'owner',
    total: 125.50,
  );
  WorkSessionPermissions permissions({bool financial = true}) =>
      WorkSessionPermissions(
        organizationId: 'business',
        actorEmployeeId: 'owner',
        permissionRevision: 'owner-1',
        visibleCreatorIds: {'owner'},
        editableKinds: WorkRecordKind.values.toSet(),
        canIssueInvoices: financial,
        canRecordPayments: financial,
      );
  PrototypeFinancialEntry entry(
    String id,
    int amount,
    PrototypeFinancialKind kind,
  ) => PrototypeFinancialEntry(
    id: id,
    kind: kind,
    occurredOn: DateTime.utc(2026, 9, 9),
    amountCents: amount,
    sourceId: invoice.number,
  );
  setUp(() async {
    harness = await DatabaseHarness.create();
    repository = SqliteWorkRepository(await harness.open());
    await repository.commit(
      organizationId: 'business',
      commandId: 'seed',
      actorEmployeeId: 'owner',
      permissionRevision: 'owner-1',
      occurredAt: DateTime.utc(2026, 9, 9),
      mutations: [
        const WorkRecordMutation(record: invoice, expectedStorageRevision: 0),
      ],
    );
    session = await WorkPersistenceSession.open(repository, permissions());
  });
  tearDown(() async {
    session.dispose();
    await harness.dispose();
  });

  test(
    'unchanged stale Work confirmation cannot consume recovery input',
    () async {
      final otherDb = await harness.open();
      final other = await WorkPersistenceSession.open(
        SqliteWorkRepository(otherDb),
        permissions(),
      );
      addTearDown(other.dispose);
      expect(await other.save(records: [invoice]), isTrue);
      final drafts = LocalDraftStore(otherDb);
      await drafts.save(
        organizationId: 'business',
        domain: 'work/invoice-editor',
        draftId: 'retained',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: {'title': 'Raw input'},
        occurredAt: DateTime.now(),
      );
      expect(
        await session.save(
          records: [
            decodeWorkRecord({
              ...encodeWorkRecord(invoice),
              'title': 'Latest saved title',
            }),
          ],
        ),
        isTrue,
      );
      expect(await other.save(records: [invoice]), isFalse);
      expect(
        await other.save(
          records: [invoice],
          draftCheckpoint: const LocalDraftCheckpoint(
            domain: 'work/invoice-editor',
            draftId: 'retained',
            revision: 1,
          ),
        ),
        isFalse,
      );
      final saved = await drafts.list(
        organizationId: 'business',
        domain: 'work/invoice-editor',
        ownerId: 'owner',
      );
      expect(saved, hasLength(1));
      expect(drafts.decode(saved.single), {'title': 'Raw input'});
      expect(
        (await repository.find(
          organizationId: 'business',
          recordId: invoice.id,
          visibleCreatorIds: {'owner'},
        ))!.record.title,
        'Latest saved title',
      );
      await otherDb.verifyIntegrity();
    },
  );

  test(
    'independent sessions cannot post partial payments against one stale balance',
    () async {
      expect(
        await session.save(
          records: [invoice.copyWith(status: WorkRecordStatus.due)],
          financialEntries: [
            entry('issued', 12550, PrototypeFinancialKind.invoiceIssued),
          ],
        ),
        isTrue,
      );
      final other = await WorkPersistenceSession.open(
        SqliteWorkRepository(await harness.open()),
        permissions(),
      );
      addTearDown(other.dispose);
      expect(
        await session.save(
          financialEntries: [
            entry(
              'first-partial',
              6000,
              PrototypeFinancialKind.paymentReceived,
            ),
          ],
        ),
        isTrue,
      );
      expect(
        await other.save(
          financialEntries: [
            entry(
              'stale-partial',
              8000,
              PrototypeFinancialKind.paymentReceived,
            ),
          ],
        ),
        isFalse,
      );
      final stored = await repository.queryFinancialEntries(
        organizationId: 'business',
        visibleActorIds: {'owner'},
      );
      expect(
        stored
            .where(
              (item) => item.kind == PrototypeFinancialKind.paymentReceived,
            )
            .fold(0, (sum, item) => sum + item.amountCents),
        6000,
      );
      expect(
        (await repository.find(
          organizationId: 'business',
          recordId: invoice.id,
          visibleCreatorIds: {'owner'},
        ))!.storageRevision,
        3,
      );
    },
  );

  test(
    'issue and partial/full payments preserve matching invoice and ledger after reopen',
    () async {
      expect(
        await session.save(
          records: [invoice.copyWith(status: WorkRecordStatus.due)],
          financialEntries: [
            entry('issued', 12550, PrototypeFinancialKind.invoiceIssued),
          ],
        ),
        isTrue,
      );
      expect(
        await session.save(
          financialEntries: [
            entry('partial', 6000, PrototypeFinancialKind.paymentReceived),
          ],
        ),
        isTrue,
      );
      expect(session.records.single.status, WorkRecordStatus.due);
      final remaining = entry(
        'remaining',
        6550,
        PrototypeFinancialKind.paymentReceived,
      );
      expect(await session.save(financialEntries: [remaining]), isTrue);
      expect(await session.save(financialEntries: [remaining]), isTrue);
      expect(session.records.single.status, WorkRecordStatus.paid);
      expect(session.financialEntries, hasLength(3));
      session.dispose();
      await harness.close(repository.database);
      repository = SqliteWorkRepository(await harness.open());
      session = await WorkPersistenceSession.open(repository, permissions());
      expect(session.records.single.status, WorkRecordStatus.paid);
      expect(
        session.financialEntries
            .where(
              (item) => item.kind == PrototypeFinancialKind.paymentReceived,
            )
            .fold(0, (sum, item) => sum + item.amountCents),
        12550,
      );
      expect(
        await session.save(
          financialEntries: [
            entry('overpayment', 1, PrototypeFinancialKind.paymentReceived),
          ],
        ),
        isFalse,
      );
      expect(session.financialEntries, hasLength(3));
    },
  );

  test(
    'failed ledger insert rolls back invoice status and retains UI last-known-good state',
    () async {
      await repository.database.customStatement('''
      CREATE TRIGGER fail_ledger BEFORE INSERT ON local_records
      WHEN NEW.domain = 'work/ledger'
      BEGIN SELECT RAISE(ABORT, 'synthetic ledger failure'); END
    ''');
      expect(
        await session.save(
          records: [invoice.copyWith(status: WorkRecordStatus.due)],
          financialEntries: [
            entry('issued', 12550, PrototypeFinancialKind.invoiceIssued),
          ],
        ),
        isFalse,
      );
      expect(session.records.single.status, WorkRecordStatus.draft);
      expect(session.financialEntries, isEmpty);
      expect(session.failureMessage, isNotNull);
      final current = await repository.find(
        organizationId: 'business',
        recordId: invoice.id,
        visibleCreatorIds: {'owner'},
      );
      expect(current!.record.status, WorkRecordStatus.draft);
      expect(current.storageRevision, 1);
      expect(
        await repository.queryFinancialEntries(
          organizationId: 'business',
          visibleActorIds: {'owner'},
        ),
        isEmpty,
      );
    },
  );

  test(
    'direct status mutation cannot bypass issuing or payment authority',
    () async {
      expect(
        await session.update(invoice.copyWith(status: WorkRecordStatus.due)),
        isFalse,
      );
      expect(
        await session.update(invoice.copyWith(status: WorkRecordStatus.paid)),
        isFalse,
      );
      session.dispose();
      session = await WorkPersistenceSession.open(
        repository,
        permissions(financial: false),
      );
      expect(
        await session.save(
          records: [invoice.copyWith(status: WorkRecordStatus.due)],
          financialEntries: [
            entry('issued', 12550, PrototypeFinancialKind.invoiceIssued),
          ],
        ),
        isFalse,
      );
      expect(session.records.single.status, WorkRecordStatus.draft);
    },
  );

  test(
    'two submitted changes with the same base revision cannot overwrite each other',
    () async {
      final first = decodeWorkRecord({
        ...encodeWorkRecord(invoice),
        'title': 'First edit',
      });
      final second = decodeWorkRecord({
        ...encodeWorkRecord(invoice),
        'title': 'Stale edit',
      });
      final results = await Future.wait([
        session.update(first),
        session.update(second),
      ]);
      expect(results, [true, false]);
      expect(session.records.single.title, 'First edit');
      expect(session.failureMessage, contains('changed'));
    },
  );
}
