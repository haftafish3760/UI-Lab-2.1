part of 'receipt_capture_models.dart';

bool _sameReceiptArtifactPath(String left, String right) {
  final normalizedLeft = normalizedReceiptPhotoPath(left);
  final normalizedRight = normalizedReceiptPhotoPath(right);
  return normalizedLeft != null && normalizedLeft == normalizedRight;
}

bool _hasDuplicateReceiptArtifactPaths(List<String> paths) {
  final seen = <String>{};
  for (final path in paths) {
    final normalizedPath = normalizedReceiptPhotoPath(path);
    if (normalizedPath == null) continue;
    if (!seen.add(normalizedPath)) return true;
  }
  return false;
}

bool _hasInvalidReceiptArtifactPaths(List<String> paths) {
  for (final path in paths) {
    if (normalizedReceiptPhotoPath(path) == null) return true;
  }
  return false;
}

bool _receiptArtifactPathSetContains(List<String> paths, String candidate) {
  final normalizedCandidate = normalizedReceiptPhotoPath(candidate);
  if (normalizedCandidate == null) return false;
  for (final path in paths) {
    if (normalizedReceiptPhotoPath(path) == normalizedCandidate) return true;
  }
  return false;
}

String _invalidInputSourceContractCode(bool usedFallback) {
  return usedFallback
      ? 'fallback_invalid_input_sources'
      : 'invalid_input_sources';
}

String _invalidOcrSourceContractCode(bool usedFallback) {
  return usedFallback ? 'fallback_invalid_ocr_sources' : 'invalid_ocr_sources';
}

ReceiptStitchResult _frozenStitchResult(ReceiptStitchResult result) {
  return ReceiptStitchResult(
    status: result.status,
    inputPaths: List<String>.unmodifiable(result.inputPaths),
    ocrSourcePaths: List<String>.unmodifiable(result.ocrSourcePaths),
    stitchedPath: result.stitchedPath,
    confidence: result.confidence,
    overlapPixels: List<int>.unmodifiable(result.overlapPixels),
    pairs: List<ReceiptStitchPairResult>.unmodifiable(result.pairs),
    failedPairIndex: result.failedPairIndex,
    stitchedWidth: result.stitchedWidth,
    stitchedHeight: result.stitchedHeight,
    warning: result.warning,
    usedManualAdjustment: result.usedManualAdjustment,
    fallbackReasonCode: result.fallbackReasonCode,
  );
}

String _safeStitchFallbackReasonCode(String value) {
  final token = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return switch (token) {
    'decode_failed' ||
    'manual_overlap_unsafe' ||
    'invalid_input_paths' ||
    'duplicate_input_paths' ||
    'duplicate_section_image' ||
    'no_input_paths' ||
    'manual_order_review' ||
    'overlap_confidence_low' ||
    'output_too_large' ||
    'stitch_exception' ||
    'stitch_timeout' ||
    'unreadable_section_image' => token,
    _ => 'unknown',
  };
}

double _safeStitchUnitInterval(double value) {
  if (!value.isFinite) return 0;
  return value.clamp(0, 1).toDouble();
}
