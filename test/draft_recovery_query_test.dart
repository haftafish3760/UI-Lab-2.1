import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_repository.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_query.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';

import 'support/storage/database_harness.dart';

class _PendingRecoveryRepository extends Fake implements DraftRepository {
  final result = Completer<List<SavedDraft>>();
  int reads = 0, decodes = 0;
  @override
  Future<List<SavedDraft>> listOwned({
    required String organizationId,
    required String ownerId,
    required Set<String> domains,
  }) {
    reads++;
    return result.future;
  }

  @override
  Map<String, Object?> decode(SavedDraft draft) {
    decodes++;
    return {'baseRecord': null, 'title': 'Private unfinished estimate'};
  }
}

void main() {
  test('denied and revoked queries do not publish retained labels', () async {
    var allowed = false;
    final repository = _PendingRecoveryRepository();
    final query = DraftRecoveryQuery(
      repository: repository,
      canList: () => allowed,
      organizationId: 'business',
      ownerId: 'owner',
      domain: 'work/estimate-editor',
      parentField: 'baseRecord',
      labelField: 'title',
      emptyLabel: 'Untitled estimate',
    );
    expect(await query.list(), isEmpty);
    expect(repository.reads, 0);
    allowed = true;
    final pending = query.list();
    expect(repository.reads, 1);
    allowed = false;
    repository.result.complete(const [
      SavedDraft(
        organizationId: 'business',
        ownerId: 'owner',
        domain: 'work/estimate-editor',
        draftId: 'draft',
        revision: 1,
        payloadVersion: 1,
        payload: '{}',
        updatedAtUs: 0,
      ),
    ]);
    expect(await pending, isEmpty);
    expect(repository.decodes, 0);
    allowed = true;
    expect((await query.list()).single.label, 'Private unfinished estimate');
    expect(repository.decodes, 1);
  });
  test(
    'recovery choices survive reopen, isolate unknown data and preserve scope',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var store = LocalDraftStore(database);
      Future<void> save(
        String id,
        Map<String, Object?> input, {
        String organization = 'business',
        String owner = 'owner',
        String domain = 'work/estimate-editor',
      }) => store.save(
        organizationId: organization,
        ownerId: owner,
        domain: domain,
        draftId: id,
        expectedRevision: 0,
        payload: input,
        occurredAt: DateTime.utc(2026, 9, 9),
      );
      await save('new', {'baseRecord': null, 'title': 'Unfinished estimate'});
      await save('blank', {'baseRecord': null, 'title': '  '});
      await save('editing-existing', {
        'baseRecord': {'id': 'existing'},
        'title': 'Existing estimate',
      });
      await save('future', {
        'baseRecord': null,
        'title': 'Future private payload',
      });
      await save('bad-label', {'baseRecord': null, 'title': 42});
      await save('other-owner', {
        'baseRecord': null,
        'title': 'Other owner',
      }, owner: 'other');
      await save('other-organization', {
        'baseRecord': null,
        'title': 'Other organization',
      }, organization: 'other');
      await save('other-workflow', {
        'baseRecord': null,
        'title': 'Invoice',
      }, domain: 'work/invoice-editor');
      await database.customStatement(
        "UPDATE local_drafts SET payload_version = 2 WHERE draft_id = 'future'",
      );
      await harness.close(database);
      database = await harness.open();
      store = LocalDraftStore(database);
      final before = await database.select(database.localDrafts).get();
      final query = DraftRecoveryQuery(
        canList: () => true,
        repository: store,
        organizationId: 'business',
        ownerId: 'owner',
        domain: 'work/estimate-editor',
        parentField: 'baseRecord',
        labelField: 'title',
        emptyLabel: 'Untitled estimate',
      );
      final choices = await query.list();
      expect(choices.map((choice) => choice.draftId).toSet(), {
        'new',
        'blank',
        'future',
        'bad-label',
      });
      final byId = {for (final choice in choices) choice.draftId: choice};
      expect(byId['new']!.label, 'Unfinished estimate');
      expect(byId['blank']!.label, 'Untitled estimate');
      expect(byId['future']!.unreadable, isTrue);
      expect(byId['bad-label']!.unreadable, isTrue);
      expect(byId['future']!.label, isNot(contains('Future private payload')));
      expect(() => choices.clear(), throwsUnsupportedError);
      expect(
        await database.select(database.localDrafts).get(),
        before,
        reason: 'Discovery must never rewrite, repair or discard stored input.',
      );
    },
  );
}
