import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:ui_lab_2_1/src/data/storage/local_database_snapshot.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';

import 'support/storage/database_harness.dart';

void main() {
  late DatabaseHarness harness;
  setUp(() async => harness = await DatabaseHarness.create());
  tearDown(() async => harness.dispose());

  test(
    'snapshot includes live WAL records, journals, metadata and raw drafts',
    () async {
      final store = await harness.openStore();
      final db = store.database;
      await db.customStatement('PRAGMA wal_autocheckpoint = 0');
      await store.commit(
        organizationId: 'business',
        commandId: 'saved-command',
        writes: [
          LocalRecordWrite(
            domain: 'work/records',
            recordId: 'invoice',
            ownerId: 'owner',
            expectedRevision: 0,
            payload: {'amountMinorUnits': 12345, 'notes': 'saved 🔧'},
          ),
        ],
        occurredAt: DateTime.utc(2026, 9, 9),
      );
      final drafts = LocalDraftStore(db);
      await drafts.save(
        organizationId: 'business',
        domain: 'invoice',
        draftId: 'unfinished',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: {'amountText': '12.', 'notes': '  exact raw input  '},
        occurredAt: DateTime.utc(2026, 9, 9),
      );
      await db.customStatement(
        "INSERT INTO local_metadata VALUES ('fixture', 'retained')",
      );
      expect(await File('${harness.file.path}-wal').length(), greaterThan(0));
      final snapshot = await LocalDatabaseSnapshot.capture(db);
      expect(snapshot.byteLength, await snapshot.file.length());
      expect(
        snapshot.sha256Digest,
        (await sha256.bind(snapshot.file.openRead()).first).toString(),
      );
      final copied = sqlite.sqlite3.open(
        snapshot.file.path,
        mode: sqlite.OpenMode.readOnly,
      );
      try {
        expect(copied.select('PRAGMA user_version').single.values.single, 1);
        for (final table in [
          'local_records',
          'local_record_revisions',
          'local_commands',
          'local_change_outbox',
          'local_drafts',
          'local_metadata',
        ]) {
          final expected = (await db.customSelect('SELECT * FROM $table').get())
              .map((row) => row.data)
              .toList();
          final actual = copied
              .select('SELECT * FROM $table')
              .map((row) => Map<String, Object?>.from(row))
              .toList();
          expect(actual, expected, reason: table);
        }
        await drafts.save(
          organizationId: 'business',
          domain: 'invoice',
          draftId: 'unfinished',
          ownerId: 'owner',
          expectedRevision: 1,
          payload: {'amountText': 'newer live edit'},
          occurredAt: DateTime.now(),
        );
        expect(
          copied.select('SELECT revision FROM local_drafts').single['revision'],
          1,
        );
        expect(
          copied.select('SELECT payload FROM local_drafts').single['payload'],
          contains('exact raw input'),
        );
      } finally {
        copied.close();
      }
      await db.verifyIntegrity();
    },
  );

  test('redirected checkpoint directory cannot receive private data', () async {
    final db = await harness.open();
    final unrelated = await Directory(
      '${harness.directory.path}/unrelated',
    ).create();
    final sentinel = File('${unrelated.path}/keep.txt');
    await sentinel.writeAsString('unchanged', flush: true);
    final link = Link('${harness.directory.path}/database_checkpoints');
    await link.create(unrelated.path);
    await expectLater(
      LocalDatabaseSnapshot.capture(db),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Checkpoint directory is redirected.',
        ),
      ),
    );
    expect(await sentinel.readAsString(), 'unchanged');
    expect((await unrelated.list().toList()).map((entry) => entry.path), [
      sentinel.path,
    ]);
    expect(await link.exists(), isTrue);
    await db.verifyIntegrity();
  });

  test(
    'failed capture preserves an earlier checkpoint and the live database',
    () async {
      final db = await harness.open();
      final prior = await LocalDatabaseSnapshot.capture(db);
      final bytes = await prior.file.readAsBytes();
      await db.transaction(() async {
        // SQLite forbids VACUUM inside a transaction: fail after staging exists.
        await expectLater(LocalDatabaseSnapshot.capture(db), throwsA(anything));
      });
      expect(await prior.file.readAsBytes(), bytes);
      final folders = await prior.file.parent.parent.list().toList();
      expect(folders.map((entry) => entry.path), [prior.file.parent.path]);
      await db.verifyIntegrity();
    },
  );
}
