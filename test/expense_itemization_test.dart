import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_expense_repository.dart';

void main() {
  group('ExpenseDecimalValue', () {
    test('normalizes and round-trips exact quantities', () {
      final quantity = ExpenseDecimalValue.fromDecimalString('002.500000');

      expect(quantity.unscaledValue, 25);
      expect(quantity.scale, 1);
      expect(quantity.decimalValue, '2.5');
      expect(ExpenseDecimalValue.fromJson(quantity.toJson()), quantity);
    });

    test('rejects ambiguous or excessive precision', () {
      expect(
        () => ExpenseDecimalValue.fromDecimalString('-1'),
        throwsFormatException,
      );
      expect(
        () => ExpenseDecimalValue.fromDecimalString('1.1234567'),
        throwsFormatException,
      );
      expect(
        () => ExpenseDecimalValue.fromJson({'unscaledValue': 250, 'scale': 2}),
        throwsFormatException,
      );
    });
  });

  test(
    'itemized Expense survives restart with package facts and exact money',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'ui-lab-expense-itemization-',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final repository = await FileExpenseRepository.open(directory);
      final original = _itemizedRecord();

      final created = await repository.create(original, context: _mutation());
      final reopened = await FileExpenseRepository.open(directory);
      final restored = await reopened.findById(
        expenseId: original.expenseId,
        access: ExpenseAccess.company(
          organizationId: 'company-1',
          employeeId: 'owner',
        ),
      );

      expect(restored, isNotNull);
      expect(restored!.toJson(), created.toJson());
      expect(restored.itemization.mode, ExpenseItemizationMode.itemized);
      expect(restored.itemization.lineItems.single.lineItemId, 'line-1');
      expect(
        restored.itemization.lineItems.single.packagesPurchased.decimalValue,
        '2',
      );
      expect(
        restored
            .itemization
            .lineItems
            .single
            .containedQuantityPerPackage!
            .decimalValue,
        '10',
      );
      expect(restored.itemization.subtotal!.minorUnits, 3000);
      expect(restored.itemization.salesTax.minorUnits, 210);
      expect(restored.total.minorUnits, 3210);
    },
  );

  test('itemization keeps reconciliation differences visible', () {
    final itemization = ExpenseItemization(
      mode: ExpenseItemizationMode.itemized,
      lineItems: [_line(extendedTotal: '29.00')],
      subtotal: ExpenseMoney.fromDecimalString('30.00'),
      salesTax: ExpenseMoney.fromDecimalString('2.10'),
    );
    final record = _recordWith(itemization);

    expect(record.itemization.reviewedLineTotalMinorUnits, 2900);
    expect(record.itemization.lineToSubtotalDifferenceMinorUnits, 100);
  });

  test('duplicate stable line identities are rejected', () {
    expect(
      () => _recordWith(
        ExpenseItemization(
          mode: ExpenseItemizationMode.itemized,
          lineItems: [_line(), _line()],
        ),
      ),
      throwsFormatException,
    );
  });

  test('repository record takes an immutable itemization snapshot', () {
    final lines = [_line()];
    final record = _recordWith(
      ExpenseItemization(
        mode: ExpenseItemizationMode.itemized,
        lineItems: lines,
      ),
    );

    lines.clear();

    expect(record.itemization.lineItems, hasLength(1));
    expect(() => record.itemization.lineItems.clear(), throwsUnsupportedError);
  });
}

StoredExpenseRecord _itemizedRecord() => _recordWith(
  ExpenseItemization(
    mode: ExpenseItemizationMode.itemized,
    lineItems: [_line()],
    subtotal: ExpenseMoney.fromDecimalString('30.00'),
    salesTax: ExpenseMoney.fromDecimalString('2.10'),
  ),
);

StoredExpenseRecord _recordWith(ExpenseItemization itemization) {
  final timestamp = DateTime.utc(2026, 9, 1, 12);
  return StoredExpenseRecord(
    expenseId: 'expense-itemized-1',
    organizationId: 'company-1',
    createdByEmployeeId: 'alex',
    paidByEmployeeId: 'alex',
    expenseDate: DateTime(2026, 9, 1),
    vendorName: 'Supply House',
    categoryId: 'materials',
    categoryLabelSnapshot: 'Materials',
    total: ExpenseMoney.fromDecimalString('32.10'),
    approval: const ExpenseApproval.notRequired(),
    lifecycle: ExpenseLifecycle(
      revision: 1,
      createdAtUtc: timestamp,
      updatedAtUtc: timestamp,
    ),
    itemization: itemization,
  );
}

StoredExpenseLineItem _line({String extendedTotal = '30.00'}) =>
    StoredExpenseLineItem(
      lineItemId: 'line-1',
      description: 'PEX-A coupling box',
      categoryId: 'materials',
      categoryLabelSnapshot: 'Materials',
      packagesPurchased: ExpenseDecimalValue.fromDecimalString('2'),
      packageStyleCode: 'box',
      pricePerPackage: ExpenseMoney.fromDecimalString('15.00'),
      extendedTotal: ExpenseMoney.fromDecimalString(extendedTotal),
      containedQuantityPerPackage: ExpenseDecimalValue.fromDecimalString('10'),
      containedUnitCode: 'each',
      partNumber: 'UC008LFZ',
      jobId: 'job-1',
      jobLabelSnapshot: 'JOB-1 · Repair',
    );

ExpenseMutationContext _mutation() => ExpenseMutationContext(
  actorEmployeeId: 'alex',
  occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
  permissionRevision: 'permissions-v1',
);
