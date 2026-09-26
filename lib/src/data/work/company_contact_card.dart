import 'dart:convert';
import 'company_address.dart';
import 'models/work_contact_models.dart';

/// Offline contact exchange using vCard 3.0 (RFC 2426). Deliberately excludes
/// internal IDs, payment terms, license/account data and local attachment paths.
String companyContactVCard(
  WorkCompanyProfile company, {
  bool includeAddress = false,
}) {
  String text(String value) => value
      .trim()
      .replaceAll('\\', '\\\\')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', r'\n')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,');
  final name = text(company.companyName);
  final lines = <String>[
    'BEGIN:VCARD',
    'VERSION:3.0',
    'FN:$name',
    'N:$name;;;;',
    'ORG:$name',
  ];
  if (company.phone.trim().isNotEmpty) {
    lines.add('TEL;TYPE=WORK,VOICE:${text(company.phone)}');
  }
  if (company.email.trim().isNotEmpty) {
    lines.add('EMAIL;TYPE=INTERNET,WORK:${text(company.email)}');
  }
  final website = company.website.trim();
  if (website.isNotEmpty && !website.contains(RegExp(r'[\r\n]'))) {
    final uri = Uri.tryParse(
      website.contains('://') ? website : 'https://$website',
    );
    if (uri != null &&
        const {'https', 'http'}.contains(uri.scheme) &&
        uri.host.isNotEmpty) {
      lines.add('URL:${uri.toString()}');
    }
  }
  if (includeAddress && company.address.trim().isNotEmpty) {
    final address = company.addressParts.isEmpty
        ? CompanyAddress.fromLegacy(company.address)
        : CompanyAddress.fromMap(company.addressParts);
    if (address.legacy.isNotEmpty) {
      lines.add('LABEL;TYPE=WORK:${text(company.address)}');
    } else {
      lines.add(
        'ADR;TYPE=WORK:;${text(address.unit)};${text(address.street)};${text(address.city)};${text(address.state)};${text(address.zip)};',
      );
    }
  }
  lines.add('END:VCARD');
  // Fold by UTF-8 octets without splitting a Unicode character.
  return '${lines.map((line) {
    final buffer = StringBuffer();
    var bytes = 0;
    for (final rune in line.runes) {
      final character = String.fromCharCode(rune);
      final length = utf8.encode(character).length;
      if (bytes + length > 75) {
        buffer.write('\r\n ');
        bytes = 1;
      }
      buffer.write(character);
      bytes += length;
    }
    return buffer.toString();
  }).join('\r\n')}\r\n';
}
