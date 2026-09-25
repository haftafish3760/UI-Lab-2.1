part of 'receipt_stitch_text_evidence.dart';

ReceiptStitchTextPairEvidence matchReceiptStitchTextOverlap(
  ReceiptStitchTextEvidence previous,
  ReceiptStitchTextEvidence next,
) {
  final previousLines = previous.normalizedLines;
  final nextLines = next.normalizedLines;
  if (previousLines.isEmpty || nextLines.isEmpty) {
    return const ReceiptStitchTextPairEvidence.none();
  }
  var best = const ReceiptStitchTextPairEvidence.none();
  final previousCounts = _receiptLineCounts(previousLines);
  final nextCounts = _receiptLineCounts(nextLines);
  final maximumLines = _minInt(
    8,
    _minInt(previousLines.length, nextLines.length),
  );
  final maximumTailOffset = _minInt(3, previousLines.length - 1);
  final maximumHeadOffset = _minInt(3, nextLines.length - 1);
  for (var tailOffset = 0; tailOffset <= maximumTailOffset; tailOffset++) {
    for (var headOffset = 0; headOffset <= maximumHeadOffset; headOffset++) {
      final availablePrevious = previousLines.length - tailOffset;
      final availableNext = nextLines.length - headOffset;
      final lineLimit = _minInt(
        maximumLines,
        _minInt(availablePrevious, availableNext),
      );
      for (var count = 1; count <= lineLimit; count++) {
        final previousStart = availablePrevious - count;
        var total = 0.0;
        var weakest = 1.0;
        var distinctiveMatches = 0;
        var uniqueAnchors = 0;
        for (var line = 0; line < count; line++) {
          final left = previousLines[previousStart + line];
          final right = nextLines[headOffset + line];
          final similarity = _receiptStitchLineSimilarity(left, right);
          total += similarity;
          if (similarity < weakest) weakest = similarity;
          if (similarity >= .72 && _isDistinctiveReceiptLine(left)) {
            distinctiveMatches += 1;
            if (previousCounts[left] == 1 && nextCounts[right] == 1) {
              uniqueAnchors++;
            }
          }
        }
        final average = total / count;
        final enoughEvidence = count >= 2
            ? distinctiveMatches >= 1 && weakest >= .48
            : distinctiveMatches == 1 &&
                  average >= .94 &&
                  _isUniqueReceiptOverlapLine(previousLines[previousStart]);
        // Repeated purchase rows are not distinct alignment anchors. Image
        // geometry can still resolve them; text must not claim certainty.
        if (!enoughEvidence || uniqueAnchors < 2) continue;
        final position = _receiptStitchPositionEvidence(
          previous: previous,
          next: next,
          previousStart: previousStart,
          nextStart: headOffset,
          count: count,
        );
        if (position.isContradictory) continue;
        final coverageBonus = count <= 1 ? 0.0 : (count - 1) * .035;
        final offsetPenalty = (tailOffset + headOffset) * .025;
        final positionAdjustment = position.available
            ? (position.confidence - .5) * .12
            : 0.0;
        final confidence =
            (average + coverageBonus - offsetPenalty + positionAdjustment)
                .clamp(0.0, 1.0);
        final materiallyBetterConfidence = confidence > best.confidence + .025;
        final longerComparableMatch =
            count > best.matchedLineCount &&
            confidence >= best.confidence - .08;
        if (materiallyBetterConfidence ||
            longerComparableMatch ||
            (best.matchedLineCount == 0 && confidence > best.confidence)) {
          best = ReceiptStitchTextPairEvidence(
            confidence: confidence,
            matchedLineCount: count,
            previousTailOffset: tailOffset,
            nextHeadOffset: headOffset,
            positionalConfidence: position.confidence,
            hasPositionalEvidence: position.available,
            previousOverlapStart: position.previousStart,
            nextOverlapEnd: position.nextEnd,
            nextContinuationStart: position.nextContinuationStart,
            nextContinuationEnd: position.nextContinuationEnd,
            previousAnchorCenters: position.previousCenters,
            nextAnchorCenters: position.nextCenters,
            previousAnchorCentersX: position.previousCentersX,
            nextAnchorCentersX: position.nextCentersX,
            previousAnchorWidths: position.previousWidths,
            nextAnchorWidths: position.nextWidths,
            previousAnchorAngles: position.previousAngles,
            nextAnchorAngles: position.nextAngles,
          );
        }
      }
    }
  }
  final sparsePositionMatch = _matchSparsePositionedReceiptAnchors(
    previous,
    next,
  );
  if (sparsePositionMatch != null &&
      (sparsePositionMatch.confidence > best.confidence + .025 ||
          (sparsePositionMatch.matchedLineCount > best.matchedLineCount &&
              sparsePositionMatch.confidence >= best.confidence - .10) ||
          !best.isStrong)) {
    return sparsePositionMatch;
  }
  return best;
}

ReceiptStitchTextPairEvidence? _matchSparsePositionedReceiptAnchors(
  ReceiptStitchTextEvidence previous,
  ReceiptStitchTextEvidence next,
) {
  if (!previous.hasPositionedLines || !next.hasPositionedLines) return null;
  final previousCounts = _receiptLineCounts(previous.normalizedLines);
  final nextCounts = _receiptLineCounts(next.normalizedLines);
  final previousStart = previous.positionedLines.length > 72
      ? previous.positionedLines.length - 72
      : 0;
  final previousCandidates = <int>[
    for (
      var index = previousStart;
      index < previous.positionedLines.length;
      index++
    )
      if (previous.positionedLines[index].centerY >= .30) index,
  ];
  final nextCandidates = <int>[
    for (
      var index = 0;
      index < next.positionedLines.length && index < 72;
      index++
    )
      if (next.positionedLines[index].centerY <= .70) index,
  ];
  final candidates =
      <({int previousIndex, int nextIndex, double similarity})>[];
  for (final previousIndex in previousCandidates) {
    final previousText = _normalizeReceiptStitchLine(
      previous.positionedLines[previousIndex].text,
    );
    if (!_isDistinctiveReceiptLine(previousText) ||
        previousCounts[previousText] != 1)
      continue;
    for (final nextIndex in nextCandidates) {
      final nextText = _normalizeReceiptStitchLine(
        next.positionedLines[nextIndex].text,
      );
      if (!_isDistinctiveReceiptLine(nextText) || nextCounts[nextText] != 1) {
        continue;
      }
      final similarity = _receiptStitchLineSimilarity(previousText, nextText);
      if (similarity >= .68) {
        candidates.add((
          previousIndex: previousIndex,
          nextIndex: nextIndex,
          similarity: similarity,
        ));
      }
    }
  }
  if (candidates.length < 2) return null;
  candidates.sort((left, right) {
    final previousOrder = left.previousIndex.compareTo(right.previousIndex);
    return previousOrder != 0
        ? previousOrder
        : left.nextIndex.compareTo(right.nextIndex);
  });
  final lengths = List<int>.filled(candidates.length, 1);
  final scores = [for (final candidate in candidates) candidate.similarity];
  final parents = List<int>.filled(candidates.length, -1);
  var bestIndex = 0;
  for (var index = 0; index < candidates.length; index++) {
    for (var prior = 0; prior < index; prior++) {
      if (candidates[prior].previousIndex >= candidates[index].previousIndex ||
          candidates[prior].nextIndex >= candidates[index].nextIndex) {
        continue;
      }
      final candidateLength = lengths[prior] + 1;
      final candidateScore = scores[prior] + candidates[index].similarity;
      if (candidateLength > lengths[index] ||
          (candidateLength == lengths[index] &&
              candidateScore > scores[index])) {
        lengths[index] = candidateLength;
        scores[index] = candidateScore;
        parents[index] = prior;
      }
    }
    if (lengths[index] > lengths[bestIndex] ||
        (lengths[index] == lengths[bestIndex] &&
            scores[index] > scores[bestIndex])) {
      bestIndex = index;
    }
  }
  if (lengths[bestIndex] < 2) return null;
  final selected = <({int previousIndex, int nextIndex, double similarity})>[];
  for (var index = bestIndex; index >= 0; index = parents[index]) {
    selected.add(candidates[index]);
    if (parents[index] < 0) break;
  }
  final ordered = selected.reversed.toList(growable: false);
  final previousTexts = {
    for (final candidate in ordered)
      _normalizeReceiptStitchLine(
        previous.positionedLines[candidate.previousIndex].text,
      ),
  };
  final nextTexts = {
    for (final candidate in ordered)
      _normalizeReceiptStitchLine(
        next.positionedLines[candidate.nextIndex].text,
      ),
  };
  if (previousTexts.length < 2 || nextTexts.length < 2) return null;
  final previousLines = [
    for (final candidate in ordered)
      previous.positionedLines[candidate.previousIndex],
  ];
  final nextLines = [
    for (final candidate in ordered) next.positionedLines[candidate.nextIndex],
  ];
  final nextContinuation = _nextReceiptTextBandAfter(
    next.positionedLines,
    nextLines.last.bottom,
  );
  final averageSimilarity =
      ordered.fold<double>(0, (sum, item) => sum + item.similarity) /
      ordered.length;
  final edgeProximity =
      (previousLines.last.bottom + (1 - nextLines.first.top)) / 2;
  final previousSpan = previousLines.last.bottom - previousLines.first.top;
  final nextSpan = nextLines.last.bottom - nextLines.first.top;
  final spanCompatibility = (1 - (previousSpan - nextSpan).abs()).clamp(
    0.0,
    1.0,
  );
  final positionalConfidence = (edgeProximity * .62 + spanCompatibility * .38)
      .clamp(0.0, 1.0);
  final confidence =
      (averageSimilarity +
              math.min(.18, (ordered.length - 1) * .025) +
              (positionalConfidence - .5) * .10)
          .clamp(0.0, 1.0);
  return ReceiptStitchTextPairEvidence(
    confidence: confidence,
    matchedLineCount: ordered.length,
    previousTailOffset:
        previous.positionedLines.length - 1 - ordered.last.previousIndex,
    nextHeadOffset: ordered.first.nextIndex,
    positionalConfidence: positionalConfidence,
    hasPositionalEvidence: true,
    previousOverlapStart: previousLines.first.top.clamp(0.0, 1.0),
    nextOverlapEnd: nextLines.last.bottom.clamp(0.0, 1.0),
    nextContinuationStart: nextContinuation.start,
    nextContinuationEnd: nextContinuation.end,
    previousAnchorCenters: [for (final line in previousLines) line.centerY],
    nextAnchorCenters: [for (final line in nextLines) line.centerY],
    previousAnchorCentersX: [for (final line in previousLines) line.centerX],
    nextAnchorCentersX: [for (final line in nextLines) line.centerX],
    previousAnchorWidths: [for (final line in previousLines) line.width],
    nextAnchorWidths: [for (final line in nextLines) line.width],
    previousAnchorAngles: [for (final line in previousLines) line.angleDegrees],
    nextAnchorAngles: [for (final line in nextLines) line.angleDegrees],
    usesSparsePositionAnchors: true,
  );
}
