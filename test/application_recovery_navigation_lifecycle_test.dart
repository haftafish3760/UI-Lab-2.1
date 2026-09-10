import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_primary_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/job_material_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/shell/application_recovery_routes.dart';
import 'estimate_draft_workflow_test.dart' show inputFor;
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final detached in [false, true]) {
    testWidgets(
      'application navigation retains draft with detached context: $detached',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final work = (await tester.runAsync(
          () async => openUiLabWorkSession(await harness.open()),
        ))!;
        final actor = work.permissions.actorEmployeeId;
        final workflow = (await tester.runAsync(
          () => work.openEstimateDraft(creatorId: actor),
        ))!;
        workflow.updateInput(inputFor(actor));
        late BuildContext routeContext;
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  routeContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          if (detached) await tester.pumpWidget(const SizedBox.shrink());
          Object? failure;
          await finishNativeOperation(tester, () async {
            try {
              await openApplicationRecovery(
                routeContext,
                ResumedEstimateDraft(workflow),
                expensePermissions: const ExpensePermissions.development(),
                estimatePermissions: const EstimatePermissions.development(),
                materialPermissions:
                    const JobWorkspacePermissions.development(),
                selectedDay: DateTime(2026, 9, 10),
                employeeLabel: (id) => id,
              );
            } on Object catch (error) {
              failure = error;
            }
          });
          // Attached context deliberately lacks the Work scope; detached context
          // must simply release its workflow without attempting navigation.
          if (detached) {
            expect(failure, isNull);
          } else {
            expect(failure, isNotNull);
          }
          expect(() => workflow.updateInput(inputFor(actor)), throwsStateError);
          final reopened = (await tester.runAsync(
            () => work.openEstimateDraft(
              creatorId: actor,
              recoveryDraftId: workflow.session.draftId,
            ),
          ))!;
          expect(reopened.recoveredInput!.discount, '0.');
          expect(
            work.records.where((r) => r.id == 'workflow-estimate'),
            isEmpty,
          );
          await finishNativeOperation(tester, reopened.session.close);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          work.dispose();
          await tester.runAsync(harness.dispose);
        }
      },
    );
  }
}
