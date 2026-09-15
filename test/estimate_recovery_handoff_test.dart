import 'support/document_form_navigation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'estimate_draft_workflow_test.dart' show inputFor;
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final mismatch in [false, true]) {
    testWidgets(
      'selected estimate handoff mismatch=$mismatch preserves input',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final db = (await tester.runAsync(harness.open))!;
        final work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
        final actor = work.permissions.actorEmployeeId;
        final workflow = (await tester.runAsync(
          () => work.openEstimateDraft(creatorId: actor),
        ))!;
        final other = (await tester.runAsync(
          () => work.openEstimateDraft(creatorId: actor),
        ))!;
        await tester.runAsync(() async {
          workflow.updateInput(inputFor(actor));
          other.updateInput(inputFor(actor));
          await workflow.session.flush();
          await other.session.close();
        });
        final before = Map<String, Object?>.from(workflow.session.input);
        final store = PrototypeOperationsStore(workSession: work);
        final scope = OperationalScopeController();
        try {
          await tester.pumpWidget(
            PrototypeOperationsScope(
              store: store,
              child: OperationalScope(
                controller: scope,
                child: MaterialApp(
                  theme: AppTheme.light,
                  home: EstimateEditorScreen(
                    initialDay: DateTime(2026, 9, 9),
                    createdByEmployeeId: mismatch ? 'wrong-creator' : actor,
                    recoveredWorkflow: workflow,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Continue an unfinished estimate?'), findsNothing);
          if (mismatch) {
            await waitForNativeSave(
              tester,
              () => find
                  .textContaining('could not be opened')
                  .evaluate()
                  .isNotEmpty,
            );
            expect(workflow.session.input, before);
          } else {
            await openDocumentSection(tester, 'estimate-information');
            final title = find.byKey(const ValueKey('estimate-title'));
            expect(title, findsOneWidget);
            expect(workflow.session.input['discount'], '0.');
            await tester.enterText(title, 'Selected estimate updated');
            await finishNativeOperation(tester, workflow.session.flush);
            expect(
              workflow.session.input['title'],
              'Selected estimate updated',
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          final saved = await tester.runAsync(
            () => work.drafts.find(
              organizationId: workflow.session.organizationId,
              domain: workflow.session.domain,
              draftId: workflow.session.draftId,
              ownerId: actor,
            ),
          );
          expect(saved, isNotNull);
          expect(
            jsonDecode(saved!.payload)['title'],
            mismatch ? '' : 'Selected estimate updated',
          );
          final untouched = await tester.runAsync(
            () => work.drafts.find(
              organizationId: other.session.organizationId,
              domain: other.session.domain,
              draftId: other.session.draftId,
              ownerId: actor,
            ),
          );
          expect(jsonDecode(untouched!.payload)['title'], '');
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          store.dispose();
          work.dispose();
          scope.dispose();
          await tester.runAsync(harness.dispose);
        }
      },
    );
  }
}
