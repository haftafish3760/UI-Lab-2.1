import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/shell/app_shell.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('Dashboard expense commits once through the editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('dashboard-expense-save-'),
    ))!;
    final persistence = (await tester.runAsync(
      () => LocalPersistence.open(directory: directory),
    ))!;
    await tester.pumpWidget(
      UiLabApp(
        expenseRepository: persistence.expenses,
        draftStore: persistence.drafts,
      ),
    );
    await tester.pumpAndSettle();
    final controller = ExpenseUiScope.maybeOf(
      tester.element(find.byType(AppShell)),
    )!;
    await waitForNativeSave(
      tester,
      () => controller.phase == ExpenseRepositoryControllerPhase.ready,
    );
    await tester.tap(find.byKey(const ValueKey('dashboard-add-button')));
    await tester.pumpAndSettle();
    final add = find.text('Record Expense');
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    final vendor = find.byKey(const ValueKey('expense-vendor-field'));
    await waitForNativeSave(tester, () => vendor.evaluate().isNotEmpty);
    await tester.enterText(vendor, 'Dashboard supplier');
    final amount = find.byKey(const ValueKey('expense-amount-field'));
    await tester.ensureVisible(amount);
    await tester.enterText(amount, '7.50');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('save-expense-button'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await waitForNativeSave(
      tester,
      () => find.byType(ExpenseEditorScreen).evaluate().isEmpty,
    );
    expect(controller.records.single.vendor, 'Dashboard supplier');
    expect(controller.failure, isNull);
    expect(controller.revisionForId(controller.records.single.id), 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await persistence.close();
      await directory.delete(recursive: true);
    });
    expect(tester.takeException(), isNull);
  });
}
