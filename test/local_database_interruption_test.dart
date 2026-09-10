import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';

import 'support/storage/database_harness.dart';

void main() {
  late DatabaseHarness harness;
  setUp(() async => harness = await DatabaseHarness.create());
  tearDown(() async => harness.dispose());

  test(
    'SIGKILL during a transaction preserves the previously acknowledged draft',
    () async {
      final process = await Process.start('dart', [
        'run',
        'test/support/storage/crash_writer.dart',
        harness.file.path,
      ]);
      final errors = process.stderr.transform(utf8.decoder).join();
      try {
        await process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .firstWhere((line) => line == 'UNCOMMITTED_WRITE_READY')
            .timeout(const Duration(seconds: 45));
        expect(process.kill(ProcessSignal.sigkill), isTrue);
        await process.exitCode.timeout(const Duration(seconds: 10));
        final database = await harness.open();
        final drafts = LocalDraftStore(database);
        final draft = await drafts.find(
          organizationId: 'business',
          domain: 'invoice',
          draftId: 'draft',
          ownerId: 'owner',
        );
        expect(draft!.revision, 1);
        expect(drafts.decode(draft), {
          'title': 'Repair pump',
          'amountText': '125.',
        });
        await database.verifyIntegrity();
      } catch (error) {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode;
        fail('$error\n${await errors}');
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'SIGKILL rolls back replacement consumption without reusing acknowledged draft revisions',
    () async {
      final process = await Process.start('dart', [
        'run',
        'test/support/storage/draft_replacement_crash_writer.dart',
        harness.file.path,
      ]);
      final errors = process.stderr.transform(utf8.decoder).join();
      try {
        final ready = await process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .firstWhere(
              (line) => line.startsWith('UNCOMMITTED_REPLACEMENT_READY:'),
            )
            .timeout(const Duration(seconds: 45));
        final revisions = ready.split(':').skip(1).map(int.parse).toList();
        expect(revisions, hasLength(2));
        expect(revisions.last, greaterThan(revisions.first));
        expect(process.kill(ProcessSignal.sigkill), isTrue);
        await process.exitCode.timeout(const Duration(seconds: 10));
        final database = await harness.open();
        final drafts = LocalDraftStore(database);
        Future<bool> consume(int revision) => drafts.consumeIfUnchanged(
          organizationId: 'business',
          ownerId: 'owner',
          domain: 'invoice',
          draftId: 'reused',
          expectedRevision: revision,
        );
        final recovered = await drafts.find(
          organizationId: 'business',
          ownerId: 'owner',
          domain: 'invoice',
          draftId: 'reused',
        );
        expect(recovered!.revision, revisions.last);
        expect(drafts.decode(recovered), {'amountText': ' 125. '});
        expect(await consume(revisions.first), isFalse);
        await expectLater(
          drafts.save(
            organizationId: 'business',
            ownerId: 'owner',
            domain: 'invoice',
            draftId: 'reused',
            expectedRevision: revisions.first,
            payload: {'amountText': 'stale editor'},
            occurredAt: DateTime.now(),
          ),
          throwsA(isA<LocalRecordConflict>()),
        );
        expect(await consume(revisions.last), isTrue);
        final next = await drafts.save(
          organizationId: 'business',
          ownerId: 'owner',
          domain: 'invoice',
          draftId: 'reused',
          expectedRevision: 0,
          payload: {'amountText': 'next invoice'},
          occurredAt: DateTime.now(),
        );
        expect(
          next,
          revisions.last + 1,
          reason:
              'The uncommitted revision marker must roll back with its draft.',
        );
        expect(await consume(revisions.last), isFalse);
        await database.verifyIntegrity();
      } catch (error) {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode;
        fail('$error\n${await errors}');
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'SQLite storage capacity failure preserves the previous committed record',
    () async {
      final store = await harness.openStore();
      LocalRecordWrite record(String content, int revision) => LocalRecordWrite(
        domain: 'work',
        recordId: 'job',
        ownerId: 'owner',
        expectedRevision: revision,
        payload: {'content': content},
      );
      await store.commit(
        organizationId: 'business',
        commandId: 'small',
        writes: [record('saved', 0)],
        occurredAt: DateTime.now(),
      );
      final pages =
          (await store.database.customSelect('PRAGMA page_count').getSingle())
                  .data
                  .values
                  .single
              as int;
      await store.database.customStatement(
        'PRAGMA max_page_count = ${pages + 1}',
      );
      await expectLater(
        store.commit(
          organizationId: 'business',
          commandId: 'too-large',
          writes: [record('x' * (1024 * 1024), 1)],
          occurredAt: DateTime.now(),
        ),
        throwsA(anything),
      );
      await harness.close(store.database);
      final reopened = await harness.openStore();
      final saved = await reopened.read(
        organizationId: 'business',
        domain: 'work',
        ownerIds: {'owner'},
      );
      expect(reopened.decode(saved.single), {'content': 'saved'});
      expect(saved.single.revision, 1);
      expect(
        await reopened.database.select(reopened.database.localCommands).get(),
        hasLength(1),
      );
    },
  );

  test(
    'newer unsupported schema is refused without rewriting user_version',
    () async {
      final database = await harness.open();
      await LocalRecordStore(database).commit(
        organizationId: 'business',
        commandId: 'confirmed',
        writes: [
          LocalRecordWrite(
            domain: 'work/records',
            recordId: 'record',
            ownerId: 'owner',
            expectedRevision: 0,
            payload: {'amountMinorUnits': 12345, 'text': 'Saved record'},
          ),
        ],
        occurredAt: DateTime.utc(2026, 9, 9),
      );
      await LocalDraftStore(database).save(
        organizationId: 'business',
        domain: 'invoice',
        draftId: 'unfinished',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: {'amountText': '123.', 'notes': '  keep exact input  '},
        occurredAt: DateTime.utc(2026, 9, 9),
      );
      await database.customStatement('PRAGMA user_version = 999');
      await harness.close(database);
      Map<String, Object?> snapshot() {
        final raw = sqlite.sqlite3.open(
          harness.file.path,
          mode: sqlite.OpenMode.readOnly,
        );
        try {
          return {
            'version': raw.select('PRAGMA user_version').single['user_version'],
            for (final table in [
              'sqlite_master',
              'local_records',
              'local_record_revisions',
              'local_commands',
              'local_change_outbox',
              'local_drafts',
              'local_metadata',
            ])
              table: raw
                  .select('SELECT * FROM $table ORDER BY rowid')
                  .map((row) => Map<String, Object?>.from(row))
                  .toList(),
          };
        } finally {
          raw.close();
        }
      }

      final before = snapshot();
      expect(before['version'], 999);
      final incompatible = LocalDatabase.file(harness.file);
      try {
        await expectLater(incompatible.verifyIntegrity(), throwsA(anything));
      } finally {
        await incompatible.close();
      }
      expect(snapshot(), before);
    },
  );
}
