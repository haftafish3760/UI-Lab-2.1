import 'snapshot_reference_aliases.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import 'local_database.dart';
import 'local_database_snapshot.dart';
import 'local_snapshot_attachment.dart';

/// Private checkpoint with registered retained files. No export/upload/restore
/// authorization is implied. A coordinator still needs to drain editor writes,
/// enforce permissions, encrypt transport, and implement verified restoration.
class LocalSnapshotBundle {
  LocalSnapshotBundle._(
    this.database,
    List<LocalSnapshotAttachment> attachments,
  ) : attachments = List.unmodifiable(attachments);
  final LocalDatabaseSnapshot database;
  final List<LocalSnapshotAttachment> attachments;
  Directory get directory => database.file.parent;

  static Future<LocalSnapshotBundle> capture(
    LocalDatabase source, {
    String Function(String)? resolveRetainedPath,
    Map<String, String> referenceAliases = const {},
  }) async {
    final snapshot = await LocalDatabaseSnapshot.capture(source);
    try {
      final sourceRoot = source.storageFile!.parent.path;
      final canonicalRoot = await source.storageFile!.parent
          .resolveSymbolicLinks();
      final entries = await Isolate.run(
        () => readSnapshotAttachments(snapshot.file.path, sourceRoot),
      );
      final aliases = validateSnapshotReferenceAliases(
        referenceAliases,
        entries,
      );
      for (final entry in entries) {
        final original = File(
          resolveRetainedPath?.call(entry.sourcePath) ?? entry.sourcePath,
        );
        // Do not allow a manifest (or a symlink below the retained root) to
        // cause copying unrelated files from elsewhere on the device.
        if (await original.resolveSymbolicLinks() !=
            File.fromUri(
              Directory(canonicalRoot).uri.resolve(entry.relativePath),
            ).path) {
          throw StateError('Retained file is outside its registered location.');
        }
        final target = File(
          '${snapshot.file.parent.path}/files/${entry.relativePath}',
        );
        await target.parent.create(recursive: true);
        await original.copy(target.path);
        if (await target.length() != entry.byteLength ||
            (await sha256.bind(target.openRead()).first).toString() !=
                entry.digest) {
          throw StateError('Retained file is missing or changed.');
        }
        final retained = await target.open(mode: FileMode.append);
        try {
          await retained.flush();
        } finally {
          await retained.close();
        }
      }
      // Publish a completion manifest only after every registered file verifies.
      // Interrupted staging remains distinguishable from a completed bundle.
      final manifest = File('${snapshot.file.parent.path}/manifest.json');
      final temporary = File('${manifest.path}.partial');
      await temporary.writeAsString(
        jsonEncode({
          'format': 'maintainiac-private-checkpoint',
          'version': 1,
          'sourceStorageRoot': sourceRoot,
          if (aliases.isNotEmpty) 'referenceAliases': aliases,
          'database': {
            'file': 'snapshot.sqlite',
            'schemaVersion': snapshot.schemaVersion,
            'byteLength': snapshot.byteLength,
            'sha256': snapshot.sha256Digest,
          },
          'attachments': entries.map((entry) => entry.toJson()).toList(),
        }),
        flush: true,
      );
      await temporary.rename(manifest.path);
      return LocalSnapshotBundle._(snapshot, entries);
    } on Object {
      try {
        await snapshot.file.parent.delete(recursive: true);
      } on FileSystemException {
        /* Keep the original failure. */
      }
      rethrow;
    }
  }
}
