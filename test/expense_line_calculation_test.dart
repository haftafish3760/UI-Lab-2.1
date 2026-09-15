import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_line_calculation.dart';

void main() {
  test('grouped quantities and prices calculate the full purchase', () {
    expect(
      calculateExpenseLineTotal(
        quantity: '1,000',
        unitPrice: '15.00',
      )!.minorUnits,
      1500000,
    );
    expect(
      calculateExpenseLineTotal(
        quantity: '2.5',
        unitPrice: '1,234.56',
      )!.minorUnits,
      308640,
    );
  });
  test('decimal multiplication rounds half cents once without binary loss', () {
    expect(
      calculateExpenseLineTotal(
        quantity: '1.005',
        unitPrice: '1.00',
      )!.minorUnits,
      101,
    );
    expect(
      calculateExpenseLineTotal(
        quantity: '1.004999',
        unitPrice: '1.00',
      )!.minorUnits,
      100,
    );
    expect(
      calculateExpenseLineTotal(
        quantity: '0.005',
        unitPrice: '1.00',
      )!.minorUnits,
      1,
    );
    expect(
      calculateExpenseLineTotal(
        quantity: '1.234567',
        unitPrice: '15.00',
      )!.minorUnits,
      1852,
    );
  });
  test('invalid or oversized inputs never become a zero-priced purchase', () {
    for (final quantity in [
      '',
      '1,00',
      '-1',
      'NaN',
      'Infinity',
      '1.0000001',
      '100000000000',
    ]) {
      expect(
        calculateExpenseLineTotal(quantity: quantity, unitPrice: '15.00'),
        isNull,
      );
    }
    for (final price in ['', '1,00', '-1', 'NaN', '3.4990001']) {
      expect(
        calculateExpenseLineTotal(quantity: '2', unitPrice: price),
        isNull,
      );
    }
  });
}
