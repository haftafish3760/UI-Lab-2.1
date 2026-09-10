import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/verified_local_snapshot_bundle.dart';

import 'support/storage/database_harness.dart';

void main() {
  late DatabaseHarness harness;
  setUp(() async => harness = await DatabaseHarness.create());
  tearDown(() async => harness.dispose());

  Future<LocalSnapshotBundle> capture() async {
    final db = await harness.open();
    final source = File('${harness.directory.path}/picker.jpg');
    await source.writeAsBytes([1, 3, 5, 7], flush: true);
    await LocalAttachmentStore(
      db,
    ).retain(source: source, organizationId: 'business', ownerId: 'alex');
    return LocalSnapshotBundle.capture(db);
  }

  test(
    'verification works after relocation without consulting original media',
    () async {
      final bundle = await capture();
      await Directory(
        '${harness.directory.path}/attachments',
      ).delete(recursive: true);
      final moved = await bundle.directory.rename(
        '${harness.directory.path}/moved-checkpoint',
      );
      final verified = await VerifiedLocalSnapshotBundle.open(moved);
      expect(verified.attachments, hasLength(1));
      expect(verified.databaseDigest, bundle.database.sha256Digest);
      expect(
        await File(
          '${verified.directory.path}/files/${verified.attachments.single.relativePath}',
        ).readAsBytes(),
        [1, 3, 5, 7],
      );
    },
  );

  test(
    'uncheckpointed sidecar changes are refused despite unchanged main hash',
    () async {
      final bundle = await capture();
      final writer = sqlite.sqlite3.open(bundle.database.file.path);
      try {
        writer.execute('PRAGMA journal_mode = WAL');
        writer.execute('PRAGMA wal_autocheckpoint = 0');
        final baselineHash =
            (await sha256.bind(bundle.database.file.openRead()).first)
                .toString();
        final manifestFile = File('${bundle.directory.path}/manifest.json');
        final manifest = jsonDecode(await manifestFile.readAsString()) as Map;
        manifest['database']['sha256'] = baselineHash;
        manifest['database']['byteLength'] = await bundle.database.file
            .length();
        await manifestFile.writeAsString(jsonEncode(manifest), flush: true);
        await VerifiedLocalSnapshotBundle.open(bundle.directory);
        writer.execute(
          "INSERT INTO local_metadata VALUES ('sidecar-only', 'unhashed')",
        );
        expect(
          await File('${bundle.database.file.path}-wal').length(),
          greaterThan(0),
        );
        expect(
          (await sha256.bind(bundle.database.file.openRead()).first).toString(),
          baselineHash,
        );
        await expectLater(
          VerifiedLocalSnapshotBundle.open(bundle.directory),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Checkpoint contains unverified SQLite sidecar data.',
            ),
          ),
        );
      } finally {
        writer.close();
      }
    },
  );

  for (final damage in [
    'missing manifest',
    'omitted file',
    'path traversal',
    'alias substitution',
    'alias traversal',
    'invalid alias type',
    'changed database',
    'changed file',
    'redirected file',
    'unsupported schema',
    'injected trigger',
    'extra table',
    'changed table',
  ]) {
    test('$damage is refused without changing live data', () async {
      final bundle = await capture();
      final manifestFile = File('${bundle.directory.path}/manifest.json');
      final manifest = jsonDecode(await manifestFile.readAsString()) as Map;
      final entry = bundle.attachments.single;
      final retained = File(
        '${bundle.directory.path}/files/${entry.relativePath}',
      );
      final original = File(entry.sourcePath);
      final originalBytes = await original.readAsBytes();
      switch (damage) {
        case 'missing manifest':
          await manifestFile.delete();
        case 'omitted file':
          manifest['attachments'] = [];
          await manifestFile.writeAsString(jsonEncode(manifest));
        case 'path traversal':
          (manifest['attachments'] as List).single['relativePath'] =
              '../picker.jpg';
          await manifestFile.writeAsString(jsonEncode(manifest));
        case 'alias substitution':
          manifest['referenceAliases'] = {
            '/former/attachments/other.image': entry.relativePath,
          };
          await manifestFile.writeAsString(jsonEncode(manifest));
        case 'alias traversal':
          manifest['referenceAliases'] = {
            '/former/../${entry.relativePath}': entry.relativePath,
          };
          await manifestFile.writeAsString(jsonEncode(manifest));
        case 'invalid alias type':
          manifest['referenceAliases'] = ['unexpected'];
          await manifestFile.writeAsString(jsonEncode(manifest));
        case 'changed database':
          await bundle.database.file.writeAsBytes([1, 2, 3]);
        case 'changed file':
          await retained.writeAsBytes([7, 5, 3, 1]);
        case 'redirected file':
          await retained.delete();
          await Link(retained.path).create(original.path);
        case 'unsupported schema':
        case 'injected trigger':
        case 'extra table':
        case 'changed table':
          final raw = sqlite.sqlite3.open(bundle.database.file.path);
          try {
            raw.execute(switch (damage) {
              'injected trigger' =>
                'CREATE TRIGGER erase_drafts AFTER INSERT ON local_metadata BEGIN DELETE FROM local_drafts; END',
              'extra table' => 'CREATE TABLE unexpected (value TEXT)',
              'changed table' =>
                'ALTER TABLE local_drafts ADD COLUMN unexpected TEXT',
              _ => 'PRAGMA user_version = 999',
            });
          } finally {
            raw.close();
          }
          manifest['database']['byteLength'] = await bundle.database.file
              .length();
          manifest['database']['sha256'] =
              (await sha256.bind(bundle.database.file.openRead()).first)
                  .toString();
          await manifestFile.writeAsString(jsonEncode(manifest));
      }
      await expectLater(
        VerifiedLocalSnapshotBundle.open(bundle.directory),
        ['injected trigger', 'extra table', 'changed table'].contains(damage)
            ? throwsA(
                isA<StateError>().having(
                  (error) => error.message,
                  'message',
                  'Checkpoint schema differs from the supported application schema.',
                ),
              )
            : throwsA(anything),
      );
      expect(await original.readAsBytes(), originalBytes);
      await (await harness.open()).verifyIntegrity();
    });
  }
}
