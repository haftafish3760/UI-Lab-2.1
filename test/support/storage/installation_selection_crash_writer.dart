import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/prepared_local_restore.dart';

/// Test-only process. Never accepts an application-support or reference path.
Future<void> main(List<String> args) async {
  final root = Directory(args[0]);
  if (!root.path.contains('selection-interruption-fixture-')) {
    throw ArgumentError('An isolated interruption fixture is required.');
  }
  Future<void> hold() async {
    stdout.writeln('SELECTION_WRITE_READY');
    await stdout.flush();
    await Completer<void>().future;
  }

  final mode = args[1];
  if (mode == 'uncommitted') {
    // Probe the exact control-row transaction boundary without a production
    // failpoint. This path deliberately does not claim to exercise select().
    final database = LocalDatabase.file(
      File('${root.path}/installation_selection/maintainiac.sqlite'),
    );
    await database.verifyIntegrity();
    await database.transaction(() async {
      await database.customStatement(
        "UPDATE local_metadata SET value = ? WHERE metadata_key = 'active-installation-v1'",
        [
          jsonEncode({'revision': 99, 'active': args[2], 'previous': ''}),
        ],
      );
      await hold();
    });
  } else {
    final selection = await LocalInstallationSelection.open(root);
    if (mode == 'committed') {
      final prepared = await PreparedLocalRestore.reopen(Directory(args[2]));
      await selection.select(installation: prepared, expectedRevision: 0);
    } else if (mode == 'rollback') {
      await selection.rollback(expectedRevision: 1);
    } else {
      throw ArgumentError('Unknown interruption mode.');
    }
    // Kill after the real API acknowledges, before any graceful close.
    await hold();
  }
}
