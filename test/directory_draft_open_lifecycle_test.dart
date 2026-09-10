import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_workflow_controller.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/customer_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/directory_draft_workflows.dart';

void main() {
  final openers =
      <
        String,
        Future<DraftWorkflowController<dynamic>> Function(
          DirectoryPersistenceSession,
        )
      >{
        'customer': (work) => work.openCustomerDraft(),
        'company': (work) => work.openCompanyDraft(),
        'employee': (work) => work.openEmployeeDraft(),
        'vehicle': (work) => work.openVehicleDraft(),
      };
  for (final entry in openers.entries) {
    for (final duringOpen in [false, true]) {
      test(
        '${entry.key} rejects disposal ${duringOpen ? 'during' : 'before'} draft opening',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'directory-draft-lifecycle-',
          );
          final persistence = await LocalPersistence.open(directory: root);
          final work = await openUiLabDirectory(persistence.database);
          try {
            if (!duringOpen) work.dispose();
            final pending = entry.value(work);
            if (duringOpen) work.dispose();
            await expectLater(pending, throwsStateError);
            // Failed opening must release any registered draft session.
            final pause = await persistence.database.draftSessions
                .pauseAndFlush();
            pause.release();
            await persistence.database.verifyIntegrity();
            // Disposing an owner does not invalidate the installation itself.
            final replacement = await openUiLabDirectory(persistence.database);
            final recovered = await entry.value(replacement);
            // Each controller exposes the reusable session independent of a UI.
            await recovered.session.close();
            replacement.dispose();
          } finally {
            await persistence.close();
            await root.delete(recursive: true);
          }
        },
      );
    }
  }
}
