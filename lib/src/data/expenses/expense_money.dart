import 'package:flutter/foundation.dart';

@immutable
class ExpenseMoney {
  const ExpenseMoney({required this.minorUnits, this.currencyCode = 'USD'});

  factory ExpenseMoney.fromDecimalString(
    String value, {
    String currencyCode = 'USD',
  }) {
    final normalized = value.trim();
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalized);
    if (match == null) {
      throw const FormatException(
        'Money must be a positive amount with no more than two decimals.',
      );
    }
    final whole = int.parse(match.group(1)!);
    final decimal = (match.group(2) ?? '').padRight(2, '0');
    return ExpenseMoney(
      minorUnits: whole * 100 + int.parse(decimal.isEmpty ? '0' : decimal),
      currencyCode: currencyCode,
    );
  }

  final int minorUnits;
  final String currencyCode;

  String get decimalValue {
    final whole = minorUnits ~/ 100;
    final decimal = (minorUnits % 100).abs().toString().padLeft(2, '0');
    return '$whole.$decimal';
  }

  Map<String, Object> toJson() => {
    'minorUnits': minorUnits,
    'currencyCode': currencyCode,
  };

  factory ExpenseMoney.fromJson(Map<String, Object?> json) => ExpenseMoney(
    minorUnits: _requiredInt(json, 'minorUnits'),
    currencyCode: _requiredString(json, 'currencyCode'),
  );

  @override
  bool operator ==(Object other) =>
      other is ExpenseMoney &&
      minorUnits == other.minorUnits &&
      currencyCode == other.currencyCode;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Missing or invalid $key.');
  return value;
}
