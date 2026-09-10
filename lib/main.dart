import 'package:flutter/material.dart';
import 'src/data/notifications/flutter_local_notification_gateway.dart';
import 'src/startup/application_startup_screen.dart';
import 'src/startup/open_ui_lab_application.dart';
import 'src/startup/ui_lab_startup_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = FlutterLocalNotificationGateway();
  final startup = UiLabStartupController(
    loadApplication: () =>
        openUiLabApplication(nativeNotifications: notifications),
  );
  runApp(
    ApplicationStartupScreen(
      hostController: startup,
      load: startup.loadApplication,
      onAbandoned: closeUnstartedApplication,
    ),
  );
}
