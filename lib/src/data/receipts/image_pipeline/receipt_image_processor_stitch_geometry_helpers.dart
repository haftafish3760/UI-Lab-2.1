part of 'receipt_image_processor.dart';

({bool isProven, double correlation, int detailedCells, int matchingCells})
_receiptOverlapGeometryEvidence({
  required img.Image previous,
  required _ReceiptOverlapMatch match,
}) {
  final next = match.nextImage;
  final overlap = math.min(
    match.pixels,
    math.min(previous.height, next.height - match.nextTopOffsetPixels),
  );
  final width = math.min(previous.width, next.width);
  if (overlap < 72 || width < 96) {
    return (
      isProven: false,
      correlation: 0,
      detailedCells: 0,
      matchingCells: 0,
    );
  }

  const columns = 4;
  const rows = 3;
  var detailedCells = 0;
  var matchingCells = 0;
  var correlationTotal = 0.0;
  final left = width ~/ 14;
  final right = width * 13 ~/ 14;
  final usableWidth = math.max(1, right - left);
  for (var row = 0; row < rows; row++) {
    final yStart = (overlap * row / rows).round();
    final yEnd = (overlap * (row + 1) / rows).round();
    for (var column = 0; column < columns; column++) {
      final xStart = left + (usableWidth * column / columns).round();
      final xEnd = left + (usableWidth * (column + 1) / columns).round();
      var evidence = (hasDetail: false, correlation: -1.0);
      // The coarse matcher intentionally works on a small image. Permit only
      // a tiny local correction here so resampling/rounding does not erase an
      // otherwise coherent two-dimensional match.
      for (final yAdjustment in const [-2, 0, 2]) {
        for (final xAdjustment in const [-1, 0, 1]) {
          final candidate = _receiptOverlapGeometryCellCorrelation(
            previous: previous,
            next: next,
            previousStartY: previous.height - overlap + yStart,
            nextStartY: match.nextTopOffsetPixels + yStart + yAdjustment,
            xStart: xStart,
            xEnd: xEnd,
            height: math.max(1, yEnd - yStart),
            horizontalOffset: match.nextXOffsetPixels + xAdjustment,
          );
          if (candidate.hasDetail &&
              (!evidence.hasDetail ||
                  candidate.correlation > evidence.correlation)) {
            evidence = candidate;
          }
        }
      }
      if (!evidence.hasDetail) continue;
      detailedCells++;
      correlationTotal += evidence.correlation;
      if (evidence.correlation >= .55) matchingCells++;
    }
  }
  final average = detailedCells == 0 ? 0.0 : correlationTotal / detailedCells;
  final requiredMatches = math.max(5, (detailedCells * .75).ceil());
  return (
    isProven:
        detailedCells >= 6 &&
        matchingCells >= requiredMatches &&
        average >= .78,
    correlation: average.clamp(-1.0, 1.0),
    detailedCells: detailedCells,
    matchingCells: matchingCells,
  );
}

bool _receiptGeometryEvidenceSupportsCandidate(
  ({bool isProven, double correlation, int detailedCells, int matchingCells})
  evidence,
) {
  return evidence.isProven ||
      (evidence.detailedCells >= 6 &&
          evidence.matchingCells >= 5 &&
          evidence.correlation >= .72);
}

({bool hasDetail, double correlation}) _receiptOverlapGeometryCellCorrelation({
  required img.Image previous,
  required img.Image next,
  required int previousStartY,
  required int nextStartY,
  required int xStart,
  required int xEnd,
  required int height,
  required int horizontalOffset,
}) {
  final previousValues = <double>[];
  final nextValues = <double>[];
  final stepX = math.max(4, (xEnd - xStart) ~/ 12);
  final stepY = math.max(3, height ~/ 14);
  for (var dy = 2; dy < height - 2; dy += stepY) {
    final previousY = (previousStartY + dy).clamp(2, previous.height - 3);
    final nextY = (nextStartY + dy).clamp(2, next.height - 3);
    for (var x = xStart + 2; x < xEnd - 2; x += stepX) {
      final nextX = x + horizontalOffset;
      if (x < 2 ||
          x >= previous.width - 2 ||
          nextX < 2 ||
          nextX >= next.width - 2) {
        continue;
      }
      previousValues.add(_receiptLocalInkResponse(previous, x, previousY));
      nextValues.add(_receiptLocalInkResponse(next, nextX, nextY));
    }
  }
  if (previousValues.length < 36) return (hasDetail: false, correlation: 0);
  final previousStats = _overlapValueStats(previousValues);
  final nextStats = _overlapValueStats(nextValues);
  if (previousStats.variance < 7 || nextStats.variance < 7) {
    return (hasDetail: false, correlation: 0);
  }
  return (
    hasDetail: true,
    correlation: _receiptProfileCorrelation(
      previousValues,
      nextValues,
      shift: 0,
    ),
  );
}

double _receiptLocalInkResponse(img.Image image, int x, int y) {
  return _luma(image.getPixel(x, y));
}
