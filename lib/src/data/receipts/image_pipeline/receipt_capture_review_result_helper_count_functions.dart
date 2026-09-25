part of 'receipt_capture_models.dart';

Map<String, int> _diagnosticValueCounts(
  ReceiptPhotoReviewResult result,
  String key,
) {
  final counts = <String, int>{};
  for (final diagnostics in result.captureDiagnosticsByPhotoPath.values) {
    final value = diagnostics[key]?.toString().trim();
    if (value == null || value.isEmpty) continue;
    final token = _diagnosticToken(value);
    if (token == 'unknown') continue;
    counts[token] = (counts[token] ?? 0) + 1;
  }
  return Map.unmodifiable(counts);
}

Map<String, int> _diagnosticListValueCounts(
  ReceiptPhotoReviewResult result,
  String key,
) {
  final counts = <String, int>{};
  for (final diagnostics in result.captureDiagnosticsByPhotoPath.values) {
    for (final value in _diagnosticStringList(diagnostics[key])) {
      if (value == 'unknown') continue;
      counts[value] = (counts[value] ?? 0) + 1;
    }
  }
  return Map.unmodifiable(counts);
}

Map<String, int> _diagnosticBoolCounts(
  ReceiptPhotoReviewResult result,
  String key,
) {
  final counts = <String, int>{};
  for (final diagnostics in result.captureDiagnosticsByPhotoPath.values) {
    final value = diagnostics[key];
    if (value is bool) {
      final token = value ? 'true' : 'false';
      counts[token] = (counts[token] ?? 0) + 1;
    }
  }
  return Map.unmodifiable(counts);
}

Map<String, int> _preparationDiagnosticValueCounts(
  ReceiptPhotoReviewResult result,
  String key,
) {
  final counts = <String, int>{};
  for (final diagnostics in result.preparationDiagnosticsByOcrPath.values) {
    final value = diagnostics[key]?.toString().trim();
    if (value == null || value.isEmpty) continue;
    final token = _diagnosticToken(value);
    if (token == 'unknown') continue;
    counts[token] = (counts[token] ?? 0) + 1;
  }
  return Map.unmodifiable(counts);
}

Map<String, int> _preparationDiagnosticBoolCounts(
  ReceiptPhotoReviewResult result,
  String key,
) {
  final counts = <String, int>{};
  for (final diagnostics in result.preparationDiagnosticsByOcrPath.values) {
    final value = diagnostics[key];
    if (value is bool) {
      final token = value ? 'true' : 'false';
      counts[token] = (counts[token] ?? 0) + 1;
    }
  }
  return Map.unmodifiable(counts);
}

Map<String, int> _diagnosticPresenceCounts(
  ReceiptPhotoReviewResult result,
  String key,
) {
  final counts = <String, int>{};
  for (final diagnostics in result.captureDiagnosticsByPhotoPath.values) {
    final value = diagnostics[key]?.toString().trim();
    final token = value == null || value.isEmpty ? 'missing' : 'present';
    counts[token] = (counts[token] ?? 0) + 1;
  }
  return Map.unmodifiable(counts);
}

String _firstPreferredCountKey(
  Map<String, int> counts,
  List<String> preferredKeys,
) {
  for (final key in preferredKeys) {
    if ((counts[key] ?? 0) > 0) return key;
  }
  return counts.isEmpty ? 'unknown' : counts.keys.first;
}
