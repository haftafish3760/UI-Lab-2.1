import 'dart:io';
import 'package:ui_lab_2_1/src/screens/expenses/expense_recovery_routes.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_input.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_draft_recovery.dart';
import 'recurring_payment_draft_workflow_test.dart' show openSession;
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'selected workflow enters editor without another picker and retains edits on exit',
    (tester) async {
      final fixture = (await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp('plan-handoff-');
        final p = await LocalPersistence.open(directory: dir);
        final app = await openSession(p);
        for (final title in ['Chosen draft', 'Other draft']) {
          final draft = await app.recurringExpenses.openPlannedDraft();
          draft.updateInput(
            RecurringPlanDraftInput.fromPayload(
              draft.input.toPayload()
                ..['title'] = title
                ..['amount'] = '12.',
            ),
          );
          await draft.session.close();
        }
        final recovery = RecurringDraftRecovery(app);
        final entry = (await recovery.list()).singleWhere(
          (e) => e.preview.title == 'Chosen draft',
        );
        final resumed = await recovery.resume(entry) as ResumedRecurringPlan;
        return (dir: dir, p: p, app: app, workflow: resumed.controller);
      }))!;
      Future<void>? route;
      try {
        await tester.pumpWidget(
          RecurringExpenseUiScope(
            controller: fixture.app.recurringExpenses,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () {
                      route = openExpenseRecovery(
                        context,
                        ResumedRecurringPlan(fixture.workflow),
                        permissions: const ExpensePermissions.development(),
                      );
                    },
                    child: const Text('Open selected workflow'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open selected workflow'));
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => find.text('Chosen draft').evaluate().isNotEmpty,
        );
        expect(
          find.text('Continue an unfinished planned expense?'),
          findsNothing,
        );
        final title = find.byKey(const ValueKey('scheduled-expense-title'));
        final amount = find.byKey(const ValueKey('scheduled-expense-amount'));
        expect(tester.widget<TextFormField>(amount).controller!.text, '12.');
        await tester.enterText(title, 'Updated chosen draft');
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find.text('Draft saved on this device').evaluate().isNotEmpty,
        );
        await tester.pageBack();
        await finishNativeOperation(tester, () => route!);
        await tester.runAsync(() async {
          await fixture.workflow.session.close();
          final drafts = await fixture
              .app
              .recurringExpenses
              .plannedDraftRecovery
              .list();
          expect(drafts.map((d) => d.label).toSet(), {
            'Updated chosen draft',
            'Other draft',
          });
        });
        expect(fixture.app.recurringExpenses.records, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await fixture.workflow.session.close();
          await fixture.p.close();
          await fixture.dir.delete(recursive: true);
        });
      }
    },
  );
}
