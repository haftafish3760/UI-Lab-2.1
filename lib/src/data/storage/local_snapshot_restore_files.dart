import 'dart:io';

import 'verified_local_snapshot_bundle.dart';

/// Verified file relocation for an isolated restore candidate. Historical JSON
/// and its integrity hashes remain untouched: callers resolve retained source
/// references through this mapping instead of rewriting audit records.
/// This is not authority to activate the candidate or expose another scope.
class LocalSnapshotRestoreFiles {
  LocalSnapshotRestoreFiles._(Map<String, File> files)
    : _files = Map.unmodifiable(files);
  final Map<String, File> _files;
  int get length => _files.length;

  /// Unknown references fail closed rather than reading an arbitrary old path.
  File resolve(String retainedSourcePath) {
    final file = _files[retainedSourcePath];
    if (file == null) {
      throw StateError('The restored checkpoint does not contain this file.');
    }
    return file;
  }

  static Future<LocalSnapshotRestoreFiles> open(
    VerifiedLocalSnapshotBundle reviewed,
  ) async {
    // Verification objects describe a past observation, not a permanent lease.
    final current = await VerifiedLocalSnapshotBundle.open(reviewed.directory);
    if (current.databaseDigest != reviewed.databaseDigest ||
        current.manifestDigest != reviewed.manifestDigest) {
      throw StateError('The restore candidate changed after review.');
    }
    final mapped = <String, File>{};
    for (final entry in current.attachments) {
      final file = File(
        '${current.directory.path}/files/${entry.relativePath}',
      );
      final previous = mapped[entry.sourcePath];
      if (previous != null && previous.path != file.path) {
        throw StateError(
          'The restore candidate has ambiguous file references.',
        );
      }
      mapped[entry.sourcePath] = file;
    }
    for (final alias in current.referenceAliases.entries) {
      mapped[alias.key] = File(
        '${current.directory.path}/files/${alias.value}',
      );
    }
    return LocalSnapshotRestoreFiles._(mapped);
  }
}
