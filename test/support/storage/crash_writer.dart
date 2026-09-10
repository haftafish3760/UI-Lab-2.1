import 'dart:async';
import 'dart:io';

import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';

/// Child process for abrupt-termination verification. Uses only the temporary
/// path supplied by its parent test, never the application-support directory.
Future<void> main(List<String> args) async {
  final file = File(args.single);
  if (!file.parent.path.contains('maintainiac-database-test-')) {
    throw ArgumentError('Crash probes require an isolated harness directory.');
  }
  final database = LocalDatabase.file(file);
  await database.verifyIntegrity();
  final drafts = LocalDraftStore(database);
  await drafts.save(
    organizationId: 'business',
    domain: 'invoice',
    draftId: 'draft',
    ownerId: 'owner',
    expectedRevision: 0,
    payload: {'title': 'Repair pump', 'amountText': '125.'},
    occurredAt: DateTime.utc(2026, 9, 9),
  );
  await database.transaction(() async {
    await drafts.save(
      organizationId: 'business',
      domain: 'invoice',
      draftId: 'draft',
      ownerId: 'owner',
      expectedRevision: 1,
      payload: {'title': 'uncommitted change'},
      occurredAt: DateTime.utc(2026, 9, 9),
    );
    stdout.writeln('UNCOMMITTED_WRITE_READY');
    await stdout.flush();
    await Completer<void>().future;
  });
}
