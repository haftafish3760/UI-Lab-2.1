part of 'receipt_capture_models.dart';

class ReceiptImageStoragePreview {
  const ReceiptImageStoragePreview({
    required this.originalBytes,
    required this.estimatedBytes,
    required this.level,
    required this.quality,
  });

  final int originalBytes;
  final int estimatedBytes;
  final ReceiptDataSaverLevel level;
  final ReceiptPhotoQualityCheck quality;

  int get savedBytes =>
      (originalBytes - estimatedBytes).clamp(0, originalBytes);
  double get savedPercent =>
      originalBytes <= 0 ? 0 : savedBytes / originalBytes;

  String get originalLabel =>
      ReceiptStorageFormatter.formatBytes(originalBytes);
  String get estimatedLabel =>
      ReceiptStorageFormatter.formatBytes(estimatedBytes);
  String get savedLabel => ReceiptStorageFormatter.formatBytes(savedBytes);
}

class ReceiptPhotoQualityCheck {
  const ReceiptPhotoQualityCheck({
    required this.width,
    required this.height,
    required this.focusScore,
    required this.isLikelyReadable,
    this.detailScore,
    this.brightness = 128,
    this.contrast = 28,
    this.cropScore = .72,
    this.textBandScore = 12,
    this.largestInteriorTextGapRatio = 0,
    this.inkCoverage = .18,
  });

  final int width;
  final int height;
  final double focusScore;
  final double? detailScore;
  final bool isLikelyReadable;
  final double brightness;
  final double contrast;
  final double cropScore;
  final double textBandScore;
  final double largestInteriorTextGapRatio;
  final double inkCoverage;

  String get resolutionLabel => '${width}x$height';
  int get reviewScore {
    if (width <= 0 || height <= 0) return 0;
    final detailLimitedFocus = _safeDetailScore * 1.35;
    final combinedFocus = _safeFocusScore < detailLimitedFocus
        ? _safeFocusScore
        : detailLimitedFocus;
    final focusPoints = (combinedFocus / 18 * 42).clamp(0, 42).round();
    final shortestSide = width < height ? width : height;
    final resolutionPoints = (shortestSide / 1600 * 22).clamp(0, 22).round();
    final contrastPoints = (_safeContrast / 34 * 16).clamp(0, 16).round();
    final cropPoints = (_safeCropScore * 12).clamp(0, 12).round();
    final textPoints = (_safeTextBandScore / 12 * 8).clamp(0, 8).round();
    final lightPenalty = isTooDark || isTooBright ? 18 : 0;
    final missingRegionPenalty = isSevereInteriorTextGap
        ? 24
        : isLargeInteriorTextGap
        ? 12
        : 0;
    final texturePenalty = isChaoticTexture ? 24 : 0;
    final rawScore =
        (focusPoints +
                resolutionPoints +
                contrastPoints +
                cropPoints +
                textPoints -
                lightPenalty -
                missingRegionPenalty -
                texturePenalty)
            .clamp(0, 100)
            .toInt();
    if (isLikelyReadable && !isTooDark && !isTooBright && !isVerySoft) {
      return rawScore < 82 ? 82 : rawScore;
    }
    return rawScore;
  }

  String get reviewScoreLabel => '$reviewScore%';
  bool get isTooDark => _safeBrightness < 68;
  bool get isUnderexposedForReceipt => _safeBrightness < 92;
  bool get isTooBright => _safeBrightness > 246;
  bool get isBrightButReadable => _safeBrightness > 224 && !isTooBright;
  bool get isLowContrast => _safeContrast < 16;
  bool get isPoorlyFramed => _safeCropScore < .30;
  bool get isMissingTextBands => _safeTextBandScore < 6;
  bool get isLargeInteriorTextGap => _safeInteriorTextGapRatio >= .10;
  bool get isSevereInteriorTextGap => _safeInteriorTextGapRatio >= .22;
  bool get isChaoticTexture => _safeInkCoverage > .46 && _safeTextBandScore < 4;
  bool get isLowResolution => width < 900 || height < 900;
  bool get isSoft =>
      _safeFocusScore < 8 || (detailScore != null && _safeDetailScore < 20);
  bool get isVerySoft =>
      _safeFocusScore < 5.5 || (detailScore != null && _safeDetailScore < 9);
  bool get isUnreadableImage => width <= 0 || height <= 0;
  bool get hasCriticalIssue =>
      isUnreadableImage ||
      isTooDark ||
      isTooBright ||
      isVerySoft ||
      isSevereInteriorTextGap ||
      isChaoticTexture;
  bool get isReadableScore => reviewScore >= 70;
  bool get isExcellentScore => reviewScore >= 85;
  double get brightnessDistanceFromReceiptIdeal =>
      (_safeBrightness - 150).abs();
  bool get needsReview {
    if (hasCriticalIssue) return true;
    if (qualityWarnings.isNotEmpty) return true;
    if (isReadableScore && isLikelyReadable) return false;
    if (reviewScore >= 80 && !isSoft && !isLowResolution) return false;
    return !isLikelyReadable || reviewScore < 70 || qualityWarnings.isNotEmpty;
  }

  bool get canContinueWithReview => !isUnreadableImage;
  bool get shouldRetakeBeforeOcr => hasCriticalIssue || reviewScore < 50;
  String get reviewActionCode {
    if (shouldRetakeBeforeOcr) return 'retake_recommended_continue_allowed';
    if (isPoorlyFramed && !isLikelyReadable) return 'crop_or_retake_then_next';
    if (isLowResolution || isMissingTextBands) {
      return 'check_readability_or_add_closer_photo';
    }
    if (needsReview) return 'check_photo_then_next';
    return 'continue_to_receipt_details';
  }

  String get reviewActionFamily {
    if (reviewActionCode.startsWith('retake')) return 'retake';
    if (reviewActionCode.startsWith('continue')) return 'continue';
    return 'review';
  }

  String get nextReviewActionLabel {
    if (shouldRetakeBeforeOcr) {
      return 'Retake recommended; use the photo only if the text is readable';
    }
    if (reviewActionCode == 'crop_or_retake_then_next') {
      return 'Crop or retake if text is missing; use the photo only if the text is readable';
    }
    if (reviewActionCode == 'check_readability_or_add_closer_photo') {
      return 'Check readability or add a closer photo';
    }
    if (needsReview) return 'Check photo, then use it if the text is readable';
    return 'Use this photo for receipt details';
  }

  String get userFacingStatusLabel {
    if (shouldRetakeBeforeOcr) {
      return '$reviewTitle: $reviewGuidance';
    }
    if (needsReview) {
      return '$reviewTitle: $reviewGuidance';
    }
    return reviewGuidance;
  }

  String get qualityEvidenceLabel {
    final parts = <String>[
      '$reviewBandLabel; photo check $reviewScoreLabel',
      'light $lightLabel',
      'focus $focusLabel',
      framingLabel,
    ];
    if (_safeTextBandScore < 8) parts.add('receipt lines weak');
    return parts.join(' • ');
  }

  String get reviewScoreMeaningLabel {
    if (shouldRetakeBeforeOcr) {
      return 'Retake is safer, but you can still use the photo if the receipt text is readable.';
    }
    if (needsReview) {
      return 'Photo check is guidance only. If the receipt text is readable, you can still use the photo.';
    }
    return 'Photo check is guidance only. Use the photo if the receipt text is readable.';
  }

  String get reviewBandLabel {
    if (hasCriticalIssue || reviewScore < 50) return 'Retake recommended';
    if (reviewScore < 70) return 'Check before using';
    if (isExcellentScore) return 'Excellent receipt photo';
    return 'Readable receipt photo';
  }

  String get focusLabel {
    if (_safeFocusScore >= 14) return 'sharp';
    if (_safeFocusScore >= 8) return 'usable';
    return 'may be blurry';
  }

  String get lightLabel {
    if (isTooDark) return 'too dark';
    if (isUnderexposedForReceipt) return 'a little dark';
    if (isTooBright) return 'glare/too bright';
    if (isBrightButReadable) return 'bright but usable';
    return 'light OK';
  }

  String get framingLabel {
    if (isPoorlyFramed) return 'check that no text is cut off';
    if (_safeCropScore < .50) return 'check framing';
    return 'framed';
  }

  String get primaryIssueLabel {
    if (isUnreadableImage) return 'could not read image';
    if (isTooDark) return 'too dark';
    if (isTooBright) return 'glare or too bright';
    if (isVerySoft) return 'looks blurry';
    if (isSoft) return 'check sharpness';
    if (isUnderexposedForReceipt) return 'could be brighter';
    if (isLowResolution) return 'move closer';
    if (isLowContrast) return 'low contrast';
    if (isChaoticTexture) return 'image does not look like receipt text';
    if (isLargeInteriorTextGap) return 'receipt text missing in one area';
    if (isPoorlyFramed) return 'check that no text is cut off';
    if (isMissingTextBands) return 'printed lines are weak';
    return 'looks readable';
  }

  String get reviewTitle {
    if (hasCriticalIssue) return 'Retake Recommended';
    if (reviewScore >= 70) return reviewBandLabel;
    if (needsReview) return 'Check Before Continuing';
    return 'Receipt Looks Readable';
  }

  String get reviewGuidance {
    if (isUnreadableImage) {
      return 'The app could not read this image file. Take another photo or choose a different image.';
    }
    if (isTooDark) {
      return 'Add light or turn on the torch so the printed receipt text is readable.';
    }
    if (isTooBright) {
      return 'Reduce glare by tilting the phone or receipt before taking another photo.';
    }
    if (isBrightButReadable) {
      return 'The receipt is bright but usable. Check for glare, then use the photo if the store, date, total, and item prices are readable.';
    }
    if (isVerySoft) {
      return 'Hold steady and let continuous autofocus settle. Retake if the store, date, total, or item prices stay fuzzy.';
    }
    if (isSoft) {
      return 'Zoom in and check the store, date, total, and item prices before continuing.';
    }
    if (isUnderexposedForReceipt) {
      return 'The receipt is readable but darker than ideal. Add light, turn on the torch, or retake if the bottom text looks dim.';
    }
    if (isLowResolution) {
      return 'If item text is too small, add another closer photo. If every line is readable, use this photo.';
    }
    if (isLowContrast) {
      return 'Check that the printed text stands out from the paper before continuing.';
    }
    if (isChaoticTexture) {
      return 'The image has sharp texture but not clear receipt lines. Retake with the receipt filling the frame.';
    }
    if (isLargeInteriorTextGap) {
      return 'A section of the receipt has little readable text. Check for glare, a shadow, a fold, or missing lines and retake or add a closer photo if needed.';
    }
    if (isPoorlyFramed) {
      return 'If every line of the receipt is visible, use this photo. Use crop or retake only if part of the receipt is missing.';
    }
    if (isMissingTextBands) {
      return 'Some printed lines look weak. Check the item prices before saving.';
    }
    if (reviewScore >= 70) {
      return 'This looks readable. Use this photo for receipt details, or add another photo only if the receipt continues.';
    }
    return 'Check the store, date, total, and item prices. If they are readable, use this photo; otherwise retake or add another photo.';
  }

  List<String> get qualityWarnings {
    return [
      if (isUnreadableImage) 'Image could not be decoded.',
      if (isTooDark) 'Photo is too dark.',
      if (!isTooDark && isUnderexposedForReceipt)
        'Photo is darker than ideal for receipt assistance.',
      if (isTooBright)
        'Photo has glare or is too bright.'
      else if (isBrightButReadable && !isLikelyReadable)
        'Photo is bright; check for glare before continuing.',
      if (isVerySoft)
        'Photo looks blurry.'
      else if (isSoft)
        'Photo sharpness should be checked.',
      if (isLowResolution) 'Receipt resolution is low.',
      if (isLowContrast) 'Printed text has low contrast.',
      if (isChaoticTexture)
        'Sharp texture was detected without normal receipt-line structure.',
      if (isLargeInteriorTextGap)
        'A large section between printed receipt lines may be washed out or obstructed.',
      if (isPoorlyFramed) 'Check that every receipt line is visible.',
      if (isMissingTextBands) 'Receipt text lines are hard to detect.',
    ];
  }

  double get _safeFocusScore => focusScore.isFinite ? focusScore : 0;
  double get _safeDetailScore {
    final value = detailScore;
    if (value == null) return _safeFocusScore;
    return value.isFinite ? value : 0;
  }

  double get _safeBrightness => brightness.isFinite ? brightness : 0;
  double get _safeContrast => contrast.isFinite ? contrast : 0;
  double get _safeCropScore => cropScore.isFinite ? cropScore : 0;
  double get _safeTextBandScore => textBandScore.isFinite ? textBandScore : 0;
  double get _safeInteriorTextGapRatio => largestInteriorTextGapRatio.isFinite
      ? largestInteriorTextGapRatio.clamp(0, 1)
      : 1;
  double get _safeInkCoverage =>
      inkCoverage.isFinite ? inkCoverage.clamp(0, 1) : 1;

  ReceiptCaptureReadinessDecision captureReadiness({
    required bool autoCaptureEnabled,
    int stableFrameCount = 0,
    int requiredStableFrames = 3,
  }) {
    return ReceiptCaptureReadinessDecision.fromQuality(
      this,
      autoCaptureEnabled: autoCaptureEnabled,
      stableFrameCount: stableFrameCount,
      requiredStableFrames: requiredStableFrames,
    );
  }
}

enum ReceiptNativeSavedPhotoWarningSeverity { notice, warning, critical }
