import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';

import 'support/storage/database_harness.dart';

void main() {
  late DatabaseHarness harness;
  setUp(() async => harness = await DatabaseHarness.create());
  tearDown(() async => harness.dispose());

  Future<DraftAutosaveSession> session() async {
    final value = DraftAutosaveSession(
      store: LocalDraftStore(await harness.open()),
      organizationId: 'business',
      domain: 'invoice',
      draftId: 'draft',
      ownerId: 'owner',
    );
    await value.initialize();
    return value;
  }

  test(
    'discard cannot succeed before saved draft initialization finishes',
    () async {
      final saved = await session();
      saved.replaceInput({'amount': '12.', 'notes': 'unfinished'});
      await saved.close();
      final opening = DraftAutosaveSession(
        store: saved.store,
        organizationId: 'business',
        domain: 'invoice',
        draftId: 'draft',
        ownerId: 'owner',
      );
      await expectLater(opening.discard(), throwsStateError);
      final loading = opening.initialize();
      await expectLater(opening.discard(), throwsStateError);
      await loading;
      expect(opening.input, {'amount': '12.', 'notes': 'unfinished'});
      expect(opening.state, DraftSaveState.savedLocally);
      await opening.discard();
      expect(opening.state, DraftSaveState.discarded);
      await opening.close();
      final reopened = await session();
      expect(reopened.input, isEmpty);
      await reopened.close();
    },
  );

  test(
    'rapid changes retain raw partial input and latest state after reopen',
    () async {
      final draft = await session();
      for (final text in ['1', '12', '12.', '12.5']) {
        draft.replaceInput({
          'amount': text,
          'customer': '',
          'items': <Object?>[],
        });
      }
      expect(draft.state, DraftSaveState.saving);
      await draft.close();
      expect(draft.state, DraftSaveState.savedLocally);
      await harness.close((draft.store as LocalDraftStore).database);
      final resumed = await session();
      expect(resumed.input, {'amount': '12.5', 'customer': '', 'items': []});
      expect(resumed.savedRevision, 4);
      expect(
        await (resumed.store as LocalDraftStore).database
            .select((resumed.store as LocalDraftStore).database.localRecords)
            .get(),
        isEmpty,
      );
    },
  );

  test(
    'failed autosave remains visible and retry preserves the newest input',
    () async {
      final draft = await session();
      draft.replaceInput({'notes': 'first'});
      await draft.flush();
      await (draft.store as LocalDraftStore).database.customStatement('''
      CREATE TRIGGER fail_draft BEFORE UPDATE ON local_drafts
      BEGIN SELECT RAISE(ABORT, 'synthetic write failure'); END
    ''');
      draft.replaceInput({'notes': 'unfinished new notes'});
      await expectLater(draft.flush(), throwsStateError);
      expect(draft.state, DraftSaveState.notSaved);
      expect(draft.input['notes'], 'unfinished new notes');
      final saved = await draft.store.find(
        organizationId: 'business',
        domain: 'invoice',
        draftId: 'draft',
        ownerId: 'owner',
      );
      expect(draft.store.decode(saved!)['notes'], 'first');
      await (draft.store as LocalDraftStore).database.customStatement(
        'DROP TRIGGER fail_draft',
      );
      draft.retry();
      await draft.flush();
      expect(draft.state, DraftSaveState.savedLocally);
      expect(draft.hasFailure, isFalse);
    },
  );

  test(
    'a failed queued checkpoint cannot hide a newer successful save',
    () async {
      final draft = await session();
      draft.replaceInput({'notes': 'original'});
      await draft.flush();
      await (draft.store as LocalDraftStore).database.customStatement('''
      CREATE TRIGGER fail_one_checkpoint BEFORE UPDATE ON local_drafts
      WHEN json_extract(NEW.payload, '\$.notes') = 'intermediate'
      BEGIN SELECT RAISE(ABORT, 'synthetic checkpoint failure'); END
    ''');
      draft.replaceInput({'notes': 'intermediate'});
      draft.replaceInput({
        'notes': '  newest unfinished input  ',
        'amount': '12.',
      });
      await draft.close();
      expect(draft.state, DraftSaveState.savedLocally);
      expect(draft.hasFailure, isFalse);
      expect(draft.savedRevision, 2);
      await harness.close((draft.store as LocalDraftStore).database);
      final resumed = await session();
      expect(resumed.input, {
        'notes': '  newest unfinished input  ',
        'amount': '12.',
      });
      expect(resumed.savedRevision, 2);
      await resumed.close();
    },
  );

  test(
    'stale retry and discard both preserve another editor checkpoint',
    () async {
      final original = await session();
      original.replaceInput({'notes': 'shared starting point'});
      await original.flush();
      final stale = await session();
      original.replaceInput({'notes': '  newer saved checkpoint  '});
      await original.flush();
      stale.replaceInput({'notes': 'unsaved changes in older editor'});
      await expectLater(stale.flush(), throwsStateError);
      stale.retry();
      await expectLater(stale.flush(), throwsStateError);
      expect(stale.state, DraftSaveState.notSaved);
      expect(stale.input['notes'], 'unsaved changes in older editor');
      await expectLater(stale.discard(), throwsA(isA<LocalRecordConflict>()));
      expect(stale.state, DraftSaveState.notSaved);
      await expectLater(stale.close(), throwsStateError);
      await original.close();
      await harness.close((stale.store as LocalDraftStore).database);
      await harness.close((original.store as LocalDraftStore).database);
      final resumed = await session();
      expect(resumed.input, {'notes': '  newer saved checkpoint  '});
      expect(resumed.savedRevision, 2);
      await resumed.close();
    },
  );

  test(
    'leaving preserves drafts and only explicit discard removes them',
    () async {
      final draft = await session();
      draft.replaceInput({'notes': 'return to this later'});
      await draft.close();
      await harness.close((draft.store as LocalDraftStore).database);
      final resumed = await session();
      expect(resumed.input['notes'], 'return to this later');
      await resumed.discard();
      expect(resumed.state, DraftSaveState.discarded);
      expect(
        await resumed.store.find(
          organizationId: 'business',
          domain: 'invoice',
          draftId: 'draft',
          ownerId: 'owner',
        ),
        isNull,
      );
    },
  );

  test(
    'mutable widget collections cannot change queued or returned draft data',
    () async {
      final draft = await session();
      final lines = <String>['pump'];
      draft.replaceInput({'items': lines});
      lines.add('unexpected');
      (draft.input['items'] as List).add('also unexpected');
      await draft.flush();
      expect(draft.input['items'], ['pump']);
    },
  );
}
