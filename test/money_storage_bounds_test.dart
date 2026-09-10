import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_money.dart';

void main() {
  test(
    'decimal parsing is exact and refuses precision loss or integer overflow',
    () {
      expect(ExpenseMoney.fromDecimalString('0.29').minorUnits, 29);
      expect(
        ExpenseMoney.fromDecimalString('92233720368547758.07').minorUnits,
        9223372036854775807,
      );
      for (final input in [
        '92233720368547758.08',
        '999999999999999999999999999.99',
        '0.001',
        'NaN',
        'Infinity',
      ]) {
        expect(
          () => ExpenseMoney.fromDecimalString(input),
          throwsFormatException,
          reason: input,
        );
      }
    },
  );
}
