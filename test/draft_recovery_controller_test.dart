import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_hub.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/shared/draft_recovery_controller.dart';
import 'support/storage/database_harness.dart';

Future<DraftRecoveryCatalog> catalog() async {
  final harness = await DatabaseHarness.create();
  addTearDown(harness.dispose);
  final drafts = LocalDraftStore(await harness.open());
  await drafts.save(
    organizationId: 'org',
    ownerId: 'actor',
    domain: 'notes',
    draftId: 'draft',
    expectedRevision: 0,
    payload: {'raw': 'unfinished'},
    occurredAt: DateTime.now().toUtc(),
  );
  return DraftRecoveryCatalog(
    repository: drafts,
    organizationId: 'org',
    ownerId: 'actor',
    handlers: [
      DraftRecoveryHandler(
        domain: 'notes',
        workflowLabel: 'Note',
        canList: () => true,
        inspect: (_) async =>
            const DraftRecoveryPreview(title: 'Unfinished note'),
        canDiscard: (_) async => true,
      ),
    ],
  );
}

void main() {
  test('latest refresh wins and a failed provider remains explicit', () async {
    final source = await catalog();
    final first = Completer<List<DraftRecoveryEntry>>();
    var reads = 0;
    final controller = DraftRecoveryController(
      DraftRecoveryHub<String>([
        DraftRecoveryProvider(
          id: 'notes',
          label: 'Notes',
          list: () => ++reads == 1 ? first.future : source.list(),
          resume: (_) async => 'workflow',
          discard: source.discard,
        ),
      ]),
      releaseUnclaimed: (_) async {},
    );
    addTearDown(controller.dispose);
    final old = controller.refresh();
    await controller.refresh();
    expect(controller.listing!.entries, hasLength(1));
    first.complete([]);
    await old;
    expect(controller.listing!.entries, hasLength(1));
    expect(controller.isBusy, isFalse);
  });

  test('failed refresh removes retired session titles and actions', () async {
    final source = await catalog();
    var actions = 0;
    final hub = DraftRecoveryHub<String>([
      DraftRecoveryProvider(
        id: 'notes',
        label: 'Notes',
        list: source.list,
        resume: (_) async {
          actions++;
          return 'workflow';
        },
        discard: (_) async {
          actions++;
        },
      ),
    ]);
    final controller = DraftRecoveryController(
      hub,
      releaseUnclaimed: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    final entry = controller.listing!.entries.single;
    hub.invalidate();
    await controller.refresh();
    expect(controller.listing, isNull);
    expect(controller.error, isNotNull);
    expect(controller.isBusy, isFalse);
    expect(await controller.resume(entry), isNull);
    expect(await controller.discard(entry), isFalse);
    expect(actions, 0);
    expect(await source.list(), hasLength(1));
  });

  test(
    'duplicate opening is excluded and disposal releases late workflow without discard',
    () async {
      final source = await catalog();
      final opening = Completer<String>();
      var calls = 0;
      final released = <String>[];
      final controller = DraftRecoveryController(
        DraftRecoveryHub<String>([
          DraftRecoveryProvider(
            id: 'notes',
            label: 'Notes',
            list: source.list,
            resume: (_) {
              calls++;
              return opening.future;
            },
            discard: source.discard,
          ),
        ]),
        releaseUnclaimed: (value) async => released.add(value),
      );
      await controller.refresh();
      final entry = controller.listing!.entries.single;
      final pending = controller.resume(entry);
      expect(await controller.resume(entry), isNull);
      expect(calls, 1);
      controller.dispose();
      opening.complete('workflow');
      expect(await pending, isNull);
      expect(released, ['workflow']);
      expect(await source.list(), hasLength(1));
    },
  );

  test(
    'discard acknowledgement controls list removal and stale failures retain input',
    () async {
      final source = await catalog();
      var fail = true;
      final controller = DraftRecoveryController(
        DraftRecoveryHub<String>([
          DraftRecoveryProvider(
            id: 'notes',
            label: 'Notes',
            list: source.list,
            resume: (_) async => 'workflow',
            discard: (entry) async {
              if (fail) throw StateError('private path');
              await source.discard(entry);
            },
          ),
        ]),
        releaseUnclaimed: (_) async {},
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      final entry = controller.listing!.entries.single;
      expect(await controller.discard(entry), isFalse);
      expect(controller.error, isNot(contains('private path')));
      expect(controller.listing!.entries.single, same(entry));
      fail = false;
      expect(await controller.discard(entry), isTrue);
      expect(controller.listing!.entries, isEmpty);
      expect(await source.list(), isEmpty);
      expect(await controller.resume(entry), isNull);
    },
  );
}
