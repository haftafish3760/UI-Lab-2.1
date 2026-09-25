import 'dart:math' as math;

// Adapted from Maintainiac 5.7 receipt_stitch_acceptance.dart. The source
// remains unchanged. Acceptance permits a review candidate, never a ledger write.

bool hasExceptionalReceiptStitchContinuity({
  required double correlation,
  required int detailedBands,
  required int matchingBands,
}) {
  if (matchingBands != detailedBands) return false;
  return (detailedBands >= 4 && correlation >= .72) ||
      (detailedBands >= 3 && correlation >= .80);
}

bool hasHighTrustPositionedReceiptOverlap({
  required double visualConfidence,
  required double textConfidence,
  required int matchedTextLineCount,
  required bool hasTextPositionEvidence,
  required double textPositionalConfidence,
}) {
  return hasTextPositionEvidence &&
      matchedTextLineCount >= 5 &&
      textConfidence >= .90 &&
      textPositionalConfidence >= .85 &&
      visualConfidence >= .50;
}

bool shouldTryFixedScaleReceiptFallback({
  required bool continuityProven,
  required bool hasHighTrustPositionedText,
  required double scaleCorrection,
  required double rotationCorrectionDegrees,
  required double perspectiveCorrection,
}) {
  final usesTransform =
      (scaleCorrection - 1).abs() >= .03 ||
      rotationCorrectionDegrees.abs() >= .5 ||
      perspectiveCorrection.abs() >= .03;
  return !continuityProven && !hasHighTrustPositionedText && usesTransform;
}

int receiptTextCoveredSeamSkipPixels({
  required int geometricOverlapPixels,
  required int nextImageHeight,
  required double nextMatchedBlockEnd,
}) {
  if (nextImageHeight <= 24 || !nextMatchedBlockEnd.isFinite) {
    return geometricOverlapPixels;
  }
  final matchedBlockEndPixels =
      (nextMatchedBlockEnd.clamp(0.0, 1.0) * nextImageHeight).ceil();
  return math
      .max(geometricOverlapPixels, matchedBlockEndPixels)
      .clamp(0, nextImageHeight - 24);
}

int receiptTextAwareSeamCropPixels({
  required int geometricOverlapPixels,
  required int nextImageHeight,
  required double matchedTextEnd,
  required double continuationTextStart,
  required double continuationTextEnd,
  required bool hasHighTrustPositionedText,
}) {
  if (nextImageHeight <= 1) return 0;
  final safeOverlap = geometricOverlapPixels.clamp(1, nextImageHeight - 1);
  if (!hasHighTrustPositionedText ||
      nextImageHeight <= 24 ||
      !matchedTextEnd.isFinite ||
      !continuationTextStart.isFinite ||
      !continuationTextEnd.isFinite) {
    return safeOverlap;
  }
  final seamFraction = safeOverlap / nextImageHeight;
  final continuationBandHeight = math.max(
    0.0,
    continuationTextEnd - continuationTextStart,
  );
  final continuationTouchesSeam =
      continuationTextStart > 0 &&
      continuationTextStart < seamFraction + continuationBandHeight * .5 &&
      continuationTextEnd > seamFraction;
  if (continuationTouchesSeam) {
    return ((continuationTextStart * nextImageHeight).floor() - 2).clamp(
      1,
      nextImageHeight - 1,
    );
  }
  return ((matchedTextEnd.clamp(0.0, 1.0) * nextImageHeight).ceil() + 2).clamp(
    1,
    nextImageHeight - 1,
  );
}

int receiptGeometryPlacementOverlapPixels({
  required int seamSkipPixels,
  required int overlapPixels,
  required int nextImageHeight,
}) {
  if (nextImageHeight <= 1) return 0;
  final geometricPlacement = seamSkipPixels > 0
      ? seamSkipPixels
      : overlapPixels;
  return geometricPlacement.clamp(0, nextImageHeight - 1);
}

Duration receiptRemainingStitchWorkerTimeout({
  required Duration totalBudget,
  required Duration elapsedBeforeWorker,
}) {
  final remaining = totalBudget - elapsedBeforeWorker;
  return remaining > Duration.zero ? remaining : Duration.zero;
}

class ReceiptStitchEvidenceDecision {
  const ReceiptStitchEvidenceDecision({
    required this.accepted,
    required this.confidence,
    required this.corroboratingSignalCount,
    required this.reasonCode,
  });

  final bool accepted;
  final double confidence;
  final int corroboratingSignalCount;
  final String reasonCode;
}

ReceiptStitchEvidenceDecision evaluateReceiptStitchEvidence({
  required double visualConfidence,
  required double continuityCorrelation,
  required int continuityDetailedBands,
  required int continuityMatchingBands,
  required bool continuityProven,
  required double geometryCorrelation,
  required int geometryDetailedCells,
  required int geometryMatchingCells,
  required bool geometryProven,
  required double textConfidence,
  required int matchedTextLineCount,
  required bool textStrong,
  required bool hasTextPositionEvidence,
  required double textPositionalConfidence,
  bool ambiguousPlacement = false,
}) {
  final scores = [
    visualConfidence,
    continuityCorrelation,
    geometryCorrelation,
    textConfidence,
    textPositionalConfidence,
  ];
  if (scores.any((value) => !value.isFinite || value < 0 || value > 1) ||
      continuityDetailedBands < 0 ||
      continuityMatchingBands < 0 ||
      continuityMatchingBands > continuityDetailedBands ||
      geometryDetailedCells < 0 ||
      geometryMatchingCells < 0 ||
      geometryMatchingCells > geometryDetailedCells ||
      matchedTextLineCount < 0) {
    return const ReceiptStitchEvidenceDecision(
      accepted: false,
      confidence: 0,
      corroboratingSignalCount: 0,
      reasonCode: 'invalid_evidence',
    );
  }
  if (ambiguousPlacement) {
    return const ReceiptStitchEvidenceDecision(
      accepted: false,
      confidence: 0,
      corroboratingSignalCount: 0,
      reasonCode: 'ambiguous_image_placement',
    );
  }
  final safeVisual = visualConfidence.clamp(0.0, 1.0);
  final safeContinuity = continuityCorrelation.clamp(0.0, 1.0);
  final safeGeometry = geometryCorrelation.clamp(0.0, 1.0);
  final safeText = textConfidence.clamp(0.0, 1.0);
  final positionedTextScore = hasTextPositionEvidence
      ? (safeText * .72 + textPositionalConfidence.clamp(0.0, 1.0) * .28)
      : safeText * .88;

  final continuitySignal =
      continuityProven ||
      (continuityDetailedBands >= 3 &&
          continuityMatchingBands >= 3 &&
          safeContinuity >= .48) ||
      (continuityDetailedBands >= 2 &&
          continuityMatchingBands == continuityDetailedBands &&
          safeContinuity >= .60);
  final exceptionalContinuity = hasExceptionalReceiptStitchContinuity(
    correlation: safeContinuity,
    detailedBands: continuityDetailedBands,
    matchingBands: continuityMatchingBands,
  );
  final geometrySignal =
      geometryProven ||
      (geometryDetailedCells >= 6 &&
          geometryMatchingCells >= 5 &&
          safeGeometry >= .72) ||
      (exceptionalContinuity &&
          geometryDetailedCells >= 8 &&
          geometryMatchingCells >= 6 &&
          safeGeometry >= .55);
  final textSignal =
      textStrong &&
      matchedTextLineCount > 0 &&
      (!hasTextPositionEvidence || textPositionalConfidence >= .52);
  final reliablePositionedText =
      textSignal &&
      hasTextPositionEvidence &&
      matchedTextLineCount >= 2 &&
      textPositionalConfidence >= .72;
  final visualSignal = safeVisual >= .48;
  final signalCount = [
    visualSignal,
    continuitySignal,
    geometrySignal,
    textSignal,
  ].where((value) => value).length;

  var weightedTotal = safeVisual * .30;
  var availableWeight = .30;
  if (continuityDetailedBands >= 2) {
    weightedTotal += safeContinuity * .25;
    availableWeight += .25;
  }
  if (geometryDetailedCells >= 4) {
    weightedTotal += safeGeometry * .25;
    availableWeight += .25;
  }
  if (matchedTextLineCount > 0) {
    weightedTotal += positionedTextScore * .20;
    availableWeight += .20;
  }
  final confidence = (weightedTotal / availableWeight).clamp(0.0, 1.0);
  // Wrinkles, shadows and perspective can make a rigid cell grid disagree
  // even when two distinct OCR lines occupy the same ordered overlap and the
  // one-dimensional ink continuity corroborates them. Do not let that weak
  // grid score numerically drown the two stronger independent signals. The
  // result remains review-required; this only permits producing the composite
  // the person was explicitly asked to inspect.
  final textBackedWeight =
      .30 +
      (continuityDetailedBands >= 2 ? .25 : 0) +
      (matchedTextLineCount > 0 ? .20 : 0);
  final textBackedTotal =
      safeVisual * .30 +
      (continuityDetailedBands >= 2 ? safeContinuity * .25 : 0) +
      (matchedTextLineCount > 0 ? positionedTextScore * .20 : 0);
  final textBackedConfidence = textBackedWeight <= 0
      ? 0.0
      : (textBackedTotal / textBackedWeight).clamp(0.0, 1.0);
  final hasStructuralCorroboration =
      continuitySignal || geometrySignal || textSignal;
  final hasNoTextEvidence = matchedTextLineCount <= 0;
  final noTextGeometryIsSafe =
      !hasNoTextEvidence ||
      (geometrySignal && (visualSignal || continuitySignal));
  // Geometry owns physical placement. OCR can corroborate or veto that
  // placement, but even dense repeated text cannot rescue unsupported image
  // geometry. This prevents one evidence system from silently cancelling the
  // failure reported by another.
  final accepted =
      geometrySignal &&
      safeVisual >= .35 &&
      (continuitySignal || reliablePositionedText) &&
      confidence >= .50 &&
      signalCount >= 2 &&
      hasStructuralCorroboration &&
      noTextGeometryIsSafe;
  final reportedConfidence =
      accepted && reliablePositionedText && textBackedConfidence > confidence
      ? textBackedConfidence
      : confidence;
  return ReceiptStitchEvidenceDecision(
    accepted: accepted,
    confidence: reportedConfidence,
    corroboratingSignalCount: signalCount,
    reasonCode: accepted
        ? reliablePositionedText
              ? 'positioned_text_corroborates_document_geometry'
              : 'fused_visual_document_geometry'
        : !geometrySignal
        ? 'document_geometry_not_proven'
        : safeVisual < .35
        ? 'visual_overlap_support_low'
        : !noTextGeometryIsSafe
        ? 'no_text_requires_geometry_corroboration'
        : signalCount < 2
        ? 'insufficient_independent_signals'
        : 'fused_confidence_low',
  );
}

bool isLargeReceiptOverlapTransformAmbiguous({
  required int overlapPixels,
  required int overlapReferenceHeight,
  required double scaleCorrection,
  required double rotationCorrectionDegrees,
  required double perspectiveCorrection,
  required double continuityCorrelation,
  required int continuityDetailedBands,
  required int continuityMatchingBands,
}) {
  final safeReferenceHeight = overlapReferenceHeight <= 0
      ? 1
      : overlapReferenceHeight;
  final overlapShare = overlapPixels / safeReferenceHeight;
  final exceptionalContinuity = hasExceptionalReceiptStitchContinuity(
    correlation: continuityCorrelation,
    detailedBands: continuityDetailedBands,
    matchingBands: continuityMatchingBands,
  );
  return overlapShare >= .40 &&
      !exceptionalContinuity &&
      ((scaleCorrection - 1).abs() >= .08 ||
          rotationCorrectionDegrees.abs() >= 2.0 ||
          perspectiveCorrection.abs() >= .05);
}
