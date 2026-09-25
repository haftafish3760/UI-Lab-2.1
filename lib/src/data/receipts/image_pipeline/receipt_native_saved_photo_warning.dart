part of 'receipt_capture_models.dart';

class ReceiptNativeSavedPhotoReviewWarning {
  const ReceiptNativeSavedPhotoReviewWarning({
    required this.code,
    required this.severity,
    required this.title,
    required this.guidance,
    required this.causeCode,
  });

  factory ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(
    Map<String, Object?>? diagnostics,
  ) {
    final warning = ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(
      diagnostics,
    );
    return warning ?? const ReceiptNativeSavedPhotoReviewWarning.none();
  }

  const ReceiptNativeSavedPhotoReviewWarning.none()
    : code = 'saved_photo_ok',
      severity = ReceiptNativeSavedPhotoWarningSeverity.notice,
      title = 'Saved photo looks usable',
      causeCode = 'saved_photo_ok',
      guidance =
          'Check the store, date, total, and item prices, then use this photo.';

  static ReceiptNativeSavedPhotoReviewWarning? maybeFromDiagnostics(
    Map<String, Object?>? diagnostics,
  ) {
    if (diagnostics == null || diagnostics.isEmpty) return null;
    if (diagnostics['documentScannerBackupUsed'] == true ||
        diagnostics['captureFlow'] == 'document_scanner_backup_receipt_photo') {
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_document_scanner_backup',
        severity: ReceiptNativeSavedPhotoWarningSeverity.notice,
        title: 'Backup scanner photo',
        causeCode: 'document_scanner_backup_capture',
        guidance:
            'This backup photo still returns to Maintainiac review. Check the crop, bottom section, subtotal, and total before relying on the reader.',
      );
    }
    if (diagnostics['phoneCameraBackupUsed'] == true ||
        diagnostics['captureFlow'] == 'phone_camera_backup_receipt_photo') {
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_phone_camera_backup',
        severity: ReceiptNativeSavedPhotoWarningSeverity.notice,
        title: 'Phone camera backup photo',
        causeCode: 'phone_camera_backup_capture',
        guidance:
            'This backup photo still returns to Maintainiac review. Check focus, bottom section, subtotal, and total before relying on the reader.',
      );
    }
    final mismatch =
        diagnostics[ReceiptCaptureDiagnosticKeys.latestCapturedExposureMismatch]
            ?.toString()
            .trim();
    final qualitySignal =
        diagnostics[ReceiptCaptureDiagnosticKeys.latestCapturedQualitySignal]
            ?.toString()
            .trim();
    final readabilitySignal =
        diagnostics[ReceiptCaptureDiagnosticKeys.latestReadabilitySignal]
            ?.toString()
            .trim();
    final brightnessBucket = diagnostics['latestCapturedBrightnessBucket']
        ?.toString()
        .trim();
    final lightingEvidence =
        diagnostics[ReceiptCaptureDiagnosticKeys.capturedLightingEvidence]
            ?.toString()
            .trim();
    final previewParitySignal =
        diagnostics[ReceiptCaptureDiagnosticKeys
                .latestCapturedPreviewParitySignal]
            ?.toString()
            .trim();
    final preCaptureExposureOutcome =
        diagnostics[ReceiptCaptureDiagnosticKeys.preCaptureExposureOutcome]
            ?.toString()
            .trim();
    final sharpnessBucket = diagnostics['latestCapturedSharpnessBucket']
        ?.toString()
        .trim();
    final verticalQualitySignal =
        diagnostics[ReceiptCaptureDiagnosticKeys
                .latestCapturedVerticalQualitySignal]
            ?.toString()
            .trim();
    final bottomTopLumaDeltaBucket =
        diagnostics[ReceiptCaptureDiagnosticKeys
                .latestCapturedBottomTopLumaDeltaBucket]
            ?.toString()
            .trim();
    final bottomLuma = _doubleValue(
      diagnostics[ReceiptCaptureDiagnosticKeys.latestCapturedBottomLuma],
    );
    final averageLuma = _doubleValue(
      diagnostics[ReceiptCaptureDiagnosticKeys.latestCapturedAverageLuma],
    );
    final edgeScore = _doubleValue(
      diagnostics[ReceiptCaptureDiagnosticKeys.latestCapturedEdgeScore],
    );
    if (mismatch == 'pre_capture_brightened_still_too_dark') {
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_brightness_assist_failed_dark',
        severity: ReceiptNativeSavedPhotoWarningSeverity.critical,
        title: 'Photo stayed too dark after brightness assist',
        causeCode: 'pre_capture_brightness_assist_failed',
        guidance:
            'Retake with more light or turn on the receipt light before using this photo.',
      );
    }
    if (mismatch == 'pre_capture_brightened_still_dim' ||
        (preCaptureExposureOutcome == 'lifted_for_dim_receipt' &&
            lightingEvidence == 'capture_dim_review_needed')) {
      if (_isBorderlineDimButReadable(averageLuma, edgeScore)) return null;
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_brightness_assist_still_dim',
        severity: ReceiptNativeSavedPhotoWarningSeverity.warning,
        title: 'Photo stayed dim after brightness assist',
        causeCode: 'pre_capture_brightness_assist_still_dim',
        guidance:
            'Check the receipt text and totals. Add light or retake if the lower lines are hard to read.',
      );
    }
    if (lightingEvidence == 'capture_too_dark' ||
        previewParitySignal ==
            'saved_photo_darker_than_preview_review_needed' ||
        mismatch == 'live_ok_capture_too_dark' ||
        qualitySignal == 'retake_brightness_risk' ||
        brightnessBucket == 'captured_too_dark') {
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_darker_than_preview',
        severity: ReceiptNativeSavedPhotoWarningSeverity.critical,
        title: 'Photo saved darker than preview',
        causeCode: 'saved_photo_darker_than_live_preview',
        guidance:
            'Retake with more light or raise Brightness before using this photo.',
      );
    }
    if (previewParitySignal ==
        'saved_photo_brighter_than_preview_review_needed') {
      if (lightingEvidence == 'capture_glare_risk' ||
          mismatch == 'live_glare_capture_glare' ||
          brightnessBucket == 'captured_glare_risk' ||
          brightnessBucket == 'too_bright') {
        if (_isBrightReadablePaper(averageLuma, edgeScore)) return null;
        return const ReceiptNativeSavedPhotoReviewWarning(
          code: 'saved_photo_glare_risk',
          severity: ReceiptNativeSavedPhotoWarningSeverity.warning,
          title: 'Photo may have glare',
          causeCode: 'saved_photo_glare_or_too_bright',
          guidance:
              'Tilt the receipt or lighting, retake if totals are washed out, or use the photo if the text is readable.',
        );
      }
      if (_isBrightReadablePaper(averageLuma, edgeScore)) return null;
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_brighter_than_preview',
        severity: ReceiptNativeSavedPhotoWarningSeverity.warning,
        title: 'Photo saved brighter than preview',
        causeCode: 'saved_photo_brighter_than_live_preview',
        guidance:
            'Check for washed-out totals or glare. Lower Brightness, tilt the receipt, or retake if the text is hard to read.',
      );
    }
    if (qualitySignal == 'retake_blur_risk' ||
        sharpnessBucket == 'captured_soft_blur_risk') {
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_soft_blur_risk',
        severity: ReceiptNativeSavedPhotoWarningSeverity.critical,
        title: 'Photo may be too soft',
        causeCode: 'saved_photo_soft_blur_risk',
        guidance:
            'Retake while holding steady if the store, date, total, or item prices look fuzzy.',
      );
    }
    if (readabilitySignal == 'dirty_lens_or_haze') {
      if (edgeScore == null) return null;
      if (_isClearEnoughAfterLensWarning(edgeScore)) return null;
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_dirty_lens_or_haze',
        severity: ReceiptNativeSavedPhotoWarningSeverity.warning,
        title: 'Photo may look hazy',
        causeCode: 'dirty_lens_or_hazy_live_preview',
        guidance:
            'Wipe the lens and retake if the store, date, total, or item prices look cloudy.',
      );
    }
    if (readabilitySignal == 'shadow_risk') {
      if (averageLuma == null || edgeScore == null) return null;
      if (_isBorderlineDimButReadable(averageLuma, edgeScore)) return null;
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_shadow_risk',
        severity: ReceiptNativeSavedPhotoWarningSeverity.warning,
        title: 'Photo has heavy shadows',
        causeCode: 'uneven_shadow_over_receipt_text',
        guidance:
            'Move the receipt into even light and retake if shadows cover the store, date, total, or item prices.',
      );
    }
    if (lightingEvidence == 'bottom_lighting_risk' ||
        verticalQualitySignal == 'bottom_too_dark' ||
        verticalQualitySignal == 'bottom_darker_than_upper' ||
        bottomTopLumaDeltaBucket == 'bottom_darker_than_top' ||
        bottomTopLumaDeltaBucket == 'bottom_much_darker_than_top') {
      if (_isBottomReadableEnough(bottomLuma, edgeScore)) return null;
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_bottom_too_dark',
        severity: ReceiptNativeSavedPhotoWarningSeverity.warning,
        title: 'Bottom of photo looks darker',
        causeCode: 'bottom_receipt_lines_darker_than_upper',
        guidance:
            'Zoom into the bottom receipt lines. Retake or raise Brightness if the total or barcode area is hard to read.',
      );
    }
    if (verticalQualitySignal == 'bottom_soft_blur_risk') {
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_bottom_soft',
        severity: ReceiptNativeSavedPhotoWarningSeverity.warning,
        title: 'Bottom of photo may be soft',
        causeCode: 'bottom_receipt_lines_soft_blur_risk',
        guidance:
            'Zoom into the bottom receipt lines. Retake while holding steady if they look fuzzy.',
      );
    }
    if (lightingEvidence == 'capture_dim_review_needed' ||
        previewParitySignal == 'saved_photo_darker_than_preview_watch' ||
        mismatch == 'live_ok_capture_dim' ||
        mismatch == 'live_dim_capture_dim' ||
        brightnessBucket == 'captured_dim' ||
        brightnessBucket == 'dim') {
      if (_isBorderlineDimButReadable(averageLuma, edgeScore)) return null;
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_dimmer_than_preview',
        severity: ReceiptNativeSavedPhotoWarningSeverity.warning,
        title: 'Photo saved a little dimmer than preview',
        causeCode: 'saved_photo_dim_or_live_to_saved_mismatch',
        guidance:
            'Check the receipt text, retake if the bottom looks dim, or use the photo if it is readable.',
      );
    }
    if (lightingEvidence == 'capture_glare_risk' ||
        mismatch == 'live_glare_capture_glare' ||
        brightnessBucket == 'captured_glare_risk' ||
        brightnessBucket == 'too_bright') {
      if (_isBrightReadablePaper(averageLuma, edgeScore)) return null;
      return const ReceiptNativeSavedPhotoReviewWarning(
        code: 'saved_photo_glare_risk',
        severity: ReceiptNativeSavedPhotoWarningSeverity.warning,
        title: 'Photo may have glare',
        causeCode: 'saved_photo_glare_or_too_bright',
        guidance:
            'Tilt the receipt or lighting, retake if totals are washed out, or use the photo if the text is readable.',
      );
    }
    return null;
  }

  final String code;
  final ReceiptNativeSavedPhotoWarningSeverity severity;
  final String title;
  final String guidance;
  final String causeCode;

  static bool _isBorderlineDimButReadable(
    double? averageLuma,
    double? edgeScore,
  ) {
    return averageLuma != null &&
        averageLuma >= 100 &&
        edgeScore != null &&
        edgeScore >= 12;
  }

  static bool _isBrightReadablePaper(double? averageLuma, double? edgeScore) {
    return averageLuma != null &&
        averageLuma < 250 &&
        edgeScore != null &&
        edgeScore >= 12;
  }

  static bool _isBottomReadableEnough(double? bottomLuma, double? edgeScore) {
    return bottomLuma != null &&
        bottomLuma >= 100 &&
        edgeScore != null &&
        edgeScore >= 12;
  }

  static bool _isClearEnoughAfterLensWarning(double? edgeScore) {
    return edgeScore != null && edgeScore >= 12;
  }

  static double? _doubleValue(Object? value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString().trim() ?? '');
    if (parsed == null || !parsed.isFinite) return null;
    return parsed;
  }
}
