import 'package:flutter/foundation.dart';

@immutable
class ExpenseDecimalValue {
  ExpenseDecimalValue({required this.unscaledValue, required this.scale}) {
    if (scale < 0 || scale > 6) {
      throw ArgumentError.value(scale, 'scale', 'Must be between 0 and 6.');
    }
    if (unscaledValue < 0) {
      throw ArgumentError.value(
        unscaledValue,
        'unscaledValue',
        'Cannot be negative.',
      );
    }
    if (scale > 0 && unscaledValue % 10 == 0) {
      throw const FormatException('Quantity decimals must be normalized.');
    }
  }

  factory ExpenseDecimalValue.fromDecimalString(String value) {
    final normalized = value.trim();
    final match = RegExp(r'^(\d+)(?:\.(\d{1,6}))?$').firstMatch(normalized);
    if (match == null) {
      throw const FormatException(
        'Quantity must be positive with no more than six decimals.',
      );
    }
    var fraction = match.group(2) ?? '';
    while (fraction.endsWith('0')) {
      fraction = fraction.substring(0, fraction.length - 1);
    }
    final scale = fraction.length;
    final unscaled = BigInt.parse('${match.group(1)!}$fraction');
    if (unscaled > BigInt.parse('9223372036854775807')) {
      throw const FormatException(
        'Decimal exceeds the supported integer range.',
      );
    }
    return ExpenseDecimalValue(unscaledValue: unscaled.toInt(), scale: scale);
  }

  final int unscaledValue;
  final int scale;

  bool get isZero => unscaledValue == 0;

  String get decimalValue {
    if (scale == 0) return unscaledValue.toString();
    final digits = unscaledValue.toString().padLeft(scale + 1, '0');
    final split = digits.length - scale;
    return '${digits.substring(0, split)}.${digits.substring(split)}';
  }

  Map<String, Object> toJson() => {
    'unscaledValue': unscaledValue,
    'scale': scale,
  };

  factory ExpenseDecimalValue.fromJson(Map<String, Object?> json) =>
      ExpenseDecimalValue(
        unscaledValue: _requiredInt(json, 'unscaledValue'),
        scale: _requiredInt(json, 'scale'),
      );

  @override
  bool operator ==(Object other) =>
      other is ExpenseDecimalValue &&
      unscaledValue == other.unscaledValue &&
      scale == other.scale;

  @override
  int get hashCode => Object.hash(unscaledValue, scale);
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Missing or invalid $key.');
  return value;
}
