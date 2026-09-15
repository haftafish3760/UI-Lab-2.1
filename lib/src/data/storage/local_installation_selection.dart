import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as paths;

import 'local_database.dart';
import 'local_installation_guard.dart';
import 'prepared_local_restore.dart';

/// A private control database, independent of the business database being
/// restored. Only an offline switch coordinator may change this selection after
/// draining editors and closing the active application. No UI calls SQL here.
class LocalInstallationSelection {
  LocalInstallationSelection._(this.root, this._database);
  final Directory root;
  final LocalDatabase _database;
  static const _key = 'active-installation-v1';

  static Future<LocalInstallationSelection> open(Directory root) async {
    await root.create(recursive: true);
    final canonical = Directory(await root.resolveSymbolicLinks());
    final control = Directory(
      paths.join(canonical.path, 'installation_selection'),
    );
    final marker = File('${canonical.path}/installation-selection-established');
    if (!await control.exists() && await marker.exists()) {
      throw StateError(
        'Established installation selection storage is missing.',
      );
    }
    await control.create();
    if (await control.resolveSymbolicLinks() != control.path) {
      throw StateError('Installation selection directory is redirected.');
    }
    final guard = LocalInstallationGuard(control);
    await guard.verifyBeforeOpen();
    final creating = !await guard.databaseFile.exists();
    final database = LocalDatabase.file(guard.databaseFile);
    try {
      await database.verifyIntegrity();
      if (creating) {
        await database.customStatement(
          'INSERT INTO local_metadata (metadata_key, value) VALUES (?, ?)',
          [
            _key,
            jsonEncode({'revision': 0, 'active': '', 'previous': null}),
          ],
        );
      }
      // Existing control storage must contain a decision, even the original
      // installation decision. A lost row is not permission to reset selection.
      await LocalInstallationSelection._(canonical, database).read();
      await guard.markEstablished();
      final markerType = await FileSystemEntity.type(
        marker.path,
        followLinks: false,
      );
      if (markerType == FileSystemEntityType.notFound) {
        await marker.writeAsString('1\n', flush: true);
      } else if (markerType != FileSystemEntityType.file) {
        throw StateError('Installation selection marker is invalid.');
      }
      return LocalInstallationSelection._(canonical, database);
    } on Object {
      await database.close();
      rethrow;
    }
  }

  Future<InstallationSelectionState> read() => _readSelection();

  Future<InstallationSelectionState> _readSelection() async {
    final rows = await _database
        .customSelect(
          "SELECT value FROM local_metadata WHERE metadata_key = 'active-installation-v1'",
        )
        .get();
    return _decode(rows.isEmpty ? null : rows.single.data['value'] as String);
  }

  InstallationSelectionState _decode(String? value) {
    if (value == null) throw StateError('Installation selection is missing.');
    final raw = jsonDecode(value);
    if (raw is! Map ||
        raw['revision'] is! int ||
        raw['revision'] < 0 ||
        (raw['revision'] == 0 &&
            (raw['active'] != '' || raw['previous'] != null)) ||
        raw['active'] is! String ||
        (raw['previous'] != null && raw['previous'] is! String)) {
      throw StateError('Installation selection is invalid.');
    }
    _validateRelative(raw['active'] as String);
    if (raw['previous'] != null) _validateRelative(raw['previous'] as String);
    return InstallationSelectionState(
      raw['revision'] as int,
      raw['active'] as String,
      raw['previous'] as String?,
    );
  }

  void _validateRelative(String relative) {
    if (relative.isEmpty) return; // Original installation, never a fallback.
    if (paths.isAbsolute(relative) ||
        paths.normalize(relative) != relative ||
        relative.split(paths.separator).contains('..') ||
        !relative.startsWith('restore_candidates${paths.separator}') ||
        paths.basename(relative) != 'installation') {
      throw StateError('Installation selection escapes its private root.');
    }
  }

  /// Revalidates selected bytes and mappings. A bad selected installation is an
  /// error; it must never silently switch the user to older business records.
  Future<PreparedLocalRestore?> resolve(
    InstallationSelectionState state,
  ) async {
    _validateRelative(state.active);
    if (state.active.isEmpty) return null;
    return PreparedLocalRestore.reopen(
      Directory(paths.join(root.path, state.active)),
    );
  }

  Future<InstallationSelectionState> select({
    required PreparedLocalRestore installation,
    required int expectedRevision,
  }) async {
    await validateCandidate(installation);
    final relative = paths.relative(
      installation.directory.path,
      from: root.path,
    );
    return _commit(relative, expectedRevision);
  }

  Future<void> validateCandidate(PreparedLocalRestore installation) async {
    final relative = paths.relative(
      installation.directory.path,
      from: root.path,
    );
    _validateRelative(relative);
    await PreparedLocalRestore.reopen(installation.directory);
  }

  /// Explicit rollback retains the newer installation and changes only selection.
  Future<InstallationSelectionState> rollback({
    required int expectedRevision,
  }) async =>
      _commit(await _validatedPrevious(expectedRevision), expectedRevision);

  Future<void> validateRollback({required int expectedRevision}) async {
    await _validatedPrevious(expectedRevision);
  }

  Future<String> _validatedPrevious(int expectedRevision) async {
    final current = await read();
    if (current.revision != expectedRevision || current.previous == null) {
      throw StateError('No matching previous installation is available.');
    }
    final previous = current.previous!;
    if (previous.isEmpty) {
      final guard = LocalInstallationGuard(root);
      if (!await guard.databaseFile.exists()) {
        throw StateError('Previous database is missing.');
      }
      await guard.verifyBeforeOpen();
      final database = LocalDatabase.file(guard.databaseFile);
      try {
        await database.verifyIntegrity();
      } finally {
        await database.close();
      }
    } else {
      await resolve(
        InstallationSelectionState(current.revision, previous, null),
      );
    }
    return previous;
  }

  Future<InstallationSelectionState> _commit(
    String relative,
    int expectedRevision,
  ) {
    return _database.transaction(() async {
      final current = await _readSelection();
      if (current.revision != expectedRevision) {
        throw StateError('Installation selection changed.');
      }
      if (current.active == relative) return current;
      final next = InstallationSelectionState(
        current.revision + 1,
        relative,
        current.active,
      );
      await _database.customStatement(
        'INSERT OR REPLACE INTO local_metadata (metadata_key, value) VALUES (?, ?)',
        [
          _key,
          jsonEncode({
            'revision': next.revision,
            'active': next.active,
            'previous': next.previous,
          }),
        ],
      );
      return next;
    });
  }

  Future<void> close() => _database.close();
}

class InstallationSelectionState {
  const InstallationSelectionState(this.revision, this.active, this.previous);
  final int revision;
  final String active;
  final String? previous;
}
