part of 'receipt_image_processor.dart';

// Kept for the isolated stitching contract and source-level regression tests.
// ignore: unused_element
img.Image _autoCropReceipt(img.Image source) {
  return _autoCropReceiptWithDecision(source).image;
}

_ScannerImageDecision _autoCropReceiptWithDecision(img.Image source) {
  final geometry = _autoCropGeometryFor(source);
  if (!geometry.isUsable) {
    return _ScannerImageDecision(source, geometry.code);
  }
  final cropped = img.copyCrop(
    source,
    x: geometry.x,
    y: geometry.y,
    width: geometry.width,
    height: geometry.height,
  );
  final sourceQuality = _qualityCheck(source);
  final cropQuality = _qualityCheck(cropped);
  final cropKeepsText =
      cropQuality.textBandScore >= sourceQuality.textBandScore * .90 &&
      cropQuality.contrast >= sourceQuality.contrast * .68;
  final cropImprovesFraming = cropQuality.cropScore >= sourceQuality.cropScore;
  final darkFrameCrop =
      _sourceHasDarkFrameAroundReceipt(source, geometry.bounds!) &&
      cropQuality.textBandScore >= sourceQuality.textBandScore * .58 &&
      cropQuality.contrast >= 12 &&
      cropQuality.cropScore >= sourceQuality.cropScore * .82;
  if (!darkFrameCrop &&
      (cropQuality.reviewScore + 2 < sourceQuality.reviewScore ||
          !cropKeepsText ||
          !cropImprovesFraming)) {
    return _ScannerImageDecision(source, 'crop_skipped_quality_guard');
  }
  return _ScannerImageDecision(cropped, 'crop_applied_safe_bounds');
}

Rect? _suggestReceiptCropNormalized(img.Image source) {
  final geometry = _autoCropGeometryFor(source);
  if (!geometry.isUsable) return null;
  return Rect.fromLTRB(
    geometry.x / source.width,
    geometry.y / source.height,
    geometry.right / source.width,
    geometry.bottom / source.height,
  );
}

_ReceiptAutoCropGeometry _autoCropGeometryFor(img.Image source) {
  final bounds = _findReceiptContentBounds(source);
  if (bounds == null) {
    return const _ReceiptAutoCropGeometry.skipped(
      'crop_skipped_no_receipt_bounds',
    );
  }
  final minUsefulArea = source.width * source.height * .18;
  if (bounds.width * bounds.height < minUsefulArea) {
    return const _ReceiptAutoCropGeometry.skipped(
      'crop_skipped_bounds_too_small',
    );
  }
  final boundsSafetyCode = _receiptBoundsSafetyCode(source, bounds);
  if (boundsSafetyCode != 'crop_bounds_safe') {
    return _ReceiptAutoCropGeometry.skipped(boundsSafetyCode);
  }
  final padX = (bounds.width * .045).round().clamp(18, 160);
  final padY = (bounds.height * .035).round().clamp(18, 180);
  final x = (bounds.left - padX).round().clamp(0, source.width - 1);
  final y = (bounds.top - padY).round().clamp(0, source.height - 1);
  final right = (bounds.right + padX).round().clamp(x + 1, source.width);
  final bottom = (bounds.bottom + padY).round().clamp(y + 1, source.height);
  return _ReceiptAutoCropGeometry(
    x: x,
    y: y,
    right: right,
    bottom: bottom,
    bounds: bounds,
  );
}

class _ReceiptAutoCropGeometry {
  const _ReceiptAutoCropGeometry({
    required this.x,
    required this.y,
    required this.right,
    required this.bottom,
    required this.bounds,
  }) : code = 'crop_candidate_safe_bounds';

  const _ReceiptAutoCropGeometry.skipped(this.code)
    : x = 0,
      y = 0,
      right = 0,
      bottom = 0,
      bounds = null;

  final int x;
  final int y;
  final int right;
  final int bottom;
  final _ReceiptImageBounds? bounds;
  final String code;

  bool get isUsable => right > x && bottom > y;
  int get width => right - x;
  int get height => bottom - y;
}

bool _sourceHasDarkFrameAroundReceipt(
  img.Image source,
  _ReceiptImageBounds bounds,
) {
  final widthRatio = bounds.width / source.width;
  final heightRatio = bounds.height / source.height;
  if (widthRatio > .94 && heightRatio > .94) return false;
  final stepX = math.max(1, source.width ~/ 48);
  final stepY = math.max(1, source.height ~/ 64);
  final leftEdge = source.width * .08;
  final rightEdge = source.width * .92;
  final topEdge = source.height * .06;
  final bottomEdge = source.height * .94;
  var dark = 0;
  var samples = 0;
  for (var y = 0; y < source.height; y += stepY) {
    for (var x = 0; x < source.width; x += stepX) {
      final onFrame =
          x < leftEdge || x > rightEdge || y < topEdge || y > bottomEdge;
      if (!onFrame) continue;
      samples++;
      if (_luma(source.getPixel(x, y)) < 86) dark++;
    }
  }
  return samples > 0 && dark / samples >= .30;
}

String _receiptBoundsSafetyCode(img.Image source, _ReceiptImageBounds bounds) {
  final widthRatio = bounds.width / source.width;
  final heightRatio = bounds.height / source.height;
  if (widthRatio < .34) return 'crop_skipped_bounds_too_narrow';
  if (heightRatio < .34) return 'crop_skipped_bounds_too_short';
  final aspect = bounds.height / math.max(1, bounds.width);
  if (aspect < .55) return 'crop_skipped_aspect_too_wide';
  if (aspect > 9.5) return 'crop_skipped_aspect_too_tall';
  final centerX = (bounds.left + bounds.right) / 2;
  final centerY = (bounds.top + bounds.bottom) / 2;
  final xOffset = ((centerX / source.width) - .5).abs();
  final yOffset = ((centerY / source.height) - .5).abs();
  if (widthRatio < .72 && xOffset > .28) {
    return 'crop_skipped_bounds_off_center_x';
  }
  if (heightRatio < .72 && yOffset > .30) {
    return 'crop_skipped_bounds_off_center_y';
  }
  return 'crop_bounds_safe';
}

_ReceiptImageBounds? _findReceiptContentBounds(img.Image source) {
  final sample = _resizeToMaxSide(source, 420);
  final scaleX = source.width / sample.width;
  final scaleY = source.height / sample.height;
  final paperBounds = _scanReceiptBounds(sample, paperOnly: true);
  final bounds = paperBounds?.hitCount != null && paperBounds!.hitCount >= 120
      ? paperBounds
      : _scanReceiptBounds(sample, paperOnly: false);
  if (bounds == null ||
      bounds.hitCount < 120 ||
      bounds.right <= bounds.left ||
      bounds.bottom <= bounds.top) {
    return null;
  }
  return _ReceiptImageBounds(
    left: bounds.left * scaleX,
    top: bounds.top * scaleY,
    right: bounds.right * scaleX,
    bottom: bounds.bottom * scaleY,
    hitCount: bounds.hitCount,
  );
}

String _perspectiveReadinessCode(img.Image source) {
  final bounds = _findReceiptContentBounds(source);
  if (bounds == null) return 'perspective_skipped_no_receipt_bounds';
  final areaRatio =
      (bounds.width * bounds.height) /
      math.max(1, source.width * source.height);
  if (areaRatio < .18) return 'perspective_skipped_bounds_too_small';
  final safetyCode = _receiptBoundsSafetyCode(source, bounds);
  if (safetyCode != 'crop_bounds_safe') {
    return safetyCode.replaceFirst('crop_', 'perspective_');
  }
  final edgeCoverage =
      ((bounds.width / source.width) * (bounds.height / source.height)).clamp(
        0.0,
        1.0,
      );
  if (edgeCoverage < .34 || bounds.hitCount < 180) {
    return 'perspective_skipped_weak_edges';
  }
  return 'perspective_ready_safe_bounds';
}

_ScannerImageDecision _autoOrientReceiptWithDecision(img.Image source) {
  if (source.width <= source.height * 1.15) {
    return _ScannerImageDecision(source, 'orientation_skipped_already_upright');
  }
  final sourceQuality = _qualityCheck(source);
  var best = source;
  var bestQuality = sourceQuality;
  for (final degrees in const [90, -90]) {
    final candidate = img.copyRotate(
      source,
      angle: degrees,
      interpolation: img.Interpolation.linear,
    );
    final candidateQuality = _qualityCheck(candidate);
    final improvesText =
        candidateQuality.textBandScore >= sourceQuality.textBandScore + 2;
    final improvesReview =
        candidateQuality.reviewScore >= sourceQuality.reviewScore + 8;
    final safePortraitReceipt =
        candidate.height > candidate.width &&
        candidateQuality.textBandScore >= sourceQuality.textBandScore * .72 &&
        candidateQuality.reviewScore >= sourceQuality.reviewScore * .55;
    final preservesFocus =
        candidateQuality.focusScore >= sourceQuality.focusScore * .82;
    final beatsCurrent =
        _enhancementScore(candidateQuality) > _enhancementScore(bestQuality);
    if (preservesFocus &&
        ((safePortraitReceipt && identical(best, source)) ||
            ((improvesText || improvesReview) && beatsCurrent))) {
      best = candidate;
      bestQuality = candidateQuality;
    }
  }
  if (identical(best, source)) {
    return _ScannerImageDecision(source, 'orientation_skipped_quality_guard');
  }
  return _ScannerImageDecision(best, 'orientation_applied_portrait_receipt');
}

_ReceiptImageBounds? _scanReceiptBounds(
  img.Image sample, {
  required bool paperOnly,
}) {
  var left = sample.width.toDouble();
  var top = sample.height.toDouble();
  var right = 0.0;
  var bottom = 0.0;
  var hits = 0;
  for (var y = 1; y < sample.height - 1; y += 2) {
    for (var x = 1; x < sample.width - 1; x += 2) {
      final luma = _luma(sample.getPixel(x, y));
      final leftDelta = (luma - _luma(sample.getPixel(x - 1, y))).abs();
      final upDelta = (luma - _luma(sample.getPixel(x, y - 1))).abs();
      final darkInk = luma < 170 && leftDelta + upDelta > 18;
      final receiptPaper = luma > 188;
      if (paperOnly) {
        if (!receiptPaper) continue;
      } else if (!darkInk && !(receiptPaper && leftDelta + upDelta > 8)) {
        continue;
      }
      hits++;
      if (x < left) left = x.toDouble();
      if (x > right) right = x.toDouble();
      if (y < top) top = y.toDouble();
      if (y > bottom) bottom = y.toDouble();
    }
  }
  return _ReceiptImageBounds(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    hitCount: hits,
  );
}

_ScannerImageDecision _autoStraightenReceiptWithDecision(img.Image source) {
  final sourceQuality = _qualityCheck(source);
  final reviewSource = _resizeToMaxSide(source, 760);
  final reviewQuality = _qualityCheck(reviewSource);
  var bestDegrees = 0.0;
  var bestAlignment = _receiptStraightnessScore(reviewSource);
  var bestQuality = reviewQuality;
  for (final degrees in const [-2.0, -1.25, -.65, .65, 1.25, 2.0]) {
    final candidate = img.copyRotate(
      reviewSource,
      angle: degrees,
      interpolation: img.Interpolation.linear,
    );
    final candidateQuality = _qualityCheck(candidate);
    final candidateAlignment = _receiptStraightnessScore(candidate);
    final preservesReading =
        candidateQuality.reviewScore + 2 >= reviewQuality.reviewScore &&
        candidateQuality.textBandScore >= reviewQuality.textBandScore * .90;
    if (preservesReading && candidateAlignment > bestAlignment) {
      bestAlignment = candidateAlignment;
      bestQuality = candidateQuality;
      bestDegrees = degrees;
    }
  }
  final baselineAlignment = _receiptStraightnessScore(reviewSource);
  final requiredGain = math.max(.045, baselineAlignment.abs() * .055);
  if (bestDegrees.abs() < .5 ||
      bestAlignment < baselineAlignment + requiredGain ||
      bestQuality.textBandScore < reviewQuality.textBandScore * .90) {
    return _ScannerImageDecision(source, 'straighten_skipped_no_benefit');
  }
  final rotated = img.copyRotate(
    source,
    angle: bestDegrees,
    interpolation: img.Interpolation.linear,
  );
  final rotatedQuality = _qualityCheck(rotated);
  if (rotatedQuality.reviewScore + 1 < sourceQuality.reviewScore ||
      rotatedQuality.textBandScore < sourceQuality.textBandScore * .92) {
    return _ScannerImageDecision(source, 'straighten_skipped_quality_guard');
  }
  return _ScannerImageDecision(rotated, 'straighten_applied_text_bands');
}

double _receiptStraightnessScore(img.Image source) {
  final sample = _resizeToMaxSide(source, 480);
  if (sample.width < 8 || sample.height < 8) return 0;
  final rowEnergy = <double>[];
  var horizontalEdgeEnergy = 0.0;
  var verticalEdgeEnergy = 0.0;
  for (var y = 2; y < sample.height - 2; y += 2) {
    var energy = 0.0;
    for (var x = 2; x < sample.width - 2; x += 2) {
      final center = _luma(sample.getPixel(x, y));
      final vertical = (center - _luma(sample.getPixel(x, y - 2))).abs();
      final horizontal = (center - _luma(sample.getPixel(x - 2, y))).abs();
      if (vertical >= 12) energy += vertical;
      horizontalEdgeEnergy += vertical;
      verticalEdgeEnergy += horizontal;
    }
    rowEnergy.add(energy);
  }
  if (rowEnergy.isEmpty || horizontalEdgeEnergy < 1) return 0;
  final mean = rowEnergy.reduce((a, b) => a + b) / rowEnergy.length;
  if (mean < 1) return 0;
  var variance = 0.0;
  for (final energy in rowEnergy) {
    final delta = energy - mean;
    variance += delta * delta;
  }
  variance /= rowEnergy.length;
  final rowConcentration = variance / (mean * mean + 1);
  final directionality =
      horizontalEdgeEnergy /
      math.max(1.0, horizontalEdgeEnergy + verticalEdgeEnergy);
  return rowConcentration + directionality * .35;
}
