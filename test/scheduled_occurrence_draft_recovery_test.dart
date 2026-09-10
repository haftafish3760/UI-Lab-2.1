import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/scheduled_expense_occurrence_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/local_draft_scope.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('individual payment raw amount survives reopen and failed save', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('occurrence-recovery-'),
    ))!;
    var persistence = (await tester.runAsync(
      () => LocalPersistence.open(directory: directory),
    ))!;
    late RecurringExpenseUiController controller;
    Future<void> mount() async {
      controller = RecurringExpenseUiController(
        AuthorizedRecurringExpenseService(persistence.recurringExpenses),
        recurringExpenseUiLabOwnerPermissions(),
        (_) => 'Alex Morgan',
        drafts: persistence.drafts,
      );
      await tester.runAsync(controller.load);
      if (controller.records.isEmpty) {
        await tester.runAsync(
          () => controller.create(
            ScheduledExpenseRecord(
              id: 'plan',
              title: 'Insurance',
              category: ExpenseCategory.vehicleInsurance,
              amount: 100,
              nextDueOn: DateTime(2030, 1, 20),
              kind: ExpenseScheduleKind.monthly,
              ownerEmployeeId: 'alex',
              owner: 'Alex Morgan',
              dueDay: 20,
            ),
          ),
        );
      }
      await tester.pumpWidget(
        LocalDraftScope(
          store: persistence.drafts,
          child: RecurringExpenseUiScope(
            controller: controller,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ScheduledExpenseOccurrenceEditorScreen(
                          occurrence: controller.currentOccurrenceFor('plan')!,
                        ),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    Future<void> saved() async {
      await tester.pump();
      await waitForNativeSave(
        tester,
        () => find.text('Draft saved on this device').evaluate().isNotEmpty,
      );
    }

    await mount();
    await saved();
    final amount = find.byKey(const ValueKey('occurrence-expected-amount'));
    await tester.enterText(amount, '12.');
    FocusManager.instance.primaryFocus?.unfocus();
    await saved();
    await tester.binding.handlePopRoute();
    await waitForNativeSave(
      tester,
      () => find
          .byType(ScheduledExpenseOccurrenceEditorScreen)
          .evaluate()
          .isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    controller.dispose();
    await tester.runAsync(persistence.close);
    persistence = (await tester.runAsync(
      () => LocalPersistence.open(directory: directory),
    ))!;
    await mount();
    await saved();
    expect(tester.widget<TextFormField>(amount).controller!.text, '12.');
    await tester.enterText(amount, '12.50');
    FocusManager.instance.primaryFocus?.unfocus();
    await saved();
    await tester.runAsync(
      () => persistence.database.customStatement(
        "CREATE TRIGGER fail_occurrence BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      ),
    );
    final save = find.byKey(const ValueKey('save-occurrence-edit'));
    await tester.tap(save);
    await waitForNativeSave(
      tester,
      () => find
          .text(
            'The payment was not saved. Your input is still here. Retry saving.',
          )
          .evaluate()
          .isNotEmpty,
    );
    expect(controller.currentOccurrenceFor('plan')!.expectedAmount, 100);
    expect(controller.revisionForId('plan'), 1);
    expect(tester.widget<TextFormField>(amount).controller!.text, '12.50');
    await tester.runAsync(
      () =>
          persistence.database.customStatement('DROP TRIGGER fail_occurrence'),
    );
    await tester.tap(save);
    await waitForNativeSave(
      tester,
      () => find
          .byType(ScheduledExpenseOccurrenceEditorScreen)
          .evaluate()
          .isEmpty,
    );
    expect(controller.currentOccurrenceFor('plan')!.expectedAmount, 12.50);
    expect(controller.records.single.amount, 100);
    expect(controller.records.single.nextDueOn, DateTime(2030, 1, 20));
    expect(controller.revisionForId('plan'), 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    controller.dispose();
    await tester.runAsync(() async {
      expect(
        await persistence.drafts.list(
          organizationId:
              recurringExpenseUiLabOwnerPermissions().organizationId,
          domain: 'expenses/planned-occurrence',
          ownerId: 'alex',
        ),
        isEmpty,
      );
      await persistence.close();
      await directory.delete(recursive: true);
    });
    expect(tester.takeException(), isNull);
  });
}
