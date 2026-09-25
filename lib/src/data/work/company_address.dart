/// Structured company address with a lossless fallback for older free-text data.
class CompanyAddress {
  const CompanyAddress({
    this.street = '',
    this.unit = '',
    this.city = '',
    this.state = '',
    this.zip = '',
    this.legacy = '',
  });
  final String street, unit, city, state, zip, legacy;

  factory CompanyAddress.fromMap(Map<String, String> values) => CompanyAddress(
    street: values['street'] ?? '',
    unit: values['unit'] ?? '',
    city: values['city'] ?? '',
    state: values['state'] ?? '',
    zip: values['zip'] ?? '',
    legacy: values['legacy'] ?? '',
  );

  factory CompanyAddress.fromLegacy(String text) {
    if (text.trim().isEmpty) return const CompanyAddress();
    final lines = text.trim().split('\n');
    final match = RegExp(
      r'^(.+),\s*([A-Za-z]{2})\s+(\d{5}(?:-\d{4})?)$',
    ).firstMatch(lines.last.trim());
    if (match == null || lines.length < 2 || lines.length > 3) {
      return CompanyAddress(legacy: text);
    }
    return CompanyAddress(
      street: lines.first,
      unit: lines.length == 3 ? lines[1] : '',
      city: match[1]!,
      state: match[2]!.toUpperCase(),
      zip: match[3]!,
    );
  }

  Map<String, String> toMap() => {
    'street': street,
    'unit': unit,
    'city': city,
    'state': state,
    'zip': zip,
    'legacy': legacy,
  };

  String get formatted {
    if (legacy.isNotEmpty &&
        [street, unit, city, state, zip].every((v) => v.isEmpty)) {
      return legacy;
    }
    final locality = [
      city.trim(),
      [state.trim(), zip.trim()].where((s) => s.isNotEmpty).join(' '),
    ].where((s) => s.isNotEmpty).join(', ');
    return [
      street.trim(),
      unit.trim(),
      locality,
    ].where((s) => s.isNotEmpty).join('\n');
  }
}
