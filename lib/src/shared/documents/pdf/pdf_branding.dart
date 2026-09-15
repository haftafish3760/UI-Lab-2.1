/// Immutable document projection of the existing company profile, not a second
/// company store. A retained snapshot can keep these values after profile edits.
class PdfBranding {
  const PdfBranding({
    required this.companyName,
    this.logoReference,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.licenseNumber = '',
    this.businessIdentifier = '',
    this.footerText = '',
    this.accentColor,
  });
  final String companyName, address, phone, email, website;
  final String licenseNumber, businessIdentifier, footerText;
  final String? logoReference;
  final int? accentColor;
  List<String> get contactLines => [
    address,
    phone,
    email,
    website,
    if (licenseNumber.isNotEmpty) 'License: $licenseNumber',
    if (businessIdentifier.isNotEmpty) 'Business ID: $businessIdentifier',
  ].where((s) => s.trim().isNotEmpty).toList(growable: false);
}
