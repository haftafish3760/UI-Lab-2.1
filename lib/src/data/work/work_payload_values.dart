/// Existing Work models still expose doubles. Preserve their exact decimal
/// representation during persistence instead of introducing another rounding
/// step. Domain arithmetic and currency ownership are separate migration work.
String encodeWorkDecimal(double value) {
  if (!value.isFinite) throw const FormatException('Non-finite Work value.');
  return value.toString();
}

double decodeWorkDecimal(Object? value) {
  if (value is! String) throw const FormatException('Expected decimal text.');
  final parsed = double.tryParse(value);
  if (parsed == null || !parsed.isFinite) {
    throw const FormatException('Invalid Work decimal value.');
  }
  return parsed;
}
