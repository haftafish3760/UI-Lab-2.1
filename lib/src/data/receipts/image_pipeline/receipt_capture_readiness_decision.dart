part of 'receipt_capture_models.dart';

class ReceiptCaptureReadinessDecision {
  const ReceiptCaptureReadinessDecision({
    required this.code,
    required this.label,
    required this.manualCaptureAllowed,
    required this.autoCaptureAllowed,
    required this.autoCaptureEnabled,
    required this.stableFrameCount,
    required this.requiredStableFrames,
  });

  factory ReceiptCaptureReadinessDecision.fromQuality(
    ReceiptPhotoQualityCheck quality, {
    required bool autoCaptureEnabled,
    int stableFrameCount = 0,
    int requiredStableFrames = 3,
  }) {
    final safeRequiredFrames = requiredStableFrames < 1
        ? 1
        : requiredStableFrames;
    final safeStableFrames = stableFrameCount < 0 ? 0 : stableFrameCount;

    if (quality.isUnreadableImage) {
      return _manualOnly(
        code: 'manual_only_unreadable_image',
        label: 'Take a new photo when the receipt is visible.',
        autoCaptureEnabled: autoCaptureEnabled,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    if (!autoCaptureEnabled) {
      return ReceiptCaptureReadinessDecision(
        code: 'manual_ready_auto_capture_off',
        label: 'Manual capture is ready. Auto capture is off.',
        manualCaptureAllowed: true,
        autoCaptureAllowed: false,
        autoCaptureEnabled: false,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    if (quality.hasCriticalIssue) {
      return _manualOnly(
        code: 'manual_only_quality_retake_recommended',
        label: quality.reviewGuidance,
        autoCaptureEnabled: true,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    if (quality.isPoorlyFramed || quality.isMissingTextBands) {
      return _manualOnly(
        code: 'manual_only_check_framing',
        label: 'Check that every receipt line is visible before auto capture.',
        autoCaptureEnabled: true,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    if (quality.needsReview) {
      return _manualOnly(
        code: 'manual_only_quality_review',
        label: 'Check receipt sharpness, light, and text before auto capture.',
        autoCaptureEnabled: true,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    if (safeStableFrames < safeRequiredFrames) {
      return _manualOnly(
        code: 'auto_capture_waiting_for_stability',
        label: 'Hold steady for automatic capture.',
        autoCaptureEnabled: true,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    return ReceiptCaptureReadinessDecision(
      code: 'auto_capture_ready',
      label: 'Receipt looks steady. Taking photo.',
      manualCaptureAllowed: true,
      autoCaptureAllowed: true,
      autoCaptureEnabled: true,
      stableFrameCount: safeStableFrames,
      requiredStableFrames: safeRequiredFrames,
    );
  }

  final String code;
  final String label;
  final bool manualCaptureAllowed;
  final bool autoCaptureAllowed;
  final bool autoCaptureEnabled;
  final int stableFrameCount;
  final int requiredStableFrames;

  static ReceiptCaptureReadinessDecision _manualOnly({
    required String code,
    required String label,
    required bool autoCaptureEnabled,
    required int stableFrameCount,
    required int requiredStableFrames,
  }) {
    return ReceiptCaptureReadinessDecision(
      code: code,
      label: label,
      manualCaptureAllowed: true,
      autoCaptureAllowed: false,
      autoCaptureEnabled: autoCaptureEnabled,
      stableFrameCount: stableFrameCount,
      requiredStableFrames: requiredStableFrames,
    );
  }

  Map<String, Object?> get diagnostics => {
    ReceiptCaptureDiagnosticKeys.captureReadinessCode: code,
    ReceiptCaptureDiagnosticKeys.captureReadinessLabel: label,
    ReceiptCaptureDiagnosticKeys.manualCaptureAllowed: manualCaptureAllowed,
    ReceiptCaptureDiagnosticKeys.autoCaptureAllowed: autoCaptureAllowed,
    ReceiptCaptureDiagnosticKeys.autoCaptureEnabled: autoCaptureEnabled,
    ReceiptCaptureDiagnosticKeys.stableFrameCount: stableFrameCount,
    ReceiptCaptureDiagnosticKeys.requiredStableFrames: requiredStableFrames,
  };
}
