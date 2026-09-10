import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/startup/application_host_controller.dart';
import 'package:ui_lab_2_1/src/startup/open_ui_lab_application.dart';
import 'package:ui_lab_2_1/src/startup/ui_lab_startup_controller.dart';

void main() {
  test(
    'host owns one restore service with live authority and attachment',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'restore-service-boundary-',
      );
      Future<Widget> load() => openUiLabApplication(
        storageDirectory: root,
        nativeNotifications: const UnsupportedNativeNotificationGateway(),
      );
      final app = await load() as UiLabApp;
      final selection = await LocalInstallationSelection.open(root);
      final startup = UiLabStartupController(loadApplication: load);
      var allowed = true;
      void authorize() {
        if (!allowed) throw StateError('Access revoked');
      }

      startup.configureRestore(selection: selection, authorize: authorize);
      final service = startup.restoreWorkflow!;
      try {
        expect(
          () => startup.configureRestore(
            selection: selection,
            authorize: authorize,
          ),
          throwsStateError,
        );
        expect(startup.restoreWorkflow, same(service));
        await expectLater(service.listCheckpoints(), throwsStateError);
        final detach = startup.attach(
          ApplicationHostAttachment(
            currentApplication: () => app,
            blockEntryPoints: (_) {},
            settleView: () async {},
            presentApplication: (_) async {},
          ),
        );
        final checkpoint = await LocalSnapshotBundle.capture(
          app.workSession!.repository.database,
        );
        final choices = await service.listCheckpoints();
        expect(choices, isNotEmpty);
        final id = checkpoint.directory.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .last;
        final review = await service.reviewCheckpoint(id);
        expect(review.checkpointId, id);
        allowed = false;
        await expectLater(service.confirm(review), throwsStateError);
        expect((await selection.read()).revision, 0);
        allowed = true;
        detach();
        await expectLater(service.listCheckpoints(), throwsStateError);
      } finally {
        await closeUnstartedApplication(app);
        await selection.close();
        await root.delete(recursive: true);
      }
    },
  );
}
