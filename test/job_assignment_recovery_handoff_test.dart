import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/job_action_draft_recovery.dart';
import 'package:ui_lab_2_1/src/screens/work/job_details_recovery_routes.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/job_assignment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/job_assignment_editor_sheet.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final mismatch in [false, true]) {
    testWidgets(
      'selected assignment mismatch=$mismatch retains unconfirmed choices',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final work = (await tester.runAsync(
          () async => openUiLabWorkSession(await harness.open()),
        ))!;
        final job = work.records.firstWhere(
          (r) => r.kind == WorkRecordKind.job && work.permissions.canEdit(r),
        );
        final workflow = (await tester.runAsync(
          () => work.openJobAssignmentDraft(job.id),
        ))!;
        await tester.runAsync(() async {
          workflow.updateAssignment(
            assignee: 'Unassigned',
            vehicle: 'Service Van 4',
          );
          await workflow.session.flush();
        });
        final revision = work.storageRevisionFor(job.id);
        final store = PrototypeOperationsStore(workSession: work);
        Future<void>? route;
        try {
          await tester.pumpWidget(
            PrototypeOperationsScope(
              store: store,
              child: MaterialApp(
                theme: AppTheme.light,
                home: mismatch
                    ? Scaffold(
                        body: JobAssignmentEditorSheet(
                          record: work.records.firstWhere(
                            (r) => r.id != job.id,
                          ),
                          work: work,
                          recoveredWorkflow: workflow,
                        ),
                      )
                    : Builder(
                        builder: (context) => Scaffold(
                          body: TextButton(
                            onPressed: () => route = openJobDetailsRecovery(
                              context,
                              ResumedJobAssignment(workflow),
                            ),
                            child: const Text('Resume assignment'),
                          ),
                        ),
                      ),
              ),
            ),
          );
          if (!mismatch) await tester.tap(find.text('Resume assignment'));
          await tester.pumpAndSettle();
          if (mismatch) {
            await waitForNativeSave(
              tester,
              () => find
                  .textContaining('could not be opened')
                  .evaluate()
                  .isNotEmpty,
            );
          } else {
            expect(find.text('Service Van 4'), findsOneWidget);
            await tester.tap(find.byKey(const ValueKey('Technician')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Jordan Lee').last);
            await tester.pumpAndSettle();
            await finishNativeOperation(tester, workflow.session.flush);
          }
          if (!mismatch) {
            await tester.ensureVisible(find.text('Keep unfinished assignment'));
            await tester.tap(find.text('Keep unfinished assignment'));
            await finishNativeOperation(tester, () => route!);
            expect(find.text('Resume assignment'), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          final saved = await tester.runAsync(
            () => work.drafts.find(
              organizationId: workflow.session.organizationId,
              domain: workflow.session.domain,
              draftId: workflow.session.draftId,
              ownerId: workflow.session.ownerId,
            ),
          );
          expect(
            jsonDecode(saved!.payload)['assignee'],
            mismatch ? 'Unassigned' : 'Jordan Lee',
          );
          expect(work.storageRevisionFor(job.id), revision);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          store.dispose();
          work.dispose();
          await tester.runAsync(harness.dispose);
        }
      },
    );
  }
}
