part of 'receipt_capture_models.dart';

extension ReceiptCameraCaptureEvidenceDiagnostics
    on ReceiptCameraCaptureEvidence {
  Map<String, Object?> toCaptureDiagnostics({
    required ReceiptPhotoQualityCheck? quality,
    required int photoIndex,
  }) {
    return {
      'engine': captureSurface,
      'captureFlow': captureFlow,
      'captureFallbackSource': 'receipt_camera_result',
      'photoIndex': photoIndex,
      'resolutionTier': resolutionTier,
      'resolutionPreset': resolutionPreset,
      'flashMode': flashMode,
      'exposureMode': exposureMode,
      'focusMode': focusMode,
      'exposurePointSupported': exposurePointSupported,
      'focusPointSupported': focusPointSupported,
      'zoomLevelBucket': _zoomBucket(zoomLevel),
      // Keep the exact native shutter zoom in the review handoff. The bucket
      // is useful for diagnostics, but it cannot prove that capture and
      // review used the same framing.
      ReceiptCaptureDiagnosticKeys.latestCaptureShutterZoomRatio: _finiteDouble(
        zoomLevel,
      ),
      'nativeZoomRangeBucket':
          '${_zoomBucket(minZoomLevel)}_${_zoomBucket(maxZoomLevel)}',
      'latestBrightnessBucket': _brightnessBucket(
        _finiteDouble(liveBrightness),
      ),
      'latestCapturedBrightnessBucket': _capturedBrightnessBucket(
        quality?.brightness,
      ),
      'latestCapturedSharpnessBucket': _sharpnessBucket(quality?.focusScore),
      'latestCapturedQualitySignal': quality == null
          ? 'quality_not_checked'
          : quality.isLikelyReadable
          ? 'captured_readable'
          : 'captured_needs_review',
      ReceiptCaptureDiagnosticKeys.latestCapturedQualityAction:
          quality?.reviewActionCode ?? 'quality_action_unknown',
      ReceiptCaptureDiagnosticKeys.latestCapturedQualityActionFamily:
          quality?.reviewActionFamily ?? 'unknown',
      'latestCaptureLiveBrightnessAtShutter': _finiteDouble(liveBrightness),
      'latestCapturedLiveToSavedLumaDelta': quality == null
          ? null
          : _roundedDiagnostic(
              quality.brightness -
                  (_finiteDouble(liveBrightness) ?? quality.brightness),
            ),
      'latestCapturedLiveToSavedLumaDeltaBucket': _liveToSavedLumaDeltaBucket(
        quality: quality,
      ),
      'latestCapturedPreviewParitySignal': _previewParitySignalFor(
        quality: quality,
      ),
      'latestCapturedExposureMismatch': _exposureMismatchFor(quality: quality),
      'capturedLightingEvidence': _capturedLightingEvidenceFor(
        quality: quality,
      ),
      'liveReadiness': liveReadiness,
      'imageStreamActiveAtCapture': imageStreamActiveAtCapture,
      'nativeExposureBaseline': exposureAtNativeBaseline,
      'selectedExposureBucket': _exposureBucket(
        selectedExposureOffset ?? exposureOffset,
      ),
      'scannerDecisionCodes': List<String>.unmodifiable([
        'receipt_camera_result_bridge',
        if (hasDarkLiveFrame) 'live_preview_dark',
        if (hasUnderexposedLiveFrame) 'live_preview_underexposed',
        if (quality?.isLikelyReadable == true) 'captured_readable',
        if (quality?.isLikelyReadable == false) 'captured_needs_review',
      ]),
    };
  }

  String _liveToSavedLumaDeltaBucket({
    required ReceiptPhotoQualityCheck? quality,
  }) {
    if (quality == null) return 'unknown';
    final measuredLiveBrightness = _finiteDouble(liveBrightness);
    if (measuredLiveBrightness == null) return 'unknown';
    final delta = quality.brightness - measuredLiveBrightness;
    if (delta <= -58) return 'saved_much_darker_than_preview';
    if (delta <= -32) return 'saved_darker_than_preview';
    if (delta >= 58) return 'saved_much_brighter_than_preview';
    if (delta >= 32) return 'saved_brighter_than_preview';
    return 'saved_matches_preview';
  }

  String _previewParitySignalFor({required ReceiptPhotoQualityCheck? quality}) {
    if (quality == null) return 'unknown';
    final bucket = _liveToSavedLumaDeltaBucket(quality: quality);
    if (bucket == 'unknown') return 'unknown';
    final capturedBucket = _capturedBrightnessBucket(quality.brightness);
    if (bucket == 'saved_much_darker_than_preview' ||
        (bucket == 'saved_darker_than_preview' &&
            (capturedBucket == 'captured_too_dark' ||
                capturedBucket == 'captured_dim'))) {
      return 'saved_photo_darker_than_preview_review_needed';
    }
    if (bucket == 'saved_darker_than_preview') {
      return 'saved_photo_darker_than_preview_watch';
    }
    if (bucket == 'saved_much_brighter_than_preview' ||
        (bucket == 'saved_brighter_than_preview' &&
            capturedBucket == 'captured_glare_risk')) {
      return 'saved_photo_brighter_than_preview_review_needed';
    }
    if (bucket == 'saved_brighter_than_preview') {
      return 'saved_photo_brighter_than_preview_watch';
    }
    return 'saved_photo_matches_preview';
  }

  double _roundedDiagnostic(double value) {
    if (!value.isFinite) return -1;
    return (value * 10).roundToDouble() / 10;
  }

  static double? _finiteDouble(double? value) {
    if (value == null || !value.isFinite) return null;
    return value;
  }

  String _exposureMismatchFor({required ReceiptPhotoQualityCheck? quality}) {
    if (quality == null) return 'capture_quality_unknown';
    if (hasUnderexposedLiveFrame && quality.brightness < 90) {
      return 'live_dim_capture_dim';
    }
    if (!hasUnderexposedLiveFrame && quality.brightness < 75) {
      return 'live_ok_capture_too_dark';
    }
    if (hasBrightLiveFrame && quality.brightness > 225) {
      return 'live_glare_capture_glare';
    }
    return 'live_capture_consistent';
  }

  String _capturedLightingEvidenceFor({
    required ReceiptPhotoQualityCheck? quality,
  }) {
    if (quality == null) return 'unknown';
    if (quality.isTooDark || quality.isUnderexposedForReceipt) {
      return 'capture_too_dark';
    }
    if (quality.isTooBright || quality.isBrightButReadable) {
      return 'capture_glare_risk';
    }
    if (!quality.isLikelyReadable && quality.brightness < 118) {
      return 'capture_dim_review_needed';
    }
    return 'lighting_readable';
  }

  static String _brightnessBucket(double? value) {
    if (value == null) return 'brightness_unknown';
    if (value < 55) return 'too_dark';
    if (value < 90) return 'dim';
    if (value > 225) return 'glare_risk';
    return 'normal';
  }

  static String _capturedBrightnessBucket(double? value) {
    if (value == null) return 'captured_brightness_unknown';
    if (value < 55) return 'captured_too_dark';
    if (value < 90) return 'captured_dim';
    if (value > 225) return 'captured_glare_risk';
    return 'captured_readable';
  }

  static String _sharpnessBucket(double? value) {
    if (value == null) return 'sharpness_unknown';
    if (value < 8) return 'captured_soft_blur_risk';
    if (value < 14) return 'captured_usable';
    return 'captured_sharp';
  }

  static String _zoomBucket(double value) {
    if (value < 1.2) return 'zoom_1x';
    if (value < 2.2) return 'zoom_2x';
    if (value < 4.2) return 'zoom_4x';
    return 'zoom_high';
  }

  static String _exposureBucket(double? value) {
    if (value == null) return 'exposure_unknown';
    if (value < -.25) return 'exposure_darker';
    if (value > .25) return 'exposure_brighter';
    return 'exposure_baseline';
  }
}
