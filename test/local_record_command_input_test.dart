import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';

void main() {
  test(
    'queued draft preserves nested raw input supplied at save time',
    () async {
      final database = LocalDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = LocalDraftStore(database);
      final ready = Completer<void>();
      final release = Completer<void>();
      final busy = database.transaction(() async {
        ready.complete();
        await release.future;
      });
      await ready.future;
      final fields = <String, Object?>{
        'amount': '12.',
        'notes': '  original  ',
      };
      final input = <String, Object?>{'fields': fields};
      final saving = store.save(
        organizationId: 'company',
        domain: 'test/drafts',
        draftId: 'draft',
        ownerId: 'owner',
        expectedRevision: 0,
        payload: input,
        occurredAt: DateTime.utc(2026, 9, 28),
      );
      fields['amount'] = '999';
      input.clear();
      release.complete();
      await busy;
      expect(await saving, 1);
      final saved = await store.find(
        organizationId: 'company',
        domain: 'test/drafts',
        draftId: 'draft',
        ownerId: 'owner',
      );
      expect(
        saved!.payload,
        canonicalJson({
          'fields': {'amount': '12.', 'notes': '  original  '},
        }),
      );
    },
  );
  test('queued command preserves submitted writes and retry identity', () async {
    final database = LocalDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = LocalRecordStore(database);
    final ready = Completer<void>();
    final release = Completer<void>();
    final busy = database.transaction(() async {
      ready.complete();
      await release.future;
    });
    await ready.future;
    final original = LocalRecordWrite(
      domain: 'test/records',
      recordId: 'original',
      ownerId: 'owner',
      expectedRevision: 0,
      payload: {'value': 'submitted'},
    );
    final inputs = [original];
    final saving = store.commit(
      organizationId: 'company',
      commandId: 'command',
      writes: inputs,
      occurredAt: DateTime.utc(2026, 9, 28),
    );
    // A screen/controller may reuse its collection while the database is busy.
    inputs.clear();
    release.complete();
    await busy;
    await saving;
    final records = await store.read(
      organizationId: 'company',
      domain: 'test/records',
      ownerIds: {'owner'},
    );
    expect(records.map((r) => r.recordId), ['original']);
    expect(store.decode(records.single), {'value': 'submitted'});
    await store.commit(
      organizationId: 'company',
      commandId: 'command',
      writes: [original],
      occurredAt: DateTime.utc(2026, 9, 29),
    );
    expect(
      await database.select(database.localRecordRevisions).get(),
      hasLength(1),
    );
    expect(
      await database.select(database.localChangeOutbox).get(),
      hasLength(1),
    );
    await database.verifyIntegrity();
  });
}
