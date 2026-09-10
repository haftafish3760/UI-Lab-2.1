import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';

import 'support/storage/database_harness.dart';

void main() {
  late DatabaseHarness harness;
  final time = DateTime.utc(2026, 9, 9);
  setUp(() async => harness = await DatabaseHarness.create());
  tearDown(() async => harness.dispose());

  LocalRecordWrite expense(int cents, {int revision = 0}) => LocalRecordWrite(
    domain: 'expenses',
    recordId: 'expense-1',
    ownerId: 'owner',
    expectedRevision: revision,
    payload: {'amountMinorUnits': cents, 'currency': 'USD', 'note': 'café 🔧'},
  );

  test(
    'file is SQLite; committed data and exact amounts survive reopen',
    () async {
      final store = await harness.openStore();
      await store.commit(
        organizationId: 'business',
        commandId: 'create-1',
        writes: [expense(123456789)],
        occurredAt: time,
      );
      await harness.close(store.database);
      final header = await harness.file.open();
      expect(
        String.fromCharCodes(await header.read(16)),
        'SQLite format 3\u0000',
      );
      await header.close();
      final reopened = await harness.openStore();
      final rows = await reopened.read(
        organizationId: 'business',
        domain: 'expenses',
        ownerIds: {'owner'},
      );
      expect(rows, hasLength(1));
      expect(reopened.decode(rows.single), {
        'amountMinorUnits': 123456789,
        'currency': 'USD',
        'note': 'café 🔧',
      });
      expect(
        (await reopened.database.customSelect('PRAGMA synchronous').getSingle())
            .data
            .values
            .single,
        2,
      );
      expect(
        (await reopened.database
                .customSelect('PRAGMA journal_mode')
                .getSingle())
            .data
            .values
            .single,
        'wal',
      );
    },
  );

  for (final setting in ['synchronous = NORMAL', 'journal_mode = DELETE']) {
    test('opening refuses weakened $setting and preserves drafts', () async {
      final database = await harness.open();
      await LocalDraftStore(database).save(
        organizationId: 'business',
        domain: 'expense-editor',
        draftId: 'unfinished',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: {'amountText': '12.', 'note': '  unfinished  '},
        occurredAt: time,
      );
      await harness.close(database);
      final weakened = LocalDatabase(
        NativeDatabase(
          harness.file,
          setup: (raw) {
            raw.execute('PRAGMA synchronous = FULL');
            raw.execute('PRAGMA $setting');
          },
        ),
        storageFile: harness.file,
      );
      try {
        await expectLater(
          weakened.verifyIntegrity(),
          throwsA(isA<StateError>()),
        );
      } finally {
        await weakened.close();
      }
      final recovered = await harness.open();
      final drafts = LocalDraftStore(recovered);
      final draft = await drafts.find(
        organizationId: 'business',
        domain: 'expense-editor',
        draftId: 'unfinished',
        ownerId: 'owner',
      );
      expect(draft!.revision, 1);
      expect(drafts.decode(draft), {
        'amountText': '12.',
        'note': '  unfinished  ',
      });
    });
  }

  test(
    'same command replay is idempotent and changed replay is rejected',
    () async {
      final store = await harness.openStore();
      for (var attempt = 0; attempt < 2; attempt++) {
        await store.commit(
          organizationId: 'business',
          commandId: 'create-1',
          writes: [expense(1500)],
          occurredAt: time.add(Duration(seconds: attempt)),
        );
      }
      await expectLater(
        store.commit(
          organizationId: 'business',
          commandId: 'create-1',
          writes: [expense(2000)],
          occurredAt: time,
        ),
        throwsA(isA<LocalRecordConflict>()),
      );
      expect(
        await store.database.select(store.database.localRecordRevisions).get(),
        hasLength(1),
      );
      final outbox = await store.database
          .select(store.database.localChangeOutbox)
          .get();
      expect(outbox, hasLength(1));
      expect(outbox.single.state, 'local');
    },
  );

  test(
    'SQLite failure rolls back records, revisions, command and outbox together',
    () async {
      final store = await harness.openStore();
      await store.database.customStatement('''
      CREATE TRIGGER reject_journal BEFORE INSERT ON local_change_outbox
      BEGIN SELECT RAISE(ABORT, 'synthetic journal failure'); END
    ''');
      await expectLater(
        store.commit(
          organizationId: 'business',
          commandId: 'create-1',
          writes: [expense(1500)],
          occurredAt: time,
        ),
        throwsA(anything),
      );
      for (final table in [
        'local_records',
        'local_record_revisions',
        'local_commands',
        'local_change_outbox',
      ]) {
        expect(
          (await store.database
                  .customSelect('SELECT COUNT(*) AS n FROM $table')
                  .getSingle())
              .read<int>('n'),
          0,
        );
      }
      await store.database.customStatement('DROP TRIGGER reject_journal');
      await store.commit(
        organizationId: 'business',
        commandId: 'create-1',
        writes: [expense(1500)],
        occurredAt: time,
      );
      await harness.close(store.database);
      await (await harness.open()).verifyIntegrity();
    },
  );

  test('a conflicting second record rolls back the whole command', () async {
    final store = await harness.openStore();
    await store.commit(
      organizationId: 'business',
      commandId: 'create-1',
      writes: [expense(1500)],
      occurredAt: time,
    );
    final other = LocalRecordWrite(
      domain: 'expenses',
      recordId: 'expense-2',
      ownerId: 'owner',
      expectedRevision: 0,
      payload: {'amount': 5},
    );
    await expectLater(
      store.commit(
        organizationId: 'business',
        commandId: 'bundle',
        writes: [other, expense(2000)],
        occurredAt: time,
      ),
      throwsA(isA<LocalRecordConflict>()),
    );
    expect(
      await store.read(
        organizationId: 'business',
        domain: 'expenses',
        ownerIds: {'owner'},
      ),
      hasLength(1),
    );
    expect(
      await store.database.select(store.database.localCommands).get(),
      hasLength(1),
    );
  });

  test(
    'two database connections cannot silently overwrite a revision',
    () async {
      final first = await harness.openStore();
      final second = await harness.openStore();
      await first.commit(
        organizationId: 'business',
        commandId: 'create-1',
        writes: [expense(1500)],
        occurredAt: time,
      );
      await second.commit(
        organizationId: 'business',
        commandId: 'edit-1',
        writes: [expense(2000, revision: 1)],
        occurredAt: time,
      );
      await expectLater(
        first.commit(
          organizationId: 'business',
          commandId: 'stale-edit',
          writes: [expense(3000, revision: 1)],
          occurredAt: time,
        ),
        throwsA(isA<LocalRecordConflict>()),
      );
      final rows = await first.read(
        organizationId: 'business',
        domain: 'expenses',
        ownerIds: {'owner'},
      );
      expect(first.decode(rows.single)['amountMinorUnits'], 2000);
      expect(
        await first.database.select(first.database.localRecordRevisions).get(),
        hasLength(2),
      );
    },
  );

  test(
    'reads enforce organization and owner before returning payloads',
    () async {
      final store = await harness.openStore();
      await store.commit(
        organizationId: 'business',
        commandId: 'create-1',
        writes: [expense(1500)],
        occurredAt: time,
      );
      expect(
        await store.read(
          organizationId: 'other',
          domain: 'expenses',
          ownerIds: {'owner'},
        ),
        isEmpty,
      );
      expect(
        await store.read(
          organizationId: 'business',
          domain: 'expenses',
          ownerIds: {'other'},
        ),
        isEmpty,
      );
      expect(
        await store.read(
          organizationId: 'business',
          domain: 'expenses',
          ownerIds: {},
        ),
        isEmpty,
      );
    },
  );

  test(
    'incomplete draft survives reopen without creating a confirmed record',
    () async {
      var db = await harness.open();
      var drafts = LocalDraftStore(db);
      await drafts.save(
        organizationId: 'business',
        domain: 'expense-editor',
        draftId: 'draft-1',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: {'amountText': '12.', 'vendor': ''},
        occurredAt: time,
      );
      await harness.close(db);
      db = await harness.open();
      drafts = LocalDraftStore(db);
      final draft = await drafts.find(
        organizationId: 'business',
        domain: 'expense-editor',
        draftId: 'draft-1',
        ownerId: 'owner',
      );
      expect(drafts.decode(draft!), {'amountText': '12.', 'vendor': ''});
      expect(await db.select(db.localRecords).get(), isEmpty);
      expect(await db.select(db.localChangeOutbox).get(), isEmpty);
      await drafts.save(
        organizationId: 'business',
        domain: 'expense-editor',
        draftId: 'draft-1',
        ownerId: 'owner',
        expectedRevision: 1,
        payload: {'amountText': '12.50'},
        occurredAt: time,
      );
      expect(
        await drafts.consumeIfUnchanged(
          organizationId: 'business',
          domain: 'expense-editor',
          draftId: 'draft-1',
          ownerId: 'owner',
          expectedRevision: 1,
        ),
        isFalse,
      );
      expect(
        await drafts.find(
          organizationId: 'business',
          domain: 'expense-editor',
          draftId: 'draft-1',
          ownerId: 'owner',
        ),
        isNotNull,
      );
    },
  );

  test(
    'corrupt database is refused and never replaced with an empty database',
    () async {
      final bytes = List<int>.filled(4096, 47);
      await harness.file.writeAsBytes(bytes, flush: true);
      await expectLater(harness.open(), throwsA(anything));
      expect(await File(harness.file.path).readAsBytes(), bytes);
    },
  );
}
