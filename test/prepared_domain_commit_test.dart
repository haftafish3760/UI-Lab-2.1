import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/dual_slot_json_store.dart';
import 'package:ui_lab_2_1/src/data/storage/sqlite_domain_snapshot_store.dart';
import 'support/storage/database_harness.dart';

typedef Rows = List<Map<String, Object?>>;
Future<SqliteDomainSnapshotStore<Rows>> openStore(
  LocalDatabase database,
  String domain, {
  String organization = 'org',
}) => SqliteDomainSnapshotStore.open<Rows>(
  database: database,
  organizationId: organization,
  domain: domain,
  collections: const [
    DomainCollection(name: 'records', idField: 'id', ownerField: 'ownerId'),
  ],
  encode: (rows) => {'records': rows},
  decode: (body) => (body['records'] as List)
      .map((row) => (row as Map).cast<String, Object?>())
      .toList(),
);
Rows rows(int value) => [
  {'id': 'record', 'organizationId': 'org', 'ownerId': 'actor', 'value': value},
];

void main() {
  test(
    'group failure preserves all caches and draft; retry commits together and survives reopen',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      final first = await openStore(database, 'first');
      final second = await openStore(database, 'second');
      final drafts = LocalDraftStore(database);
      await drafts.save(
        organizationId: 'org',
        domain: 'review',
        draftId: 'input',
        ownerId: 'actor',
        expectedRevision: 0,
        payload: {'amount': '12.'},
        occurredAt: DateTime.utc(2030),
      );
      final input = rows(1);
      final plans = [first.prepare(input), second.prepare(rows(2))];
      input.single['value'] = 99;
      expect(first.value, isEmpty);
      expect(second.value, isEmpty);
      await database.customStatement(
        "CREATE TRIGGER fail_second BEFORE INSERT ON local_records WHEN NEW.domain = 'second/records' BEGIN SELECT RAISE(ABORT, 'injected second-domain failure'); END",
      );
      Future<void> commit() => commitPreparedDomainChanges(
        plans,
        organizationId: 'org',
        ownerId: 'actor',
        checkpoint: const LocalDraftCheckpoint(
          domain: 'review',
          draftId: 'input',
          revision: 1,
        ),
      );
      await expectLater(
        commit(),
        throwsA(isA<DualSlotSnapshotWriteException>()),
      );
      expect(first.value, isEmpty);
      expect(second.value, isEmpty);
      expect(await database.select(database.localRecords).get(), isEmpty);
      expect(
        await database.select(database.localRecordRevisions).get(),
        isEmpty,
      );
      expect(await database.select(database.localCommands).get(), isEmpty);
      expect(await database.select(database.localChangeOutbox).get(), isEmpty);
      expect(
        await drafts.list(
          organizationId: 'org',
          domain: 'review',
          ownerId: 'actor',
        ),
        hasLength(1),
      );
      await database.customStatement('DROP TRIGGER fail_second');
      await commit();
      expect(first.value.single['value'], 1);
      expect(second.value.single['value'], 2);
      expect(
        await drafts.list(
          organizationId: 'org',
          domain: 'review',
          ownerId: 'actor',
        ),
        isEmpty,
      );
      await harness.close(database);
      database = await harness.open();
      expect((await openStore(database, 'first')).value.single['value'], 1);
      expect((await openStore(database, 'second')).value.single['value'], 2);
      await database.verifyIntegrity();
    },
  );

  test(
    'stale prepared cache cannot overwrite a newer commit including a no-op plan',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final database = await harness.open();
      final store = await openStore(database, 'first');
      await store.persist(rows(1));
      final noOp = store.prepare(rows(1));
      final stale = store.prepare(rows(3));
      await store.persist(rows(2));
      for (final plan in [noOp, stale]) {
        await expectLater(
          commitPreparedDomainChanges([plan], organizationId: 'org'),
          throwsA(isA<DualSlotSnapshotWriteException>()),
        );
      }
      expect(store.value.single['value'], 2);
      expect((await openStore(database, 'first')).value.single['value'], 2);
    },
  );

  test(
    'group rejects mixed databases, organizations and duplicate domains before writing',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final firstDb = await harness.open();
      final secondDb = await harness.open();
      final first = await openStore(firstDb, 'first');
      final duplicate = await openStore(firstDb, 'first');
      final otherDb = await openStore(secondDb, 'second');
      final otherOrg = await openStore(
        firstDb,
        'second',
        organization: 'other',
      );
      for (final second in [
        duplicate.prepare(rows(2)),
        otherDb.prepare(rows(2)),
        otherOrg.prepare([]),
      ]) {
        expect(
          () => commitPreparedDomainChanges([
            first.prepare(rows(1)),
            second,
          ], organizationId: 'org'),
          throwsArgumentError,
        );
      }
      expect(await firstDb.select(firstDb.localRecords).get(), isEmpty);
    },
  );
}
