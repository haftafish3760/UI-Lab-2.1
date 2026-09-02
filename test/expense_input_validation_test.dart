import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_input_validation.dart';

void main() {
  test('required money accepts cents and valid grouping', () {
    expect(validateRequiredExpenseMoney('48.72'), isNull);
    expect(validateRequiredExpenseMoney('1,234.50'), isNull);
    expect(validateRequiredExpenseMoney('10'), isNull);
  });

  test('required money rejects rounding and malformed grouping', () {
    expect(validateRequiredExpenseMoney('10.999'), isNotNull);
    expect(validateRequiredExpenseMoney('1,2,3.00'), isNotNull);
    expect(validateRequiredExpenseMoney('0.00'), isNotNull);
  });

  test('optional money permits blank and zero but not excess precision', () {
    expect(validateOptionalExpenseMoney(''), isNull);
    expect(validateOptionalExpenseMoney('0.00'), isNull);
    expect(validateOptionalExpenseMoney('1.001'), isNotNull);
  });

  test('quantity allows six decimals without silently rounding', () {
    expect(validateRequiredExpenseQuantity('0.125'), isNull);
    expect(validateRequiredExpenseQuantity('1,000.000001'), isNull);
    expect(validateRequiredExpenseQuantity('1.0000001'), isNotNull);
    expect(validateRequiredExpenseQuantity('-1'), isNotNull);
  });
}
