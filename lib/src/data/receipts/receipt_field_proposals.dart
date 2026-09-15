import 'receipt_photo_reader.dart';
import 'receipt_date_proposal.dart';
import 'receipt_reading_rows.dart';
export 'receipt_reading_rows.dart' show receiptReadingRows;

/// Evidence-backed suggestions only. Missing or conflicting values stay unset.
class ReceiptFieldProposals {
  const ReceiptFieldProposals({
    required this.merchant,
    required this.totalMinor,
    required this.subtotalMinor,
    required this.taxMinor,
    required this.rows,
    required this.warnings,
    this.date,
  });
  final String? merchant;
  final DateTime? date;
  final int? totalMinor, subtotalMinor, taxMinor;
  final List<String> rows, warnings;
}

/// Structural extraction has no merchant list and no generator dependencies.
/// This initial currency grammar accepts dot decimals only; ambiguous formats
/// are kept as source text instead of guessed into financial records.
ReceiptFieldProposals proposeReceiptFields(ReceiptPhotoText source) {
  final rows = receiptReadingRows(source);
  final warnings = <String>[...source.warnings];
  final dateProposal = proposeReceiptDate(rows);
  warnings.addAll(dateProposal.warnings);
  final totals = <int>{}, subtotals = <int>{}, taxes = <int>{};
  final amount = RegExp(
    r'(?<![\d.,])(?:\$\s*)?(-?(?:\d{1,3}(?:,\d{3})+|\d+)\.\d{2})\s*(?:USD|CAD|AUD)?\s*$',
    caseSensitive: false,
  );
  final totalLabel = RegExp(
    r'^(?:grand\s+total|total(?:\s+(?:due|amount))?|amount\s+due|balance\s+due)\s*[:=]?\s*$',
    caseSensitive: false,
  );
  final subtotalLabel = RegExp(
    r'^sub\s*total\s*[:=]?\s*$',
    caseSensitive: false,
  );
  final taxLabel = RegExp(
    r'^(?:sales\s+tax|tax)\s*[:=]?\s*$',
    caseSensitive: false,
  );
  for (final row in rows) {
    final match = amount.firstMatch(row);
    if (match == null) continue;
    final label = row.substring(0, match.start).trim();
    final raw = match.group(1)!.replaceAll(',', '');
    final negative = raw.startsWith('-');
    final parts = raw.replaceFirst('-', '').split('.');
    final major = int.tryParse(parts[0]);
    if (major == null || major > 999999999) continue;
    final minor = (major * 100 + int.parse(parts[1])) * (negative ? -1 : 1);
    if (totalLabel.hasMatch(label)) totals.add(minor);
    if (subtotalLabel.hasMatch(label)) subtotals.add(minor);
    if (taxLabel.hasMatch(label)) taxes.add(minor);
  }
  int? unique(Set<int> values, String label) {
    if (values.length > 1) {
      warnings.add('More than one $label was found. Check the receipt.');
    }
    return values.length == 1 ? values.single : null;
  }

  final total = unique(totals, 'total');
  final subtotal = unique(subtotals, 'subtotal');
  final tax = unique(taxes, 'tax amount');
  if (total == null) warnings.add('The total needs your review.');
  if (total != null &&
      subtotal != null &&
      tax != null &&
      subtotal + tax != total) {
    warnings.add(
      'Subtotal and tax do not match the total. Check discounts, fees, and rounding.',
    );
  }
  String? merchant;
  final headerNoise = RegExp(
    r'\b(receipt|invoice|date|time|cashier|terminal|register|tel|phone|tax|total|customer|welcome|thank|copy|transaction|order)\b',
    caseSensitive: false,
  );
  for (final row in rows.take(6)) {
    if (row.length < 3 || row.length > 90 || headerNoise.hasMatch(row)) {
      continue;
    }
    if (!RegExp(r'[A-Za-z]{3}').hasMatch(row) || RegExp(r'\d').hasMatch(row)) {
      continue;
    }
    merchant = row;
    break;
  }
  return ReceiptFieldProposals(
    date: dateProposal.date,
    merchant: merchant,
    totalMinor: total,
    subtotalMinor: subtotal,
    taxMinor: tax,
    rows: List.unmodifiable(rows),
    warnings: List.unmodifiable(warnings),
  );
}
