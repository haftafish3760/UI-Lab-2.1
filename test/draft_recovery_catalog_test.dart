import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'support/storage/database_harness.dart';

void main() {
  late DatabaseHarness harness;
  late LocalDatabase database;
  late LocalDraftStore store;
  var allowed = true;
  var discardAllowed = true;
  setUp(() async {
    harness = await DatabaseHarness.create();
    database = await harness.open();
    store = LocalDraftStore(database);
    allowed = true;
    discardAllowed = true;
  });
  tearDown(() => harness.dispose());
  Future<int> save(
    String id, {
    String domain = 'work',
    String organization = 'company',
    String owner = 'actor',
    int revision = 0,
    String title = 'Unfinished',
    bool missing = false,
  }) => store.save(
    organizationId: organization,
    ownerId: owner,
    domain: domain,
    draftId: id,
    expectedRevision: revision,
    payload: {'title': title, 'missing': missing},
    occurredAt: DateTime.utc(2030),
  );
  DraftRecoveryHandler handler(
    String domain, {
    Future<bool> Function(DraftRecoveryPreview)? discard,
  }) => DraftRecoveryHandler(
    domain: domain,
    workflowLabel: domain,
    canList: () => allowed,
    inspect: (input) async => input['title'] == 'denied-record'
        ? null
        : DraftRecoveryPreview(
            title: input['title'] as String,
            recordId: 'stable-record',
            availability: input['missing'] == true
                ? DraftRecoveryAvailability.parentUnavailable
                : DraftRecoveryAvailability.recoverable,
          ),
    canDiscard: discard ?? (_) async => discardAllowed,
  );
  DraftRecoveryCatalog catalog({
    Future<bool> Function(DraftRecoveryPreview)? discard,
  }) => DraftRecoveryCatalog(
    repository: store,
    organizationId: 'company',
    ownerId: 'actor',
    handlers: [
      handler('work', discard: discard),
      handler('expenses'),
    ],
  );

  test(
    'catalog survives reopen and finds orphaned input without exposing other scopes',
    () async {
      await save('a');
      await save('b', domain: 'expenses', missing: true);
      await save('foreign-owner', owner: 'someone');
      await save('foreign-company', organization: 'elsewhere');
      await save('unregistered', domain: 'private');
      await save('hidden-record', title: 'denied-record');
      await harness.close(database);
      database = await harness.open();
      store = LocalDraftStore(database);
      final entries = await catalog().list();
      expect(entries.map((e) => e.draftId).toSet(), {'a', 'b'});
      expect(
        entries.firstWhere((e) => e.draftId == 'b').preview.availability,
        DraftRecoveryAvailability.parentUnavailable,
      );
      expect(
        entries.singleWhere((e) => e.draftId == 'a').preview.recordId,
        'stable-record',
      );
      expect(
        await store.listOwned(
          organizationId: 'company',
          ownerId: 'actor',
          domains: {},
        ),
        isEmpty,
      );
      expect(() => entries.clear(), throwsUnsupportedError);
    },
  );

  test(
    'unknown payload version remains visible without hiding independent valid work',
    () async {
      await save('old');
      await save('valid', domain: 'expenses');
      await database.customStatement(
        "UPDATE local_drafts SET payload_version = 99 WHERE draft_id = 'old'",
      );
      final recovery = catalog();
      final entries = await recovery.list();
      expect(entries, hasLength(2));
      final old = entries.singleWhere((e) => e.draftId == 'old');
      expect(old.preview.availability, DraftRecoveryAvailability.unreadable);
      final before = await store.find(
        organizationId: 'company',
        ownerId: 'actor',
        domain: 'work',
        draftId: 'old',
      );
      discardAllowed = false;
      await expectLater(recovery.discard(old), throwsStateError);
      expect(
        (await store.find(
          organizationId: 'company',
          ownerId: 'actor',
          domain: 'work',
          draftId: 'old',
        ))!.payload,
        before!.payload,
      );
      discardAllowed = true;
      await recovery.discard(old);
      expect((await recovery.list()).single.draftId, 'valid');
    },
  );

  test('stale entries and revoked access cannot discard newer input', () async {
    await save('a');
    final recovery = catalog();
    final entry = (await recovery.list()).single;
    await save('a', revision: entry.revision, title: 'Newer input');
    await expectLater(
      recovery.discard(entry),
      throwsA(isA<LocalRecordConflict>()),
    );
    final latest = (await recovery.list()).single;
    allowed = false;
    expect(await recovery.list(), isEmpty);
    await expectLater(recovery.discard(latest), throwsStateError);
    allowed = true;
    await expectLater(catalog().discard(latest), throwsStateError);
    expect((await recovery.list()).single.preview.title, 'Newer input');
  });

  test(
    'write during discard authorization is rejected by the transaction revision check',
    () async {
      await save('a');
      final recovery = catalog(
        discard: (_) async {
          await save('a', revision: 1, title: 'Concurrent input');
          return true;
        },
      );
      final entry = (await recovery.list()).single;
      await expectLater(
        recovery.discard(entry),
        throwsA(isA<LocalRecordConflict>()),
      );
      expect((await recovery.list()).single.preview.title, 'Concurrent input');
    },
  );

  test(
    'failed discard preserves input and retry consumes only the selected draft',
    () async {
      await save('a');
      await save('b', domain: 'expenses');
      final recovery = catalog();
      final entry = (await recovery.list()).singleWhere(
        (e) => e.draftId == 'a',
      );
      await database.customStatement(
        "CREATE TRIGGER fail_catalog_discard BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await expectLater(recovery.discard(entry), throwsA(anything));
      expect(await recovery.list(), hasLength(2));
      await database.customStatement('DROP TRIGGER fail_catalog_discard');
      await recovery.discard(entry);
      expect((await recovery.list()).single.draftId, 'b');
      await expectLater(
        recovery.discard(entry),
        throwsA(isA<LocalRecordConflict>()),
      );
    },
  );
}
