part of 'receipt_image_processor.dart';

_ReceiptOverlapMatch _bestScaleTolerantVerticalOverlap({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  int comparisonWidth = 400,
  int retryComparisonWidth = 320,
  bool allowUprightFastPath = false,
  int? horizontalOffsetHint,
}) {
  final safeComparisonWidth = comparisonWidth.clamp(240, 480).toInt();
  final safeRetryComparisonWidth = retryComparisonWidth
      .clamp(200, safeComparisonWidth)
      .toInt();
  final primaryMatch = _bestScaleTolerantVerticalOverlapAtWidth(
    previous: previous,
    next: next,
    targetWidth: targetWidth,
    comparisonWidth: safeComparisonWidth,
    allowUprightFastPath: allowUprightFastPath,
    horizontalOffsetHint: horizontalOffsetHint,
  );
  if (_stitchMatchHasVisualCorroboration(previous, primaryMatch) &&
      primaryMatch.nextTopOffsetPixels <= primaryMatch.pixels) {
    return primaryMatch;
  }
  final detailRetry = _bestScaleTolerantVerticalOverlapAtWidth(
    previous: previous,
    next: next,
    targetWidth: targetWidth,
    comparisonWidth: safeRetryComparisonWidth,
    allowUprightFastPath: allowUprightFastPath,
    horizontalOffsetHint: horizontalOffsetHint,
  );
  return _strongerCorroboratedStitchMatch(
    previous: previous,
    primary: primaryMatch,
    retry: detailRetry,
  );
}

_ReceiptOverlapMatch _bestScaleTolerantVerticalOverlapAtWidth({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  required int comparisonWidth,
  required bool allowUprightFastPath,
  int? horizontalOffsetHint,
}) {
  final sampleWidth = math.min(
    comparisonWidth,
    math.min(previous.width, next.width),
  );
  final previousSample = previous.width == sampleWidth
      ? previous
      : img.copyResize(previous, width: sampleWidth);
  final nextSample = next.width == sampleWidth
      ? next
      : img.copyResize(next, width: sampleWidth);
  final sampleHorizontalOffsetHint = horizontalOffsetHint == null
      ? null
      : (horizontalOffsetHint * sampleWidth / targetWidth).round();
  final searchBudget = _ReceiptStitchSearchBudget.forSampleWidth(sampleWidth);
  final uprightFastPath = allowUprightFastPath
      ? _uprightReceiptOverlapFastPath(
          previous: previous,
          next: next,
          previousSample: previousSample,
          nextSample: nextSample,
          targetWidth: targetWidth,
          sampleWidth: sampleWidth,
          horizontalOffsetHint: sampleHorizontalOffsetHint,
        )
      : null;
  if (uprightFastPath != null) return uprightFastPath;
  final candidates = <_ReceiptStitchCandidate>[];
  for (final scale in searchBudget.scales) {
    final candidateImage = _transformForStitchComparison(
      nextSample,
      targetWidth: sampleWidth,
      scale: scale,
      rotationDegrees: 0,
    );
    final match = _bestVerticalOverlap(
      previous: previousSample,
      next: candidateImage,
      horizontalOffsetHint: sampleHorizontalOffsetHint,
    );
    final scalePenalty = (scale - 1).abs() * .45;
    candidates.add(
      _ReceiptStitchCandidate(
        pixels: match.pixels,
        nextSkipPixels: match.nextSkipPixels,
        nextXOffsetPixels: match.nextXOffsetPixels,
        confidence: (match.confidence - scalePenalty).clamp(0.0, 1.0),
        scaleCorrection: scale,
        sampleHeight: candidateImage.height,
        sampleWidth: candidateImage.width,
      ),
    );
  }
  candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
  final baseScaleCandidate = candidates.firstWhere(
    (candidate) => (candidate.scaleCorrection - 1).abs() < .001,
  );
  final bestUnrotatedCandidate = candidates.first;
  final selectedUnrotatedCandidate =
      (bestUnrotatedCandidate.scaleCorrection - 1).abs() >= .03 &&
          bestUnrotatedCandidate.confidence <
              baseScaleCandidate.confidence + .05
      ? baseScaleCandidate
      : bestUnrotatedCandidate;
  // A continuity-proven upright match already meets the same safe acceptance
  // floor used by the final proof gate. Avoid dozens of rotation/perspective
  // resamples unless base geometry cannot prove the overlap.
  if (selectedUnrotatedCandidate.confidence >= .49 &&
      _stitchCandidateHasVerifiedGeometry(
        candidate: selectedUnrotatedCandidate,
        previous: previousSample,
        next: nextSample,
        targetWidth: sampleWidth,
      )) {
    return _materializeStitchCandidate(
      candidate: selectedUnrotatedCandidate,
      previousHeight: previous.height,
      next: next,
      targetWidth: targetWidth,
    );
  }

  final rotationCandidates = candidates
      .take(searchBudget.rotationBaseCount)
      .toList(growable: false);
  for (final base in rotationCandidates) {
    for (final rotationDegrees in searchBudget.rotations) {
      final candidateImage = _transformForStitchComparison(
        nextSample,
        targetWidth: sampleWidth,
        scale: base.scaleCorrection,
        rotationDegrees: rotationDegrees,
      );
      final match = _bestVerticalOverlap(
        previous: previousSample,
        next: candidateImage,
        horizontalOffsetHint: sampleHorizontalOffsetHint,
      );
      final scalePenalty = (base.scaleCorrection - 1).abs() * .45;
      final rotationPenalty = rotationDegrees.abs() * .025;
      candidates.add(
        _ReceiptStitchCandidate(
          pixels: match.pixels,
          nextSkipPixels: match.nextSkipPixels,
          nextXOffsetPixels: match.nextXOffsetPixels,
          confidence: (match.confidence - scalePenalty - rotationPenalty).clamp(
            0.0,
            1.0,
          ),
          scaleCorrection: base.scaleCorrection,
          rotationCorrectionDegrees: rotationDegrees,
          sampleHeight: candidateImage.height,
          sampleWidth: candidateImage.width,
        ),
      );
    }
  }
  candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
  final bestCandidate = candidates.first;
  // A tiny score change from resampling is not evidence that an upright
  // receipt needs rotation. Applying it can crop the derived proof and hide
  // its leading merchant/date rows. Require a material improvement before
  // accepting a rotation correction.
  var selectedCandidate =
      bestCandidate.rotationCorrectionDegrees.abs() >= .001 &&
          bestCandidate.confidence <
              selectedUnrotatedCandidate.confidence + .065
      ? selectedUnrotatedCandidate
      : bestCandidate;
  final perspectiveBaseline = selectedCandidate;
  final perspectiveBases = candidates
      .take(searchBudget.perspectiveBaseCount)
      .toList(growable: false);
  for (final base in perspectiveBases) {
    for (final correction in searchBudget.perspectiveCorrections) {
      final candidateImage = _transformForStitchComparison(
        nextSample,
        targetWidth: sampleWidth,
        scale: base.scaleCorrection,
        rotationDegrees: base.rotationCorrectionDegrees,
        perspectiveCorrection: correction,
      );
      final match = _bestVerticalOverlap(
        previous: previousSample,
        next: candidateImage,
        horizontalOffsetHint: sampleHorizontalOffsetHint,
      );
      final scalePenalty = (base.scaleCorrection - 1).abs() * .45;
      final rotationPenalty = base.rotationCorrectionDegrees.abs() * .025;
      final perspectivePenalty = correction.abs() * .35;
      candidates.add(
        _ReceiptStitchCandidate(
          pixels: match.pixels,
          nextSkipPixels: match.nextSkipPixels,
          nextXOffsetPixels: match.nextXOffsetPixels,
          confidence:
              (match.confidence -
                      scalePenalty -
                      rotationPenalty -
                      perspectivePenalty)
                  .clamp(0.0, 1.0),
          scaleCorrection: base.scaleCorrection,
          rotationCorrectionDegrees: base.rotationCorrectionDegrees,
          perspectiveCorrection: correction,
          sampleHeight: candidateImage.height,
          sampleWidth: candidateImage.width,
        ),
      );
    }
  }
  candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
  final perspectiveCandidate = candidates.first;
  if (perspectiveCandidate.perspectiveCorrection.abs() >= .001 &&
      perspectiveCandidate.confidence >=
          perspectiveBaseline.confidence + .055) {
    selectedCandidate = perspectiveCandidate;
  }
  if ((selectedCandidate.scaleCorrection - 1).abs() >= .03 &&
      selectedCandidate.confidence < baseScaleCandidate.confidence + .05) {
    selectedCandidate = baseScaleCandidate;
  }
  selectedCandidate = _preferContinuityBackedStitchCandidate(
    candidates: candidates,
    fallback: selectedCandidate,
    previous: previousSample,
    next: nextSample,
    targetWidth: sampleWidth,
    candidateLimit: searchBudget.continuityCandidateCount,
  );
  return _materializeStitchCandidate(
    candidate: selectedCandidate,
    previousHeight: previous.height,
    next: next,
    targetWidth: targetWidth,
  );
}

bool _stitchCandidateHasVerifiedGeometry({
  required _ReceiptStitchCandidate candidate,
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
}) {
  final match = _materializeStitchCandidate(
    candidate: candidate,
    previousHeight: previous.height,
    next: next,
    targetWidth: targetWidth,
  );
  final continuity = _receiptOverlapContinuityEvidence(
    previous: previous,
    match: match,
  );
  final geometry = _receiptOverlapGeometryEvidence(
    previous: previous,
    match: match,
  );
  return continuity.isProven &&
      _receiptGeometryEvidenceSupportsCandidate(geometry);
}

_ReceiptStitchCandidate _preferContinuityBackedStitchCandidate({
  required List<_ReceiptStitchCandidate> candidates,
  required _ReceiptStitchCandidate fallback,
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  required int candidateLimit,
}) {
  var selected = fallback;
  final fallbackMatch = _materializeStitchCandidate(
    candidate: fallback,
    previousHeight: previous.height,
    next: next,
    targetWidth: targetWidth,
  );
  final fallbackContinuity = _receiptOverlapContinuityEvidence(
    previous: previous,
    match: fallbackMatch,
  );
  final fallbackGeometry = _receiptOverlapGeometryEvidence(
    previous: previous,
    match: fallbackMatch,
  );
  var selectedHasGeometry = _receiptGeometryEvidenceSupportsCandidate(
    fallbackGeometry,
  );
  var selectedContinuityScore = fallbackContinuity.isProven
      ? _stitchCandidateEvidenceScore(
          candidate: fallback,
          continuity: fallbackContinuity,
          geometry: fallbackGeometry,
        )
      : -1.0;
  final minimumConfidence = math.max(.44, fallback.confidence - .14);
  final continuityCandidates = <_ReceiptStitchCandidate>{
    ...candidates.take(candidateLimit),
    ...candidates.where(
      (candidate) =>
          candidate.rotationCorrectionDegrees.abs() < .001 &&
          candidate.perspectiveCorrection.abs() < .001,
    ),
  };
  for (final candidate in continuityCandidates) {
    if (candidate.confidence < minimumConfidence) continue;
    final match = _materializeStitchCandidate(
      candidate: candidate,
      previousHeight: previous.height,
      next: next,
      targetWidth: targetWidth,
    );
    final continuity = _receiptOverlapContinuityEvidence(
      previous: previous,
      match: match,
    );
    if (!continuity.isProven) continue;
    final geometry = _receiptOverlapGeometryEvidence(
      previous: previous,
      match: match,
    );
    final candidateHasGeometry = _receiptGeometryEvidenceSupportsCandidate(
      geometry,
    );
    if (selectedHasGeometry && !candidateHasGeometry) continue;
    final score = _stitchCandidateEvidenceScore(
      candidate: candidate,
      continuity: continuity,
      geometry: geometry,
    );
    if (candidateHasGeometry && !selectedHasGeometry) {
      selected = candidate;
      selectedHasGeometry = true;
      selectedContinuityScore = score;
      continue;
    }
    if (score > selectedContinuityScore) {
      selected = candidate;
      selectedHasGeometry = candidateHasGeometry;
      selectedContinuityScore = score;
    }
  }
  return selected;
}

double _stitchCandidateEvidenceScore({
  required _ReceiptStitchCandidate candidate,
  required ({
    bool isProven,
    double correlation,
    int matchingBands,
    int detailedBands,
  })
  continuity,
  required ({
    bool isProven,
    double correlation,
    int detailedCells,
    int matchingCells,
  })
  geometry,
}) {
  final geometryShare = geometry.detailedCells == 0
      ? 0.0
      : geometry.matchingCells / geometry.detailedCells;
  return candidate.confidence +
      continuity.correlation * .10 +
      continuity.matchingBands * .006 +
      (_receiptGeometryEvidenceSupportsCandidate(geometry) ? .12 : 0) +
      geometry.correlation.clamp(0.0, 1.0) * .10 +
      geometryShare * .04;
}

_ReceiptOverlapMatch _fixedScaleVerticalOverlap({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  int comparisonWidth = 400,
  int? horizontalOffsetHint,
}) {
  final safeComparisonWidth = comparisonWidth.clamp(240, 480).toInt();
  final sampleWidth = math.min(
    safeComparisonWidth,
    math.min(previous.width, next.width),
  );
  final previousSample = previous.width == sampleWidth
      ? previous
      : img.copyResize(previous, width: sampleWidth);
  final nextSample = next.width == sampleWidth
      ? next
      : img.copyResize(next, width: sampleWidth);
  final match = _bestVerticalOverlap(
    previous: previousSample,
    next: nextSample,
    horizontalOffsetHint: horizontalOffsetHint == null
        ? null
        : (horizontalOffsetHint * sampleWidth / targetWidth).round(),
  );
  return _materializeStitchCandidate(
    candidate: _ReceiptStitchCandidate(
      pixels: match.pixels,
      nextSkipPixels: match.nextSkipPixels,
      nextXOffsetPixels: match.nextXOffsetPixels,
      confidence: match.confidence,
      scaleCorrection: 1,
      sampleHeight: nextSample.height,
      sampleWidth: nextSample.width,
    ),
    previousHeight: previous.height,
    next: next,
    targetWidth: targetWidth,
  );
}
