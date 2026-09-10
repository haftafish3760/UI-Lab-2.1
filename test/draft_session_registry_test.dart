import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_repository.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_session_registry.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/database_harness.dart';

class _Repository extends Fake
    implements DraftRepository, ManagedDraftRepository {
  @override
  final draftSessions = DraftSessionRegistry();
  final writes = <Completer<int>>[];
  Completer<SavedDraft?>? loading;
  Completer<bool>? deleting;
  @override
  Future<SavedDraft?> find({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
  }) async => loading == null ? null : await loading!.future;
  @override
  Future<int> save({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
    required int expectedRevision,
    required Map<String, Object?> payload,
    required DateTime occurredAt,
  }) {
    final result = Completer<int>();
    writes.add(result);
    return result.future;
  }

  @override
  Future<bool> consumeIfUnchanged({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
    required int expectedRevision,
  }) => deleting!.future;
}

DraftAutosaveSession session(DraftRepository repository, String id) =>
    DraftAutosaveSession(
      store: repository,
      organizationId: 'business',
      domain: 'invoice',
      draftId: id,
      ownerId: 'owner',
    );
Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'pause waits for all saves, rejects new editors and retains exact input',
    () async {
      final repository = _Repository();
      final first = session(repository, 'first');
      final second = session(repository, 'second');
      await first.initialize();
      await second.initialize();
      first.replaceInput({'amount': '12.'});
      second.replaceInput({'notes': '  raw  '});
      var acknowledged = false;
      final pause = repository.draftSessions.pauseAndFlush().then((lease) {
        acknowledged = true;
        return lease;
      });
      await tick();
      expect(first.isCommittingInput, isTrue);
      expect(() => first.replaceInput({'amount': 'changed'}), throwsStateError);
      await expectLater(
        session(repository, 'new').initialize(),
        throwsStateError,
      );
      repository.writes[0].complete(1);
      await tick();
      expect(acknowledged, isFalse);
      repository.writes[1].complete(1);
      final lease = await pause;
      expect(first.input, {'amount': '12.'});
      expect(second.input, {'notes': '  raw  '});
      await expectLater(
        repository.draftSessions.pauseAndFlush(),
        throwsStateError,
      );
      lease.release();
      lease.release();
      expect(first.isCommittingInput, isFalse);
      await first.close();
      await second.close();
    },
  );

  test(
    'failed flush cancels pause and leaves input available for retry',
    () async {
      final repository = _Repository();
      final draft = session(repository, 'first');
      await draft.initialize();
      draft.replaceInput({'amount': '12.'});
      final pause = repository.draftSessions.pauseAndFlush();
      final failure = expectLater(pause, throwsStateError);
      await tick();
      repository.writes.single.completeError(StateError('disk full'));
      await failure;
      expect(draft.isCommittingInput, isFalse);
      expect(draft.input, {'amount': '12.'});
      draft.retry();
      await tick();
      repository.writes.last.complete(1);
      final lease = await repository.draftSessions.pauseAndFlush();
      lease.release();
      await draft.close();
    },
  );

  test('pause waits for an editor that is still loading', () async {
    final repository = _Repository()..loading = Completer();
    final draft = session(repository, 'loading');
    final loading = draft.initialize();
    var done = false;
    final pending = repository.draftSessions.pauseAndFlush().then((lease) {
      done = true;
      return lease;
    });
    await tick();
    expect(done, isFalse);
    repository.loading!.complete(null);
    await loading;
    final lease = await pending;
    lease.release();
    await draft.close();
  });

  test('pause waits for an already-started explicit discard', () async {
    final repository = _Repository()..deleting = Completer();
    final draft = session(repository, 'discard');
    await draft.initialize();
    draft.replaceInput({'amount': '12.'});
    await tick();
    repository.writes.single.complete(1);
    await draft.flush();
    final discard = draft.discard();
    var done = false;
    final pending = repository.draftSessions.pauseAndFlush().then((lease) {
      done = true;
      return lease;
    });
    await tick();
    expect(done, isFalse);
    repository.deleting!.complete(true);
    await discard;
    final lease = await pending;
    lease.release();
    await draft.close();
  });

  test(
    'different repository instances share the database lifecycle registry',
    () async {
      final harness = await DatabaseHarness.create();
      try {
        final database = await harness.open();
        final first = session(LocalDraftStore(database), 'first');
        final second = session(LocalDraftStore(database), 'second');
        await first.initialize();
        await second.initialize();
        first.replaceInput({'amount': '12.'});
        second.replaceInput({'notes': '  raw  '});
        final lease = await database.draftSessions.pauseAndFlush();
        expect(first.isCommittingInput, isTrue);
        expect(second.isCommittingInput, isTrue);
        expect(
          (await database.select(database.localDrafts).get()),
          hasLength(2),
        );
        await first.close();
        await second.close();
        lease.release();
      } finally {
        await harness.dispose();
      }
    },
  );
}
