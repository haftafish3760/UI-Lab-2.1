import 'receipt_field_proposals.dart';

/// User-selected suggestions, never a confirmed expense or an OCR score.
/// The evidence ID distinguishes separate photos even when their bytes match.
class ReceiptSelectedDetails {
  ReceiptSelectedDetails({
    required this.evidenceId,
    required this.sha256,
    required ReceiptFieldProposals details,
  }) : details = ReceiptFieldProposals(
         merchant: details.merchant,
         date: details.date,
         totalMinor: details.totalMinor,
         subtotalMinor: details.subtotalMinor,
         taxMinor: details.taxMinor,
         rows: List.unmodifiable(details.rows),
         warnings: List.unmodifiable(details.warnings),
       ) {
    if (evidenceId.trim().isEmpty ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256)) {
      throw const FormatException('Invalid suggestion source.');
    }
  }

  final String evidenceId, sha256;
  final ReceiptFieldProposals details;

  bool matches(String id, String checksum) =>
      evidenceId == id && sha256 == checksum;

  Map<String, Object?> toJson() => {
    'version': 1,
    'evidenceId': evidenceId,
    'sha256': sha256,
    'merchant': details.merchant,
    'date': details.date?.toIso8601String(),
    'totalMinor': details.totalMinor,
    'subtotalMinor': details.subtotalMinor,
    'taxMinor': details.taxMinor,
    'rows': details.rows,
    'warnings': details.warnings,
  };

  factory ReceiptSelectedDetails.fromJson(Map<String, Object?> json) {
    if (json['version'] != 1 ||
        !const [
          'merchant',
          'date',
          'totalMinor',
          'subtotalMinor',
          'taxMinor',
        ].every(json.containsKey)) {
      throw const FormatException('Unsupported selected receipt details.');
    }
    final dateText = json['date'] as String?;
    final date = dateText == null ? null : DateTime.tryParse(dateText);
    if (dateText != null &&
        (date == null || date.toIso8601String() != dateText)) {
      throw const FormatException('Invalid suggested receipt date.');
    }
    return ReceiptSelectedDetails(
      evidenceId: json['evidenceId'] as String,
      sha256: json['sha256'] as String,
      details: ReceiptFieldProposals(
        merchant: json['merchant'] as String?,
        date: date,
        totalMinor: json['totalMinor'] as int?,
        subtotalMinor: json['subtotalMinor'] as int?,
        taxMinor: json['taxMinor'] as int?,
        rows: (json['rows'] as List).cast<String>(),
        warnings: (json['warnings'] as List).cast<String>(),
      ),
    );
  }
}
