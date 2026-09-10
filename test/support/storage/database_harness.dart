import 'dart:io';

import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';

/// Reusable disk-backed harness. Each case owns its files and all connections;
/// no fixture can open the app's private database or the protected reference.
class DatabaseHarness {
  DatabaseHarness._(this.directory);

  final Directory directory;
  final List<LocalDatabase> _connections = [];
  File get file => File('${directory.path}/test.sqlite');

  static Future<DatabaseHarness> create() async => DatabaseHarness._(
    await Directory.systemTemp.createTemp('maintainiac-database-test-'),
  );

  Future<LocalDatabase> open() async {
    final database = LocalDatabase.file(file);
    _connections.add(database);
    await database.verifyIntegrity();
    return database;
  }

  Future<LocalRecordStore> openStore() async => LocalRecordStore(await open());

  Future<void> close(LocalDatabase database) async {
    await database.close();
    _connections.remove(database);
  }

  Future<void> dispose() async {
    for (final database in _connections.reversed) {
      await database.close();
    }
    _connections.clear();
    await directory.delete(recursive: true);
  }
}
