part of 'receipt_image_processor.dart';

ReceiptStitchResult? _validateReceiptStitchInputPaths(List<String> inputPaths) {
  if (inputPaths.isEmpty) {
    return ReceiptStitchResult.fallback(
      inputPaths: const [],
      warning: 'No receipt photos were available for stitching.',
      fallbackReasonCode: 'no_input_paths',
    );
  }
  if (inputPaths.length <= 1) return ReceiptStitchResult.notNeeded(inputPaths);
  if (!receiptPhotoPathsAreUniqueAndNormalized(inputPaths)) {
    final duplicateOrAlias = _stitchInputPathsHaveDuplicateAliases(inputPaths);
    return ReceiptStitchResult.fallback(
      inputPaths: inputPaths,
      warning:
          'Receipt photos included invalid or repeated section paths. Receipt details will use the photos separately.',
      fallbackReasonCode: duplicateOrAlias
          ? 'duplicate_input_paths'
          : 'invalid_input_paths',
    );
  }
  if (!_stitchInputPathsAreUnique(inputPaths)) {
    return ReceiptStitchResult.fallback(
      inputPaths: inputPaths,
      warning:
          'Receipt photos included the same section more than once. Receipt details will use them separately.',
      fallbackReasonCode: 'duplicate_input_paths',
    );
  }
  return null;
}

int _receiptImageAverageHashDistance(img.Image a, img.Image b) {
  return _receiptImageAverageHashHammingDistance(
    _receiptImageAverageHash(a),
    _receiptImageAverageHash(b),
  );
}

int _receiptImageAverageHashHammingDistance(
  List<bool> hashA,
  List<bool> hashB,
) {
  var distance = 0;
  final length = math.min(hashA.length, hashB.length);
  for (var index = 0; index < length; index++) {
    if (hashA[index] != hashB[index]) distance++;
  }
  return distance + (hashA.length - hashB.length).abs();
}

List<bool> _receiptImageAverageHash(img.Image source) {
  final sample = img.copyResize(source, width: 32, height: 32);
  final values = <double>[];
  var total = 0.0;
  for (var y = 0; y < sample.height; y++) {
    for (var x = 0; x < sample.width; x++) {
      final value = _luma(sample.getPixel(x, y));
      values.add(value);
      total += value;
    }
  }
  final mean = total / math.max(1, values.length);
  return [for (final value in values) value >= mean];
}

bool _receiptImageContentMatches(img.Image a, img.Image b) {
  return _receiptImageContentMatchScore(
    a,
    b,
    maxLumaAverage: 40,
    maxNormalizedLumaAverage: 20,
    maxInkProfileAverage: .12,
    maxBandDifference: 16,
  );
}

bool _receiptImageImmediateDuplicateContentMatches(img.Image a, img.Image b) {
  return _receiptImageContentMatchScore(
    a,
    b,
    maxLumaAverage: 32,
    maxNormalizedLumaAverage: 8,
    maxInkProfileAverage: .04,
    maxBandDifference: 32,
  );
}

bool _receiptImageSmallShiftDuplicateContentMatches(img.Image a, img.Image b) {
  final shortestHeight = math.min(a.height, b.height);
  final shortestWidth = math.min(a.width, b.width);
  if (shortestHeight < 160 || shortestWidth < 160) return false;
  for (final fraction in const [.02, .025, .028, .03, .04, .05, .06]) {
    final verticalShift = (shortestHeight * fraction).round();
    final commonHeight = shortestHeight - verticalShift;
    if (commonHeight >= 120) {
      final aTop = img.copyCrop(
        a,
        x: 0,
        y: 0,
        width: a.width,
        height: commonHeight,
      );
      final aBottom = img.copyCrop(
        a,
        x: 0,
        y: verticalShift,
        width: a.width,
        height: commonHeight,
      );
      final bTop = img.copyCrop(
        b,
        x: 0,
        y: 0,
        width: b.width,
        height: commonHeight,
      );
      final bBottom = img.copyCrop(
        b,
        x: 0,
        y: verticalShift,
        width: b.width,
        height: commonHeight,
      );
      if (_receiptImageImmediateDuplicateContentMatches(aTop, bBottom) ||
          _receiptImageImmediateDuplicateContentMatches(aBottom, bTop)) {
        return true;
      }
    }

    // A person can recapture the same section with the paper shifted to one
    // side. That must be detected before OCR or the whole section can be
    // counted twice. Compare the common horizontal field in both directions;
    // the bounded fractions cover ordinary handheld framing drift.
    // Extremely narrow, very tall sections contain many similar row bands;
    // horizontally cropping them can falsely resemble a duplicate even when
    // their unique continuation content differs. Their exact/recompressed
    // checks still run, but shift matching needs a normal capture aspect.
    if (shortestHeight / shortestWidth > 4.5) continue;
    final horizontalShift = (shortestWidth * fraction).round();
    final commonWidth = shortestWidth - horizontalShift;
    if (commonWidth < 120) continue;
    final aLeft = img.copyCrop(
      a,
      x: 0,
      y: 0,
      width: commonWidth,
      height: a.height,
    );
    final aRight = img.copyCrop(
      a,
      x: horizontalShift,
      y: 0,
      width: commonWidth,
      height: a.height,
    );
    final bLeft = img.copyCrop(
      b,
      x: 0,
      y: 0,
      width: commonWidth,
      height: b.height,
    );
    final bRight = img.copyCrop(
      b,
      x: horizontalShift,
      y: 0,
      width: commonWidth,
      height: b.height,
    );
    if (_receiptImageImmediateDuplicateContentMatches(aLeft, bRight) ||
        _receiptImageImmediateDuplicateContentMatches(aRight, bLeft)) {
      return true;
    }
  }
  return false;
}

img.Image _receiptDuplicateComparisonSample(img.Image source) {
  const maximumWidth = 192;
  const maximumHeight = 512;
  if (source.width <= maximumWidth && source.height <= maximumHeight) {
    return source;
  }
  final scale = math.min(
    maximumWidth / math.max(1, source.width),
    maximumHeight / math.max(1, source.height),
  );
  return img.copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
  );
}

bool _receiptImageContentMatchScore(
  img.Image a,
  img.Image b, {
  required double maxLumaAverage,
  required double maxNormalizedLumaAverage,
  required double maxInkProfileAverage,
  required double maxBandDifference,
}) {
  final aspectA = a.width / math.max(1, a.height);
  final aspectB = b.width / math.max(1, b.height);
  if ((aspectA - aspectB).abs() > .03) return false;

  const sampleWidth = 96;
  const maximumSampleHeight = 512;
  var sampleA = img.copyResize(a, width: sampleWidth);
  var sampleB = img.copyResize(b, width: sampleWidth);
  if (sampleA.height > maximumSampleHeight) {
    sampleA = img.copyResize(
      sampleA,
      width: sampleWidth,
      height: maximumSampleHeight,
    );
  }
  if (sampleB.height > maximumSampleHeight) {
    sampleB = img.copyResize(
      sampleB,
      width: sampleWidth,
      height: maximumSampleHeight,
    );
  }
  final sampleHeight = math.min(sampleA.height, sampleB.height);
  if (sampleHeight < 96) return false;

  var meanA = 0.0;
  var meanB = 0.0;
  var meanSamples = 0;
  for (var y = 8; y < sampleHeight - 8; y += 8) {
    for (var x = 8; x < sampleWidth - 8; x += 8) {
      meanA += _luma(sampleA.getPixel(x, y));
      meanB += _luma(sampleB.getPixel(x, y));
      meanSamples++;
    }
  }
  if (meanSamples == 0) return false;
  meanA /= meanSamples;
  meanB /= meanSamples;

  var lumaTotal = 0.0;
  var normalizedLumaTotal = 0.0;
  var inkProfileTotal = 0.0;
  var samples = 0;
  for (var y = 8; y < sampleHeight - 8; y += 8) {
    var inkA = 0;
    var inkB = 0;
    var rowSamples = 0;
    for (var x = 8; x < sampleWidth - 8; x += 8) {
      final lumaA = _luma(sampleA.getPixel(x, y));
      final lumaB = _luma(sampleB.getPixel(x, y));
      lumaTotal += (lumaA - lumaB).abs();
      normalizedLumaTotal += ((lumaA - meanA) - (lumaB - meanB)).abs();
      if (lumaA < 165) inkA++;
      if (lumaB < 165) inkB++;
      rowSamples++;
      samples++;
    }
    if (rowSamples > 0) {
      inkProfileTotal += (inkA - inkB).abs() / rowSamples;
    }
  }
  if (samples == 0) return false;
  final lumaAverage = lumaTotal / samples;
  final normalizedLumaAverage = normalizedLumaTotal / samples;
  final rowCount = (sampleHeight / 8).floor().clamp(1, 10000);
  final inkProfileAverage = inkProfileTotal / rowCount;
  final topBandDifference = _receiptImageBandDifference(
    sampleA,
    sampleB,
    startFraction: .05,
    endFraction: .22,
  );
  final bottomBandDifference = _receiptImageBandDifference(
    sampleA,
    sampleB,
    startFraction: .78,
    endFraction: .95,
  );
  return lumaAverage <= maxLumaAverage &&
      normalizedLumaAverage <= maxNormalizedLumaAverage &&
      inkProfileAverage <= maxInkProfileAverage &&
      topBandDifference <= maxBandDifference &&
      bottomBandDifference <= maxBandDifference;
}
