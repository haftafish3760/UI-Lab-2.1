import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/local_draft_scope.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'manual expense raw input survives reopen and failed confirmation',
    (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('expense-editor-recovery-'),
      ))!;
      var persistence = (await tester.runAsync(
        () => LocalPersistence.open(directory: directory),
      ))!;
      final scope = OperationalScopeController();
      late ExpenseUiRepositoryController controller;
      Future<void> mount() async {
        controller = ExpenseUiRepositoryController(
          ExpenseUiRepositoryBridge(
            service: AuthorizedExpenseService(persistence.expenses),
            employeeLabelForId: expenseUiLabEmployeeLabel,
            jobLabelForId: (_) => null,
          ),
          expenseUiLabOwnerPermissions(),
          drafts: persistence.drafts,
        );
        await tester.runAsync(controller.load);
        await tester.pumpWidget(
          LocalDraftScope(
            store: persistence.drafts,
            child: ExpenseUiScope(
              controller: controller,
              child: OperationalScope(
                controller: scope,
                child: MaterialApp(
                  theme: AppTheme.light,
                  home: Builder(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ExpenseEditorScreen(
                              expenseDate: DateTime(2030, 1, 2),
                            ),
                          ),
                        ),
                        child: const Text('New expense'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('New expense'));
        await tester.pump();
      }

      final vendor = find.byKey(const ValueKey('expense-vendor-field'));
      final amount = find.byKey(const ValueKey('expense-amount-field'));
      await mount();
      await waitForNativeSave(tester, () => vendor.evaluate().isNotEmpty);
      await tester.enterText(vendor, '  Partial supplier  ');
      await tester.ensureVisible(amount);
      await tester.enterText(amount, '12.');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await waitForNativeSave(
        tester,
        () => find.text('Draft saved on this device').evaluate().isNotEmpty,
      );
      Navigator.of(tester.element(vendor)).pop();
      await waitForNativeSave(
        tester,
        () => find.byType(ExpenseEditorScreen).evaluate().isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      controller.dispose();
      await tester.runAsync(() async {
        await persistence.close();
        persistence = await LocalPersistence.open(directory: directory);
        await persistence.database.customStatement('''
        CREATE TRIGGER fail_confirmation BEFORE DELETE ON local_drafts
        BEGIN SELECT RAISE(ABORT, 'injected confirmation failure'); END
      ''');
      });
      await mount();
      await waitForNativeSave(
        tester,
        () =>
            find.text('Continue an unfinished expense?').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('  Partial supplier  '));
      await waitForNativeSave(tester, () => vendor.evaluate().isNotEmpty);
      expect(
        tester.widget<TextFormField>(vendor).controller!.text,
        '  Partial supplier  ',
      );
      expect(tester.widget<TextFormField>(amount).controller!.text, '12.');
      await tester.ensureVisible(amount);
      await tester.enterText(amount, '12.50');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save-expense-button'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await waitForNativeSave(
        tester,
        () => find
            .text(
              'The expense was not saved. Your input is still here. Retry saving.',
            )
            .evaluate()
            .isNotEmpty,
      );
      expect(controller.records, isEmpty);
      expect(tester.widget<TextFormField>(amount).controller!.text, '12.50');
      await tester.runAsync(
        () => persistence.database.customStatement(
          'DROP TRIGGER fail_confirmation',
        ),
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await waitForNativeSave(
        tester,
        () => find.byType(ExpenseEditorScreen).evaluate().isEmpty,
      );
      expect(controller.records.single.vendor, 'Partial supplier');
      expect(controller.records.single.amount, 12.5);
      await tester.runAsync(() async {
        expect(
          await persistence.drafts.list(
            organizationId: expenseUiLabOrganizationId,
            domain: 'expenses/manual-entry',
            ownerId: 'alex',
          ),
          isEmpty,
        );
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      controller.dispose();
      scope.dispose();
      await tester.runAsync(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      expect(tester.takeException(), isNull);
    },
  );
}
