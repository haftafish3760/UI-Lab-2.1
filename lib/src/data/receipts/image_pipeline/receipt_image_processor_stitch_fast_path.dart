part of 'receipt_image_processor.dart';

bool _stitchMatchHasVisualCorroboration(
  img.Image previous,
  _ReceiptOverlapMatch match,
) {
  final continuity = _receiptOverlapContinuityEvidence(
    previous: previous,
    match: match,
  );
  return continuity.isProven ||
      (match.confidence >= .35 &&
          continuity.detailedBands >= 3 &&
          continuity.matchingBands >= 3 &&
          continuity.correlation >= .30) ||
      (match.confidence >= .44 &&
          continuity.detailedBands >= 2 &&
          continuity.matchingBands == continuity.detailedBands &&
          continuity.correlation >= .55);
}

_ReceiptOverlapMatch? _uprightReceiptOverlapFastPath({
  required img.Image previous,
  required img.Image next,
  required img.Image previousSample,
  required img.Image nextSample,
  required int targetWidth,
  required int sampleWidth,
  int? horizontalOffsetHint,
}) {
  final baseMatch = _bestVerticalOverlap(
    previous: previousSample,
    next: nextSample,
    horizontalOffsetHint: horizontalOffsetHint,
  );
  final candidate = _ReceiptStitchCandidate(
    pixels: baseMatch.pixels,
    nextSkipPixels: baseMatch.nextSkipPixels,
    nextXOffsetPixels: baseMatch.nextXOffsetPixels,
    confidence: baseMatch.confidence,
    scaleCorrection: 1,
    sampleHeight: nextSample.height,
    sampleWidth: nextSample.width,
  );
  final sampleMatch = _materializeStitchCandidate(
    candidate: candidate,
    previousHeight: previousSample.height,
    next: nextSample,
    targetWidth: sampleWidth,
  );
  final geometry = _receiptOverlapGeometryEvidence(
    previous: previousSample,
    match: sampleMatch,
  );
  // The no-text final gate requires two-dimensional geometry. Returning early
  // on repetitive one-dimensional continuity alone only guarantees a later
  // rejection and hides stronger transform candidates.
  if (!_receiptGeometryEvidenceSupportsCandidate(geometry)) {
    return null;
  }
  final materialized = _materializeStitchCandidate(
    candidate: candidate,
    previousHeight: previous.height,
    next: next,
    targetWidth: targetWidth,
  );
  final materializedGeometry = _receiptOverlapGeometryEvidence(
    previous: previous,
    match: materialized,
  );
  if (!_receiptGeometryEvidenceSupportsCandidate(materializedGeometry)) {
    return null;
  }
  return materialized;
}
