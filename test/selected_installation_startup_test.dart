import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/prepared_local_restore.dart';
import 'package:ui_lab_2_1/src/data/storage/verified_local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/startup/open_ui_lab_application.dart';

void main() {
  late Directory root;
  late PreparedLocalRestore candidate;
  late LocalInstallationSelection selection;
  Future<UiLabApp> open() async =>
      await openUiLabApplication(
            storageDirectory: root,
            nativeNotifications: const UnsupportedNativeNotificationGateway(),
          )
          as UiLabApp;
  Future<void> save(UiLabApp app, String text, int revision) => app.draftStore!
      .save(
        organizationId: 'fixture',
        ownerId: 'owner',
        domain: 'invoice',
        draftId: 'input',
        expectedRevision: revision,
        payload: {'raw': text},
        occurredAt: DateTime.utc(2026),
      )
      .then((_) {});
  Future<String> raw(UiLabApp app) async => (await app.draftStore!.find(
    organizationId: 'fixture',
    ownerId: 'owner',
    domain: 'invoice',
    draftId: 'input',
  ))!.payload;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('selected-startup-');
    final app = await open();
    try {
      await save(app, '  restored input  ', 0);
      final backup = await LocalSnapshotBundle.capture(
        app.workSession!.repository.database,
      );
      candidate = await PreparedLocalRestore.prepare(
        source: await VerifiedLocalSnapshotBundle.open(backup.directory),
        liveDatabaseFile: app.workSession!.repository.database.storageFile!,
      );
      await save(app, 'newer original input', 1);
    } finally {
      await closeUnstartedApplication(app);
    }
    selection = await LocalInstallationSelection.open(root);
    await selection.select(installation: candidate, expectedRevision: 0);
  });
  tearDown(() async {
    await selection.close();
    await root.delete(recursive: true);
  });

  test(
    'normal startup selects restore, keeps new drafts on reopen and honors explicit rollback',
    () async {
      var app = await open();
      try {
        expect(await raw(app), contains('  restored input  '));
        expect(
          app.workSession!.repository.database.storageFile!.path,
          candidate.databaseFile.path,
        );
        final currentMedia =
            '${candidate.directory.path}/attachments/new/photo.jpg';
        expect(app.resolveRetainedPath!(currentMedia), currentMedia);
        await save(app, 'edited after restore', 1);
      } finally {
        await closeUnstartedApplication(app);
      }
      app = await open();
      try {
        expect(await raw(app), contains('edited after restore'));
      } finally {
        await closeUnstartedApplication(app);
      }
      await selection.rollback(expectedRevision: 1);
      app = await open();
      try {
        expect(await raw(app), contains('newer original input'));
      } finally {
        await closeUnstartedApplication(app);
      }
    },
  );

  test(
    'missing selected database fails startup without opening the original',
    () async {
      await candidate.databaseFile.delete();
      await expectLater(open(), throwsA(anything));
      expect(await candidate.databaseFile.exists(), isFalse);
      expect((await selection.read()).revision, 1);
    },
  );

  test(
    'missing control directory fails startup without resetting selection',
    () async {
      await selection.close();
      final control = Directory('${root.path}/installation_selection');
      final moved = await control.rename('${root.path}/saved-control');
      await expectLater(open(), throwsStateError);
      expect(await control.exists(), isFalse);
      await moved.rename(control.path);
      selection = await LocalInstallationSelection.open(root);
    },
  );
}
