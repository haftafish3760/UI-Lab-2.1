import 'dart:io';
import 'package:path/path.dart' as paths;
import 'verified_local_snapshot_bundle.dart';

import 'local_restore_controller.dart';
export 'local_restore_controller.dart' show LocalCheckpointSummary;

/// Enumerates app-private checkpoint directories without exposing filesystem or
/// SQL objects to a future presentation. Invalid/partial entries remain visible
/// as unavailable; discovery never deletes, repairs or activates anything.
Future<List<LocalCheckpointSummary>> listLocalCheckpoints(File database) async {
  final canonicalDatabase = await database.resolveSymbolicLinks();
  final root = Directory(
    paths.join(paths.dirname(canonicalDatabase), 'database_checkpoints'),
  );
  final type = await FileSystemEntity.type(root.path, followLinks: false);
  if (type == FileSystemEntityType.notFound) return const [];
  if (type != FileSystemEntityType.directory ||
      await root.resolveSymbolicLinks() != root.path) {
    throw StateError('Checkpoint location is redirected or unavailable.');
  }
  final entries = <LocalCheckpointSummary>[];
  await for (final entity in root.list(followLinks: false)) {
    // Ordinary files are not checkpoint candidates. Never traverse links.
    if (entity is! Directory && entity is! Link) continue;
    final id = paths.basename(entity.path);
    try {
      if (entity is Link ||
          await entity.resolveSymbolicLinks() != entity.path) {
        throw StateError('Checkpoint location is redirected.');
      }
      final verified = await VerifiedLocalSnapshotBundle.open(
        Directory(entity.path),
      );
      entries.add(
        LocalCheckpointSummary(
          checkpointId: id,
          isVerified: true,
          databaseBytes: await verified.databaseFile.length(),
          attachmentCount: verified.attachments.length,
        ),
      );
    } on Object {
      // Keep one damaged/incomplete candidate from hiding other saved work.
      // No raw path or parser error is needed by the selection UI.
      entries.add(LocalCheckpointSummary(checkpointId: id, isVerified: false));
    }
  }
  entries.sort((a, b) => a.checkpointId.compareTo(b.checkpointId));
  return List.unmodifiable(entries);
}
