import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'local_record_integrity.dart';
import 'draft_session_registry.dart';

part 'local_database.g.dart';

/// One connection owner for the app. Domain services receive repositories,
/// never a database opened by a widget. Tests own isolated temporary files.
@DriftDatabase(include: {'local_database.drift'})
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.executor, {this.storageFile});

  final File? storageFile;
  final draftSessions = DraftSessionRegistry();

  factory LocalDatabase.file(File file) => LocalDatabase(
    NativeDatabase.createInBackground(file, setup: _configureConnection),
    storageFile: file,
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      // Every future upgrade requires an explicit, tested migration.
      throw StateError('Unsupported database upgrade: $from to $to.');
    },
    beforeOpen: (details) async {
      if (storageFile != null) {
        final journal = await customSelect('PRAGMA journal_mode').getSingle();
        final synchronization = await customSelect(
          'PRAGMA synchronous',
        ).getSingle();
        if (journal.data.values.single != 'wal' ||
            synchronization.data.values.single != 2) {
          throw StateError(
            'Required local database durability is unavailable.',
          );
        }
      }
      await customStatement('PRAGMA foreign_keys = ON');
      final foreignKeys = await customSelect('PRAGMA foreign_keys').getSingle();
      if (foreignKeys.read<int>('foreign_keys') != 1) {
        throw StateError('Database relationship enforcement is unavailable.');
      }
    },
  );

  Future<void> verifyIntegrity() => transaction(() async {
    final integrity = await customSelect('PRAGMA quick_check').get();
    if (integrity.length != 1 || integrity.single.data.values.single != 'ok') {
      throw StateError('Local database integrity check failed.');
    }
    if ((await customSelect('PRAGMA foreign_key_check').get()).isNotEmpty) {
      throw StateError('Local database contains invalid relationships.');
    }
    await verifyLocalRecordHistory(
      (sql, arguments) async => (await customSelect(
        sql,
        variables: [for (final value in arguments) Variable<int>(value)],
      ).get()).map((row) => row.data).toList(),
    );
  });
}

// Runs on the database isolate before schema migration. FULL ensures that
// acknowledging a commit waits for SQLite's durability boundary.
void _configureConnection(sqlite.Database database) {
  database.execute('PRAGMA journal_mode = WAL');
  database.execute('PRAGMA synchronous = FULL');
  database.execute('PRAGMA foreign_keys = ON');
  database.execute('PRAGMA busy_timeout = 5000');
}
