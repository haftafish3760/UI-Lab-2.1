import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record_adapter.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_line_calculation.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_editor_record_codec.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_submission_coordinator.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';

ExpenseLineItem _fuel(double price, {double? total}) => ExpenseLineItem(
  id: 'fuel-line',
  description: 'Regular unleaded',
  category: ExpenseCategory.fuel,
  quantity: 16.81,
  unit: 'gallon',
  unitPrice: price,
  confirmedLineTotal: total,
);
ExpenseRecord _record(ExpenseLineItem line) => ExpenseRecord(
  id: 'fuel-expense',
  vendor: 'Example fuel counter',
  category: ExpenseCategory.fuel,
  amount: line.total,
  receiptSubtotal: line.total,
  salesTax: 0,
  date: DateTime(2030, 1, 2),
  owner: 'Alex',
  paidByEmployeeId: 'alex',
  receiptType: ExpenseReceiptType.detailed,
  lineItems: [line],
);

void main() {
  test(
    'entry bounds retain six-decimal precision across the UI number bridge',
    () {
      const maximum = '999999999.999999';
      expect(expenseUnitPriceValue(double.parse(maximum)), maximum);
      expect(
        calculateExpenseLineTotal(
          quantity: '0.000001',
          unitPrice: maximum,
        )!.minorUnits,
        100000,
      );
      expect(
        calculateExpenseLineTotal(
          quantity: maximum,
          unitPrice: '0.000001',
        )!.minorUnits,
        100000,
      );
      expect(
        calculateExpenseLineTotal(quantity: '1', unitPrice: '1000000000'),
        isNull,
      );
      expect(
        calculateExpenseLineTotal(quantity: '1000000000', unitPrice: '0'),
        isNull,
      );
    },
  );
  test(
    'legacy cents remain byte-shape compatible and decimal prices stay exact',
    () {
      final old = <String, Object>{'minorUnits': 349, 'currencyCode': 'USD'};
      expect(ExpenseUnitPrice.fromJson(old).toJson(), old);
      for (final text in [
        '3.499',
        '3.499123',
        '0.000001',
        '999999999.999999',
      ]) {
        final value = ExpenseUnitPrice.fromDecimalString(text);
        expect(ExpenseUnitPrice.fromJson(value.toJson()), value);
        expect(value.decimalValue, text);
        expect(value.toJson().containsKey('minorUnits'), isFalse);
      }
      expect(ExpenseUnitPrice.fromDecimalString('3.490000').toJson(), old);
      final large = ExpenseUnitPrice.fromDecimalString('9223372036854775807');
      expect(ExpenseUnitPrice.fromJson(large.toJson()), large);
    },
  );

  test(
    'conflicting representations, malformed decimals and overflow are rejected',
    () {
      for (final json in <Map<String, Object?>>[
        {'decimalValue': '3.499', 'minorUnits': 349, 'currencyCode': 'USD'},
        {'decimalValue': null, 'currencyCode': 'USD'},
        {'decimalValue': '3.4990001', 'currencyCode': 'USD'},
        {'decimalValue': '-1', 'currencyCode': 'USD'},
        {'minorUnits': -1, 'currencyCode': 'USD'},
        {'decimalValue': '3.499', 'currencyCode': ''},
      ]) {
        expect(() => ExpenseUnitPrice.fromJson(json), throwsFormatException);
      }
      expect(
        () => ExpenseDecimalValue.fromDecimalString('9223372036854.775808'),
        throwsFormatException,
      );
      expect(
        ExpenseDecimalValue.fromDecimalString(
          '9223372036854.775807',
        ).unscaledValue,
        9223372036854775807,
      );
    },
  );

  test(
    'fuel extended amounts use all unit-price digits and one final rounding',
    () {
      expect(
        calculateExpenseLineTotal(
          quantity: '16.810',
          unitPrice: '3.499',
        )!.minorUnits,
        5882,
      );
      expect(
        calculateExpenseLineTotal(
          quantity: '16.810',
          unitPrice: '3.491',
        )!.minorUnits,
        5868,
      );
      expect(
        calculateExpenseLineTotal(
          quantity: '16.810',
          unitPrice: '3.49',
        )!.minorUnits,
        5867,
      );
      expect(
        calculateExpenseLineTotal(quantity: '1', unitPrice: '0')!.minorUnits,
        0,
      );
      expect(calculateExpenseLineTotal(quantity: '1', unitPrice: ''), isNull);
      expect(_fuel(3.499).total, 58.82);
      expect(expenseUnitPrice(3.499123), r'$3.499123');
      expect(expenseUnitPrice(3.49), r'$3.49');
      expect(expenseUnitPrice(0), r'$0.00');
    },
  );

  test('same-cent prices cannot pass as an unchanged receipt retry', () {
    final first = _record(_fuel(3.491, total: 58.68));
    final second = _record(_fuel(3.494, total: 58.68));
    expect(receiptSubmissionMatches(first, second), isFalse);
    expect(receiptSubmissionMatches(first, first), isTrue);
    final draft = decodeExpenseEditorLine(
      encodeExpenseEditorLine(_fuel(3.499123)),
    );
    expect(draft.unitPrice, 3.499123);
  });

  test(
    'six-decimal prices and prior revisions survive SQLite close and reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'exact-fuel-price-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      StoredExpenseRecord stored(double price) =>
          ExpenseRecordAdapter.fromUiRecord(
            record: _record(_fuel(price)),
            organizationId: expenseUiLabOrganizationId,
            createdByEmployeeId: 'alex',
            paidByEmployeeId: 'alex',
            nowUtc: DateTime.utc(2030, 1, 2),
          );
      ExpenseMutationContext mutation(int hour) => ExpenseMutationContext(
        actorEmployeeId: 'alex',
        occurredAtUtc: DateTime.utc(2030, 1, 2, hour),
        permissionRevision: 'test',
        note: 'Confirmed price from receipt',
      );
      final created = await persistence.expenses.create(
        stored(3.499123),
        context: mutation(1),
      );
      final correction = stored(3.491);
      await persistence.expenses.update(
        created.copyWith(
          itemization: correction.itemization,
          total: correction.total,
        ),
        expectedRevision: 1,
        context: mutation(2),
        auditAction: ExpenseAuditAction.corrected,
      );
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      final restored = (await persistence.expenses.findById(
        expenseId: created.expenseId,
        access: ExpenseAccess.company(
          organizationId: expenseUiLabOrganizationId,
          employeeId: 'alex',
        ),
      ))!;
      expect(
        restored.itemization.lineItems.single.pricePerPackage.decimalValue,
        '3.491',
      );
      expect(restored.total!.minorUnits, 5868);
      final prior = restored.priorVersions.single;
      expect(
        prior.itemization.lineItems.single.pricePerPackage.decimalValue,
        '3.499123',
      );
      expect(prior.total!.minorUnits, 5882);
      expect(restored.auditTrail.last.actorEmployeeId, 'alex');
      expect(
        ExpenseRecordAdapter.toUiRecord(
          record: restored,
          ownerDisplayName: 'Alex',
        ).lineItems.single.unitPrice,
        3.491,
      );
    },
  );
}
