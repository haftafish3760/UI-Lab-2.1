import 'package:flutter/material.dart';
import 'src/data/notifications/flutter_local_notification_gateway.dart';
import 'src/startup/application_startup_screen.dart';
import 'src/startup/open_ui_lab_application.dart';
import 'src/startup/ui_lab_startup_controller.dart';
import 'src/startup/firebase_connection.dart';
import 'src/data/account/firebase_account_gateway.dart';
import 'src/shared/account_scope.dart';
import 'src/data/device_capabilities/device_resource_monitor.dart';
import 'src/data/device_capabilities/device_workload_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DeviceResourceMonitor(DeviceWorkloadService.instance).start();
  final notifications = FlutterLocalNotificationGateway();
  final firebase = FirebaseConnection();
  final startup = UiLabStartupController(
    loadApplication: () async {
      return openUiLabApplication(nativeNotifications: notifications);
    },
  );
  runApp(
    AccountScope(
      gateway: FirebaseAccountGateway(firebase),
      child: ApplicationStartupScreen(
        hostController: startup,
        load: startup.loadApplication,
        onAbandoned: closeUnstartedApplication,
      ),
    ),
  );
}
