/// Converts explicit miles to integer tenths without rounding or floating point.
/// A trailing decimal point is accepted only where the existing workday workflow
/// already permits explicit confirmation of a whole-mile reading (for example
/// `12,345.`). Raw drafts are never normalized by this conversion.
int parseExactOdometerMiles(
  String raw, {
  bool allowTrailingDecimalPoint = false,
}) {
  final text = raw.trim();
  final syntax = allowTrailingDecimalPoint
      ? RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d?)?$')
      : RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d)?$');
  if (!syntax.hasMatch(text)) {
    throw const FormatException(
      'Enter miles with no more than one decimal place.',
    );
  }
  final parts = text.replaceAll(',', '').split('.');
  final fraction = parts.length == 1 || parts.last.isEmpty ? '0' : parts.last;
  final exact =
      BigInt.parse(parts.first) * BigInt.from(10) + BigInt.parse(fraction);
  if (exact > BigInt.from(99999990)) {
    throw const FormatException(
      'Enter an odometer reading no greater than 9,999,999 miles.',
    );
  }
  return exact.toInt();
}

int? tryParseWorkdayOdometerMiles(String raw) {
  try {
    return parseExactOdometerMiles(raw, allowTrailingDecimalPoint: true);
  } on FormatException {
    return null;
  }
}
