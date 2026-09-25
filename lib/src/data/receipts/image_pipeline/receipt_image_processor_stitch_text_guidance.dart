part of 'receipt_image_processor.dart';

_ReceiptOverlapMatch? _textGuidedReceiptOverlap({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  required ReceiptStitchTextPairEvidence evidence,
}) {
  final previousAnchors = evidence.previousAnchorCenters;
  final nextAnchors = evidence.nextAnchorCenters;
  if (!evidence.isStrong ||
      !evidence.hasPositionalEvidence ||
      previousAnchors.length < 2 ||
      previousAnchors.length != nextAnchors.length) {
    return null;
  }
  final previousSpan =
      (previousAnchors.last - previousAnchors.first) * previous.height;
  final nextSpan = (nextAnchors.last - nextAnchors.first) * next.height;
  if (previousSpan < 8 || nextSpan < 8) return null;
  final scaleSignals = <double>[(previousSpan / nextSpan).clamp(.82, 1.18)];
  if (evidence.previousAnchorWidths.length == previousAnchors.length &&
      evidence.nextAnchorWidths.length == nextAnchors.length) {
    final widthRatios = <double>[
      for (var index = 0; index < previousAnchors.length; index++)
        if (evidence.nextAnchorWidths[index] > .001)
          (evidence.previousAnchorWidths[index] * previous.width) /
              (evidence.nextAnchorWidths[index] * next.width),
    ]..removeWhere((ratio) => ratio < .82 || ratio > 1.18);
    if (widthRatios.isNotEmpty) {
      widthRatios.sort();
      scaleSignals.add(widthRatios[widthRatios.length ~/ 2]);
    }
  }
  final scale = (scaleSignals.reduce((a, b) => a + b) / scaleSignals.length)
      .clamp(.82, 1.18);
  var rotationDegrees = 0.0;
  if (evidence.previousAnchorAngles.length == previousAnchors.length &&
      evidence.nextAnchorAngles.length == nextAnchors.length) {
    final angleCorrections = <double>[
      for (var index = 0; index < previousAnchors.length; index++)
        evidence.previousAnchorAngles[index] - evidence.nextAnchorAngles[index],
    ]..sort();
    rotationDegrees = angleCorrections[angleCorrections.length ~/ 2].clamp(
      -4.0,
      4.0,
    );
  }
  final transformedNext = _transformForStitchComparison(
    next,
    targetWidth: targetWidth,
    scale: scale,
    rotationDegrees: rotationDegrees,
  );
  final placements = <double>[
    for (var index = 0; index < previousAnchors.length; index++)
      previousAnchors[index] * previous.height -
          nextAnchors[index] * transformedNext.height,
  ]..sort();
  final placement = placements[placements.length ~/ 2];
  final overlap = (previous.height - placement).round();
  final minOverlap = math.max(24, (previous.height * .04).round());
  final maxOverlap = math.min(
    previous.height - 24,
    (previous.height * .68).round(),
  );
  if (overlap < minOverlap || overlap > maxOverlap) return null;
  var horizontalOffset = 0;
  if (evidence.previousAnchorCentersX.length == previousAnchors.length &&
      evidence.nextAnchorCentersX.length == nextAnchors.length) {
    final offsets = <double>[
      for (var index = 0; index < previousAnchors.length; index++)
        evidence.nextAnchorCentersX[index] * transformedNext.width -
            evidence.previousAnchorCentersX[index] * previous.width,
    ]..sort();
    horizontalOffset = offsets[offsets.length ~/ 2].round().clamp(
      -(targetWidth * .16).round(),
      (targetWidth * .16).round(),
    );
  }
  final visualScore = _overlapDifference(
    previous: previous,
    next: transformedNext,
    pixels: overlap,
    horizontalOffset: horizontalOffset,
    nextYOffset: 0,
  );
  final visualConfidence = (1 - visualScore / 64).clamp(0.0, 1.0);
  // Geometry places the frames; positioned OCR identifies the complete
  // matched text block. Crop through that block so its final row cannot
  // survive a second time below the seam.
  final seamSkipPixels = receiptTextCoveredSeamSkipPixels(
    geometricOverlapPixels: overlap,
    nextImageHeight: transformedNext.height,
    nextMatchedBlockEnd: evidence.nextOverlapEnd,
  );
  return _ReceiptOverlapMatch(
    pixels: overlap,
    nextSkipPixels: seamSkipPixels,
    nextXOffsetPixels: horizontalOffset,
    nextTopOffsetPixels: 0,
    // OCR confidence is evaluated independently by the fused acceptance gate.
    // This field must remain image evidence or text would be counted twice.
    confidence: visualConfidence,
    nextImage: transformedNext,
    scaleCorrection: scale,
    rotationCorrectionDegrees: rotationDegrees,
  );
}
