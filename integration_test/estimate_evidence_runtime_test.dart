import 'dart:io';

import 'package:integration_test/integration_test.dart';

import '../test/estimate_photo_management_test.dart' as photos;
import '../test/estimate_photo_note_recovery_test.dart' as photo_notes;
import '../test/estimate_signature_draft_recovery_test.dart' as signatures;
import '../test/work_customer_approval_permissions_test.dart' as permissions;

/// Synthetic evidence in disposable databases only. On mobile the dedicated
/// QA package protects the normal installation and its company records.
void main() {
  if ((Platform.isAndroid || Platform.isIOS) &&
      !const bool.fromEnvironment('STORAGE_QA')) {
    throw StateError('Mobile tests require the isolated STORAGE_QA runner.');
  }
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  photos.main();
  photo_notes.main();
  signatures.main();
  permissions.main();
}
