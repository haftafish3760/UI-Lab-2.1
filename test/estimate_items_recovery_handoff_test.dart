import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_action_draft_recovery.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_action_recovery_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_items_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_items_draft_input.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_items_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/stored_estimate_items_editor.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'work_draft_controller_compatibility_test.dart'
    show legacyItemsWorkspace;
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final mismatch in [false, true]) {
    testWidgets(
      'selected item workspace mismatch=$mismatch retains nested input',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final work = (await tester.runAsync(
          () async => openUiLabWorkSession(await harness.open()),
        ))!;
        final base = work.records.singleWhere((r) => r.id == 'est-1040');
        final workflow = (await tester.runAsync(
          () => work.openEstimateItemsDraft(base),
        ))!;
        await tester.runAsync(() async {
          workflow.updateWorkspace(
            WorkItemsDraftInput.fromPayload(legacyItemsWorkspace()),
          );
          await workflow.session.flush();
        });
        final raw = workflow.session.input;
        final revision = work.storageRevisionFor(base.id);
        final scope = OperationalScopeController();
        final store = PrototypeOperationsStore(workSession: work);
        Future<void>? route;
        try {
          await tester.pumpWidget(
            PrototypeOperationsScope(
              store: store,
              child: OperationalScope(
                controller: scope,
                child: MaterialApp(
                  theme: AppTheme.light,
                  home: mismatch
                      ? StoredEstimateItemsEditor(
                          record: work.records.firstWhere(
                            (r) => r.id != base.id,
                          ),
                          work: work,
                          recoveredWorkflow: workflow,
                        )
                      : Builder(
                          builder: (context) => Scaffold(
                            body: TextButton(
                              onPressed: () =>
                                  route = openEstimateActionRecovery(
                                    context,
                                    ResumedEstimateItems(workflow),
                                    reviewPermissions:
                                        const EstimatePermissions.development(),
                                  ),
                              child: const Text('Resume action'),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          );
          if (!mismatch) await tester.tap(find.text('Resume action'));
          await tester.pumpAndSettle();
          if (mismatch) {
            await waitForNativeSave(
              tester,
              () => find
                  .text('Selected items belong to another estimate.')
                  .evaluate()
                  .isNotEmpty,
            );
          } else {
            expect(
              tester
                  .widget<EstimateItemsScreen>(find.byType(EstimateItemsScreen))
                  .recoveryInput!
                  .pendingItem!
                  .quantity,
              '1.',
            );
          }
          if (!mismatch) {
            await tester.ensureVisible(find.byTooltip('Back to Work'));
            await tester.pumpAndSettle();
            await tester.tap(find.byTooltip('Back to Work'));
            await finishNativeOperation(tester, () => route!);
            expect(find.text('Resume action'), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          expect(workflow.session.input, raw);
          expect(work.storageRevisionFor(base.id), revision);
          final reopened = (await tester.runAsync(
            () => work.openEstimateItemsDraft(base),
          ))!;
          expect(reopened.input.workspace.pendingItem!.quantity, '1.');
          await finishNativeOperation(tester, reopened.session.close);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          store.dispose();
          scope.dispose();
          work.dispose();
          await tester.runAsync(harness.dispose);
        }
      },
    );
  }
}
