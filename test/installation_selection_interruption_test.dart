import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/prepared_local_restore.dart';
import 'package:ui_lab_2_1/src/data/storage/verified_local_snapshot_bundle.dart';

void main() {
  for (final mode in ['uncommitted', 'committed', 'rollback']) {
    test('SIGKILL preserves the acknowledged selection: $mode', () async {
      var root = await Directory.systemTemp.createTemp(
        'selection-interruption-fixture-',
      );
      root = Directory(await root.resolveSymbolicLinks());
      final original = File('${root.path}/maintainiac.sqlite');
      final db = LocalDatabase.file(original);
      late PreparedLocalRestore candidate;
      try {
        await db.verifyIntegrity();
        final snapshot = await LocalSnapshotBundle.capture(db);
        candidate = await PreparedLocalRestore.prepare(
          source: await VerifiedLocalSnapshotBundle.open(snapshot.directory),
          liveDatabaseFile: original,
        );
      } finally {
        await db.close();
      }
      var selection = await LocalInstallationSelection.open(root);
      final relative = candidate.directory.path.substring(root.path.length + 1);
      if (mode == 'rollback') {
        await selection.select(installation: candidate, expectedRevision: 0);
      }
      await selection.close();
      final originalBytes = await original.readAsBytes();
      // Opening a prepared copy establishes WAL mode (SQLite header bytes
      // legitimately change). Compare bytes after that normal initialization.
      await PreparedLocalRestore.reopen(candidate.directory);
      final candidateBytes = await candidate.databaseFile.readAsBytes();
      final process = await Process.start('dart', [
        'run',
        'test/support/storage/installation_selection_crash_writer.dart',
        root.path,
        mode,
        mode == 'uncommitted' ? relative : candidate.directory.path,
      ]);
      final errors = process.stderr.transform(utf8.decoder).join();
      try {
        await process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .firstWhere((line) => line == 'SELECTION_WRITE_READY')
            .timeout(const Duration(seconds: 45));
        expect(process.kill(ProcessSignal.sigkill), isTrue);
        await process.exitCode.timeout(const Duration(seconds: 10));
        selection = await LocalInstallationSelection.open(root);
        try {
          final state = await selection.read();
          expect(state.revision, switch (mode) {
            'committed' => 1,
            'rollback' => 2,
            _ => 0,
          });
          expect(state.active, mode == 'committed' ? relative : '');
          final resolved = await selection.resolve(state);
          expect(
            resolved?.directory.path,
            mode == 'committed' ? candidate.directory.path : null,
          );
          expect(await original.readAsBytes(), originalBytes);
          expect(await candidate.databaseFile.readAsBytes(), candidateBytes);
        } finally {
          await selection.close();
        }
      } catch (error) {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode;
        fail('$error\n${await errors}');
      } finally {
        await root.delete(recursive: true);
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  }
}
