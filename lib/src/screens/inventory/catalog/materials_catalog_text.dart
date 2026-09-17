/// Display correction only: original source labels remain intact for auditing.
String materialsAngleLabel(String value) => value.replaceAllMapped(
  RegExp(r'\b(90|45|22\.5|11\.25)(?= Elbows?\b)'),
  (match) => '${match[1]}°',
);

/// Sorts measurement sequences numerically without rearranging connection ends.
int compareMaterialsSizes(String a, String b) {
  final number = RegExp(r'\d+(?:-\d+/\d+|/\d+|\.\d+)?|[^\d]+');
  final left = number.allMatches(a).map((m) => m[0]!).toList();
  final right = number.allMatches(b).map((m) => m[0]!).toList();
  for (var i = 0; i < left.length && i < right.length; i++) {
    final x = _fraction(left[i]);
    final y = _fraction(right[i]);
    final compared = x != null && y != null
        ? x.compareTo(y)
        : left[i].toLowerCase().compareTo(right[i].toLowerCase());
    if (compared != 0) return compared;
  }
  return left.length.compareTo(right.length);
}

double? _fraction(String value) {
  final mixed = value.split('-');
  if (mixed.length == 2) {
    final whole = double.tryParse(mixed.first);
    final fraction = _fraction(mixed.last);
    return whole == null || fraction == null ? null : whole + fraction;
  }
  final parts = value.split('/');
  if (parts.length == 2) {
    final numerator = double.tryParse(parts.first);
    final denominator = double.tryParse(parts.last);
    return numerator == null || denominator == null || denominator == 0
        ? null
        : numerator / denominator;
  }
  return double.tryParse(value);
}
