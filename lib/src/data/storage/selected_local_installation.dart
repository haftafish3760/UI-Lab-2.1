import 'dart:io';

import 'local_installation_selection.dart';

/// Startup configuration independent of widgets and the selected database's SQL.
class SelectedLocalInstallation {
  const SelectedLocalInstallation(this.directory, this.resolveRetainedPath);
  final Directory directory;
  final String Function(String)? resolveRetainedPath;

  static Future<SelectedLocalInstallation> resolve(Directory root) async {
    final controlPath = '${root.path}/installation_selection';
    final type = await FileSystemEntity.type(controlPath, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      if (await FileSystemEntity.type(
            '${root.path}/installation-selection-established',
            followLinks: false,
          ) !=
          FileSystemEntityType.notFound) {
        throw StateError(
          'Established installation selection storage is missing.',
        );
      }
      return SelectedLocalInstallation(root, null);
    }
    if (type != FileSystemEntityType.directory) {
      throw StateError('Installation selection location is invalid.');
    }
    final selection = await LocalInstallationSelection.open(root);
    try {
      final prepared = await selection.resolve(await selection.read());
      if (prepared == null) return SelectedLocalInstallation(root, null);
      return SelectedLocalInstallation(
        prepared.directory,
        prepared.resolveRetainedPath,
      );
    } finally {
      await selection.close();
    }
  }
}
