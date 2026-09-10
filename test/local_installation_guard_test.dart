import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('installation-guard-');
  });
  tearDown(() async => root.delete(recursive: true));

  test(
    'clean first launch and pre-guard database reopen preserve drafts',
    () async {
      var persistence = await LocalPersistence.open(directory: root);
      await persistence.drafts.save(
        organizationId: 'business',
        domain: 'invoice',
        draftId: 'unfinished',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: {'amount': '12.', 'notes': '  unfinished  '},
        occurredAt: DateTime.utc(2026),
      );
      await persistence.close();
      final marker = File('${root.path}/sqlite-installation-established');
      await marker.delete(); // Simulate an installation predating this guard.
      persistence = await LocalPersistence.open(directory: root);
      final saved = await persistence.drafts.find(
        organizationId: 'business',
        domain: 'invoice',
        draftId: 'unfinished',
        ownerId: 'owner',
      );
      expect(persistence.drafts.decode(saved!)['notes'], '  unfinished  ');
      expect(await marker.exists(), isTrue);
      await persistence.close();
    },
  );

  test('missing established database is not silently recreated', () async {
    final persistence = await LocalPersistence.open(directory: root);
    await persistence.close();
    final database = File('${root.path}/maintainiac.sqlite');
    await database.delete();
    await expectLater(LocalPersistence.open(directory: root), throwsStateError);
    expect(await database.exists(), isFalse);
  });

  for (final length in [0, 25]) {
    test('existing $length-byte database remains untouched', () async {
      final file = File('${root.path}/maintainiac.sqlite');
      final bytes = List<int>.filled(length, 42);
      await file.writeAsBytes(bytes, flush: true);
      await expectLater(
        LocalPersistence.open(directory: root),
        throwsStateError,
      );
      expect(await file.readAsBytes(), bytes);
      expect(
        await File('${root.path}/sqlite-installation-established').exists(),
        isFalse,
      );
    });
  }

  for (final remnant in [
    'maintainiac.sqlite-wal',
    'maintainiac.sqlite-shm',
    'maintainiac.sqlite-journal',
    'attachments',
    'receipt_evidence',
    'database_checkpoints',
    'restore_candidates',
  ]) {
    test(
      'missing database preserves $remnant and refuses new storage',
      () async {
        final file = File('${root.path}/$remnant');
        await file.writeAsString('retained evidence', flush: true);
        await expectLater(
          LocalPersistence.open(directory: root),
          throwsStateError,
        );
        expect(await file.readAsString(), 'retained evidence');
        expect(await File('${root.path}/maintainiac.sqlite').exists(), isFalse);
      },
    );
  }

  test('database symlink is not followed or overwritten', () async {
    final original = File('${root.path}/unrelated');
    await original.writeAsBytes(List.filled(120, 42), flush: true);
    final link = Link('${root.path}/maintainiac.sqlite');
    await link.create(original.path);
    await expectLater(LocalPersistence.open(directory: root), throwsStateError);
    expect(await original.readAsBytes(), List.filled(120, 42));
    expect(await link.exists(), isTrue);
  });
}
