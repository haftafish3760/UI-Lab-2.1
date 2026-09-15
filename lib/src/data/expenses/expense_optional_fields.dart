import 'expense_money.dart';

ExpenseMoney? readExpenseTotal(Map<String, Object?> json) {
  if (!json.containsKey('total')) throw const FormatException('Missing total.');
  final value = json['total'];
  if (value == null) return null;
  if (value is! Map) throw const FormatException('Invalid total.');
  return ExpenseMoney.fromJson(value.cast<String, Object?>());
}

/// A missing category is a deliberate null pair, never an inferred category.
void validateOptionalExpenseCategory(String? id, String? label) {
  if ((id == null) != (label == null) ||
      (id != null && id.trim().isEmpty) ||
      (label != null && label.trim().isEmpty)) {
    throw const FormatException(
      'Category identity and label must be set or cleared together.',
    );
  }
}

String? readOptionalExpenseCategory(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) throw FormatException('Missing $key.');
  final value = json[key];
  if (value != null && (value is! String || value.trim().isEmpty)) {
    throw FormatException('Invalid $key.');
  }
  return value as String?;
}

/// Blank merchant names are allowed; a damaged/missing field is not a blank.
String readExpenseMerchant(Map<String, Object?> json) {
  final value = json['vendorName'];
  if (value is! String) {
    throw const FormatException('Missing or invalid vendorName.');
  }
  return value;
}
