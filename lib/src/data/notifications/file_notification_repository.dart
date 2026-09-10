// Compatibility entry point for existing file-backed tests and legacy readers.
// Current application storage is injected into the shared domain repository.
import 'local_notification_repository.dart';
export 'local_notification_repository.dart';

typedef FileNotificationRepository = LocalNotificationRepository;
