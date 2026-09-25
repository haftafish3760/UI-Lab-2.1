part of 'receipt_image_processor.dart';

_ScannerImageDecision _enhanceReceiptForReadingWithDecision(
  img.Image source, {
  ReceiptImageCleanupSettings cleanupSettings =
      const ReceiptImageCleanupSettings(),
}) {
  final base = _resizeToMaxSide(source, 2600);
  final quality = _qualityCheck(base);
  if (!cleanupSettings.usesScannerCleanup) {
    return _ScannerImageDecision(base, 'cleanup_skipped_setting_off');
  }
  final candidates = <img.Image>[];
  if (cleanupSettings.grayscale || cleanupSettings.contrastBoost) {
    candidates.add(
      _basicReceiptEnhancement(
        base,
        quality,
        grayscale: cleanupSettings.grayscale,
        contrastBoost: cleanupSettings.contrastBoost,
      ),
    );
    candidates.add(
      _thermalReceiptEnhancement(
        base,
        quality,
        grayscale: cleanupSettings.grayscale,
        contrastBoost: cleanupSettings.contrastBoost,
        sharpening: cleanupSettings.sharpening,
      ),
    );
  }
  if (cleanupSettings.adaptiveExposure) {
    candidates.add(
      _adaptiveExposureReceiptEnhancement(
        base,
        quality,
        grayscale: cleanupSettings.grayscale,
        contrastBoost: cleanupSettings.contrastBoost,
        sharpening: cleanupSettings.sharpening,
        shadowReduction: cleanupSettings.shadowReduction,
      ),
    );
  }
  if (cleanupSettings.shadowReduction) {
    candidates.add(
      _shadowBalancedEnhancement(
        base,
        quality,
        grayscale: cleanupSettings.grayscale,
        contrastBoost: cleanupSettings.contrastBoost,
      ),
    );
  }
  if (cleanupSettings.contrastBoost) {
    candidates.add(_fadedReceiptEnhancement(base, quality));
  }
  if (cleanupSettings.sharpening &&
      candidates.isNotEmpty &&
      (quality.isSoft || quality.focusScore < 11)) {
    candidates.add(_mildTextSharpen(candidates.last));
  }
  if (candidates.isEmpty) {
    return _ScannerImageDecision(base, 'cleanup_skipped_no_candidates');
  }

  var best = candidates.first;
  var bestQuality = _qualityCheck(best);
  for (final candidate in candidates.skip(1)) {
    final candidateQuality = _qualityCheck(candidate);
    if (_enhancementScore(candidateQuality) > _enhancementScore(bestQuality)) {
      best = candidate;
      bestQuality = candidateQuality;
    }
  }
  final baseScore = _enhancementScore(quality);
  final bestScore = _enhancementScore(bestQuality);
  if (bestQuality.reviewScore < quality.reviewScore ||
      bestQuality.textBandScore < quality.textBandScore ||
      bestQuality.contrast < quality.contrast * .72 ||
      bestScore + 2 < baseScore) {
    return _ScannerImageDecision(base, 'cleanup_skipped_quality_guard');
  }
  return _ScannerImageDecision(best, _cleanupAppliedCode(quality));
}

img.Image _bestReceiptOcrSource(List<img.Image> candidates) {
  var best = candidates.first;
  var bestQuality = _qualityCheck(best);
  for (final candidate in candidates.skip(1)) {
    final quality = _qualityCheck(candidate);
    final preservesText =
        quality.textBandScore >= bestQuality.textBandScore &&
        quality.contrast >= bestQuality.contrast * .72 &&
        quality.reviewScore >= bestQuality.reviewScore * .85;
    final substantiallyImprovesReceiptLines =
        quality.textBandScore >= bestQuality.textBandScore + 4 &&
        quality.contrast >= bestQuality.contrast * .55 &&
        quality.reviewScore >= math.max(50, bestQuality.reviewScore * .55);
    final scoreBeatsCurrent =
        _enhancementScore(quality) >= _enhancementScore(bestQuality);
    if ((preservesText && scoreBeatsCurrent) ||
        substantiallyImprovesReceiptLines) {
      best = candidate;
      bestQuality = quality;
    }
  }
  return best;
}

String _cleanupAppliedCode(ReceiptPhotoQualityCheck quality) {
  if (quality.isTooDark) return 'cleanup_applied_dark_receipt';
  if (quality.isTooBright) return 'cleanup_applied_glare_receipt';
  if (quality.isLowContrast || quality.textBandScore < 8) {
    return 'cleanup_applied_faded_receipt';
  }
  if (quality.isSoft || quality.focusScore < 11) {
    return 'cleanup_applied_soft_text';
  }
  return 'cleanup_applied_receipt_readability';
}

img.Image _basicReceiptEnhancement(
  img.Image source,
  ReceiptPhotoQualityCheck quality, {
  required bool grayscale,
  required bool contrastBoost,
}) {
  var output = source;
  if (quality.isTooDark) {
    output = img.adjustColor(output, brightness: 1.16, gamma: .92);
  } else if (quality.isTooBright) {
    output = img.adjustColor(output, brightness: .90, gamma: 1.06);
  }
  if (grayscale) output = img.grayscale(output);
  if (!contrastBoost) return output;
  output = img.normalize(output, min: 8, max: 248);
  return img.contrast(output, contrast: quality.isLowContrast ? 1.35 : 1.18);
}

img.Image _thermalReceiptEnhancement(
  img.Image source,
  ReceiptPhotoQualityCheck quality, {
  required bool grayscale,
  required bool contrastBoost,
  required bool sharpening,
}) {
  var output = grayscale ? img.grayscale(source) : source;
  output = img.adjustColor(
    output,
    brightness: quality.isTooDark ? 1.18 : .98,
    gamma: quality.isTooBright ? 1.12 : .86,
    contrast: contrastBoost ? (quality.isLowContrast ? 1.42 : 1.24) : 1,
  );
  if (contrastBoost) output = img.normalize(output, min: 18, max: 238);
  return sharpening ? _mildTextSharpen(output) : output;
}

img.Image _adaptiveExposureReceiptEnhancement(
  img.Image source,
  ReceiptPhotoQualityCheck quality, {
  required bool grayscale,
  required bool contrastBoost,
  required bool sharpening,
  required bool shadowReduction,
}) {
  var output = grayscale ? img.grayscale(source) : source;
  final exposure = _receiptExposureCurve(output);
  final targetMid = quality.isTooDark
      ? 158
      : quality.isTooBright
      ? 136
      : 148;
  final currentMid = exposure.midpoint.clamp(1.0, 254.0);
  final brightnessFactor = (targetMid / currentMid).clamp(.72, 1.42);
  final gamma = quality.isTooDark
      ? .78
      : quality.isTooBright
      ? 1.16
      : exposure.isShadowHeavy
      ? .86
      : .94;
  output = img.adjustColor(
    output,
    brightness: brightnessFactor,
    gamma: gamma,
    contrast: contrastBoost ? (quality.isLowContrast ? 1.34 : 1.18) : 1,
  );
  if (shadowReduction) {
    output = _balanceReceiptRows(output, targetBrightness: targetMid);
  }
  if (contrastBoost) {
    output = img.normalize(
      output,
      min: exposure.blackPoint.round().clamp(0, 48),
      max: exposure.whitePoint.round().clamp(206, 255),
    );
  }
  return sharpening ? _mildTextSharpen(output) : output;
}

img.Image _fadedReceiptEnhancement(
  img.Image source,
  ReceiptPhotoQualityCheck quality,
) {
  var output = img.grayscale(source);
  output = img.adjustColor(
    output,
    brightness: quality.brightness < 150 ? 1.10 : .96,
    gamma: .78,
    contrast: 1.55,
  );
  output = img.normalize(output, min: 28, max: 232);
  return _mildTextSharpen(output);
}

img.Image _shadowBalancedEnhancement(
  img.Image source,
  ReceiptPhotoQualityCheck quality, {
  required bool grayscale,
  required bool contrastBoost,
}) {
  final output = grayscale ? img.grayscale(source) : img.Image.from(source);
  final sampleStep = math.max(1, output.width ~/ 40);
  for (var y = 0; y < output.height; y++) {
    var rowTotal = 0.0;
    var rowCount = 0;
    for (var x = 0; x < output.width; x += sampleStep) {
      rowTotal += _luma(output.getPixel(x, y));
      rowCount++;
    }
    if (rowCount == 0) continue;
    final rowBrightness = rowTotal / rowCount;
    final lift = (quality.brightness - rowBrightness).clamp(-28.0, 34.0);
    if (lift.abs() < 4) continue;
    for (var x = 0; x < output.width; x++) {
      final pixel = output.getPixel(x, y);
      final value = (pixel.r + lift).round().clamp(0, 255);
      pixel
        ..r = value
        ..g = value
        ..b = value;
    }
  }
  if (!contrastBoost) return output;
  final normalized = img.normalize(output, min: 12, max: 244);
  return img.contrast(
    normalized,
    contrast: quality.isLowContrast ? 1.36 : 1.18,
  );
}

img.Image _mildTextSharpen(img.Image source) {
  return img.convolution(
    source,
    filter: const [0, -1, 0, -1, 5, -1, 0, -1, 0],
    amount: .34,
  );
}

double _enhancementScore(ReceiptPhotoQualityCheck quality) {
  final lightPenalty = quality.isTooDark || quality.isTooBright ? 10 : 0;
  return quality.reviewScore +
      (_finiteEnhancementMetric(quality.textBandScore) * 1.9) +
      (_finiteEnhancementMetric(quality.contrast).clamp(0, 42) * .38) +
      (_finiteEnhancementMetric(quality.focusScore).clamp(0, 18) * .42) -
      lightPenalty;
}

double _finiteEnhancementMetric(double value) => value.isFinite ? value : 0;
