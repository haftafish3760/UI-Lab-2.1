part of 'receipt_image_processor.dart';

({List<String> paths, ReceiptStitchResult? failure})
_normalizeReceiptStitchInputPaths(List<String> paths) {
  final normalized = paths
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
  return (
    paths: normalized,
    failure: _validateReceiptStitchInputPaths(normalized),
  );
}

bool _receiptManualZeroOverlapFor(List<bool>? values, int pairIndex) {
  return values != null && pairIndex < values.length && values[pairIndex];
}

ReceiptStitchResult _receiptStitchExceptionFallback({
  required List<String> inputPaths,
  required List<double> confidences,
  required int activePairIndex,
  required List<ReceiptStitchPairResult> pairs,
}) {
  return ReceiptStitchResult.fallback(
    inputPaths: inputPaths,
    warning:
        'Receipt photos could not be stitched safely. Receipt details will use them separately.',
    fallbackReasonCode: 'stitch_exception',
    confidence: confidences.isEmpty ? 0 : confidences.reduce(math.min),
    failedPairIndex: activePairIndex >= 0 ? activePairIndex : null,
    pairs: pairs,
  );
}

({
  double scale,
  double rotationDegrees,
  double horizontalOffsetFraction,
  img.Image next,
  int? overlap,
})
_prepareReceiptManualStitchPair({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  required int pairIndex,
  required List<int>? manualOverlapPixels,
  required List<double>? manualOverlapFractions,
  required List<double>? manualScaleCorrections,
  required List<double>? manualRotationCorrectionsDegrees,
  required List<double>? manualHorizontalOffsetFractions,
}) {
  final scale = _manualStitchValue(
    manualScaleCorrections,
    pairIndex,
    fallback: 1,
    minimum: .75,
    maximum: 1.25,
  );
  final rotationDegrees = _manualStitchValue(
    manualRotationCorrectionsDegrees,
    pairIndex,
    fallback: 0,
    minimum: -8,
    maximum: 8,
  );
  final horizontalOffsetFraction = _manualStitchValue(
    manualHorizontalOffsetFractions,
    pairIndex,
    fallback: 0,
    minimum: -.20,
    maximum: .20,
  );
  final transformedNext = _transformForStitchComparison(
    next,
    targetWidth: targetWidth,
    scale: scale,
    rotationDegrees: rotationDegrees,
  );
  return (
    scale: scale,
    rotationDegrees: rotationDegrees,
    horizontalOffsetFraction: horizontalOffsetFraction,
    next: transformedNext,
    overlap: _manualOverlapFor(
      previous: previous,
      next: transformedNext,
      pairIndex: pairIndex,
      manualOverlapPixels: manualOverlapPixels,
      manualOverlapFractions: manualOverlapFractions,
    ),
  );
}
