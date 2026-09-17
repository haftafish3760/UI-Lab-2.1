import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'returning setup updates the same draft atomically at its reviewed revision',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var store = LocalDraftStore(db);
      for (final domain in ['setup', 'expense']) {
        await store.save(
          organizationId: 'company',
          ownerId: 'owner',
          domain: domain,
          draftId: 'id',
          expectedRevision: 0,
          payload: {'domain': domain, 'amount': '12.', 'vendor': 'Unfinished'},
          occurredAt: DateTime.now(),
        );
      }
      Future<int> transfer(int revision) => store.transfer(
        organizationId: 'company',
        ownerId: 'owner',
        source: const LocalDraftCheckpoint(
          domain: 'setup',
          draftId: 'id',
          revision: 1,
        ),
        targetDomain: 'expense',
        targetDraftId: 'id',
        expectedTargetRevision: revision,
        targetPayload: {
          'category': 'fuel',
          'amount': '12.',
          'vendor': 'Unfinished',
        },
        occurredAt: DateTime.now(),
      );
      final before = (await db.select(db.localDrafts).get())
          .map((r) => r.toJson())
          .toList();
      // Never overwrite a destination that no longer matches the reviewed input.
      await expectLater(transfer(2), throwsA(isA<LocalRecordConflict>()));
      expect(
        (await db.select(db.localDrafts).get()).map((r) => r.toJson()).toList(),
        before,
      );
      // Fail after updating the destination, while consuming the source.
      await db.customStatement(
        "CREATE TRIGGER fail_return BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await expectLater(transfer(1), throwsA(anything));
      expect(
        (await db.select(db.localDrafts).get()).map((r) => r.toJson()).toList(),
        before,
      );
      await db.customStatement('DROP TRIGGER fail_return');
      expect(await transfer(1), 2);
      await expectLater(transfer(1), throwsA(isA<LocalRecordConflict>()));
      await harness.close(db);
      db = await harness.open();
      store = LocalDraftStore(db);
      final rows = await store.list(
        organizationId: 'company',
        ownerId: 'owner',
        domain: 'expense',
      );
      expect(rows.single.draftId, 'id');
      expect(rows.single.revision, 2);
      expect(store.decode(rows.single), {
        'category': 'fuel',
        'amount': '12.',
        'vendor': 'Unfinished',
      });
      expect(await db.select(db.localDrafts).get(), hasLength(1));
      expect(await db.select(db.localRecords).get(), isEmpty);
    },
  );
  test(
    'failed transfer keeps source; retry atomically moves input and survives reopen',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var store = LocalDraftStore(db);
      await store.save(
        organizationId: 'company',
        ownerId: 'owner',
        domain: 'setup',
        draftId: 'start',
        expectedRevision: 0,
        payload: {'category': 'fuel'},
        occurredAt: DateTime.now(),
      );
      const source = LocalDraftCheckpoint(
        domain: 'setup',
        draftId: 'start',
        revision: 1,
      );
      Future<int> transfer() => store.transfer(
        organizationId: 'company',
        ownerId: 'owner',
        source: source,
        targetDomain: 'expense',
        targetDraftId: 'target',
        targetPayload: {'category': 'fuel', 'amount': '12.'},
        occurredAt: DateTime.now(),
      );
      await db.customStatement(
        "CREATE TRIGGER fail_transfer BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await expectLater(transfer(), throwsA(anything));
      var rows = await db.select(db.localDrafts).get();
      expect(rows.single.domain, 'setup');
      expect(rows.single.revision, 1);
      await db.customStatement('DROP TRIGGER fail_transfer');
      expect(await transfer(), 1);
      await expectLater(transfer(), throwsA(isA<LocalRecordConflict>()));
      await harness.close(db);
      db = await harness.open();
      store = LocalDraftStore(db);
      final target = await store.find(
        organizationId: 'company',
        ownerId: 'owner',
        domain: 'expense',
        draftId: 'target',
      );
      expect(store.decode(target!), {'category': 'fuel', 'amount': '12.'});
      rows = await db.select(db.localDrafts).get();
      expect(rows, hasLength(1));
      expect(await db.select(db.localRecords).get(), isEmpty);
    },
  );

  test(
    'stale source, wrong owner and occupied destination retain both drafts',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final store = LocalDraftStore(db);
      for (final domain in ['setup', 'expense']) {
        await store.save(
          organizationId: 'company',
          ownerId: 'owner',
          domain: domain,
          draftId: 'id',
          expectedRevision: 0,
          payload: {'domain': domain},
          occurredAt: DateTime.now(),
        );
      }
      final before = (await db.select(db.localDrafts).get())
          .map((r) => r.toJson())
          .toList();
      for (final proposal in [
        (2, 'owner', 'fresh'),
        (1, 'stranger', 'fresh'),
        (1, 'owner', 'id'),
      ]) {
        await expectLater(
          store.transfer(
            organizationId: 'company',
            ownerId: proposal.$2,
            source: LocalDraftCheckpoint(
              domain: 'setup',
              draftId: 'id',
              revision: proposal.$1,
            ),
            targetDomain: 'expense',
            targetDraftId: proposal.$3,
            targetPayload: {'unsafe': true},
            occurredAt: DateTime.now(),
          ),
          throwsA(isA<LocalRecordConflict>()),
        );
      }
      expect(
        (await db.select(db.localDrafts).get()).map((r) => r.toJson()).toList(),
        before,
      );
    },
  );
}
