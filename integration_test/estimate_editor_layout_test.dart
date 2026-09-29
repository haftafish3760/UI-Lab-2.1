import 'dart:io';

import 'package:integration_test/integration_test.dart';

import '../test/estimate_editor_scrolling_test.dart' as layout;
import '../test/estimate_editor_draft_recovery_test.dart' as recovery;
import '../test/estimate_saved_section_editing_test.dart' as saved_editing;

/// Executes estimate layout and recovery on a native host. SQLite fixtures live
/// in disposable harness directories; this never opens normal company storage.
/// Logical viewport overrides exercise narrow/wide and accessibility layouts;
/// these checks do not replace visual review of actual native windows.
void main() {
  if ((Platform.isAndroid || Platform.isIOS) &&
      !const bool.fromEnvironment('STORAGE_QA')) {
    throw StateError('Mobile tests require the isolated STORAGE_QA runner.');
  }
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  layout.main();
  recovery.main();
  saved_editing.main();
}
