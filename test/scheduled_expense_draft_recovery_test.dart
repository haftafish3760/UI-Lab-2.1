import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/screens/expenses/scheduled_expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/local_draft_scope.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'planned expense raw input and reminders survive reopen and failed confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('planned-recovery-'),
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
                          builder: (_) => const ScheduledExpenseEditorScreen(),
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
      final title = find.byKey(const ValueKey('scheduled-expense-title'));
      final amount = find.byKey(const ValueKey('scheduled-expense-amount'));
      await tester.enterText(title, '  Supplies  ');
      await tester.enterText(amount, '12.');
      await tester.tap(find.text('7 days before'));
      await tester.tap(find.text('Require a receipt each time'));
      FocusManager.instance.primaryFocus?.unfocus();
      await saved();
      await tester.binding.handlePopRoute();
      await waitForNativeSave(
        tester,
        () => find.byType(ScheduledExpenseEditorScreen).evaluate().isEmpty,
      );
      expect(controller.records, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      controller.dispose();
      await tester.runAsync(persistence.close);
      persistence = (await tester.runAsync(
        () => LocalPersistence.open(directory: directory),
      ))!;
      await mount();
      await waitForNativeSave(
        tester,
        () => find
            .text('Continue an unfinished planned expense?')
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(find.text('  Supplies  '));
      await saved();
      expect(
        tester.widget<TextFormField>(title).controller!.text,
        '  Supplies  ',
      );
      expect(tester.widget<TextFormField>(amount).controller!.text, '12.');
      expect(
        tester
            .widget<FilterChip>(
              find.widgetWithText(FilterChip, '7 days before'),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(
                SwitchListTile,
                'Require a receipt each time',
              ),
            )
            .value,
        isTrue,
      );
      await tester.enterText(amount, '12.50');
      FocusManager.instance.primaryFocus?.unfocus();
      await saved();
      await tester.runAsync(
        () => persistence.database.customStatement(
          "CREATE TRIGGER fail_planned BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
        ),
      );
      final save = find.byKey(const ValueKey('save-scheduled-expense'));
      await tester.tap(save);
      await waitForNativeSave(
        tester,
        () => find
            .text(
              'The planned expense was not saved. Your input is still here. Retry saving.',
            )
            .evaluate()
            .isNotEmpty,
      );
      expect(controller.records, isEmpty);
      expect(tester.widget<TextFormField>(amount).controller!.text, '12.50');
      await tester.runAsync(
        () => persistence.database.customStatement('DROP TRIGGER fail_planned'),
      );
      await tester.tap(save);
      await waitForNativeSave(
        tester,
        () => find.byType(ScheduledExpenseEditorScreen).evaluate().isEmpty,
      );
      expect(controller.records.single.amount, 12.50);
      expect(controller.records.single.receiptRequired, isTrue);
      expect(controller.records.single.reminderDaysBefore, [7]);
      expect(
        controller.currentOccurrenceFor(controller.records.single.id),
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      controller.dispose();
      await tester.runAsync(() async {
        expect(
          await persistence.drafts.list(
            organizationId:
                recurringExpenseUiLabOwnerPermissions().organizationId,
            domain: 'expenses/planned-new',
            ownerId: 'alex',
          ),
          isEmpty,
        );
        await persistence.close();
        await directory.delete(recursive: true);
      });
      expect(tester.takeException(), isNull);
    },
  );
}
