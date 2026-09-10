final _moneyPattern = RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d{1,2})?$');
final _quantityPattern = RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d{1,6})?$');

String? validateRequiredExpenseMoney(String? value) {
  final normalized = (value ?? '').trim();
  if (!_moneyPattern.hasMatch(normalized)) {
    return 'Enter dollars and cents, with no more than 2 decimal places.';
  }
  final parsed = double.tryParse(normalized.replaceAll(',', ''));
  return parsed == null || !parsed.isFinite || parsed <= 0
      ? 'Enter an amount above zero.'
      : null;
}

String? validateOptionalExpenseMoney(String? value) {
  final normalized = (value ?? '').trim();
  if (normalized.isEmpty) return null;
  if (!_moneyPattern.hasMatch(normalized)) {
    return 'Use no more than 2 decimal places.';
  }
  final parsed = double.tryParse(normalized.replaceAll(',', ''));
  return parsed == null || !parsed.isFinite ? 'Enter a valid amount.' : null;
}

String? validateRequiredExpenseQuantity(String? value) {
  final normalized = (value ?? '').trim();
  if (!_quantityPattern.hasMatch(normalized)) {
    return 'Use a number with no more than 6 decimal places.';
  }
  final parsed = double.tryParse(normalized.replaceAll(',', ''));
  return parsed == null || !parsed.isFinite || parsed <= 0
      ? 'Enter a value above zero.'
      : null;
}
