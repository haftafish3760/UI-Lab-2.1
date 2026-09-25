part of 'receipt_image_processor.dart';

_ReceiptOverlapMatch _preferVerifiedSequenceGuidedReceiptOverlap({
  required img.Image previous,
  required img.Image next,
  required _ReceiptOverlapMatch current,
  required ReceiptStitchPairResult? priorPair,
}) {
  if (priorPair == null ||
      _receiptOverlapGeometryEvidence(
        previous: previous,
        match: current,
      ).isProven) {
    return current;
  }
  return _verifiedSequenceGuidedReceiptOverlap(
        previous: previous,
        next: next,
        priorPair: priorPair,
      ) ??
      current;
}

_ReceiptOverlapMatch? _verifiedSequenceGuidedReceiptOverlap({
  required img.Image previous,
  required img.Image next,
  required ReceiptStitchPairResult priorPair,
}) {
  final referenceOverlap = priorPair.overlapPixels;
  if (referenceOverlap < 72) return null;
  final minimumOverlap = (math.min(previous.height, next.height) * .08)
      .round()
      .clamp(48, 320);
  final maximumOverlap = (math.min(previous.height, next.height) * .68)
      .round()
      .clamp(minimumOverlap + 1, 1800);
  final overlapStep = math.max(18, (referenceOverlap * .06).round());
  final overlapCandidates = <int>{
    for (final multiple in const [-1, 0, 1])
      (referenceOverlap + overlapStep * multiple).clamp(
        minimumOverlap,
        maximumOverlap,
      ),
  };
  final offsetUnit = math.max(12, (previous.width * .035).round());
  final horizontalCandidates = <int>{
    priorPair.horizontalOffsetPixels,
    -priorPair.horizontalOffsetPixels,
    0,
    -offsetUnit,
    offsetUnit,
  };
  final priorY = priorPair.verticalOffsetPixels.clamp(0, 320);
  final verticalCandidates = <int>{0, priorY, priorY ~/ 2};
  _ReceiptOverlapMatch? selected;
  var selectedScore = double.negativeInfinity;

  for (final overlap in overlapCandidates) {
    final visualCandidates =
        <({double score, int horizontalOffset, int verticalOffset})>[];
    for (final horizontalOffset in horizontalCandidates) {
      for (final verticalOffset in verticalCandidates) {
        if (verticalOffset + overlap >= next.height) continue;
        final score = _overlapDifference(
          previous: previous,
          next: next,
          pixels: overlap,
          horizontalOffset: horizontalOffset,
          nextYOffset: verticalOffset,
        );
        if (!score.isFinite) continue;
        visualCandidates.add((
          score: score,
          horizontalOffset: horizontalOffset,
          verticalOffset: verticalOffset,
        ));
      }
    }
    visualCandidates.sort((a, b) => a.score.compareTo(b.score));
    for (final candidate in visualCandidates.take(3)) {
      final match = _ReceiptOverlapMatch(
        pixels: overlap,
        nextSkipPixels: overlap + candidate.verticalOffset,
        nextXOffsetPixels: candidate.horizontalOffset,
        nextTopOffsetPixels: candidate.verticalOffset,
        confidence: 0,
        nextImage: next,
      );
      final geometry = _receiptOverlapGeometryEvidence(
        previous: previous,
        match: match,
      );
      if (!_receiptGeometryEvidenceSupportsCandidate(geometry)) continue;
      final matchingShare =
          geometry.matchingCells / math.max(1, geometry.detailedCells);
      final visualConfidence = (1 - candidate.score / 64).clamp(0.0, 1.0);
      final overlapDrift =
          (overlap - referenceOverlap).abs() / math.max(1, referenceOverlap);
      final evidenceScore =
          geometry.correlation * .58 +
          matchingShare * .27 +
          visualConfidence * .15 -
          overlapDrift * .08;
      if (evidenceScore <= selectedScore) continue;
      selectedScore = evidenceScore;
      selected = _ReceiptOverlapMatch(
        pixels: overlap,
        nextSkipPixels: overlap + candidate.verticalOffset,
        nextXOffsetPixels: candidate.horizontalOffset,
        nextTopOffsetPixels: candidate.verticalOffset,
        confidence: (visualConfidence * .55 + geometry.correlation * .45).clamp(
          0.0,
          1.0,
        ),
        nextImage: next,
      );
    }
  }
  return selected;
}
