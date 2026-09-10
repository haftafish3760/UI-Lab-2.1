import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_switch_coordinator.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/prepared_local_restore.dart';
import 'package:ui_lab_2_1/src/data/storage/selected_local_installation.dart';
import 'package:ui_lab_2_1/src/data/storage/verified_local_snapshot_bundle.dart';

/// Real temporary storage; deliberately not a claim about mounted widget or
/// background-service shutdown, which the production runtime must implement.
class _Runtime implements InstallationSwitchRuntime {
  _Runtime(this.root, this.persistence);
  final Directory root;
  LocalPersistence persistence;
  DraftAutosaveSession? draft;
  final events = <String>[];
  bool failPause = false, failClose = false, failOpen = false;
  Completer<void>? pauseGate;
  @override
  Future<void Function()> pauseAndFlush() async {
    events.add('pause');
    if (failPause) throw StateError('save failed');
    await pauseGate?.future;
    final drafts = await persistence.database.draftSessions.pauseAndFlush();
    try {
      final queues = await persistence.pauseOperations();
      return () {
        events.add('resume');
        queues.release();
        drafts.release();
      };
    } catch (_) {
      drafts.release();
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    events.add('close');
    if (failClose) throw StateError('uncertain close');
    await draft?.close();
    draft = null;
    await persistence.close();
  }

  @override
  Future<void> openSelected() async {
    events.add('open');
    if (failOpen) throw StateError('open failed');
    final target = await SelectedLocalInstallation.resolve(root);
    persistence = await LocalPersistence.open(
      directory: target.directory,
      resolveRetainedPath: target.resolveRetainedPath,
    );
  }
}

void main() {
  late Directory root;
  late _Runtime runtime;
  late PreparedLocalRestore candidate;
  late LocalInstallationSelection selection;
  late LocalInstallationSwitchCoordinator coordinator;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('switch-runtime-fixture-');
    final persistence = await LocalPersistence.open(directory: root);
    final backup = await LocalSnapshotBundle.capture(persistence.database);
    candidate = await PreparedLocalRestore.prepare(
      source: await VerifiedLocalSnapshotBundle.open(backup.directory),
      liveDatabaseFile: persistence.database.storageFile!,
    );
    runtime = _Runtime(root, persistence);
    selection = await LocalInstallationSelection.open(root);
    coordinator = LocalInstallationSwitchCoordinator(
      selection: selection,
      runtime: runtime,
    );
  });
  tearDown(() async {
    await runtime.draft?.close();
    await runtime.persistence.close();
    await selection.close();
    await root.delete(recursive: true);
  });

  test(
    'restore flushes active input before close and explicit rollback recovers it',
    () async {
      final draft = DraftAutosaveSession(
        store: runtime.persistence.drafts,
        organizationId: 'business',
        ownerId: 'owner',
        domain: 'invoice',
        draftId: 'raw',
      );
      runtime.draft = draft;
      await draft.initialize();
      draft.replaceInput({'amount': '12.'});
      await coordinator.restore(candidate, expectedRevision: 0);
      expect(runtime.events, ['pause', 'close', 'open']);
      expect(
        runtime.persistence.database.storageFile!.path,
        candidate.databaseFile.path,
      );
      expect(coordinator.phase, InstallationSwitchPhase.idle);
      await coordinator.rollback(expectedRevision: 1);
      final saved = await runtime.persistence.drafts.find(
        organizationId: 'business',
        ownerId: 'owner',
        domain: 'invoice',
        draftId: 'raw',
      );
      expect(runtime.persistence.drafts.decode(saved!)['amount'], '12.');
    },
  );

  test('failed pause never closes or changes selection', () async {
    runtime.failPause = true;
    await expectLater(
      coordinator.restore(candidate, expectedRevision: 0),
      throwsA(isA<InstallationSwitchFailure>()),
    );
    expect(runtime.events, ['pause']);
    expect((await selection.read()).revision, 0);
    expect(coordinator.phase, InstallationSwitchPhase.idle);
    runtime.failPause = false;
    await coordinator.restore(candidate, expectedRevision: 0);
  });

  test('uncertain close does not resume or open another runtime', () async {
    runtime.failClose = true;
    await expectLater(
      coordinator.restore(candidate, expectedRevision: 0),
      throwsA(isA<InstallationSwitchFailure>()),
    );
    expect(runtime.events, ['pause', 'close']);
    expect((await selection.read()).revision, 0);
    expect(coordinator.canRetryOpening, isFalse);
    await expectLater(coordinator.retryOpening(), throwsStateError);
  });

  test(
    'failed open retains selected target and retries without another close',
    () async {
      runtime.failOpen = true;
      await expectLater(
        coordinator.restore(candidate, expectedRevision: 0),
        throwsA(isA<InstallationSwitchFailure>()),
      );
      expect((await selection.read()).revision, 1);
      expect(coordinator.canRetryOpening, isTrue);
      runtime.failOpen = false;
      await coordinator.retryOpening();
      expect(runtime.events, ['pause', 'close', 'open', 'open']);
      expect(coordinator.phase, InstallationSwitchPhase.idle);
    },
  );

  test('duplicate switch is rejected while pause is pending', () async {
    runtime.pauseGate = Completer();
    final first = coordinator.restore(candidate, expectedRevision: 0);
    while (!runtime.events.contains('pause')) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    await expectLater(
      coordinator.restore(candidate, expectedRevision: 0),
      throwsStateError,
    );
    runtime.pauseGate!.complete();
    await first;
    expect((await selection.read()).revision, 1);
  });

  test(
    'invalid target and stale selection are refused before touching runtime',
    () async {
      await expectLater(
        coordinator.restore(candidate, expectedRevision: 7),
        throwsA(isA<InstallationSwitchFailure>()),
      );
      await candidate.databaseFile.delete();
      await expectLater(
        coordinator.restore(candidate, expectedRevision: 0),
        throwsA(isA<InstallationSwitchFailure>()),
      );
      expect(runtime.events, isEmpty);
      expect((await selection.read()).revision, 0);
    },
  );
}
