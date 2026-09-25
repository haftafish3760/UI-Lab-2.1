part of 'receipt_capture_models.dart';

List<String> _diagnosticStringList(Object? value) {
  if (value is Iterable) {
    return List.unmodifiable(
      value
          .map((entry) => _diagnosticToken(entry?.toString() ?? ''))
          .where((entry) => entry != 'unknown')
          .toList(),
    );
  }
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return const [];
  return List.unmodifiable(
    text
        .split(RegExp(r'[|,]'))
        .map(_diagnosticToken)
        .where((entry) => entry != 'unknown')
        .toList(),
  );
}

bool _diagnosticPositive(Object? value) {
  if (value is num) return value.isFinite && value > 0;
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed != null && parsed > 0;
}

int? _diagnosticPositiveInt(Object? value) {
  if (value is num) {
    if (!value.isFinite) return null;
    final intValue = value.toInt();
    return intValue > 0 ? intValue : null;
  }
  final parsed = int.tryParse(value?.toString().trim() ?? '');
  return parsed != null && parsed > 0 ? parsed : null;
}

int? _diagnosticZeroOrPositiveInt(Object? value) {
  if (value is num) {
    if (!value.isFinite) return null;
    final intValue = value.toInt();
    return intValue >= 0 ? intValue : null;
  }
  final parsed = int.tryParse(value?.toString().trim() ?? '');
  return parsed != null && parsed >= 0 ? parsed : null;
}

bool? _diagnosticBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true') return true;
  if (normalized == 'false') return false;
  return null;
}

String _diagnosticToken(String value) {
  final token = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (token.isEmpty) return 'unknown';
  return token.length > 80 ? token.substring(0, 80) : token;
}

Map<String, ReceiptPhotoQualityCheck> _qualityChecksForPaths(
  Map<String, ReceiptPhotoQualityCheck> values,
  List<String> paths,
) {
  if (values.isEmpty || paths.isEmpty) return const {};
  final pathSet = paths.toSet();
  return Map<String, ReceiptPhotoQualityCheck>.unmodifiable({
    for (final entry in values.entries)
      if (pathSet.contains(entry.key.trim())) entry.key.trim(): entry.value,
  });
}

Map<String, Map<String, Object?>> _diagnosticsForPaths(
  Map<String, Map<String, Object?>> values,
  List<String> paths,
) {
  if (values.isEmpty || paths.isEmpty) return const {};
  final pathSet = paths.toSet();
  return Map<String, Map<String, Object?>>.unmodifiable({
    for (final entry in values.entries)
      if (pathSet.contains(entry.key.trim()))
        entry.key.trim(): Map<String, Object?>.unmodifiable(entry.value),
  });
}

List<String> _nonBlankPaths(List<String> paths) {
  return [
    for (final path in paths)
      if (path.trim().isNotEmpty) path.trim(),
  ];
}

List<String> _uniqueNonBlankPaths(List<String> paths) {
  final seen = <String>{};
  return [
    for (final path in _nonBlankPaths(paths))
      if (seen.add(path)) path,
  ];
}

bool _pathInputWasSanitized(List<String> paths) {
  if (paths.any((path) => path.trim().isEmpty || path.trim() != path)) {
    return true;
  }
  final uniquePaths = _uniqueNonBlankPaths(paths);
  if (uniquePaths.length != paths.length) return true;
  return !receiptPhotoPathsAreUniqueAndNormalized(uniquePaths);
}
