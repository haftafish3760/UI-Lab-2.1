import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_switch_coordinator.dart';
import 'package:ui_lab_2_1/src/data/storage/local_restore_workflow.dart';

// Synthetic runtime boundaries; native selection/checkpoint storage is real.
// Mounted shutdown/reopening is covered by mounted_application_switch_runtime_test.
class _Runtime implements InstallationSwitchRuntime {
  int pauses = 0, closes = 0, opens = 0, resumes = 0;
  void Function()? afterPause;
  Completer<void>? pauseGate;
  bool failOpen = false;
  @override
  Future<void Function()> pauseAndFlush() async {
    pauses++;
    await pauseGate?.future;
    afterPause?.call();
    return () {
      resumes++;
    };
  }

  @override
  Future<void> close() async {
    closes++;
  }

  @override
  Future<void> openSelected() async {
    opens++;
    if (failOpen) throw StateError('injected open failure');
  }
}

class _CopiedReview implements LocalRestoreReview {
  _CopiedReview(LocalRestoreReview source)
    : checkpointId = source.checkpointId,
      databaseBytes = source.databaseBytes,
      attachmentCount = source.attachmentCount;
  @override
  final String checkpointId;
  @override
  final int databaseBytes;
  @override
  final int attachmentCount;
}

void main() {
  late Directory root;
  late LocalPersistence persistence;
  late LocalInstallationSelection selection;
  late LocalSnapshotBundle snapshot;
  late LocalRestoreWorkflow workflow;
  late _Runtime runtime;
  late String checkpointId;
  var allowed = true;
  setUp(() async {
    allowed = true;
    root = await Directory.systemTemp.createTemp('restore-review-');
    persistence = await LocalPersistence.open(directory: root);
    snapshot = await LocalSnapshotBundle.capture(persistence.database);
    checkpointId = paths.basename(snapshot.directory.path);
    selection = await LocalInstallationSelection.open(root);
    runtime = _Runtime();
    workflow = LocalRestoreWorkflow(
      selection: selection,
      runtime: runtime,
      authorize: () {
        if (!allowed) throw StateError('Restore access unavailable');
      },
      currentDatabaseFile: () => persistence.database.storageFile!,
    );
  });
  tearDown(() async {
    await persistence.close();
    await selection.close();
    await root.delete(recursive: true);
  });

  test(
    'controller rejects copied review facts without consuming real review',
    () async {
      final LocalRestoreController controller = workflow;
      final review = await controller.reviewCheckpoint(checkpointId);
      final copy = _CopiedReview(review);
      controller.cancelReview(copy);
      await expectLater(controller.confirm(copy), throwsStateError);
      expect(runtime.pauses, 0);
      expect((await selection.read()).revision, 0);
      await controller.confirm(review);
      expect(runtime.opens, 1);
    },
  );

  test(
    'checkpoint discovery verifies valid entries and retains damaged ones',
    () async {
      final partial = await Directory(
        '${snapshot.directory.parent.path}/partial',
      ).create();
      final bad = await Directory(
        '${snapshot.directory.parent.path}/bad',
      ).create();
      await File('${bad.path}/manifest.json').writeAsString('not json');
      final redirected = Link('${snapshot.directory.parent.path}/redirected');
      await redirected.create(root.path);
      final review = await workflow.reviewCheckpoint(checkpointId);
      final entries = await workflow.listCheckpoints();
      expect(entries, hasLength(4));
      final good = entries.singleWhere(
        (entry) => entry.checkpointId == checkpointId,
      );
      expect(good.isVerified, isTrue);
      expect(good.databaseBytes, greaterThan(0));
      expect(good.attachmentCount, 0);
      expect(entries.where((entry) => !entry.isVerified), hasLength(3));
      expect(await partial.exists(), isTrue);
      expect(await redirected.exists(), isTrue);
      expect((await selection.read()).revision, 0);
      expect(runtime.pauses, 0);
      // Discovery does not silently change the selection already reviewed.
      await workflow.confirm(review);
      expect(runtime.opens, 1);
    },
  );

  test('checkpoint discovery refuses a redirected root', () async {
    final checkpointRoot = snapshot.directory.parent;
    final moved = await checkpointRoot.rename('${root.path}/held-checkpoints');
    await Link(checkpointRoot.path).create(moved.path);
    await expectLater(workflow.listCheckpoints(), throwsStateError);
    expect(runtime.pauses, 0);
    expect((await selection.read()).revision, 0);
  });

  test(
    'review/cancel never activate; explicit confirmation applies once',
    () async {
      final review = await workflow.reviewCheckpoint(checkpointId);
      expect(review.databaseBytes, greaterThan(0));
      expect(review.attachmentCount, 0);
      expect((await selection.read()).revision, 0);
      expect(runtime.pauses, 0);
      workflow.cancelReview(review);
      await expectLater(workflow.confirm(review), throwsStateError);
      final replacement = await workflow.reviewCheckpoint(checkpointId);
      await expectLater(workflow.confirm(review), throwsStateError);
      await workflow.confirm(replacement);
      expect((await selection.read()).revision, 1);
      expect(runtime.closes, 1);
      expect(runtime.opens, 1);
      await expectLater(workflow.confirm(replacement), throwsStateError);
      expect(runtime.closes, 1);
    },
  );

  test('invalid new selection invalidates the previous review', () async {
    final review = await workflow.reviewCheckpoint(checkpointId);
    await expectLater(
      workflow.reviewCheckpoint('../outside'),
      throwsArgumentError,
    );
    await expectLater(workflow.confirm(review), throwsStateError);
    expect((await selection.read()).revision, 0);
    expect(runtime.pauses, 0);
  });

  test('revoked access rejects discovery, review and confirmation', () async {
    final review = await workflow.reviewCheckpoint(checkpointId);
    allowed = false;
    await expectLater(workflow.listCheckpoints(), throwsStateError);
    await expectLater(
      workflow.reviewCheckpoint(checkpointId),
      throwsStateError,
    );
    await expectLater(workflow.confirm(review), throwsStateError);
    expect(runtime.pauses, 0);
    expect((await selection.read()).revision, 0);
  });

  test(
    'revocation during pause resumes old runtime without selecting',
    () async {
      final review = await workflow.reviewCheckpoint(checkpointId);
      runtime.afterPause = () {
        allowed = false;
      };
      await expectLater(
        workflow.confirm(review),
        throwsA(isA<InstallationSwitchFailure>()),
      );
      expect(runtime.pauses, 1);
      expect(runtime.resumes, 1);
      expect(runtime.closes, 0);
      expect(runtime.opens, 0);
      expect((await selection.read()).revision, 0);
      expect(workflow.isBusy, isFalse);
    },
  );

  test('changed reviewed manifest fails before runtime pause', () async {
    final review = await workflow.reviewCheckpoint(checkpointId);
    final manifest = File('${snapshot.directory.path}/manifest.json');
    await manifest.writeAsString(
      '${await manifest.readAsString()}\n',
      flush: true,
    );
    await expectLater(workflow.confirm(review), throwsStateError);
    expect(runtime.pauses, 0);
    expect((await selection.read()).revision, 0);
  });

  test(
    'another installation decision invalidates a reviewed confirmation',
    () async {
      final oldReview = await workflow.reviewCheckpoint(checkpointId);
      final other = LocalRestoreWorkflow(
        selection: selection,
        runtime: runtime,
        authorize: () {
          if (!allowed) throw StateError('Restore access unavailable');
        },
        currentDatabaseFile: () => persistence.database.storageFile!,
      );
      await other.confirm(await other.reviewCheckpoint(checkpointId));
      await expectLater(workflow.confirm(oldReview), throwsStateError);
      expect(runtime.pauses, 1);
      expect(runtime.closes, 1);
      expect((await selection.read()).revision, 1);
    },
  );

  test('redirected checkpoint directory cannot enter review', () async {
    final alias = Link('${snapshot.directory.parent.path}/redirected');
    await alias.create(snapshot.directory.path);
    await expectLater(
      workflow.reviewCheckpoint('redirected'),
      throwsStateError,
    );
    expect(runtime.pauses, 0);
    expect((await selection.read()).revision, 0);
  });

  test(
    'installation changing during review cannot publish a stale review',
    () async {
      var reads = 0;
      final changing = LocalRestoreWorkflow(
        selection: selection,
        runtime: runtime,
        authorize: () {},
        currentDatabaseFile: () {
          reads++;
          return reads == 1
              ? persistence.database.storageFile!
              : snapshot.database.file;
        },
      );
      await expectLater(
        changing.reviewCheckpoint(checkpointId),
        throwsStateError,
      );
      expect(changing.isBusy, isFalse);
      expect(runtime.pauses, 0);
      expect((await selection.read()).revision, 0);
    },
  );

  test(
    'concurrent confirmation is rejected and failed reopen is explicitly retried',
    () async {
      final review = await workflow.reviewCheckpoint(checkpointId);
      runtime.pauseGate = Completer<void>();
      runtime.failOpen = true;
      final confirming = workflow.confirm(review);
      final failed = expectLater(
        confirming,
        throwsA(isA<InstallationSwitchFailure>()),
      );
      await expectLater(workflow.confirm(review), throwsStateError);
      await expectLater(
        workflow.reviewCheckpoint(checkpointId),
        throwsStateError,
      );
      expect(() => workflow.cancelReview(review), throwsStateError);
      runtime.pauseGate!.complete();
      await failed;
      expect(workflow.canRetryOpening, isTrue);
      expect((await selection.read()).revision, 1);
      runtime.failOpen = false;
      await workflow.retryOpening();
      expect(runtime.closes, 1);
      expect(runtime.opens, 2);
      expect(workflow.canRetryOpening, isFalse);
      await expectLater(workflow.confirm(review), throwsStateError);
    },
  );
}
