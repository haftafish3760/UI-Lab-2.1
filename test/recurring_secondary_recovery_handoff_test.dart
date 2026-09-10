import 'dart:io';
import 'package:ui_lab_2_1/src/screens/expenses/expense_recovery_routes.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_draft_recovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_payment_session.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_payment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_occurrence_draft_workflow.dart';
import 'recurring_payment_draft_workflow_test.dart' show openSession, seed;
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final payment in [true, false]) {
    testWidgets(
      'recurring payment=$payment handoff keeps partial amount without confirming',
      (tester) async {
        final f = (await tester.runAsync(() async {
          final dir = await Directory.systemTemp.createTemp(
            'recurring-handoff-',
          );
          final p = await LocalPersistence.open(directory: dir);
          final app = await openSession(p);
          final id = await seed(app);
          final pay = await app.openPaymentDraft(
            templateId: 'plan',
            occurrenceId: id,
          );
          final occurrence = await app.recurringExpenses.openOccurrenceDraft(
            templateId: 'plan',
            occurrenceId: id,
          );
          pay.updateAmount('12.');
          occurrence.updateValues(amount: '-', dueOn: DateTime(2030, 1, 22));
          await pay.session.flush();
          await occurrence.session.flush();
          return (dir: dir, p: p, app: app, pay: pay, occurrence: occurrence);
        }))!;
        final session = payment ? f.pay.session : f.occurrence.session;
        try {
          await tester.pumpWidget(
            RecurringPaymentScope(
              session: f.app,
              child: RecurringExpenseUiScope(
                controller: f.app.recurringExpenses,
                child: MaterialApp(
                  home: Builder(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () {
                          openExpenseRecovery(
                            context,
                            payment
                                ? ResumedRecurringPayment(f.pay)
                                : ResumedRecurringOccurrence(f.occurrence),
                            permissions: const ExpensePermissions.development(),
                          );
                        },
                        child: const Text('Open'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          final field = find.byKey(
            ValueKey(
              payment
                  ? 'scheduled-expense-actual-amount'
                  : 'occurrence-expected-amount',
            ),
          );
          await waitForNativeSave(tester, () => field.evaluate().isNotEmpty);
          expect(
            tester.widget<TextFormField>(field).controller!.text,
            payment ? '12.' : '-',
          );
          await tester.enterText(field, '34.');
          await tester.pump();
          await waitForNativeSave(
            tester,
            () => find.text('Draft saved on this device').evaluate().isNotEmpty,
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await finishNativeOperation(tester, session.close);
          await tester.runAsync(() async {
            final saved = (await f.p.drafts.find(
              organizationId: session.organizationId,
              ownerId: session.ownerId,
              domain: session.domain,
              draftId: session.draftId,
            ))!;
            expect(f.p.drafts.decode(saved)['amount'], '34.');
          });
          expect(f.app.expenses.records, isEmpty);
          expect(
            f.app.recurringExpenses
                .currentOccurrenceFor('plan')!
                .expectedAmount,
            100,
          );
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await finishNativeOperation(tester, f.pay.session.close);
          await finishNativeOperation(tester, f.occurrence.session.close);
          await tester.runAsync(() async {
            await f.p.close();
            await f.dir.delete(recursive: true);
          });
        }
      },
    );
  }
}
