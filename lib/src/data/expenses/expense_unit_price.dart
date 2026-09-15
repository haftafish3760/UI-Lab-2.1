import 'package:flutter/foundation.dart';
import 'expense_decimal_value.dart';
import 'expense_money.dart';

/// A price per purchased unit may include fractions of a currency minor unit.
/// Only the final charged line amount is rounded to cents.
@immutable
class ExpenseUnitPrice {
  ExpenseUnitPrice({required this.value, this.currencyCode = 'USD'}) {
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currencyCode)) {
      throw const FormatException('Invalid unit-price currency.');
    }
  }

  factory ExpenseUnitPrice.fromDecimalString(
    String text, {
    String currencyCode = 'USD',
  }) => ExpenseUnitPrice(
    value: ExpenseDecimalValue.fromDecimalString(text),
    currencyCode: currencyCode,
  );

  final ExpenseDecimalValue value;
  final String currencyCode;
  String get decimalValue => value.decimalValue;

  Map<String, Object> toJson() {
    // Preserve the existing representation for representable cents-only
    // records. A valid decimal must never overflow while being serialized.
    if (value.scale <= 2) {
      final minor =
          BigInt.from(value.unscaledValue) *
          BigInt.from(10).pow(2 - value.scale);
      if (minor <= BigInt.parse('9223372036854775807')) {
        return ExpenseMoney(
          minorUnits: minor.toInt(),
          currencyCode: currencyCode,
        ).toJson();
      }
    }
    return {'decimalValue': decimalValue, 'currencyCode': currencyCode};
  }

  factory ExpenseUnitPrice.fromJson(Map<String, Object?> json) {
    if (json.containsKey('decimalValue')) {
      if (json.containsKey('minorUnits') ||
          json['decimalValue'] is! String ||
          json['currencyCode'] is! String) {
        throw const FormatException('Invalid decimal unit-price record.');
      }
      return ExpenseUnitPrice.fromDecimalString(
        json['decimalValue'] as String,
        currencyCode: json['currencyCode'] as String,
      );
    }
    final legacy = ExpenseMoney.fromJson(json);
    if (legacy.minorUnits < 0) {
      throw const FormatException('Unit price cannot be negative.');
    }
    return ExpenseUnitPrice.fromDecimalString(
      legacy.decimalValue,
      currencyCode: legacy.currencyCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExpenseUnitPrice &&
      value == other.value &&
      currencyCode == other.currencyCode;

  @override
  int get hashCode => Object.hash(value, currencyCode);
}
