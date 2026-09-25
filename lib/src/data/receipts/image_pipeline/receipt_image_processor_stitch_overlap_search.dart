part of 'receipt_image_processor.dart';

_ReceiptOverlapMatch _bestVerticalOverlap({
  required img.Image previous,
  required img.Image next,
  int? horizontalOffsetHint,
}) {
  final searchBudget = _ReceiptStitchSearchBudget.forSampleWidth(
    math.min(previous.width, next.width),
  );
  // A careful long-receipt capture can intentionally repeat well over half
  // of the prior frame. Search that bounded region, then let two-dimensional
  // geometry and the final fused acceptance gate decide whether removing the
  // repeated rows is safe.
  final maxOverlap = math.min(previous.height, next.height) * .68;
  final minOverlap = math.min(previous.height, next.height) * .08;
  final minPixels = minOverlap.round().clamp(48, 320);
  final maxPixels = maxOverlap.round().clamp(minPixels + 1, 1800);
  var bestPixels = 0;
  var bestScore = double.infinity;
  var secondBestScore = double.infinity;
  var bestHorizontalOffset = 0;
  var bestNextYOffset = 0;
  final offsetSeeds =
      <int, ({double score, int pixels, int horizontalOffset})>{};
  final geometryCandidates =
      <({double score, int pixels, int horizontalOffset, int nextYOffset})>[];
  final geometryCandidatesByOffsetBucket =
      <
        int,
        ({double score, int pixels, int horizontalOffset, int nextYOffset})
      >{};
  final geometryCandidatesByOverlapBucket =
      <
        int,
        ({double score, int pixels, int horizontalOffset, int nextYOffset})
      >{};
  final geometryCandidatesByHorizontalOffset =
      <
        int,
        List<
          ({double score, int pixels, int horizontalOffset, int nextYOffset})
        >
      >{};
  void trackGeometryCandidate({
    required double score,
    required int pixels,
    required int horizontalOffset,
    required int nextYOffset,
  }) {
    final candidate = (
      score: score,
      pixels: pixels,
      horizontalOffset: horizontalOffset,
      nextYOffset: nextYOffset,
    );
    geometryCandidates.add(candidate);
    geometryCandidates.sort((a, b) => a.score.compareTo(b.score));
    if (geometryCandidates.length > 10) geometryCandidates.removeLast();
    final bucket = nextYOffset ~/ 12;
    final bucketCandidate = geometryCandidatesByOffsetBucket[bucket];
    if (bucketCandidate == null || score < bucketCandidate.score) {
      geometryCandidatesByOffsetBucket[bucket] = candidate;
    }
    // Repeated item rows can give the wrong overlap length a much cleaner
    // one-dimensional score. Preserve one bounded candidate per materially
    // different overlap basin so two-dimensional geometry can still inspect
    // the real join, including the common zero-X case.
    final overlapBucket = pixels ~/ 48;
    final overlapCandidate = geometryCandidatesByOverlapBucket[overlapBucket];
    if (overlapCandidate == null || score < overlapCandidate.score) {
      geometryCandidatesByOverlapBucket[overlapBucket] = candidate;
    }
    if (horizontalOffset != 0) {
      final candidates = geometryCandidatesByHorizontalOffset.putIfAbsent(
        horizontalOffset,
        () => [],
      );
      final basinIndex = candidates.indexWhere(
        (existing) => (existing.pixels - pixels).abs() <= 36,
      );
      if (basinIndex < 0) {
        candidates.add(candidate);
      } else if (score < candidates[basinIndex].score) {
        candidates[basinIndex] = candidate;
      }
      candidates.sort((a, b) => a.score.compareTo(b.score));
      if (candidates.length > 3) candidates.removeRange(3, candidates.length);
    }
  }

  final horizontalOffsets = _stitchHorizontalOffsets(
    previous.width,
    searchBudget,
    horizontalOffsetHint: horizontalOffsetHint,
  );
  for (
    var pixels = minPixels;
    pixels <= maxPixels;
    pixels += searchBudget.coarseOverlapStep
  ) {
    final nextTopOffsets = _stitchNextTopOffsets(
      next.height,
      pixels,
      searchBudget,
    );
    for (final horizontalOffset in horizontalOffsets) {
      for (final nextYOffset in nextTopOffsets) {
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
        final offsetSeed = offsetSeeds[nextYOffset];
        if (offsetSeed == null || score < offsetSeed.score) {
          offsetSeeds[nextYOffset] = (
            score: score,
            pixels: pixels,
            horizontalOffset: horizontalOffset,
          );
        }
        trackGeometryCandidate(
          score: score,
          pixels: pixels,
          horizontalOffset: horizontalOffset,
          nextYOffset: nextYOffset,
        );
        if (_stitchCandidateBeatsCurrent(
          score: score,
          pixels: pixels,
          bestScore: bestScore,
          bestPixels: bestPixels,
        )) {
          secondBestScore = bestScore;
          bestScore = score;
          bestPixels = pixels;
          bestHorizontalOffset = horizontalOffset;
          bestNextYOffset = nextYOffset;
        } else if ((pixels - bestPixels).abs() > 36 &&
            score < secondBestScore) {
          secondBestScore = score;
        }
      }
    }
  }
  // Refine the continuation start as well as the overlap height. The coarse
  // start grid is deliberately small for device cost, but a two- or
  // three-sample miss can put narrow printed strokes out of phase and hide a
  // real overlap. Refining only each coarse offset's best local basin keeps
  // the extra work bounded instead of scanning every possible row.
  for (final entry in offsetSeeds.entries) {
    final seed = entry.value;
    for (
      var yDelta = -searchBudget.offsetRefinementRadius;
      yDelta <= searchBudget.offsetRefinementRadius;
      yDelta += searchBudget.offsetRefinementStep
    ) {
      final nextYOffset = entry.key + yDelta;
      if (nextYOffset < 0 || nextYOffset + minPixels >= next.height) continue;
      for (
        var pixels = seed.pixels - searchBudget.refinedOverlapRadius ~/ 2;
        pixels <= seed.pixels + searchBudget.refinedOverlapRadius ~/ 2;
        pixels += searchBudget.refinedOverlapStep
      ) {
        if (pixels < minPixels ||
            pixels > maxPixels ||
            nextYOffset + pixels >= next.height) {
          continue;
        }
        final visualScore = _overlapDifference(
          previous: previous,
          next: next,
          pixels: pixels,
          horizontalOffset: seed.horizontalOffset,
          nextYOffset: nextYOffset,
        );
        final score =
            visualScore +
            (seed.horizontalOffset.abs() / math.max(1, previous.width) * 80) +
            _stitchNextTopOffsetPenalty(
              height: next.height,
              overlapPixels: pixels,
              nextTopOffset: nextYOffset,
            );
        trackGeometryCandidate(
          score: score,
          pixels: pixels,
          horizontalOffset: seed.horizontalOffset,
          nextYOffset: nextYOffset,
        );
        if (_stitchCandidateBeatsCurrent(
          score: score,
          pixels: pixels,
          bestScore: bestScore,
          bestPixels: bestPixels,
        )) {
          secondBestScore = bestScore;
          bestScore = score;
          bestPixels = pixels;
          bestHorizontalOffset = seed.horizontalOffset;
          bestNextYOffset = nextYOffset;
        } else if ((pixels - bestPixels).abs() > 36 &&
            score < secondBestScore) {
          secondBestScore = score;
        }
      }
    }
  }
  final refinedStart = (bestPixels - searchBudget.refinedOverlapRadius).clamp(
    minPixels,
    maxPixels,
  );
  final refinedEnd = (bestPixels + searchBudget.refinedOverlapRadius).clamp(
    minPixels,
    maxPixels,
  );
  for (
    var pixels = refinedStart;
    pixels <= refinedEnd;
    pixels += searchBudget.refinedOverlapStep
  ) {
    final nextTopOffsets = _stitchNextTopOffsets(
      next.height,
      pixels,
      searchBudget,
    );
    for (final horizontalOffset in horizontalOffsets) {
      for (final nextYOffset in nextTopOffsets) {
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
        trackGeometryCandidate(
          score: score,
          pixels: pixels,
          horizontalOffset: horizontalOffset,
          nextYOffset: nextYOffset,
        );
        if (_stitchCandidateBeatsCurrent(
          score: score,
          pixels: pixels,
          bestScore: bestScore,
          bestPixels: bestPixels,
        )) {
          secondBestScore = bestScore;
          bestScore = score;
          bestPixels = pixels;
          bestHorizontalOffset = horizontalOffset;
          bestNextYOffset = nextYOffset;
        } else if ((pixels - bestPixels).abs() > 36 &&
            score < secondBestScore) {
          secondBestScore = score;
        }
      }
    }
  }
  // Coarse X samples keep the first pass affordable, but the selected seam
  // must carry the actual horizontal coordinate. Geometry-only local
  // corrections cannot be composed later, so refine a bounded set of the
  // strongest X basins before geometry scoring.
  final horizontalRefinementSeeds =
      <({double score, int pixels, int horizontalOffset, int nextYOffset})>{
        ...geometryCandidates.take(4),
        ...geometryCandidatesByHorizontalOffset.values.expand(
          (candidates) => candidates.take(2),
        ),
      };
  final maximumHorizontalOffset = horizontalOffsets
      .map((offset) => offset.abs())
      .fold(0, math.max);
  for (final seed in horizontalRefinementSeeds) {
    for (var delta = -8; delta <= 8; delta++) {
      final horizontalOffset = seed.horizontalOffset + delta;
      if (horizontalOffset.abs() > maximumHorizontalOffset) continue;
      final visualScore = _overlapDifference(
        previous: previous,
        next: next,
        pixels: seed.pixels,
        horizontalOffset: horizontalOffset,
        nextYOffset: seed.nextYOffset,
      );
      final score =
          visualScore +
          (horizontalOffset.abs() / math.max(1, previous.width) * 80) +
          _stitchNextTopOffsetPenalty(
            height: next.height,
            overlapPixels: seed.pixels,
            nextTopOffset: seed.nextYOffset,
          );
      trackGeometryCandidate(
        score: score,
        pixels: seed.pixels,
        horizontalOffset: horizontalOffset,
        nextYOffset: seed.nextYOffset,
      );
      if (_stitchCandidateBeatsCurrent(
        score: score,
        pixels: seed.pixels,
        bestScore: bestScore,
        bestPixels: bestPixels,
      )) {
        secondBestScore = bestScore;
        bestScore = score;
        bestPixels = seed.pixels;
        bestHorizontalOffset = horizontalOffset;
        bestNextYOffset = seed.nextYOffset;
      }
    }
  }
  // Repetitive receipt rows can make the lowest one-dimensional profile score
  // belong to the wrong occurrence. Re-rank only the bounded best basins with
  // two-dimensional local-ink correspondence, without widening the search.
  _ReceiptGeometryChoice? geometryChoice;
  final geometryShortlist =
      <({double score, int pixels, int horizontalOffset, int nextYOffset})>{
        ...geometryCandidates,
        ...geometryCandidatesByOffsetBucket.values,
        ...geometryCandidatesByOverlapBucket.values,
        ...geometryCandidatesByHorizontalOffset.values.expand(
          (candidates) => candidates,
        ),
      };
  final overlapBasinCandidates = geometryCandidatesByOverlapBucket.values
      .toSet();
  for (final candidate in geometryShortlist) {
    if (candidate.score > bestScore + 40 &&
        !overlapBasinCandidates.contains(candidate)) {
      continue;
    }
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
    final currentChoice = geometryChoice;
    if (currentChoice == null ||
        geometryScore < currentChoice.geometryScore - 1.5 ||
        ((geometryScore - currentChoice.geometryScore).abs() <= 1.5 &&
            candidate.pixels > currentChoice.pixels)) {
      geometryChoice = (
        score: candidate.score,
        pixels: candidate.pixels,
        horizontalOffset: candidate.horizontalOffset,
        nextYOffset: candidate.nextYOffset,
        geometryScore: geometryScore,
      );
    }
  }
  final selectedGeometryChoice = geometryChoice;
  if (selectedGeometryChoice != null) {
    final refinedGeometryChoice = _refineReceiptGeometryChoice(
      previous: previous,
      next: next,
      initial: selectedGeometryChoice,
      minPixels: minPixels,
      maxPixels: maxPixels,
    );
    bestScore = refinedGeometryChoice.score;
    bestPixels = refinedGeometryChoice.pixels;
    bestHorizontalOffset = refinedGeometryChoice.horizontalOffset;
    bestNextYOffset = refinedGeometryChoice.nextYOffset;
  }
  final visualConfidence = (1 - (bestScore / 64)).clamp(0.0, 1.0);
  final distinctiveness = secondBestScore.isFinite
      ? ((secondBestScore - bestScore) / 32).clamp(0.0, 1.0)
      : 1.0;
  final horizontalDriftPenalty = _overlapHorizontalDriftPenalty(
    previous: previous,
    next: next,
    pixels: bestPixels,
    horizontalOffset: bestHorizontalOffset,
    nextYOffset: bestNextYOffset,
  );
  final offsetPenalty = _stitchHorizontalOffsetPenalty(
    width: previous.width,
    offset: bestHorizontalOffset,
  );
  final texturePenalty = _overlapFlatTexturePenalty(
    previous: previous,
    next: next,
    pixels: bestPixels,
    horizontalOffset: bestHorizontalOffset,
    nextYOffset: bestNextYOffset,
  );
  final confidence =
      (visualConfidence * (.55 + (.45 * distinctiveness)) -
              horizontalDriftPenalty -
              offsetPenalty -
              texturePenalty)
          .clamp(0.0, 1.0);
  return _ReceiptOverlapMatch(
    pixels: bestPixels,
    nextSkipPixels: bestPixels + bestNextYOffset,
    nextXOffsetPixels: bestHorizontalOffset,
    nextTopOffsetPixels: bestNextYOffset,
    confidence: confidence,
    nextImage: next,
  );
}

double _stitchNextTopOffsetPenalty({
  required int height,
  required int overlapPixels,
  required int nextTopOffset,
}) {
  // In a normal long-receipt capture the shared area begins near the top of
  // the continuation. A deep start remains possible, but it must win with
  // materially better evidence rather than tying a repeated line pattern.
  final ordinaryPenalty = nextTopOffset / math.max(1, height) * 180;
  if (nextTopOffset <= overlapPixels) return ordinaryPenalty;
  final unsupportedPreRoll = nextTopOffset - overlapPixels;
  return ordinaryPenalty + 48 + (unsupportedPreRoll / math.max(1, height) * 80);
}

bool _stitchCandidateBeatsCurrent({
  required double score,
  required int pixels,
  required double bestScore,
  required int bestPixels,
}) {
  if (!bestScore.isFinite) return true;
  if (score < bestScore) return true;
  // A shorter slice is a strict subset of a real overlap and can score a
  // little cleaner simply because it excludes one faded or shadowed row.
  // Prefer the materially longer candidate when its normalized score remains
  // close, otherwise valid repeated lines are left duplicated at the join.
  final closeEnough = score <= bestScore + 6.0;
  final materiallyLonger = pixels >= bestPixels + 48;
  return closeEnough && materiallyLonger;
}
