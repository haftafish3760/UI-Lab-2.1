part of 'receipt_image_processor.dart';

typedef _ReceiptGeometryChoice = ({
  double score,
  int pixels,
  int horizontalOffset,
  int nextYOffset,
  double geometryScore,
});

_ReceiptGeometryChoice _refineReceiptGeometryChoice({
  required img.Image previous,
  required img.Image next,
  required _ReceiptGeometryChoice initial,
  required int minPixels,
  required int maxPixels,
}) {
  var selected = initial;
  final candidates =
      <({double score, int pixels, int horizontalOffset, int nextYOffset})>[];
  for (
    var pixels = initial.pixels - 5;
    pixels <= initial.pixels + 5;
    pixels++
  ) {
    if (pixels < minPixels || pixels > maxPixels) continue;
    for (
      var horizontalOffset = initial.horizontalOffset - 1;
      horizontalOffset <= initial.horizontalOffset + 1;
      horizontalOffset++
    ) {
      for (
        var nextYOffset = initial.nextYOffset - 2;
        nextYOffset <= initial.nextYOffset + 2;
        nextYOffset++
      ) {
        if (nextYOffset < 0 || nextYOffset + pixels >= next.height) continue;
        final visualScore = _overlapDifference(
          previous: previous,
          next: next,
          pixels: pixels,
          horizontalOffset: horizontalOffset,
          nextYOffset: nextYOffset,
        );
        final score =
            visualScore +
            (horizontalOffset.abs() / math.max(1, previous.width) * 80) +
            _stitchNextTopOffsetPenalty(
              height: next.height,
              overlapPixels: pixels,
              nextTopOffset: nextYOffset,
            );
        candidates.add((
          score: score,
          pixels: pixels,
          horizontalOffset: horizontalOffset,
          nextYOffset: nextYOffset,
        ));
      }
    }
  }
  candidates.sort((a, b) => a.score.compareTo(b.score));
  for (final candidate in candidates.take(10)) {
    final match = _ReceiptOverlapMatch(
      pixels: candidate.pixels,
      nextSkipPixels: candidate.pixels + candidate.nextYOffset,
      nextXOffsetPixels: candidate.horizontalOffset,
      nextTopOffsetPixels: candidate.nextYOffset,
      confidence: 0,
      nextImage: next,
    );
    final geometry = _receiptOverlapGeometryEvidence(
      previous: previous,
      match: match,
    );
    if (!_receiptGeometryEvidenceSupportsCandidate(geometry)) continue;
    final matchShare =
        geometry.matchingCells / math.max(1, geometry.detailedCells);
    final geometryScore =
        candidate.score - geometry.correlation * 16 - matchShare * 5;
    if (geometryScore < selected.geometryScore - 1.0 ||
        ((geometryScore - selected.geometryScore).abs() <= 1.0 &&
            candidate.pixels > selected.pixels)) {
      selected = (
        score: candidate.score,
        pixels: candidate.pixels,
        horizontalOffset: candidate.horizontalOffset,
        nextYOffset: candidate.nextYOffset,
        geometryScore: geometryScore,
      );
    }
  }
  return selected;
}
