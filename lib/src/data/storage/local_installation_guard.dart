import 'dart:io';

/// Distinguishes a clean first launch from missing storage in an installation
/// that has already opened successfully. Never repairs, resets or deletes data.
class LocalInstallationGuard {
  LocalInstallationGuard(this.directory);
  final Directory directory;
  File get databaseFile => File('${directory.path}/maintainiac.sqlite');
  File get _marker => File('${directory.path}/sqlite-installation-established');

  Future<void> verifyBeforeOpen() async {
    final type = await FileSystemEntity.type(
      databaseFile.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.file) {
      // An existing empty/truncated file must not trigger SQLite onCreate.
      if (await databaseFile.length() < 100) {
        throw StateError('The saved database is incomplete.');
      }
      return;
    }
    if (type != FileSystemEntityType.notFound) {
      throw StateError('The saved database location is redirected or invalid.');
    }
    for (final name in [
      'sqlite-installation-established',
      'maintainiac.sqlite-wal',
      'maintainiac.sqlite-shm',
      'maintainiac.sqlite-journal',
      'attachments',
      'receipt_evidence',
      'database_checkpoints',
      'restore_candidates',
    ]) {
      if (await FileSystemEntity.type(
            '${directory.path}/$name',
            followLinks: false,
          ) !=
          FileSystemEntityType.notFound) {
        throw StateError(
          'The saved database is missing from this installation.',
        );
      }
    }
  }

  /// Publish before handing writable repositories to the application. Presence
  /// alone is meaningful, including an interrupted marker write. Existing valid
  /// databases from before this guard are adopted without changing their schema.
  Future<void> markEstablished() async {
    final type = await FileSystemEntity.type(_marker.path, followLinks: false);
    if (type == FileSystemEntityType.file) return;
    if (type != FileSystemEntityType.notFound) {
      throw StateError('The installation marker is redirected or invalid.');
    }
    await _marker.writeAsString('1\n', flush: true);
  }
}
