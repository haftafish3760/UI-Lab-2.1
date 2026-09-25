part of 'receipt_image_processor.dart';

_DataSaverProfile _profileFor(ReceiptDataSaverLevel level) {
  return switch (level) {
    ReceiptDataSaverLevel.original => const _DataSaverProfile(
      maxLongSide: 4096,
      quality: 96,
      grayscale: false,
      contrast: 100,
    ),
    ReceiptDataSaverLevel.light => const _DataSaverProfile(
      maxLongSide: 2200,
      quality: 82,
      grayscale: false,
      contrast: 100,
    ),
    ReceiptDataSaverLevel.balanced => const _DataSaverProfile(
      maxLongSide: 1800,
      quality: 74,
      grayscale: true,
      contrast: 100,
    ),
    ReceiptDataSaverLevel.strong => const _DataSaverProfile(
      maxLongSide: 1400,
      quality: 66,
      grayscale: true,
      contrast: 115,
    ),
    ReceiptDataSaverLevel.economy => const _DataSaverProfile(
      maxLongSide: 950,
      quality: 52,
      grayscale: true,
      contrast: 122,
    ),
    ReceiptDataSaverLevel.maximum => const _DataSaverProfile(
      maxLongSide: 700,
      quality: 42,
      grayscale: true,
      contrast: 130,
    ),
  };
}

ReceiptPhotoQualityCheck _qualityCheck(img.Image source) {
  final sample = _resizeToMaxSide(source, 320);
  var totalDelta = 0.0;
  var laplacianTotal = 0.0;
  var laplacianCount = 0;
  var sum = 0.0;
  var sumSquares = 0.0;
  var centerInk = 0;
  var outerInk = 0;
  final rowDarkCounts = <int>[];
  var count = 0;
  for (var y = 1; y < sample.height; y += 2) {
    var rowDark = 0;
    for (var x = 1; x < sample.width; x += 2) {
      final current = sample.getPixel(x, y);
      final left = sample.getPixel(x - 1, y);
      final up = sample.getPixel(x, y - 1);
      final currentLuma = _luma(current);
      sum += currentLuma;
      sumSquares += currentLuma * currentLuma;
      totalDelta += (currentLuma - _luma(left)).abs();
      totalDelta += (currentLuma - _luma(up)).abs();
      if (x + 1 < sample.width && y + 1 < sample.height) {
        final rightLuma = _luma(sample.getPixel(x + 1, y));
        final downLuma = _luma(sample.getPixel(x, y + 1));
        final laplacian =
            (currentLuma * 4) - _luma(left) - rightLuma - _luma(up) - downLuma;
        laplacianTotal += laplacian.abs();
        laplacianCount++;
      }
      if (currentLuma < 148) {
        rowDark++;
        final centered =
            x > sample.width * .12 &&
            x < sample.width * .88 &&
            y > sample.height * .08 &&
            y < sample.height * .92;
        if (centered) {
          centerInk++;
        } else {
          outerInk++;
        }
      }
      count += 2;
    }
    rowDarkCounts.add(rowDark);
  }
  final focusScore = count == 0 ? 0.0 : totalDelta / count;
  final detailScore = laplacianCount == 0
      ? 0.0
      : laplacianTotal / laplacianCount;
  final sampleCount = (count / 2).round();
  final brightness = sampleCount == 0 ? 0.0 : sum / sampleCount;
  final variance = sampleCount == 0
      ? 0.0
      : (sumSquares / sampleCount) - brightness * brightness;
  final contrast = variance <= 0 ? 0.0 : math.sqrt(variance);
  final inkTotal = centerInk + outerInk;
  final inkCoverage = sampleCount == 0 ? 0.0 : inkTotal / sampleCount;
  final cropScore = inkTotal == 0 ? 0.0 : centerInk / inkTotal;
  final textBandScore = _textBandScore(rowDarkCounts);
  final largestInteriorTextGapRatio = _largestInteriorTextGapRatio(
    rowDarkCounts,
  );
  final enoughResolution = source.width >= 900 && source.height >= 900;
  final readableLight = brightness >= 68 && brightness <= 224;
  final readableContrast = contrast >= 16;
  final readableCrop = cropScore >= .30;
  final readableLines = textBandScore >= 6;
  final readableCore =
      enoughResolution && readableLight && focusScore >= 8 && readableContrast;
  final strongTextEvidence = textBandScore >= 8 && cropScore >= .24;
  final strongShapeEvidence =
      focusScore >= 10 && contrast >= 20 && cropScore >= .22;
  final borderlineReadable =
      readableCore &&
      (strongTextEvidence ||
          strongShapeEvidence ||
          (readableCrop && textBandScore >= 4));
  return ReceiptPhotoQualityCheck(
    width: source.width,
    height: source.height,
    focusScore: focusScore,
    detailScore: detailScore,
    brightness: brightness,
    contrast: contrast,
    cropScore: cropScore,
    textBandScore: textBandScore,
    largestInteriorTextGapRatio: largestInteriorTextGapRatio,
    inkCoverage: inkCoverage,
    isLikelyReadable:
        largestInteriorTextGapRatio < .22 &&
        !(inkCoverage > .46 && textBandScore < 4) &&
        (borderlineReadable || (readableCore && readableCrop && readableLines)),
  );
}

double _textBandScore(List<int> rowDarkCounts) {
  if (rowDarkCounts.isEmpty) return 0;
  final threshold = _textRowThreshold(rowDarkCounts);
  var bands = 0;
  var inBand = false;
  for (final darkCount in rowDarkCounts) {
    final hasText = darkCount >= threshold;
    if (hasText && !inBand) bands++;
    inBand = hasText;
  }
  return bands.toDouble().clamp(0, 18);
}

int _textRowThreshold(List<int> rowDarkCounts) {
  final sortedCounts = [...rowDarkCounts]..sort();
  final strongRowSample =
      sortedCounts[(sortedCounts.length * .90).floor().clamp(
        0,
        sortedCounts.length - 1,
      )];
  return math.max(4, (strongRowSample * .28).round());
}

double _largestInteriorTextGapRatio(List<int> rowDarkCounts) {
  if (rowDarkCounts.length < 3) return 0;
  final threshold = _textRowThreshold(rowDarkCounts);
  final firstText = rowDarkCounts.indexWhere((count) => count >= threshold);
  final lastText = rowDarkCounts.lastIndexWhere((count) => count >= threshold);
  if (firstText < 0 || lastText <= firstText) return 0;
  var longestGap = 0;
  var currentGap = 0;
  for (var index = firstText + 1; index < lastText; index++) {
    if (rowDarkCounts[index] < threshold) {
      currentGap++;
      if (currentGap > longestGap) longestGap = currentGap;
    } else {
      currentGap = 0;
    }
  }
  return longestGap / rowDarkCounts.length;
}

double _luma(img.Pixel pixel) {
  return pixel.r * .299 + pixel.g * .587 + pixel.b * .114;
}

Future<String> _writeJpg(
  img.Image image, {
  required String prefix,
  required int quality,
}) async {
  final file = File(
    '${Directory.systemTemp.path}/maintaniac_receipt_${prefix}_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(img.encodeJpg(image, quality: quality), flush: true);
  return file.path;
}

Future<String> _writeJpgToPath(
  img.Image image, {
  required String outputPath,
  required int quality,
}) async {
  final file = File(outputPath);
  final encoded = img.encodeJpg(image, quality: quality);
  if (encoded.length > 16 * 1024 * 1024) {
    throw StateError('Combined receipt exceeds its admitted storage budget.');
  }
  if (await file.exists()) {
    throw StateError('Refusing to replace an existing receipt artifact.');
  }
  await file.writeAsBytes(encoded, flush: true);
  return file.path;
}

class _DataSaverProfile {
  const _DataSaverProfile({
    required this.maxLongSide,
    required this.quality,
    required this.grayscale,
    required this.contrast,
  });

  final int maxLongSide;
  final int quality;
  final bool grayscale;
  final num contrast;
}

class _ReceiptImageBounds {
  const _ReceiptImageBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.hitCount = 0,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
  final int hitCount;

  double get width => right - left;
  double get height => bottom - top;
}

class _ReceiptOverlapMatch {
  const _ReceiptOverlapMatch({
    required this.pixels,
    required this.confidence,
    required this.nextImage,
    int? nextSkipPixels,
    this.nextXOffsetPixels = 0,
    this.nextTopOffsetPixels = 0,
    this.scaleCorrection = 1,
    this.rotationCorrectionDegrees = 0,
    this.perspectiveCorrection = 0,
  }) : nextSkipPixels = nextSkipPixels ?? pixels;

  final int pixels;
  final int nextSkipPixels;
  final int nextXOffsetPixels;
  final int nextTopOffsetPixels;
  final double confidence;
  final img.Image nextImage;
  final double scaleCorrection;
  final double rotationCorrectionDegrees;
  final double perspectiveCorrection;

  bool get isConfident => pixels > 0 && confidence >= .50;

  // A tentative join is shown only in the review screen, never saved without
  // the user's next explicit Continue. This admits a hard-but-readable
  // receipt pair that has a clear best overlap but misses the stricter OCR
  // handoff threshold. The original sections remain available for retake.
  bool get isReviewableJoin => pixels > 0 && confidence >= .35;
}

class _ReceiptExposureCurve {
  const _ReceiptExposureCurve({
    required this.blackPoint,
    required this.midpoint,
    required this.whitePoint,
    required this.shadowShare,
    required this.highlightShare,
  });

  final double blackPoint;
  final double midpoint;
  final double whitePoint;
  final double shadowShare;
  final double highlightShare;

  bool get isShadowHeavy => shadowShare > .18 && highlightShare < .20;
}

class _ScannerImageDecision {
  const _ScannerImageDecision(this.image, this.code);

  final img.Image image;
  final String code;
}

class _ReceiptStitchCandidate {
  const _ReceiptStitchCandidate({
    required this.pixels,
    required this.confidence,
    required this.scaleCorrection,
    required this.sampleHeight,
    required this.sampleWidth,
    int? nextSkipPixels,
    this.nextXOffsetPixels = 0,
    this.rotationCorrectionDegrees = 0,
    this.perspectiveCorrection = 0,
  }) : nextSkipPixels = nextSkipPixels ?? pixels;

  final int pixels;
  final int nextSkipPixels;
  final int nextXOffsetPixels;
  final double confidence;
  final double scaleCorrection;
  final int sampleHeight;
  final int sampleWidth;
  final double rotationCorrectionDegrees;
  final double perspectiveCorrection;
}
