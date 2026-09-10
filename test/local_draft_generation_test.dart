import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'a stale checkpoint cannot consume a replacement draft after reopen',
    () async {
      final harness = await DatabaseHarness.create();
      var db = await harness.open();
      var store = LocalDraftStore(db);
      Future<int> save(String value) => store.save(
        organizationId: 'company',
        ownerId: 'employee',
        domain: 'invoice-editor',
        draftId: 'new-employee',
        expectedRevision: 0,
        payload: {'raw': value},
        occurredAt: DateTime.now(),
      );
      Future<bool> consume(int revision) => store.consumeIfUnchanged(
        organizationId: 'company',
        ownerId: 'employee',
        domain: 'invoice-editor',
        draftId: 'new-employee',
        expectedRevision: revision,
      );
      try {
        final old = await save('first invoice');
        expect(await consume(old), isTrue);
        await harness.close(db);
        db = await harness.open();
        store = LocalDraftStore(db);
        final replacement = await save('second invoice, incomplete');
        expect(
          await consume(old),
          isFalse,
          reason:
              'An old editor must never discard or confirm replacement input.',
        );
        expect(replacement, greaterThan(old));
        final retained = await store.list(
          organizationId: 'company',
          ownerId: 'employee',
          domain: 'invoice-editor',
        );
        expect(store.decode(retained.single), {
          'raw': 'second invoice, incomplete',
        });
        expect(await consume(replacement), isTrue);
      } finally {
        await harness.dispose();
      }
    },
  );

  test(
    'legacy draft consumption retains its revision and failed writes roll back markers',
    () async {
      final harness = await DatabaseHarness.create();
      final db = await harness.open();
      final store = LocalDraftStore(db);
      Future<int> save() => store.save(
        organizationId: 'org',
        ownerId: 'owner',
        domain: 'editor',
        draftId: 'new',
        expectedRevision: 0,
        payload: {'raw': 'retained'},
        occurredAt: DateTime.now(),
      );
      try {
        await db.customStatement(
          "CREATE TRIGGER fail_draft BEFORE INSERT ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        await expectLater(save(), throwsA(isA<Exception>()));
        expect(await db.select(db.localMetadata).get(), isEmpty);
        expect(await db.select(db.localDrafts).get(), isEmpty);
        await db.customStatement('DROP TRIGGER fail_draft');
        // This fixture simulates a draft written before revision markers existed.
        await db.customStatement(
          "INSERT INTO local_drafts VALUES ('org', 'editor', 'new', 'owner', 7, 1, '{}', 1)",
        );
        Future<bool> consume() => store.consumeIfUnchanged(
          organizationId: 'org',
          ownerId: 'owner',
          domain: 'editor',
          draftId: 'new',
          expectedRevision: 7,
        );
        await expectLater(
          db.transaction(() async {
            expect(await consume(), isTrue);
            throw StateError('confirmation failed');
          }),
          throwsStateError,
        );
        expect(await db.select(db.localMetadata).get(), isEmpty);
        expect((await db.select(db.localDrafts).get()).single.revision, 7);
        expect(await consume(), isTrue);
        expect(await save(), 8);
        expect(await consume(), isFalse);
      } finally {
        await harness.dispose();
      }
    },
  );
}
