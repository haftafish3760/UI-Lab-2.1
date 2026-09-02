import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'file_notification_repository.dart';

/// Opens notification state in private Application Support/app data.
Future<FileNotificationRepository> openPrivateNotificationRepository() async {
  final applicationSupport = await getApplicationSupportDirectory();
  final directory = Directory.fromUri(
    applicationSupport.uri.resolve(
      'maintainiac_ui_lab/${FileNotificationRepository.directoryName}/',
    ),
  );
  return FileNotificationRepository.open(directory);
}
