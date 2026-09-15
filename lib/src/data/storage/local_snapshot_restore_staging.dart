import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as paths;

import 'verified_local_snapshot_bundle.dart';
import 'local_database_snapshot.dart';

/// Copies only the reviewed checkpoint contents into a new private candidate.
/// No live database replacement, business command, path rewriting, or cloud
/// authorization occurs here. Activation requires a separate verified workflow.
Future<VerifiedLocalSnapshotBundle> stageLocalSnapshotRestore({
  required VerifiedLocalSnapshotBundle source,
  required File liveDatabaseFile,
}) async {
  await requireSelfContainedSnapshot(source.databaseFile.path);
  final privateRoot = await liveDatabaseFile.parent.resolveSymbolicLinks();
  final candidates = Directory(paths.join(privateRoot, 'restore_candidates'));
  await candidates.create(recursive: true);
  if (await candidates.resolveSymbolicLinks() != candidates.path) {
    throw StateError('Restore staging directory is redirected.');
  }
  final candidate = await candidates.createTemp('candidate-');
  try {
    await _copyVerifiedFile(
      source.databaseFile,
      File('${candidate.path}/snapshot.sqlite'),
      source.databaseDigest,
    );
    for (final entry in source.attachments) {
      final relative = 'files/${entry.relativePath}';
      await _copyVerifiedFile(
        File('${source.directory.path}/$relative'),
        File('${candidate.path}/$relative'),
        entry.digest,
      );
    }
    // The exact manifest that was reviewed must travel with the exact files.
    // A changed source cannot substitute a newly consistent but different set.
    final partial = File('${candidate.path}/manifest.json.partial');
    await _copyVerifiedFile(
      File('${source.directory.path}/manifest.json'),
      partial,
      source.manifestDigest,
    );
    await requireSelfContainedSnapshot(source.databaseFile.path);
    await partial.rename('${candidate.path}/manifest.json');
    return await VerifiedLocalSnapshotBundle.open(candidate);
  } on Object {
    try {
      await candidate.delete(recursive: true);
    } on FileSystemException {
      /* Preserve the original staging failure. */
    }
    rethrow;
  }
}

Future<void> _copyVerifiedFile(File source, File target, String digest) async {
  await target.parent.create(recursive: true);
  await source.copy(target.path);
  if ((await sha256.bind(target.openRead()).first).toString() != digest) {
    throw StateError('The checkpoint changed after it was reviewed.');
  }
  final output = await target.open(mode: FileMode.append);
  try {
    await output.flush();
  } finally {
    await output.close();
  }
}
