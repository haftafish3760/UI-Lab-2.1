import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as paths;
import 'local_database_snapshot.dart';
import 'local_database.dart';
import 'local_snapshot_bundle.dart';
import 'local_snapshot_restore_staging.dart';
import 'verified_local_snapshot_bundle.dart';

/// An isolated writable installation, never the live database. Construction
/// completes only after every reviewed byte has been copied and verified.
/// Activation and a restart-safe active-installation pointer are separate work.
class PreparedLocalRestore {
  PreparedLocalRestore._(this.directory, Map<String, String> references)
    : _references = Map.unmodifiable(references);
  final Directory directory;
  final Map<String, String> _references;
  Map<String, String> get checkpointReferenceAliases => Map.unmodifiable({
    for (final entry in _references.entries)
      entry.key: paths
          .relative(entry.value, from: directory.path)
          .replaceAll(paths.separator, '/'),
  });
  File get databaseFile => File('${directory.path}/maintainiac.sqlite');

  /// Carries historical references forward with the matching installation.
  /// This does not drain editors or authorize export of the private checkpoint.
  Future<LocalSnapshotBundle> captureCheckpoint(LocalDatabase database) async {
    final source = database.storageFile;
    if (source == null ||
        source.absolute.path != databaseFile.absolute.path ||
        await source.resolveSymbolicLinks() != databaseFile.absolute.path) {
      throw StateError('Checkpoint database belongs to another installation.');
    }
    return LocalSnapshotBundle.capture(
      database,
      resolveRetainedPath: resolveRetainedPath,
      referenceAliases: checkpointReferenceAliases,
    );
  }

  String resolveRetainedPath(String reference) {
    final mapped = _references[reference];
    if (mapped != null) return mapped;
    // Files newly retained after restore already belong to this installation.
    // Never fall back to an unregistered path from the former installation.
    final normalized = paths.normalize(reference);
    final attachments = paths.join(directory.path, 'attachments');
    final receipts = paths.join(directory.path, 'receipt_evidence', 'evidence');
    if (paths.isAbsolute(reference) &&
        normalized == reference &&
        (paths.isWithin(attachments, reference) ||
            paths.isWithin(receipts, reference))) {
      return reference;
    }
    throw StateError(
      'File reference does not belong to the restored installation.',
    );
  }

  /// Rebuilds reference mapping from the retained, immutable checkpoint manifest.
  /// The writable database is integrity-checked, not replaced by that checkpoint:
  /// edits made since preparation must survive reopening.
  static Future<PreparedLocalRestore> reopen(Directory installation) async {
    final root = await installation.resolveSymbolicLinks();
    if (root != installation.absolute.path ||
        paths.basename(root) != 'installation') {
      throw StateError(
        'Restore installation directory is redirected or unsupported.',
      );
    }
    final reviewed = await VerifiedLocalSnapshotBundle.open(
      installation.parent,
    );
    final databaseFile = File('$root/maintainiac.sqlite');
    await _requireRegularOwnedFile(databaseFile);
    final references = <String, String>{};
    for (final entry in reviewed.attachments) {
      final target = File('$root/${entry.relativePath}');
      await _requireRegularOwnedFile(target);
      if (await target.length() != entry.byteLength ||
          (await sha256.bind(target.openRead()).first).toString() !=
              entry.digest) {
        throw StateError(
          'Restored attachment contents are missing or damaged.',
        );
      }
      final previous = references[entry.sourcePath];
      if (previous != null && previous != target.path) {
        throw StateError('Ambiguous restored file reference.');
      }
      references[entry.sourcePath] = target.path;
    }
    for (final alias in reviewed.referenceAliases.entries) {
      references[alias.key] = '$root/${alias.value}';
    }
    final database = LocalDatabase.file(databaseFile);
    try {
      await database.verifyIntegrity();
    } finally {
      await database.close();
    }
    return PreparedLocalRestore._(Directory(root), references);
  }

  static Future<PreparedLocalRestore> prepare({
    required VerifiedLocalSnapshotBundle source,
    required File liveDatabaseFile,
  }) async {
    final staged = await stageLocalSnapshotRestore(
      source: source,
      liveDatabaseFile: liveDatabaseFile,
    );
    try {
      final runtime = await Directory(
        '${staged.directory.path}/installation',
      ).create();
      final references = <String, String>{};
      await _copyChecked(
        staged.databaseFile,
        File('${runtime.path}/maintainiac.sqlite'),
        staged.databaseDigest,
      );
      for (final entry in staged.attachments) {
        final target = File('${runtime.path}/${entry.relativePath}');
        final previous = references[entry.sourcePath];
        if (previous != null && previous != target.path) {
          throw StateError('Ambiguous restored file reference.');
        }
        await _copyChecked(
          File('${staged.directory.path}/files/${entry.relativePath}'),
          target,
          entry.digest,
        );
        references[entry.sourcePath] = target.path;
      }
      for (final alias in staged.referenceAliases.entries) {
        references[alias.key] = '${runtime.path}/${alias.value}';
      }
      await verifyDatabaseSnapshotFile('${runtime.path}/maintainiac.sqlite', 1);
      return PreparedLocalRestore._(runtime, references);
    } on Object {
      try {
        await staged.directory.delete(recursive: true);
      } on FileSystemException {
        // Only this invocation's staging directory is eligible for cleanup.
      }
      rethrow;
    }
  }
}

Future<void> _copyChecked(
  File source,
  File target,
  String expectedDigest,
) async {
  await target.parent.create(recursive: true);
  await source.copy(target.path);
  if ((await sha256.bind(target.openRead()).first).toString() !=
      expectedDigest) {
    throw StateError('Restore contents changed during preparation.');
  }
  final output = await target.open(mode: FileMode.append);
  try {
    await output.flush();
  } finally {
    await output.close();
  }
}

Future<void> _requireRegularOwnedFile(File file) async {
  if (await FileSystemEntity.type(file.path, followLinks: false) !=
          FileSystemEntityType.file ||
      await file.resolveSymbolicLinks() != file.absolute.path) {
    throw StateError(
      'Restore installation contains a missing or redirected file.',
    );
  }
}
