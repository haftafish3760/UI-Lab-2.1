import 'snapshot_reference_aliases.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import 'local_database_snapshot.dart';
import 'local_record_command.dart';
import 'local_snapshot_attachment.dart';

/// Verified contents of an app-private checkpoint at the time of checking.
/// Hashes detect corruption; they do not authenticate an external backup.
/// Never treats verification as permission to replace live data or upload it.
/// Restore must copy into isolated staging and reverify before activation.
class VerifiedLocalSnapshotBundle {
  VerifiedLocalSnapshotBundle._({
    required this.directory,
    required this.databaseFile,
    required this.databaseDigest,
    required this.manifestDigest,
    required this.referenceAliases,
    required List<LocalSnapshotAttachment> attachments,
  }) : attachments = List.unmodifiable(attachments);
  final Directory directory;
  final File databaseFile;
  final String databaseDigest;
  final String manifestDigest;
  final Map<String, String> referenceAliases;
  final List<LocalSnapshotAttachment> attachments;

  // Bound metadata allocation before decoding; data files are hashed as streams.
  static const maximumManifestBytes = 16 * 1024 * 1024;

  static Future<VerifiedLocalSnapshotBundle> open(Directory directory) async {
    final root = await directory.resolveSymbolicLinks();
    final manifestFile = File('$root/manifest.json');
    await _requireRetainedPath(manifestFile, root, 'manifest.json');
    final bytes = await manifestFile
        .openRead(0, maximumManifestBytes + 1)
        .fold<List<int>>([], (all, part) => all..addAll(part));
    if (bytes.length > maximumManifestBytes) {
      throw StateError('Checkpoint manifest exceeds the supported size.');
    }
    final manifest = (jsonDecode(utf8.decode(bytes)) as Map)
        .cast<String, Object?>();
    if (manifest['format'] != 'maintainiac-private-checkpoint' ||
        manifest['version'] != 1 ||
        manifest['sourceStorageRoot'] is! String ||
        (manifest['sourceStorageRoot'] as String).isEmpty) {
      throw StateError('Unsupported checkpoint manifest.');
    }
    final database = (manifest['database'] as Map).cast<String, Object?>();
    if (database['file'] != 'snapshot.sqlite' ||
        database['schemaVersion'] != 1) {
      throw StateError('Unsupported checkpoint database.');
    }
    final file = File('$root/snapshot.sqlite');
    await _requireRetainedPath(file, root, 'snapshot.sqlite');
    await _verifyContents(file, database['byteLength'], database['sha256']);
    final sourceRoot = manifest['sourceStorageRoot'] as String;
    final path = file.path;
    final entries = await Isolate.run(() async {
      await verifyDatabaseSnapshotFile(path, 1);
      return readSnapshotAttachments(path, sourceRoot);
    });
    // Do not trust a manifest that quietly omits SQL-registered evidence or
    // substitutes an arbitrary device path. Only SQL-derived relative paths
    // are used to locate files inside this checkpoint.
    if (canonicalJson(manifest['attachments']) !=
        canonicalJson(entries.map((entry) => entry.toJson()).toList())) {
      throw StateError('Checkpoint files disagree with the database.');
    }
    for (final entry in entries) {
      final relative = 'files/${entry.relativePath}';
      final attachment = File('$root/$relative');
      await _requireRetainedPath(attachment, root, relative);
      await _verifyContents(attachment, entry.byteLength, entry.digest);
    }
    await requireSelfContainedSnapshot(file.path);
    return VerifiedLocalSnapshotBundle._(
      directory: Directory(root),
      databaseFile: file,
      databaseDigest: database['sha256'] as String,
      manifestDigest: sha256.convert(bytes).toString(),
      attachments: entries,
      referenceAliases: validateSnapshotReferenceAliases(
        manifest['referenceAliases'],
        entries,
      ),
    );
  }
}

Future<void> _requireRetainedPath(
  File file,
  String root,
  String relative,
) async {
  final expected = File.fromUri(Directory(root).uri.resolve(relative)).path;
  if (await file.resolveSymbolicLinks() != expected) {
    throw StateError('Checkpoint contains a redirected file.');
  }
}

Future<void> _verifyContents(File file, Object? length, Object? digest) async {
  if (length is! int ||
      length < 1 ||
      digest is! String ||
      !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest) ||
      await file.length() != length ||
      (await sha256.bind(file.openRead()).first).toString() != digest) {
    throw StateError('Checkpoint contents are missing or damaged.');
  }
}
