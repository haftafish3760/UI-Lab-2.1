import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'local_database.dart';
import 'local_record_command.dart';
import 'local_snapshot_schema.dart';
import 'local_record_integrity.dart';

/// Internal SQL checkpoint only: contains all database scopes and raw drafts.
/// Not an export, a portable attachment bundle, or an authorized cloud payload.
/// Callers must separately drain editors if they need their pending input and
/// assemble/verify referenced files before describing anything as a backup.
class LocalDatabaseSnapshot {
  const LocalDatabaseSnapshot._({
    required this.file,
    required this.byteLength,
    required this.sha256Digest,
    required this.schemaVersion,
  });

  final File file;
  final int byteLength;
  final String sha256Digest;
  final int schemaVersion;

  /// SQLite captures one consistent committed view, including uncheckpointed
  /// WAL data. Never copy the live .sqlite file alone. The destination is unique
  /// and remains in the database's app-owned directory; no caller-selected path
  /// can overwrite an existing record, checkpoint, or unrelated user file.
  static Future<LocalDatabaseSnapshot> capture(LocalDatabase database) async {
    final source = database.storageFile;
    if (source == null) {
      throw StateError('A file-backed database is required for a checkpoint.');
    }
    await database.verifyIntegrity();
    final privateRoot = await source.parent.resolveSymbolicLinks();
    final root = Directory('$privateRoot/database_checkpoints');
    await root.create(recursive: true);
    if (await root.resolveSymbolicLinks() != root.path) {
      throw StateError('Checkpoint directory is redirected.');
    }
    final staging = await root.createTemp('checkpoint-');
    final target = File('${staging.path}/snapshot.sqlite');
    try {
      await database.customStatement('VACUUM main INTO ?', [target.path]);
      final version = database.schemaVersion;
      await Isolate.run(() => verifyDatabaseSnapshotFile(target.path, version));
      final output = await target.open(mode: FileMode.append);
      try {
        await output.flush();
      } finally {
        await output.close();
      }
      final length = await target.length();
      final digest = (await sha256.bind(target.openRead()).first).toString();
      return LocalDatabaseSnapshot._(
        file: target,
        byteLength: length,
        sha256Digest: digest,
        schemaVersion: version,
      );
    } on Object {
      // Only this invocation's unique staging directory is eligible for cleanup.
      // Interrupted processes may leave staging files; existence alone must
      // never be interpreted by a future recovery flow as a valid checkpoint.
      try {
        await staging.delete(recursive: true);
      } on FileSystemException {
        // Preserve the original capture/validation failure for the caller.
      }
      rethrow;
    }
  }
}

Future<void> verifyDatabaseSnapshotFile(
  String path,
  int expectedVersion,
) async {
  await requireSelfContainedSnapshot(path);
  final expectedSchema = await expectedLocalSnapshotSchema(expectedVersion);
  final database = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
  try {
    database.execute('PRAGMA trusted_schema = OFF');
    database.execute('PRAGMA query_only = ON');
    database.execute('BEGIN');
    final actualSchema = canonicalJson(
      database
          .select(localSnapshotSchemaQuery)
          .map((row) => Map<String, Object?>.from(row))
          .toList(),
    );
    if (actualSchema != expectedSchema) {
      throw StateError(
        'Checkpoint schema differs from the supported application schema.',
      );
    }
    final integrity = database.select('PRAGMA integrity_check');
    if (integrity.length != 1 ||
        integrity.single.values.single != 'ok' ||
        database.select('PRAGMA foreign_key_check').isNotEmpty ||
        database.select('PRAGMA user_version').single.values.single !=
            expectedVersion) {
      throw StateError('Database checkpoint verification failed.');
    }
    await verifyLocalRecordHistory(
      (sql, arguments) async => database
          .select(sql, arguments)
          .map((row) => Map<String, Object?>.from(row))
          .toList(),
    );
  } finally {
    database.close();
  }
  await requireSelfContainedSnapshot(path);
}

/// The main-file digest cannot cover committed changes in a separate journal.
/// Empty WAL and its derived shared-memory index may be created by a reader.
Future<void> requireSelfContainedSnapshot(String path) async {
  for (final suffix in ['-wal', '-journal', '-shm']) {
    final sidecar = File('$path$suffix');
    final type = await FileSystemEntity.type(sidecar.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) continue;
    if (type != FileSystemEntityType.file ||
        (suffix != '-shm' && await sidecar.length() != 0)) {
      throw StateError('Checkpoint contains unverified SQLite sidecar data.');
    }
  }
}
