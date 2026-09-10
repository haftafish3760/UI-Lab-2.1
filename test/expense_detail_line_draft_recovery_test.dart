import 'dart:io';
import 'package:ui_lab_2_1/src/screens/expenses/expense_line_item_editor.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record_adapter.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart'
    show ExpenseAuditAction;
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_detail_screen.dart';
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
    'direct receipt-line edit recovers through the audited parent draft',
    (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('expense-editor-recovery-'),
      ))!;
      var persistence = (await tester.runAsync(
        () => LocalPersistence.open(directory: directory),
      ))!;
      await tester.runAsync(
        () => persistence.expenses.create(
          ExpenseRecordAdapter.fromUiRecord(
            record: ExpenseRecord(
              id: 'receipt-edit',
              vendor: 'Supplier',
              category: ExpenseCategory.office,
              amount: 10,
              receiptType: ExpenseReceiptType.detailed,
              receiptSubtotal: 10,
              lineItems: const [
                ExpenseLineItem(
                  id: 'original-line',
                  description: 'Copper fitting',
                  category: ExpenseCategory.materials,
                  quantity: 2,
                  unit: 'each',
                  unitPrice: 5,
                  partNumber: 'CF-10',
                  jobId: 'job-test',
                  jobLabel: 'Service job',
                ),
              ],
              date: DateTime(2030, 1, 2),
              owner: 'Alex Morgan',
              paidByEmployeeId: 'alex',
            ),
            organizationId: expenseUiLabOrganizationId,
            createdByEmployeeId: 'alex',
            paidByEmployeeId: 'alex',
            nowUtc: DateTime.utc(2030, 1, 2),
            receiptId: 'retained-receipt-test',
          ),
          context: ExpenseMutationContext(
            actorEmployeeId: 'alex',
            occurredAtUtc: DateTime.utc(2030, 1, 2),
            permissionRevision: 'test',
          ),
        ),
      );
      late PrototypeOperationsStore operations;
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
        operations = PrototypeOperationsStore()
          ..bindAuthorizedExpenseController(controller);
        await tester.pumpWidget(
          LocalDraftScope(
            store: persistence.drafts,
            child: ExpenseUiScope(
              controller: controller,
              child: OperationalScope(
                controller: scope,
                child: MaterialApp(
                  builder: (context, child) => PrototypeOperationsScope(
                    store: operations,
                    child: child!,
                  ),
                  theme: AppTheme.light,
                  home: Builder(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ExpenseDetailScreen(
                              expenseId: 'receipt-edit',
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
        await tester.pumpAndSettle();
        final item = find.byKey(const ValueKey('expense-line-original-line'));
        await tester.ensureVisible(item);
        await tester.pumpAndSettle();
        await tester.tap(item);
        await tester.pump();
      }

      final description = find.byKey(
        const ValueKey('expense-line-description'),
      );
      final quantity = find.byKey(const ValueKey('expense-line-quantity'));
      final vendor = find.byKey(const ValueKey('expense-vendor-field'));
      await mount();
      await waitForNativeSave(tester, () => description.evaluate().isNotEmpty);
      await tester.ensureVisible(quantity);
      await tester.pumpAndSettle();
      await tester.enterText(quantity, '');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(description)).pop();
      await waitForNativeSave(
        tester,
        () => find.byType(ExpenseLineItemEditorScreen).evaluate().isEmpty,
      );
      expect(controller.records.single.lineItems.single.quantity, 2);
      Navigator.of(tester.element(vendor)).pop();
      await waitForNativeSave(
        tester,
        () => find.byType(ExpenseEditorScreen).evaluate().isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      operations.dispose();
      controller.dispose();
      await tester.runAsync(() async {
        await persistence.close();
        persistence = await LocalPersistence.open(directory: directory);
      });
      await mount();
      await waitForNativeSave(tester, () => description.evaluate().isNotEmpty);
      expect(tester.widget<TextFormField>(quantity).controller!.text, '');
      expect(
        tester.widget<TextFormField>(description).controller!.text,
        'Copper fitting',
      );
      await tester.ensureVisible(quantity);
      await tester.pumpAndSettle();
      await tester.enterText(quantity, '3');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-expense-line-item')));
      await waitForNativeSave(
        tester,
        () => find.byType(ExpenseLineItemEditorScreen).evaluate().isEmpty,
      );
      expect(controller.revisionForId('receipt-edit'), 1);
      final reason = find.byKey(
        const ValueKey('expense-editor-correction-reason'),
      );
      await tester.ensureVisible(reason);
      await tester.pumpAndSettle();
      await tester.enterText(reason, 'Corrected quantity from receipt');
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
      final record = controller.records.single;
      expect(record.amount, 15);
      expect(record.lineItems.single.id, 'original-line');
      expect(record.lineItems.single.quantity, 3);
      expect(record.lineItems.single.partNumber, 'CF-10');
      expect(record.lineItems.single.jobId, 'job-test');
      expect(controller.revisionForId(record.id), 2);
      await tester.runAsync(() async {
        final stored = (await persistence.expenses.query(
          ExpenseQuery(access: expenseUiLabOwnerPermissions().readAccess!),
        )).single;
        expect(stored.auditTrail.last.action, ExpenseAuditAction.corrected);
        expect(stored.auditTrail.last.note, 'Corrected quantity from receipt');
        expect(stored.priorVersions, hasLength(1));
        expect(
          await persistence.drafts.list(
            organizationId: expenseUiLabOrganizationId,
            domain: 'expenses/edit-entry',
            ownerId: 'alex',
          ),
          isEmpty,
        );
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      operations.dispose();
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
