part of 'receipt_image_processor.dart';

ReceiptNativeRegistrationProposal? _receiptNativeRegistrationProposalForPair(
  List<ReceiptNativeRegistrationProposal> proposals,
  int pairIndex,
) {
  for (final proposal in proposals) {
    if (proposal.pairIndex == pairIndex && proposal.isUsable) return proposal;
  }
  return null;
}

_ReceiptOverlapMatch? _verifiedNativeGuidedReceiptOverlap({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  required int comparisonWidth,
  required ReceiptNativeRegistrationProposal? proposal,
}) {
  final match = _nativeGuidedReceiptOverlap(
    previous: previous,
    next: next,
    targetWidth: targetWidth,
    comparisonWidth: comparisonWidth,
    proposal: proposal,
  );
  if (match == null) return null;
  final continuity = _receiptOverlapContinuityEvidence(
    previous: previous,
    match: match,
  );
  final geometry = _receiptOverlapGeometryEvidence(
    previous: previous,
    match: match,
  );
  return continuity.isProven || geometry.isProven ? match : null;
}

_ReceiptOverlapMatch? _nativeGuidedReceiptOverlap({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  required int comparisonWidth,
  required ReceiptNativeRegistrationProposal? proposal,
}) {
  if (proposal == null || !proposal.isUsable) return null;
  final sampleWidth = math.min(
    comparisonWidth.clamp(240, 480),
    math.min(previous.width, next.width),
  );
  final previousSample = previous.width == sampleWidth
      ? previous
      : img.copyResize(previous, width: sampleWidth);
  final nextSample = next.width == sampleWidth
      ? next
      : img.copyResize(next, width: sampleWidth);
  final transformedNext = _transformForStitchComparison(
    nextSample,
    targetWidth: sampleWidth,
    scale: proposal.scale,
    rotationDegrees: proposal.rotationDegrees,
  );
  final horizontalOffsets = <double>[];
  final verticalPlacements = <double>[];
  for (final anchor in proposal.anchors) {
    final transformed = _mapReceiptNativeAnchorIntoTransformedImage(
      anchor: anchor,
      source: nextSample,
      transformed: transformedNext,
      scale: proposal.scale,
      rotationDegrees: proposal.rotationDegrees,
    );
    final previousX = anchor.previousX * previousSample.width;
    final previousY = anchor.previousY * previousSample.height;
    horizontalOffsets.add(transformed.x - previousX);
    verticalPlacements.add(previousY - transformed.y);
  }
  if (horizontalOffsets.length < 6 || verticalPlacements.length < 6) {
    return null;
  }
  horizontalOffsets.sort();
  verticalPlacements.sort();
  final horizontalOffset = horizontalOffsets[horizontalOffsets.length ~/ 2]
      .round();
  final placement = verticalPlacements[verticalPlacements.length ~/ 2];
  final overlap = (previousSample.height - placement).round();
  final minOverlap = math.max(32, (previousSample.height * .06).round());
  final maxOverlap = math.min(
    previousSample.height - 24,
    (math.min(previousSample.height, transformedNext.height) * .62).round(),
  );
  final maxHorizontalOffset = (sampleWidth * .20).round();
  if (overlap < minOverlap ||
      overlap > maxOverlap ||
      horizontalOffset.abs() > maxHorizontalOffset) {
    return null;
  }

  final initialDifference = _overlapDifference(
    previous: previousSample,
    next: transformedNext,
    pixels: overlap,
    horizontalOffset: horizontalOffset,
  );
  final refined = _refineReceiptGeometryChoice(
    previous: previousSample,
    next: transformedNext,
    initial: (
      score: initialDifference,
      pixels: overlap,
      horizontalOffset: horizontalOffset,
      nextYOffset: 0,
      geometryScore: double.infinity,
    ),
    minPixels: minOverlap,
    maxPixels: maxOverlap,
  );
  final geometryMatch = _ReceiptOverlapMatch(
    pixels: refined.pixels,
    nextSkipPixels: refined.pixels + refined.nextYOffset,
    nextXOffsetPixels: refined.horizontalOffset,
    nextTopOffsetPixels: refined.nextYOffset,
    confidence: 0,
    nextImage: transformedNext,
  );
  final geometry = _receiptOverlapGeometryEvidence(
    previous: previousSample,
    match: geometryMatch,
  );
  if (!_receiptGeometryEvidenceSupportsCandidate(geometry)) return null;

  final visualConfidence = (1 - (refined.score / 64)).clamp(0.0, 1.0);
  final inlierConfidence = proposal.confidence.clamp(0.0, 1.0);
  final confidence = (visualConfidence * .55 + inlierConfidence * .45).clamp(
    0.0,
    .92,
  );
  final scaleY = previous.height / math.max(1, previousSample.height);
  final scaleX = previous.width / math.max(1, previousSample.width);
  final fullOverlap = (refined.pixels * scaleY).round();
  final fullTopOffset = (refined.nextYOffset * scaleY).round();
  return _ReceiptOverlapMatch(
    pixels: fullOverlap,
    nextSkipPixels: fullOverlap + fullTopOffset,
    nextXOffsetPixels: (refined.horizontalOffset * scaleX).round(),
    nextTopOffsetPixels: fullTopOffset,
    confidence: confidence,
    nextImage: _transformForStitchComparison(
      next,
      targetWidth: targetWidth,
      scale: proposal.scale,
      rotationDegrees: proposal.rotationDegrees,
    ),
    scaleCorrection: proposal.scale,
    rotationCorrectionDegrees: proposal.rotationDegrees,
  );
}

({double x, double y}) _mapReceiptNativeAnchorIntoTransformedImage({
  required ReceiptNativeRegistrationAnchor anchor,
  required img.Image source,
  required img.Image transformed,
  required double scale,
  required double rotationDegrees,
}) {
  final scaledWidth = (source.width * scale).round().clamp(1, 3200);
  final scaledHeight = (source.height * scaledWidth / source.width).round();
  final sourceX = anchor.nextX * scaledWidth;
  final sourceY = anchor.nextY * scaledHeight;
  if (rotationDegrees.abs() < .001) {
    return (x: sourceX, y: sourceY);
  }
  final radians = (rotationDegrees % 360) * math.pi / 180;
  final cosine = math.cos(radians);
  final sine = math.sin(radians);
  final sourceCenterX = scaledWidth / 2;
  final sourceCenterY = scaledHeight / 2;
  final destinationCenterX = transformed.width / 2;
  final destinationCenterY = transformed.height / 2;
  return (
    x:
        destinationCenterX +
        cosine * (sourceX - sourceCenterX) -
        sine * (sourceY - sourceCenterY),
    y:
        destinationCenterY +
        sine * (sourceX - sourceCenterX) +
        cosine * (sourceY - sourceCenterY),
  );
}
