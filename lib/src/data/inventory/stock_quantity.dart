import '../expenses/expense_decimal_value.dart';

/// Exact stock amount with the application's existing six-decimal precision.
/// Negative balances and overflow fail; quantities are never rounded silently.
class StockQuantity {
  StockQuantity._(this.millionths) {
    if (millionths < BigInt.zero || millionths > _maximum) {
      throw const FormatException(
        'Stock quantity is outside the supported range.',
      );
    }
  }

  static final _maximum = BigInt.parse('9223372036854775807');
  final BigInt millionths;

  factory StockQuantity.parse(String input) {
    if (input.length > 40) throw const FormatException('Quantity is too long.');
    final value = ExpenseDecimalValue.fromDecimalString(input);
    return StockQuantity._(
      BigInt.from(value.unscaledValue) * BigInt.from(10).pow(6 - value.scale),
    );
  }

  bool get isZero => millionths == BigInt.zero;
  bool get isWhole => millionths % BigInt.from(1000000) == BigInt.zero;
  StockQuantity operator +(StockQuantity other) =>
      StockQuantity._(millionths + other.millionths);
  StockQuantity operator -(StockQuantity other) =>
      StockQuantity._(millionths - other.millionths);

  String get decimal {
    var fraction = (millionths % BigInt.from(1000000)).toString().padLeft(
      6,
      '0',
    );
    while (fraction.endsWith('0')) {
      fraction = fraction.substring(0, fraction.length - 1);
    }
    final whole = millionths ~/ BigInt.from(1000000);
    return fraction.isEmpty ? '$whole' : '$whole.$fraction';
  }
}
