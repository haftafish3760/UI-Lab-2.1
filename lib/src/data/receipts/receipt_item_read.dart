import 'receipt_item_proposal.dart';
import 'receipt_item_read_codec.dart';
import 'receipt_photo_text.dart';

/// Retained observations from one image, not reviewed expense or stock facts.
class ReceiptItemRead {
  ReceiptItemRead({
    required this.evidenceId,
    required this.sha256,
    required this.parserVersion,
    required DateTime readAtUtc,
    required this.recognizedText,
    required this.result,
    List<String> warnings = const [],
    List<ReceiptTextLine> sourceLines = const [],
  }) : readAtUtc = readAtUtc.toUtc(),
       warnings = List.unmodifiable(warnings),
       sourceLines = List.unmodifiable(sourceLines) {
    if (evidenceId.trim().isEmpty ||
        parserVersion.trim().isEmpty ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256)) {
      throw const FormatException('Invalid receipt item source.');
    }
    final ids = result.items.map((item) => item.id).toSet();
    if (ids.length != result.items.length ||
        ids.any((id) => id.trim().isEmpty)) {
      throw const FormatException('Receipt item identities must be unique.');
    }
  }

  final String evidenceId, sha256, parserVersion, recognizedText;
  final DateTime readAtUtc;
  final ReceiptItemParseResult result;
  final List<String> warnings;
  final List<ReceiptTextLine> sourceLines;

  bool matches(String id, String checksum) =>
      evidenceId == id && sha256 == checksum;

  Map<String, Object?> toJson() => encodeReceiptItemRead(this);
  factory ReceiptItemRead.fromJson(Map<String, Object?> json) =>
      decodeReceiptItemRead(json);
}

List<ReceiptItemRead> decodeReceiptItemReads(Map<String, Object?> payload) {
  if (!payload.containsKey('itemReads')) return const [];
  final values = payload['itemReads'];
  if (values is! List) {
    throw const FormatException('Invalid receipt item reads.');
  }
  final reads = values.map((value) {
    if (value is! Map) {
      throw const FormatException('Invalid receipt item read.');
    }
    return ReceiptItemRead.fromJson(value.cast<String, Object?>());
  }).toList();
  if (reads.map((read) => read.evidenceId).toSet().length != reads.length) {
    throw const FormatException('Repeated receipt item source.');
  }
  return List.unmodifiable(reads);
}
