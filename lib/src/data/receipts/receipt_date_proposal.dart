/// Calendar dates only. Do not infer a locale from a merchant or currency.
({DateTime? date, List<String> warnings}) proposeReceiptDate(
  List<String> rows,
) {
  final dates = <DateTime>{};
  var ambiguous = false;
  final pattern = RegExp(r'(?<!\d)(\d{1,4})[-/](\d{1,2})[-/](\d{1,4})(?!\d)');
  for (final row in rows) {
    for (final match in pattern.allMatches(row)) {
      final a = int.parse(match.group(1)!);
      final b = int.parse(match.group(2)!);
      final c = int.parse(match.group(3)!);
      int year, month, day;
      if (match.group(1)!.length == 4) {
        year = a;
        month = b;
        day = c;
      } else if (match.group(3)!.length == 4) {
        year = c;
        if (a > 12 && b <= 12) {
          day = a;
          month = b;
        } else if (b > 12 && a <= 12) {
          month = a;
          day = b;
        } else if (a == b && a >= 1 && a <= 12) {
          month = a;
          day = b;
        } else {
          ambiguous = true;
          continue;
        }
      } else {
        // Two-digit years need a declared date convention and century policy.
        ambiguous = true;
        continue;
      }
      if (year < 1900 ||
          year > 2199 ||
          month < 1 ||
          month > 12 ||
          day < 1 ||
          day > 31) {
        continue;
      }
      final date = DateTime(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        dates.add(date);
      }
    }
  }
  final warnings = <String>[
    if (ambiguous) 'The printed date format needs your review.',
    if (dates.length > 1)
      'More than one date was found. Choose the purchase date.',
  ];
  return (
    date: !ambiguous && dates.length == 1 ? dates.single : null,
    warnings: warnings,
  );
}
