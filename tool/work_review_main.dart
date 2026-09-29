// Explicit development launch target. Never imported by lib/main.dart.
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/startup/application_startup_screen.dart';
import 'package:ui_lab_2_1/src/startup/open_ui_lab_application.dart';
import 'package:ui_lab_2_1/src/startup/ui_lab_startup_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const workspace = String.fromEnvironment('WORK_REVIEW_WORKSPACE');
  final startup = UiLabStartupController(
    loadApplication: () async {
      if (!kDebugMode ||
          const bool.fromEnvironment('MAINTAINIAC_UI_LAB_DEMO_DATA') ||
          !RegExp(r'^[a-z0-9][a-z0-9-]{7,63}$').hasMatch(workspace)) {
        throw StateError('An explicit isolated debug workspace is required.');
      }
      final support = await getApplicationSupportDirectory();
      final root = Directory(
        '${support.path}/work_review_workspaces/$workspace',
      );
      // Missing preparation is an error, never a reason to use normal storage.
      if (await FileSystemEntity.type(root.path, followLinks: false) !=
              FileSystemEntityType.directory ||
          await File('${root.path}/review-workspace-id').readAsString() !=
              workspace ||
          !await File('${root.path}/maintainiac.sqlite').exists()) {
        throw StateError('The prepared test workspace is unavailable.');
      }
      return openUiLabApplication(
        storageDirectory: root,
        nativeNotifications: const UnsupportedNativeNotificationGateway(),
      );
    },
  );
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Banner(
        message: 'TEST WORKSPACE',
        location: BannerLocation.topEnd,
        color: const Color(0xffa64000),
        child: ApplicationStartupScreen(
          hostController: startup,
          load: startup.loadApplication,
          onAbandoned: closeUnstartedApplication,
        ),
      ),
    ),
  );
}
