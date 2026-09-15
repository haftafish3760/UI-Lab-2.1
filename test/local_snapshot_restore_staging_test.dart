import 'package:ui_lab_2_1/src/data/storage/prepared_local_restore.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_restore_files.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_restore_staging.dart';
import 'package:ui_lab_2_1/src/data/storage/verified_local_snapshot_bundle.dart';

import 'support/storage/database_harness.dart';

void main() {
  late DatabaseHarness harness;
  late LocalDatabase live;
  late LocalDraftStore drafts;
  setUp(() async {
    harness = await DatabaseHarness.create();
    live = await harness.open();
    drafts = LocalDraftStore(live);
  });
  tearDown(() async => harness.dispose());

  Future<void> save(String text, int revision) => drafts.save(
    organizationId: 'company',
    domain: 'invoice',
    draftId: 'unfinished',
    ownerId: 'alex',
    expectedRevision: revision,
    payload: {'amount': text, 'note': '  keep this  '},
    occurredAt: DateTime.now(),
  );

  Future<VerifiedLocalSnapshotBundle> checkpoint() async {
    await save('12.', 0);
    final picker = File('${harness.directory.path}/picker.jpg');
    await picker.writeAsBytes([1, 2, 3], flush: true);
    await LocalAttachmentStore(
      live,
    ).retain(source: picker, organizationId: 'company', ownerId: 'alex');
    final bundle = await LocalSnapshotBundle.capture(live);
    return VerifiedLocalSnapshotBundle.open(bundle.directory);
  }

  test(
    'staged candidate reopens old drafts independently without replacing live input',
    () async {
      final source = await checkpoint();
      await save('newer live input', 1);
      final staged = await stageLocalSnapshotRestore(
        source: source,
        liveDatabaseFile: harness.file,
      );
      final files = await LocalSnapshotRestoreFiles.open(staged);
      final reference = staged.attachments.single.sourcePath;
      expect(files.length, 1);
      expect(
        () => files.resolve('/unregistered/private/file'),
        throwsStateError,
      );
      await source.directory.delete(recursive: true);
      await File(reference).delete();
      expect(await files.resolve(reference).readAsBytes(), [1, 2, 3]);
      final db = LocalDatabase.file(staged.databaseFile);
      try {
        await db.verifyIntegrity();
        final row = await LocalDraftStore(db).find(
          organizationId: 'company',
          domain: 'invoice',
          draftId: 'unfinished',
          ownerId: 'alex',
        );
        expect(LocalDraftStore(db).decode(row!), {
          'amount': '12.',
          'note': '  keep this  ',
        });
        final current = await drafts.find(
          organizationId: 'company',
          domain: 'invoice',
          draftId: 'unfinished',
          ownerId: 'alex',
        );
        expect(drafts.decode(current!)['amount'], 'newer live input');
        expect(
          await File(
            '${staged.directory.path}/files/${staged.attachments.single.relativePath}',
          ).readAsBytes(),
          [1, 2, 3],
        );
      } finally {
        await db.close();
      }
    },
  );

  test(
    'redirected staging directory is rejected without writing outside the live root',
    () async {
      final source = await checkpoint();
      final outside = await harness.directory.createTemp('unrelated-');
      final marker = File.fromUri(outside.uri.resolve('keep.txt'));
      await marker.writeAsString('unrelated content', flush: true);
      final staging = Link('${harness.directory.path}/restore_candidates');
      await staging.create(outside.path);
      await expectLater(
        stageLocalSnapshotRestore(
          source: source,
          liveDatabaseFile: harness.file,
        ),
        throwsStateError,
      );
      expect((await outside.list().toList()).map((entry) => entry.path), [
        marker.path,
      ]);
      expect(await marker.readAsString(), 'unrelated content');
      await live.verifyIntegrity();
      final current = await drafts.find(
        organizationId: 'company',
        domain: 'invoice',
        draftId: 'unfinished',
        ownerId: 'alex',
      );
      expect(drafts.decode(current!)['amount'], '12.');
    },
  );

  test(
    'restore file resolver rechecks candidate contents before exposing paths',
    () async {
      final staged = await stageLocalSnapshotRestore(
        source: await checkpoint(),
        liveDatabaseFile: harness.file,
      );
      final file = File(
        '${staged.directory.path}/files/${staged.attachments.single.relativePath}',
      );
      await file.writeAsBytes([9, 9, 9], flush: true);
      await expectLater(
        LocalSnapshotRestoreFiles.open(staged),
        throwsStateError,
      );
      await live.verifyIntegrity();
    },
  );

  test(
    'writable restored installation retains history while live input stays newer',
    () async {
      final source = await checkpoint();
      await save('newer live input', 1);
      final prepared = await PreparedLocalRestore.prepare(
        source: source,
        liveDatabaseFile: harness.file,
      );
      final originalReference = source.attachments.single.sourcePath;
      await source.directory.delete(recursive: true);
      expect(
        await File(
          prepared.resolveRetainedPath(originalReference),
        ).readAsBytes(),
        [1, 2, 3],
      );
      expect(
        () => prepared.resolveRetainedPath(
          '${harness.directory.path}/private.image',
        ),
        throwsStateError,
      );
      final newlyRetained = File.fromUri(
        prepared.directory.uri.resolve('attachments/new/image'),
      ).path;
      expect(prepared.resolveRetainedPath(newlyRetained), newlyRetained);
      expect(
        () => prepared.resolveRetainedPath(
          '${prepared.directory.path}/attachments/../../outside',
        ),
        throwsStateError,
      );
      final restored = LocalDatabase.file(prepared.databaseFile);
      try {
        final restoredDrafts = LocalDraftStore(restored);
        final row = await restoredDrafts.find(
          organizationId: 'company',
          domain: 'invoice',
          draftId: 'unfinished',
          ownerId: 'alex',
        );
        expect(restoredDrafts.decode(row!)['amount'], '12.');
        await restoredDrafts.save(
          organizationId: 'company',
          domain: 'invoice',
          draftId: 'unfinished',
          ownerId: 'alex',
          expectedRevision: 1,
          payload: {'amount': 'restored edit'},
          occurredAt: DateTime.now(),
        );
        final current = await drafts.find(
          organizationId: 'company',
          domain: 'invoice',
          draftId: 'unfinished',
          ownerId: 'alex',
        );
        expect(drafts.decode(current!)['amount'], 'newer live input');
        await live.verifyIntegrity();
        await restored.verifyIntegrity();
      } finally {
        await restored.close();
      }
      final reopened = await PreparedLocalRestore.reopen(prepared.directory);
      expect(
        await File(
          reopened.resolveRetainedPath(originalReference),
        ).readAsBytes(),
        [1, 2, 3],
      );
      final reopenedDatabase = LocalDatabase.file(reopened.databaseFile);
      try {
        final recovered = await LocalDraftStore(reopenedDatabase).find(
          organizationId: 'company',
          domain: 'invoice',
          draftId: 'unfinished',
          ownerId: 'alex',
        );
        expect(
          LocalDraftStore(reopenedDatabase).decode(recovered!)['amount'],
          'restored edit',
        );
      } finally {
        await reopenedDatabase.close();
      }
      final retainedFile = File(
        reopened.resolveRetainedPath(originalReference),
      );
      final contents = await retainedFile.readAsBytes();
      await retainedFile.delete();
      await expectLater(
        PreparedLocalRestore.reopen(prepared.directory),
        throwsStateError,
      );
      final redirect = Link(retainedFile.path);
      await redirect.create(originalReference);
      await expectLater(
        PreparedLocalRestore.reopen(prepared.directory),
        throwsStateError,
      );
      await redirect.delete();
      await retainedFile.writeAsBytes(contents, flush: true);
      await prepared.databaseFile.delete();
      await expectLater(
        PreparedLocalRestore.reopen(prepared.directory),
        throwsStateError,
      );
      expect(await prepared.databaseFile.exists(), isFalse);
      await live.verifyIntegrity();
    },
  );

  test(
    'attachment aliases survive three restore generations without older installations',
    () async {
      final source = await checkpoint();
      final originalReference = source.attachments.single.sourcePath;
      var installation = await PreparedLocalRestore.prepare(
        source: source,
        liveDatabaseFile: harness.file,
      );
      await expectLater(installation.captureCheckpoint(live), throwsStateError);
      await source.directory.delete(recursive: true);
      await File(originalReference).delete();
      for (var generation = 0; generation < 3; generation++) {
        final database = LocalDatabase.file(installation.databaseFile);
        late PreparedLocalRestore next;
        try {
          final backup = await installation.captureCheckpoint(database);
          next = await PreparedLocalRestore.prepare(
            source: await VerifiedLocalSnapshotBundle.open(backup.directory),
            liveDatabaseFile: harness.file,
          );
        } finally {
          await database.close();
        }
        await installation.directory.parent.delete(recursive: true);
        installation = await PreparedLocalRestore.reopen(next.directory);
        expect(
          await File(
            installation.resolveRetainedPath(originalReference),
          ).readAsBytes(),
          [1, 2, 3],
        );
      }
    },
  );

  test(
    'checkpoint aliases cannot substitute another attachment identity',
    () async {
      final source = await checkpoint();
      final relative = source.attachments.single.relativePath;
      await expectLater(
        LocalSnapshotBundle.capture(
          live,
          referenceAliases: {'/old/attachments/wrong-file.image': relative},
        ),
        throwsStateError,
      );
      await live.verifyIntegrity();
    },
  );

  for (final changed in ['database', 'attachment', 'manifest']) {
    test(
      'changed $changed aborts staging and preserves source and live state',
      () async {
        final source = await checkpoint();
        await save('newer live input', 1);
        final path = switch (changed) {
          'database' => source.databaseFile.path,
          'attachment' =>
            '${source.directory.path}/files/${source.attachments.single.relativePath}',
          _ => '${source.directory.path}/manifest.json',
        };
        final target = File(path);
        final bytes = await target.readAsBytes();
        // Keep JSON valid when altering the manifest; its reviewed digest matters.
        await target.writeAsBytes([...bytes, 32], flush: true);
        await expectLater(
          stageLocalSnapshotRestore(
            source: source,
            liveDatabaseFile: harness.file,
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'The checkpoint changed after it was reviewed.',
            ),
          ),
        );
        expect(
          await Directory(
            '${harness.directory.path}/restore_candidates',
          ).list().toList(),
          isEmpty,
        );
        expect(await target.readAsBytes(), [...bytes, 32]);
        final current = await drafts.find(
          organizationId: 'company',
          domain: 'invoice',
          draftId: 'unfinished',
          ownerId: 'alex',
        );
        expect(drafts.decode(current!)['amount'], 'newer live input');
        await live.verifyIntegrity();
      },
    );
  }
}
