part of 'receipt_stitch_text_evidence.dart';

({
  bool available,
  bool isContradictory,
  double confidence,
  double previousStart,
  double nextEnd,
  double nextContinuationStart,
  double nextContinuationEnd,
  List<double> previousCenters,
  List<double> nextCenters,
  List<double> previousCentersX,
  List<double> nextCentersX,
  List<double> previousWidths,
  List<double> nextWidths,
  List<double> previousAngles,
  List<double> nextAngles,
})
_receiptStitchPositionEvidence({
  required ReceiptStitchTextEvidence previous,
  required ReceiptStitchTextEvidence next,
  required int previousStart,
  required int nextStart,
  required int count,
}) {
  // Matching indexes address normalized, nonempty text. Keep coordinates tied
  // to those same lines when OCR emits blank or punctuation-only detections.
  final previousPositioned = previous.positionedLines
      .where((line) => _normalizeReceiptStitchLine(line.text).isNotEmpty)
      .toList(growable: false);
  final nextPositioned = next.positionedLines
      .where((line) => _normalizeReceiptStitchLine(line.text).isNotEmpty)
      .toList(growable: false);
  if (!previous.hasPositionedLines || !next.hasPositionedLines) {
    return (
      available: false,
      isContradictory: false,
      confidence: 0.0,
      previousStart: 0.0,
      nextEnd: 0.0,
      nextContinuationStart: 0.0,
      nextContinuationEnd: 0.0,
      previousCenters: const <double>[],
      nextCenters: const <double>[],
      previousCentersX: const <double>[],
      nextCentersX: const <double>[],
      previousWidths: const <double>[],
      nextWidths: const <double>[],
      previousAngles: const <double>[],
      nextAngles: const <double>[],
    );
  }
  if (previousStart < 0 ||
      nextStart < 0 ||
      previousStart + count > previousPositioned.length ||
      nextStart + count > nextPositioned.length) {
    return (
      available: false,
      isContradictory: false,
      confidence: 0.0,
      previousStart: 0.0,
      nextEnd: 0.0,
      nextContinuationStart: 0.0,
      nextContinuationEnd: 0.0,
      previousCenters: const <double>[],
      nextCenters: const <double>[],
      previousCentersX: const <double>[],
      nextCentersX: const <double>[],
      previousWidths: const <double>[],
      nextWidths: const <double>[],
      previousAngles: const <double>[],
      nextAngles: const <double>[],
    );
  }
  final previousLines = previousPositioned.sublist(
    previousStart,
    previousStart + count,
  );
  final nextLines = nextPositioned.sublist(nextStart, nextStart + count);
  final previousFirst = previousLines.first;
  final previousLast = previousLines.last;
  final nextFirst = nextLines.first;
  final nextLast = nextLines.last;
  final nextContinuation = _nextReceiptTextBandAfter(
    next.positionedLines,
    nextLast.bottom,
  );
  final contradictory = previousLast.centerY < .25 && nextFirst.centerY > .75;
  final edgeProximity =
      (previousLast.bottom.clamp(0.0, 1.0) +
          (1 - nextFirst.top.clamp(0.0, 1.0))) /
      2;
  final previousSpan = (previousLast.bottom - previousFirst.top).abs();
  final nextSpan = (nextLast.bottom - nextFirst.top).abs();
  final spanCompatibility = (1 - (previousSpan - nextSpan).abs()).clamp(
    0.0,
    1.0,
  );
  var orderCompatibility = 1.0;
  for (var index = 1; index < count; index++) {
    if (previousLines[index].centerY <= previousLines[index - 1].centerY ||
        nextLines[index].centerY <= nextLines[index - 1].centerY) {
      orderCompatibility = 0;
      break;
    }
  }
  final confidence =
      (edgeProximity * .55 + spanCompatibility * .25 + orderCompatibility * .20)
          .clamp(0.0, 1.0);
  return (
    available: true,
    isContradictory: contradictory,
    confidence: confidence,
    previousStart: previousFirst.top.clamp(0.0, 1.0),
    nextEnd: nextLast.bottom.clamp(0.0, 1.0),
    nextContinuationStart: nextContinuation.start,
    nextContinuationEnd: nextContinuation.end,
    previousCenters: [for (final line in previousLines) line.centerY],
    nextCenters: [for (final line in nextLines) line.centerY],
    previousCentersX: [for (final line in previousLines) line.centerX],
    nextCentersX: [for (final line in nextLines) line.centerX],
    previousWidths: [for (final line in previousLines) line.width],
    nextWidths: [for (final line in nextLines) line.width],
    previousAngles: [for (final line in previousLines) line.angleDegrees],
    nextAngles: [for (final line in nextLines) line.angleDegrees],
  );
}

({double start, double end}) _nextReceiptTextBandAfter(
  List<ReceiptStitchTextLineEvidence> lines,
  double matchedEnd,
) {
  final following =
      lines
          .where((line) => line.centerY > matchedEnd + .002)
          .toList(growable: false)
        ..sort((left, right) => left.top.compareTo(right.top));
  if (following.isEmpty) return (start: 0.0, end: 0.0);
  final first = following.first;
  var bandEnd = first.bottom;
  for (final line in following.skip(1)) {
    if (line.top > bandEnd + .006) break;
    bandEnd = math.max(bandEnd, line.bottom);
  }
  return (start: first.top.clamp(0.0, 1.0), end: bandEnd.clamp(0.0, 1.0));
}
