import 'dart:io';
import 'package:integration_test/integration_test.dart';
import '../test/mounted_application_switch_runtime_test.dart' as restore;

/// Executes the same real-host restore/rollback/failure contract in a platform
/// application. Fixtures use temporary directories, never normal app data.
/// This is runtime storage validation, not visual acceptance or OS-kill testing.
void main() {
  if ((Platform.isAndroid || Platform.isIOS) &&
      !const bool.fromEnvironment('STORAGE_QA')) {
    throw StateError(
      'Mobile runtime tests require STORAGE_QA=true and the isolated QA runner.',
    );
  }
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  restore.main();
}
