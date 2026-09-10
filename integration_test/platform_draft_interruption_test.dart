import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';

/// Two explicit invocations surround an external OS kill. The write invocation
/// intentionally cannot pass; only the subsequent read verifies recovery.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const runId = String.fromEnvironment('STORAGE_INTERRUPTION_RUN');
  const phase = String.fromEnvironment('STORAGE_INTERRUPTION_PHASE');
  testWidgets('platform draft interruption: $phase', (tester) async {
    if (!Platform.isAndroid ||
        !const bool.fromEnvironment('STORAGE_QA') ||
        !RegExp(r'^[a-zA-Z0-9_-]{8,64}$').hasMatch(runId) ||
        !['write', 'read'].contains(phase)) {
      throw ArgumentError(
        'Supply an isolated interruption run ID and write/read phase.',
      );
    }
    final support = await getApplicationSupportDirectory();
    final root = Directory('${support.path}/uilab-interruption-$runId');
    const expected = {
      'amount': '12.',
      'notes': '  acknowledged unfinished input  ',
    };
    if (phase == 'write') {
      if (await root.exists()) {
        throw StateError('Refusing to reuse a write fixture.');
      }
      final persistence = await LocalPersistence.open(directory: root);
      final draft = DraftAutosaveSession(
        store: persistence.drafts,
        organizationId: 'business',
        ownerId: 'owner',
        domain: 'invoice',
        draftId: 'interrupted-work',
      );
      await draft.initialize();
      draft.replaceInput(expected);
      await draft.flush();
      expect(draft.savedRevision, 1);
      // This subsequent store transaction is deliberately not acknowledged by
      // an autosave session. Kill only after its SQL mutation has executed.
      await persistence.database.transaction(() async {
        await persistence.drafts.save(
          organizationId: 'business',
          ownerId: 'owner',
          domain: 'invoice',
          draftId: 'interrupted-work',
          expectedRevision: 1,
          payload: {'amount': '999', 'notes': 'uncommitted replacement'},
          occurredAt: DateTime.now().toUtc(),
        );
        // External harness synchronization; contains only its synthetic run ID.
        // ignore: avoid_print
        print('UILAB_UNCOMMITTED_READY_$runId');
        await Completer<void>().future;
      });
      fail('Write phase must be interrupted before commit.');
    } else {
      expect(
        await root.exists(),
        isTrue,
        reason: 'The original fixture must survive.',
      );
      final persistence = await LocalPersistence.open(directory: root);
      try {
        final recovered = await persistence.drafts.find(
          organizationId: 'business',
          ownerId: 'owner',
          domain: 'invoice',
          draftId: 'interrupted-work',
        );
        expect(recovered, isNotNull);
        expect(recovered!.revision, 1);
        expect(persistence.drafts.decode(recovered), expected);
        await persistence.database.verifyIntegrity();
      } finally {
        await persistence.close();
      }
      await root.delete(recursive: true);
      // ignore: avoid_print
      print('UILAB_RECOVERY_VERIFIED_$runId');
    }
  });
}
