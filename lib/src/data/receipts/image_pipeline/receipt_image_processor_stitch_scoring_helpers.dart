part of 'receipt_image_processor.dart';

bool _receiptImageHasReadableDetail(img.Image image) {
  final stepX = math.max(4, (image.width / 72).round());
  final stepY = math.max(4, (image.height / 96).round());
  var samples = 0;
  var total = 0.0;
  var totalSquares = 0.0;
  for (var y = 0; y < image.height; y += stepY) {
    for (var x = 0; x < image.width; x += stepX) {
      final value = _luma(image.getPixel(x, y));
      total += value;
      totalSquares += value * value;
      samples++;
    }
  }
  if (samples < 64) return false;
  final mean = total / samples;
  final variance = (totalSquares / samples) - (mean * mean);
  // A uniform frame cannot prove an overlap. This deliberately makes a
  // person retake a black, white, or lens-covered section instead of
  // combining it with a real receipt section.
  return variance >= 24;
}

bool _receiptImageLooksLikeReceiptPhoto(img.Image image) {
  if (image.width < 48 || image.height < 80) return false;
  final stepX = math.max(4, (image.width / 80).round());
  final stepY = math.max(3, (image.height / 120).round());
  var sampledRows = 0;
  var paperRows = 0;
  for (var y = 0; y < image.height; y += stepY) {
    var samples = 0;
    var paperLike = 0;
    for (var x = 0; x < image.width; x += stepX) {
      final pixel = image.getPixel(x, y);
      final maximum = math.max(pixel.r, math.max(pixel.g, pixel.b));
      final minimum = math.min(pixel.r, math.min(pixel.g, pixel.b));
      final luma = _luma(pixel);
      if (luma >= 105 && maximum - minimum <= 52) paperLike++;
      samples++;
    }
    if (samples == 0) continue;
    sampledRows++;
    // A receipt can be narrow and surrounded by a desk or vehicle interior,
    // but its paper should still form a sustained vertical document. App
    // screens and unrelated photos may contain bright cards; they do not
    // supply paper-like coverage through most rows of the frame.
    if (paperLike / samples >= .22) paperRows++;
  }
  return sampledRows >= 20 && paperRows / sampledRows >= .62;
}

double _overlapDifference({
  required img.Image previous,
  required img.Image next,
  required int pixels,
  int horizontalOffset = 0,
  int nextYOffset = 0,
}) {
  final sampleWidth = math.min(previous.width, next.width);
  final stepX = math.max(8, (sampleWidth / 64).round());
  final stepY = math.max(4, (pixels / 36).round());
  var lumaTotal = 0.0;
  var lumaSamples = 0;
  final previousLumas = <double>[];
  final nextLumas = <double>[];
  var rowProfileTotal = 0.0;
  var rowProfileSamples = 0;
  var columnProfileTotal = 0.0;
  var columnProfileSamples = 0;
  var previousWeightedX = 0.0;
  var nextWeightedX = 0.0;
  var previousInkTotal = 0;
  var nextInkTotal = 0;
  final previousStartY = previous.height - pixels;
  for (var y = 0; y < pixels; y += stepY) {
    var previousInk = 0;
    var nextInk = 0;
    var rowSamples = 0;
    for (var x = sampleWidth ~/ 24; x < sampleWidth * 23 ~/ 24; x += stepX) {
      final nextX = x + horizontalOffset;
      if (nextX < 0 || nextX >= sampleWidth) continue;
      final a = _luma(previous.getPixel(x, previousStartY + y));
      final b = _luma(next.getPixel(nextX, nextYOffset + y));
      lumaTotal += (a - b).abs();
      previousLumas.add(a);
      nextLumas.add(b);
      lumaSamples++;
      if (a < 160) previousInk++;
      if (b < 160) nextInk++;
      rowSamples++;
    }
    if (rowSamples > 0) {
      final previousRatio = previousInk / rowSamples;
      final nextRatio = nextInk / rowSamples;
      rowProfileTotal += (previousRatio - nextRatio).abs() * 74;
      rowProfileSamples++;
    }
  }
  for (var x = sampleWidth ~/ 24; x < sampleWidth * 23 ~/ 24; x += stepX) {
    final nextX = x + horizontalOffset;
    if (nextX < 0 || nextX >= sampleWidth) continue;
    var previousInk = 0;
    var nextInk = 0;
    var columnSamples = 0;
    for (var y = 0; y < pixels; y += stepY) {
      final a = _luma(previous.getPixel(x, previousStartY + y));
      final b = _luma(next.getPixel(nextX, nextYOffset + y));
      if (a < 170) {
        previousInk++;
        previousWeightedX += x;
        previousInkTotal++;
      }
      if (b < 170) {
        nextInk++;
        nextWeightedX += x;
        nextInkTotal++;
      }
      columnSamples++;
    }
    if (columnSamples > 0) {
      final previousRatio = previousInk / columnSamples;
      final nextRatio = nextInk / columnSamples;
      columnProfileTotal += (previousRatio - nextRatio).abs() * 96;
      columnProfileSamples++;
    }
  }
  if (lumaSamples == 0) return double.infinity;
  final lumaAverage = lumaTotal / lumaSamples;
  final exposureTolerantLumaAverage = _overlapExposureTolerantDifference(
    previousLumas,
    nextLumas,
  );
  final effectiveLumaAverage = math.min(
    lumaAverage,
    exposureTolerantLumaAverage,
  );
  final rowProfileAverage = rowProfileSamples == 0
      ? double.infinity
      : rowProfileTotal / rowProfileSamples;
  final columnProfileAverage = columnProfileSamples == 0
      ? double.infinity
      : columnProfileTotal / columnProfileSamples;
  final centerPenalty = previousInkTotal == 0 || nextInkTotal == 0
      ? 0.0
      : ((previousWeightedX / previousInkTotal) -
                    (nextWeightedX / nextInkTotal))
                .abs() /
            sampleWidth *
            150;
  final leadingPreRollPenalty = _leadingContinuationPreRollPenalty(
    next: next,
    nextYOffset: nextYOffset,
  );
  return (effectiveLumaAverage * .50) +
      (rowProfileAverage * .22) +
      (columnProfileAverage * .20) +
      (centerPenalty * .08) +
      leadingPreRollPenalty;
}

double _leadingContinuationPreRollPenalty({
  required img.Image next,
  required int nextYOffset,
}) {
  // A black or near-uniform strip at the very top is usually table/background
  // captured before the receipt continuation. It must not be treated as part
  // of an overlap: otherwise a long, weak join can preserve that strip in the
  // middle of the combined receipt. A true receipt top is normally light and
  // detailed, so this is intentionally a conservative safety signal.
  if (nextYOffset != 0 || next.height < 48 || next.width < 48) return 0;
  final bandHeight = math.min(96, math.max(18, (next.height * .08).round()));
  final stepX = math.max(4, (next.width / 56).round());
  final stepY = math.max(2, (bandHeight / 18).round());
  var samples = 0;
  var darkSamples = 0;
  var lumaTotal = 0.0;
  var lumaSquares = 0.0;
  for (var y = 0; y < bandHeight; y += stepY) {
    for (var x = next.width ~/ 20; x < next.width * 19 ~/ 20; x += stepX) {
      final luma = _luma(next.getPixel(x, y));
      lumaTotal += luma;
      lumaSquares += luma * luma;
      if (luma < 36) darkSamples++;
      samples++;
    }
  }
  if (samples < 24) return 0;
  final mean = lumaTotal / samples;
  final variance = (lumaSquares / samples) - (mean * mean);
  if (darkSamples / samples >= .84 && mean < 42 && variance < 70) {
    return 44;
  }
  return 0;
}

double _overlapExposureTolerantDifference(
  List<double> previousLumas,
  List<double> nextLumas,
) {
  final length = math.min(previousLumas.length, nextLumas.length);
  if (length < 8) return double.infinity;
  final previousMean =
      previousLumas.take(length).reduce((a, b) => a + b) / length;
  final nextMean = nextLumas.take(length).reduce((a, b) => a + b) / length;
  var normalizedTotal = 0.0;
  for (var index = 0; index < length; index++) {
    normalizedTotal +=
        ((previousLumas[index] - previousMean) - (nextLumas[index] - nextMean))
            .abs();
  }
  final normalizedAverage = normalizedTotal / length;
  final exposureShiftPenalty = (previousMean - nextMean).abs() * .18;
  return normalizedAverage + exposureShiftPenalty;
}

double _overlapFlatTexturePenalty({
  required img.Image previous,
  required img.Image next,
  required int pixels,
  required int horizontalOffset,
  required int nextYOffset,
}) {
  final sampleWidth = math.min(previous.width, next.width);
  final stepX = math.max(8, (sampleWidth / 72).round());
  final stepY = math.max(4, (pixels / 42).round());
  final previousStartY = previous.height - pixels;
  final previousRatios = <double>[];
  final nextRatios = <double>[];
  final nextLumas = <double>[];
  for (var y = 0; y < pixels; y += stepY) {
    var previousInk = 0;
    var nextInk = 0;
    var samples = 0;
    for (var x = sampleWidth ~/ 24; x < sampleWidth * 23 ~/ 24; x += stepX) {
      final nextX = x + horizontalOffset;
      if (nextX < 0 || nextX >= sampleWidth) continue;
      if (_luma(previous.getPixel(x, previousStartY + y)) < 170) {
        previousInk++;
      }
      final nextLuma = _luma(next.getPixel(nextX, nextYOffset + y));
      nextLumas.add(nextLuma);
      if (nextLuma < 170) {
        nextInk++;
      }
      samples++;
    }
    if (samples == 0) continue;
    previousRatios.add(previousInk / samples);
    nextRatios.add(nextInk / samples);
  }
  if (previousRatios.length < 6 || nextRatios.length < 6) return .35;
  final previousStats = _overlapInkProfileStats(previousRatios);
  final nextStats = _overlapInkProfileStats(nextRatios);
  final nextLumaStats = _overlapValueStats(nextLumas);
  final nextLooksFlatDark = nextStats.mean > .70 && nextStats.variance < .0018;
  final previousLooksReceiptLike = previousStats.variance > .004;
  if (nextLooksFlatDark && previousLooksReceiptLike) return .48;
  if (previousLooksReceiptLike && nextLumaStats.variance < 18) return .48;
  return 0;
}

({double mean, double variance}) _overlapInkProfileStats(List<double> values) {
  return _overlapValueStats(values);
}

({double mean, double variance}) _overlapValueStats(List<double> values) {
  final mean = values.reduce((a, b) => a + b) / values.length;
  var variance = 0.0;
  for (final value in values) {
    final delta = value - mean;
    variance += delta * delta;
  }
  return (mean: mean, variance: variance / values.length);
}

double _overlapHorizontalDriftPenalty({
  required img.Image previous,
  required img.Image next,
  required int pixels,
  int horizontalOffset = 0,
  int nextYOffset = 0,
}) {
  final sampleWidth = math.min(previous.width, next.width);
  final stepX = math.max(6, (sampleWidth / 100).round());
  final stepY = math.max(4, (pixels / 40).round());
  final previousStartY = previous.height - pixels;
  var previousWeightedX = 0.0;
  var nextWeightedX = 0.0;
  var previousInkTotal = 0;
  var nextInkTotal = 0;
  for (var y = 0; y < pixels; y += stepY) {
    for (var x = sampleWidth ~/ 14; x < sampleWidth * 13 ~/ 14; x += stepX) {
      final nextX = x + horizontalOffset;
      if (nextX < 0 || nextX >= sampleWidth) continue;
      final previousLuma = _luma(previous.getPixel(x, previousStartY + y));
      final nextLuma = _luma(next.getPixel(nextX, nextYOffset + y));
      if (previousLuma < 170) {
        previousWeightedX += x;
        previousInkTotal++;
      }
      if (nextLuma < 170) {
        nextWeightedX += x;
        nextInkTotal++;
      }
    }
  }
  if (previousInkTotal < 12 || nextInkTotal < 12) return 0;
  final delta =
      ((previousWeightedX / previousInkTotal) - (nextWeightedX / nextInkTotal))
          .abs();
  final safeDrift = sampleWidth * .075;
  final unsafeDrift = sampleWidth * .16;
  if (delta <= safeDrift) return 0;
  return ((delta - safeDrift) / math.max(1, unsafeDrift - safeDrift) * .35)
      .clamp(0.0, .35);
}

double _stitchHorizontalOffsetPenalty({
  required int width,
  required int offset,
}) {
  final unit = math.max(12, (width * .035).round());
  final magnitude = offset.abs();
  if (magnitude < unit * 2.5) return 0;
  final maxOffset = math.max(unit * 2, (width * .14).round());
  final range = math.max(1, maxOffset - unit * 2.5);
  final share = ((magnitude - unit * 2.5) / range).clamp(0.0, 1.0);
  return (.04 + (.08 * share)).clamp(0.0, .12);
}

double _receiptImageBandDifference(
  img.Image a,
  img.Image b, {
  required double startFraction,
  required double endFraction,
}) {
  final sampleWidth = math.min(a.width, b.width);
  final sampleHeight = math.min(a.height, b.height);
  final startY = (sampleHeight * startFraction).round();
  final endY = (sampleHeight * endFraction).round().clamp(
    startY + 1,
    sampleHeight,
  );
  var total = 0.0;
  var samples = 0;
  for (var y = startY; y < endY; y += 6) {
    for (var x = 8; x < sampleWidth - 8; x += 8) {
      total += (_luma(a.getPixel(x, y)) - _luma(b.getPixel(x, y))).abs();
      samples++;
    }
  }
  return samples == 0 ? double.infinity : total / samples;
}

({bool isProven, double correlation, int detailedBands, int matchingBands})
_receiptOverlapContinuityEvidence({
  required img.Image previous,
  required _ReceiptOverlapMatch match,
}) {
  final next = match.nextImage;
  final overlap = math.min(
    match.pixels,
    math.min(previous.height, next.height - match.nextTopOffsetPixels),
  );
  if (overlap < 72) {
    return (
      isProven: false,
      correlation: 0,
      detailedBands: 0,
      matchingBands: 0,
    );
  }

  const bandCount = 7;
  var detailedBands = 0;
  var matchingBands = 0;
  var correlationTotal = 0.0;
  for (var band = 0; band < bandCount; band++) {
    final start = (overlap * band / bandCount).round();
    final end = (overlap * (band + 1) / bandCount).round();
    final evidence = _receiptOverlapBandCorrelation(
      previous: previous,
      next: next,
      previousStartY: previous.height - overlap + start,
      nextStartY: match.nextTopOffsetPixels + start,
      height: math.max(1, end - start),
      horizontalOffset: match.nextXOffsetPixels,
    );
    if (!evidence.hasDetail) continue;
    detailedBands++;
    correlationTotal += evidence.correlation;
    if (evidence.correlation >= .24) matchingBands++;
  }
  final averageCorrelation = detailedBands == 0
      ? 0.0
      : correlationTotal / detailedBands;
  final requiredMatchingBands = math.max(2, (detailedBands * .50).ceil());
  return (
    isProven:
        detailedBands >= 3 &&
        matchingBands >= requiredMatchingBands &&
        averageCorrelation >= .20,
    correlation: averageCorrelation.clamp(-1.0, 1.0),
    detailedBands: detailedBands,
    matchingBands: matchingBands,
  );
}

({bool hasDetail, double correlation}) _receiptOverlapBandCorrelation({
  required img.Image previous,
  required img.Image next,
  required int previousStartY,
  required int nextStartY,
  required int height,
  required int horizontalOffset,
}) {
  final sampleWidth = math.min(previous.width, next.width);
  final stepX = math.max(6, sampleWidth ~/ 96);
  final stepY = math.max(2, height ~/ 28);
  final previousRows = <double>[];
  final nextRows = <double>[];
  for (var dy = 0; dy < height; dy += stepY) {
    final previousY = (previousStartY + dy).clamp(0, previous.height - 1);
    final nextY = (nextStartY + dy).clamp(0, next.height - 1);
    var previousLuma = 0.0;
    var nextLuma = 0.0;
    var rowSamples = 0;
    for (var x = sampleWidth ~/ 12; x < sampleWidth * 11 ~/ 12; x += stepX) {
      final nextX = x + horizontalOffset;
      if (nextX < 0 || nextX >= next.width) continue;
      final a = _luma(previous.getPixel(x, previousY));
      final b = _luma(next.getPixel(nextX, nextY));
      previousLuma += a;
      nextLuma += b;
      rowSamples++;
    }
    if (rowSamples == 0) continue;
    previousRows.add(previousLuma / rowSamples);
    nextRows.add(nextLuma / rowSamples);
  }
  if (previousRows.length < 12 || nextRows.length < 12) {
    return (hasDetail: false, correlation: 0);
  }
  final previousStats = _overlapValueStats(previousRows);
  final nextStats = _overlapValueStats(nextRows);
  if (previousStats.variance < 4 || nextStats.variance < 4) {
    return (hasDetail: false, correlation: 0);
  }
  var bestCorrelation = -1.0;
  for (var shift = -4; shift <= 4; shift++) {
    final correlation = _receiptProfileCorrelation(
      previousRows,
      nextRows,
      shift: shift,
    );
    if (correlation > bestCorrelation) bestCorrelation = correlation;
  }
  return (hasDetail: true, correlation: bestCorrelation);
}

double _receiptProfileCorrelation(
  List<double> previous,
  List<double> next, {
  required int shift,
}) {
  final previousStart = math.max(0, -shift);
  final nextStart = math.max(0, shift);
  final length = math.min(
    previous.length - previousStart,
    next.length - nextStart,
  );
  if (length < 8) return -1;
  var previousTotal = 0.0;
  var nextTotal = 0.0;
  for (var index = 0; index < length; index++) {
    previousTotal += previous[previousStart + index];
    nextTotal += next[nextStart + index];
  }
  final previousMean = previousTotal / length;
  final nextMean = nextTotal / length;
  var covariance = 0.0;
  var previousVariance = 0.0;
  var nextVariance = 0.0;
  for (var index = 0; index < length; index++) {
    final a = previous[previousStart + index] - previousMean;
    final b = next[nextStart + index] - nextMean;
    covariance += a * b;
    previousVariance += a * a;
    nextVariance += b * b;
  }
  final denominator = math.sqrt(previousVariance * nextVariance);
  if (!denominator.isFinite || denominator <= 0) return -1;
  return (covariance / denominator).clamp(-1.0, 1.0);
}
