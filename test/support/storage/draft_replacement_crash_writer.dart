import 'dart:async';
import 'dart:io';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';

/// Only operates on the parent test's disposable database, never app storage.
Future<void> main(List<String> args) async {
  final file = File(args.single);
  if (!file.parent.path.contains('maintainiac-database-test-')) {
    throw ArgumentError('Crash probes require an isolated harness directory.');
  }
  final database = LocalDatabase.file(file);
  await database.verifyIntegrity();
  final store = LocalDraftStore(database);
  Future<int> save(String text) => store.save(
    organizationId: 'business',
    ownerId: 'owner',
    domain: 'invoice',
    draftId: 'reused',
    expectedRevision: 0,
    payload: {'amountText': text},
    occurredAt: DateTime.utc(2026, 9, 9),
  );
  Future<bool> consume(int revision) => store.consumeIfUnchanged(
    organizationId: 'business',
    ownerId: 'owner',
    domain: 'invoice',
    draftId: 'reused',
    expectedRevision: revision,
  );
  final original = await save('first');
  if (!await consume(original)) {
    throw StateError('Original draft not consumed.');
  }
  final replacement = await save(' 125. ');
  await database.transaction(() async {
    if (!await consume(replacement)) {
      throw StateError('Replacement not consumed.');
    }
    await save('uncommitted replacement');
    stdout.writeln('UNCOMMITTED_REPLACEMENT_READY:$original:$replacement');
    await stdout.flush();
    await Completer<void>().future;
  });
}
