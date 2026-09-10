import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/prepared_local_restore.dart';
import 'package:ui_lab_2_1/src/data/storage/verified_local_snapshot_bundle.dart';

void main() {
  late Directory root;
  late LocalInstallationSelection selection;
  late PreparedLocalRestore candidate;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('installation-selection-');
    final persistence = await LocalPersistence.open(directory: root);
    final backup = await LocalSnapshotBundle.capture(persistence.database);
    candidate = await PreparedLocalRestore.prepare(
      source: await VerifiedLocalSnapshotBundle.open(backup.directory),
      liveDatabaseFile: persistence.database.storageFile!,
    );
    await persistence.close();
    selection = await LocalInstallationSelection.open(root);
  });
  tearDown(() async {
    await selection.close();
    await root.delete(recursive: true);
  });

  test(
    'selection and explicit rollback survive reopen without replacing databases',
    () async {
      final original = File('${root.path}/maintainiac.sqlite');
      final originalBytes = await original.readAsBytes();
      final selected = await selection.select(
        installation: candidate,
        expectedRevision: 0,
      );
      expect(selected.revision, 1);
      expect(selected.previous, '');
      await selection.close();
      selection = await LocalInstallationSelection.open(root);
      final restored = await selection.resolve(await selection.read());
      expect(restored!.directory.path, candidate.directory.path);
      final rolledBack = await selection.rollback(expectedRevision: 1);
      expect(rolledBack.revision, 2);
      expect(rolledBack.active, '');
      expect(rolledBack.previous, selected.active);
      expect(await selection.resolve(rolledBack), isNull);
      expect(await original.readAsBytes(), originalBytes);
      expect(await candidate.databaseFile.exists(), isTrue);
    },
  );

  test('stale selector cannot overwrite a newer decision', () async {
    final other = await LocalInstallationSelection.open(root);
    try {
      await selection.select(installation: candidate, expectedRevision: 0);
      await expectLater(
        other.select(installation: candidate, expectedRevision: 0),
        throwsStateError,
      );
      await expectLater(other.rollback(expectedRevision: 0), throwsStateError);
      expect((await other.read()).revision, 1);
    } finally {
      await other.close();
    }
  });

  test('missing selected database fails instead of falling back', () async {
    final state = await selection.select(
      installation: candidate,
      expectedRevision: 0,
    );
    await candidate.databaseFile.delete();
    await expectLater(
      selection.resolve(await selection.read()),
      throwsA(anything),
    );
    expect((await selection.read()).active, state.active);
    expect(await candidate.databaseFile.exists(), isFalse);
  });

  test(
    'failed rollback preserves current selection when original database is missing',
    () async {
      final state = await selection.select(
        installation: candidate,
        expectedRevision: 0,
      );
      await File('${root.path}/maintainiac.sqlite').delete();
      await expectLater(
        selection.rollback(expectedRevision: 1),
        throwsStateError,
      );
      expect((await selection.read()).active, state.active);
      expect((await selection.read()).revision, 1);
    },
  );

  test('traversal selection is rejected without filesystem access', () async {
    await expectLater(
      selection.resolve(
        const InstallationSelectionState(
          1,
          'restore_candidates/../../outside/installation',
          null,
        ),
      ),
      throwsStateError,
    );
    expect((await selection.read()).revision, 0);
  });

  test(
    'missing established selection database cannot reset to original',
    () async {
      await selection.select(installation: candidate, expectedRevision: 0);
      await selection.close();
      final file = File(
        '${root.path}/installation_selection/maintainiac.sqlite',
      );
      final bytes = await file.readAsBytes();
      await file.delete();
      await expectLater(
        LocalInstallationSelection.open(root),
        throwsStateError,
      );
      expect(await file.exists(), isFalse);
      await file.writeAsBytes(bytes, flush: true);
      selection = await LocalInstallationSelection.open(root);
      expect((await selection.read()).revision, 1);
    },
  );
}
