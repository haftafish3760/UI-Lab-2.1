import 'expense_input_validation.dart';
import 'expense_money.dart';
import 'expense_decimal_value.dart';
import 'expense_unit_price.dart';

/// Calculates a reviewed line from the user's decimal text, rounding only the
/// extended amount to cents. A missing, invalid or oversized result is unknown.
ExpenseMoney? calculateExpenseLineTotal({
  required String quantity,
  required String unitPrice,
}) {
  if (validateRequiredExpenseQuantity(quantity) != null ||
      validateRequiredExpenseUnitPrice(unitPrice) != null) {
    return null;
  }
  try {
    final units = ExpenseDecimalValue.fromDecimalString(
      quantity.trim().replaceAll(',', ''),
    );
    final price = ExpenseUnitPrice.fromDecimalString(
      unitPrice.trim().replaceAll(',', ''),
    ).value;
    final divisor = BigInt.from(10).pow(units.scale + price.scale);
    final product =
        BigInt.from(units.unscaledValue) *
        BigInt.from(price.unscaledValue) *
        BigInt.from(100);
    final rounded = (product + divisor ~/ BigInt.two) ~/ divisor;
    // Matches the bounded receipt proposal amount range. The UI still carries
    // doubles, so do not admit values beyond its exact cents representation.
    if (rounded > BigInt.from(99999999999)) return null;
    return ExpenseMoney(minorUnits: rounded.toInt());
  } on FormatException {
    return null;
  }
}
