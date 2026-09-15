import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record_adapter.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_editor_record_codec.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_line_item_editor.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_submission_coordinator.dart';

ExpenseLineItem box({double? contents, double quantity = 2}) => ExpenseLineItem(
  id: 'line',
  description: 'Coupling box',
  category: ExpenseCategory.materials,
  quantity: quantity,
  unit: 'box',
  unitPrice: 15,
  unitsPerPackage: contents,
);

void main() {
  test('receipt retries distinguish unknown box contents from one piece', () {
    ExpenseRecord record(ExpenseLineItem line) => ExpenseRecord(
      id: 'record',
      vendor: 'Supply counter',
      category: ExpenseCategory.materials,
      amount: 30,
      date: DateTime(2030, 1, 2),
      owner: 'Alex',
      paidByEmployeeId: 'alex',
      receiptType: ExpenseReceiptType.detailed,
      lineItems: [line],
      receiptSubtotal: 30,
      salesTax: 0,
    );
    expect(
      receiptSubmissionMatches(record(box()), record(box(contents: 1))),
      isFalse,
    );
    // Legacy each-unit UI defaults were never package facts in stored records.
    expect(
      receiptSubmissionMatches(
        record(box().copyWith(unit: 'each')),
        record(box(contents: 1).copyWith(unit: 'each')),
      ),
      isTrue,
    );
  });
  test(
    'unknown and explicitly known package contents survive SQLite reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'package-contents-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      for (final contents in <double?>[null, 1, 10]) {
        final record = ExpenseRecord(
          id: 'expense-$contents',
          vendor: 'Supply counter',
          category: ExpenseCategory.materials,
          amount: 30,
          date: DateTime(2030, 1, 2),
          owner: 'Alex',
          paidByEmployeeId: 'alex',
          receiptType: ExpenseReceiptType.detailed,
          lineItems: [box(contents: contents)],
          receiptSubtotal: 30,
          salesTax: 0,
        );
        final stored = ExpenseRecordAdapter.fromUiRecord(
          record: record,
          organizationId: expenseUiLabOrganizationId,
          createdByEmployeeId: 'alex',
          paidByEmployeeId: 'alex',
          nowUtc: DateTime.utc(2030, 1, 2),
        );
        final line = stored.itemization.lineItems.single;
        expect(line.packagesPurchased.decimalValue, '2');
        expect(line.extendedTotal.minorUnits, 3000);
        expect(line.containedUnitCode, contents == null ? null : 'each');
        await persistence.expenses.create(
          stored,
          context: ExpenseMutationContext(
            actorEmployeeId: 'alex',
            occurredAtUtc: DateTime.utc(2030, 1, 2),
            permissionRevision: 'test',
          ),
        );
      }
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      for (final contents in <double?>[null, 1, 10]) {
        final stored = (await persistence.expenses.findById(
          expenseId: 'expense-$contents',
          access: ExpenseAccess.company(
            organizationId: expenseUiLabOrganizationId,
            employeeId: 'alex',
          ),
        ))!;
        final restored = ExpenseRecordAdapter.toUiRecord(
          record: stored,
          ownerDisplayName: 'Alex',
        );
        expect(restored.lineItems.single.unitsPerPackage, contents);
        expect(restored.lineItems.single.total, 30);
      }
    },
  );

  test(
    'draft codec can clear contents without inventing a count or losing precision',
    () {
      final initial = box(contents: 10, quantity: 1.234567);
      final cleared = initial.copyWith(unitsPerPackage: null);
      final decoded = decodeExpenseEditorLine(encodeExpenseEditorLine(cleared));
      expect(decoded.quantity, 1.234567);
      expect(decoded.unitsPerPackage, isNull);
      expect(initial.copyWith().unitsPerPackage, 10);
      expect(cleared.copyWith(unitsPerPackage: 1).unitsPerPackage, 1);
      final damaged = encodeExpenseEditorLine(cleared)
        ..remove('unitsPerPackage');
      expect(() => decodeExpenseEditorLine(damaged), throwsFormatException);
    },
  );

  for (final contents in <double?>[null, 10]) {
    testWidgets(
      'box contents can remain unknown or be cleared from $contents',
      (tester) async {
        await tester.binding.setSurfaceSize(
          Size(contents == null ? 320 : 1400, 844),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));
        ExpenseLineItem? saved;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(contents == null ? 2 : 1),
              ),
              child: child!,
            ),
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    saved = await showExpenseLineItemEditor(
                      context,
                      initial: box(contents: contents, quantity: 1.234567),
                      defaultCategory: ExpenseCategory.materials,
                    );
                  },
                  child: const Text('Open item'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open item'));
        await tester.pumpAndSettle();
        final quantity = tester.widget<TextFormField>(
          find.byKey(const ValueKey('expense-line-quantity')),
        );
        expect(quantity.controller!.text, '1.234567');
        final field = find.byKey(
          const ValueKey('expense-line-units-per-package'),
        );
        expect(
          tester.widget<TextFormField>(field).controller!.text,
          contents == null ? '' : '10',
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, '');
        await tester.pumpAndSettle();
        expect(find.textContaining('items total'), findsNothing);
        await tester.tap(find.text('Save').first);
        await tester.pumpAndSettle();
        expect(saved, isNotNull);
        expect(saved!.unitsPerPackage, isNull);
        expect(saved!.quantity, 1.234567);
        expect(saved!.confirmedLineTotal, 18.52);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('grouped quantity saves the displayed amount', (tester) async {
    ExpenseLineItem? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await showExpenseLineItemEditor(
                  context,
                  initial: box(),
                  defaultCategory: ExpenseCategory.materials,
                );
              },
              child: const Text('Open item'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open item'));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('expense-line-quantity'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '1,000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();
    expect(saved!.quantity, 1000);
    expect(saved!.confirmedLineTotal, 15000);
    expect(saved!.unitsPerPackage, isNull);
    expect(tester.takeException(), isNull);
  });
}
