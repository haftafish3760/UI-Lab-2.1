import 'receipt_photo_path_identity.dart';

part 'receipt_capture_review_result_continuation.dart';
part 'receipt_capture_review_result_handoff.dart';
part 'receipt_capture_review_result_warnings.dart';
part 'receipt_capture_review_result_handoff_labels.dart';
part 'receipt_capture_review_result_metadata.dart';
part 'receipt_capture_review_result_brain_install_metadata.dart';
part 'receipt_capture_review_result_native_signals.dart';
part 'receipt_capture_review_result_section_order_counts.dart';
part 'receipt_capture_review_result_section_order_helpers.dart';
part 'receipt_capture_review_result_section_order_review.dart';
part 'receipt_capture_review_result_completion.dart';
part 'receipt_capture_review_result_next_review.dart';
part 'receipt_capture_review_result_helpers.dart';
part 'receipt_capture_review_result_handoff_counts.dart';
part 'receipt_capture_review_result_handoff_brain_counts.dart';
part 'receipt_capture_review_result_handoff_storage.dart';
part 'receipt_capture_review_result_native_brain_signals.dart';
part 'receipt_capture_review_result_native_outcomes.dart';
part 'receipt_capture_review_result_helper_counts.dart';
part 'receipt_capture_review_result_helper_count_functions.dart';
part 'receipt_capture_review_result_helper_health_codes.dart';
part 'receipt_capture_review_result_helper_control_health_codes.dart';
part 'receipt_capture_review_result_helper_diagnostics.dart';
part 'receipt_capture_review_result_settings_health.dart';
part 'receipt_capture_stitch_pair_models.dart';
part 'receipt_capture_stitch_models.dart';
part 'receipt_capture_stitch_result_labels.dart';
part 'receipt_capture_stitch_model_helpers.dart';
part 'receipt_camera_result_models.dart';
part 'receipt_camera_result_diagnostics.dart';
part 'receipt_photo_quality_models.dart';
part 'receipt_capture_readiness_decision.dart';
part 'receipt_native_saved_photo_warning.dart';
part 'receipt_native_saved_photo_warning_details.dart';
part 'receipt_photo_coverage_decision.dart';
part 'receipt_photo_coverage_decision_from_signals.dart';
part 'receipt_photo_coverage_evidence_helpers.dart';
part 'receipt_photo_coverage_decision_labels.dart';
part 'receipt_camera_fixture_matrix.dart';
part 'receipt_attachment_record.dart';
part 'receipt_attachment_record_serialization.dart';
part 'receipt_attachment_storage_models.dart';

final class ReceiptCaptureDiagnosticKeys {
  const ReceiptCaptureDiagnosticKeys._();

  static const latestFramingSignal = 'latestFramingSignal';
  static const latestFramingConfidence = 'latestFramingConfidence';
  static const latestEdgeCoverage = 'latestEdgeCoverage';
  static const latestFramingWidthRatio = 'latestFramingWidthRatio';
  static const latestFramingHeightRatio = 'latestFramingHeightRatio';
  static const latestPerspectiveReadiness = 'latestPerspectiveReadiness';
  static const latestReadabilitySignal = 'latestReadabilitySignal';
  static const latestMotionSignal = 'latestMotionSignal';
  static const latestMotionScore = 'latestMotionScore';
  static const latestCapturedPhotoWidth = 'latestCapturedPhotoWidth';
  static const latestCapturedPhotoHeight = 'latestCapturedPhotoHeight';
  static const latestCapturedAverageLuma = 'latestCapturedAverageLuma';
  static const latestCapturedEdgeScore = 'latestCapturedEdgeScore';
  static const latestCapturedTopLuma = 'latestCapturedTopLuma';
  static const latestCapturedMiddleLuma = 'latestCapturedMiddleLuma';
  static const latestCapturedBottomLuma = 'latestCapturedBottomLuma';
  static const latestCapturedBottomEdgeScore = 'latestCapturedBottomEdgeScore';
  static const latestCapturedBottomTopLumaDelta =
      'latestCapturedBottomTopLumaDelta';
  static const latestCapturedBottomTopLumaDeltaBucket =
      'latestCapturedBottomTopLumaDeltaBucket';
  static const latestCapturedVerticalQualitySignal =
      'latestCapturedVerticalQualitySignal';
  static const latestCapturedQualitySignal = 'latestCapturedQualitySignal';
  static const latestCapturedQualityAction = 'latestCapturedQualityAction';
  static const latestCapturedQualityActionFamily =
      'latestCapturedQualityActionFamily';
  static const latestCaptureLiveBrightnessAtShutter =
      'latestCaptureLiveBrightnessAtShutter';
  static const latestCaptureShutterZoomRatio = 'latestCaptureShutterZoomRatio';
  static const latestCaptureShutterExposureIndex =
      'latestCaptureShutterExposureIndex';
  static const latestCaptureShutterExposureTargetBias =
      'latestCaptureShutterExposureTargetBias';
  static const latestCapturedLiveToSavedLumaDelta =
      'latestCapturedLiveToSavedLumaDelta';
  static const latestCapturedLiveToSavedLumaDeltaBucket =
      'latestCapturedLiveToSavedLumaDeltaBucket';
  static const latestCapturedPreviewParitySignal =
      'latestCapturedPreviewParitySignal';
  static const latestCapturedExposureMismatch =
      'latestCapturedExposureMismatch';
  static const capturedLightingEvidence = 'capturedLightingEvidence';
  static const preCaptureExposureOutcome = 'preCaptureExposureOutcome';
  static const latestCaptureToSavedMs = 'latestCaptureToSavedMs';
  static const latestCaptureToReviewReadyMs = 'latestCaptureToReviewReadyMs';
  static const latestNativeCaptureLatencyBucket =
      'latestNativeCaptureLatencyBucket';
  static const nativeCaptureResponsivenessPolicy =
      'nativeCaptureResponsivenessPolicy';
  static const photoCoverageStatus = 'photoCoverageStatus';
  static const photoCoverageReason = 'photoCoverageReason';
  static const photoCoverageNeedsMorePhotos = 'photoCoverageNeedsMorePhotos';
  static const receiptBottomEdgeDetected = 'receiptBottomEdgeDetected';
  static const receiptBottomEdgeStatus = 'receiptBottomEdgeStatus';
  static const receiptSubtotalDetected = 'receiptSubtotalDetected';
  static const receiptTotalDetected = 'receiptTotalDetected';
  static const receiptTotalAmountDetected = 'receiptTotalAmountDetected';
  static const receiptTotalsTextEvidenceStatus =
      'receiptTotalsTextEvidenceStatus';
  static const receiptCompletionUserDecision = 'receiptCompletionUserDecision';
  static const receiptCompletionUserConfirmedComplete =
      'receiptCompletionUserConfirmedComplete';
  static const receiptCompletionPromptReasonCode =
      'receiptCompletionPromptReasonCode';
  static const receiptCompletionPromptNeedsMorePhotos =
      'receiptCompletionPromptNeedsMorePhotos';
  static const captureReadinessCode = 'captureReadinessCode';
  static const captureReadinessLabel = 'captureReadinessLabel';
  static const manualCaptureAllowed = 'manualCaptureAllowed';
  static const autoCaptureAllowed = 'autoCaptureAllowed';
  static const autoCaptureEnabled = 'autoCaptureEnabled';
  static const stableFrameCount = 'stableFrameCount';
  static const requiredStableFrames = 'requiredStableFrames';
}

final class ReceiptNativeCoverageSignalValues {
  const ReceiptNativeCoverageSignalValues._();

  static const framingOk = 'framing_ok';
  static const possiblyCutOff = 'possibly_cut_off';
  static const moveCloser = 'move_closer';
  static const receiptNotFound = 'receipt_not_found';
  static const perspectiveReadySafeBounds = 'perspective_ready_safe_bounds';
  static const perspectiveSkippedCutOffRisk =
      'perspective_skipped_cut_off_risk';
  static const motionSteady = 'steady';
  static const motionMoving = 'moving';
  static const readabilityReadable = 'readable';
  static const readabilityNeedsReview = 'needs_review';
  static const readabilityUnreadable = 'unreadable';

  static const framingSignals = {
    framingOk,
    possiblyCutOff,
    moveCloser,
    receiptNotFound,
  };

  static const perspectiveReadiness = {
    perspectiveReadySafeBounds,
    perspectiveSkippedCutOffRisk,
  };
}

enum ReceiptPhotoReviewOutcome {
  acceptedForReceiptDetails,
  saveDraftAndExit,
  discardAndExit,
}

class ReceiptPhotoReviewResult {
  ReceiptPhotoReviewResult({
    required List<String> photoPaths,
    required List<String> ocrSourcePhotoPaths,
    required this.dataSaverLevel,
    required ReceiptStitchResult stitchResult,
    Map<String, ReceiptPhotoQualityCheck> photoQualityChecksByPath = const {},
    Map<String, Map<String, Object?>> preparationDiagnosticsByOcrPath =
        const {},
    Map<String, Map<String, Object?>> captureDiagnosticsByPhotoPath = const {},
    List<String> temporarySourcePhotoPaths = const [],
    this.outcome = ReceiptPhotoReviewOutcome.acceptedForReceiptDetails,
    bool allowSavedProofOcrFallback = true,
  }) : photoPaths = List.unmodifiable(_uniqueNonBlankPaths(photoPaths)),
       ocrSourcePhotoPaths = List.unmodifiable(
         _uniqueNonBlankPaths(ocrSourcePhotoPaths).isEmpty &&
                 allowSavedProofOcrFallback
             ? _uniqueNonBlankPaths(photoPaths)
             : _uniqueNonBlankPaths(ocrSourcePhotoPaths),
       ),
       photoQualityChecksByPath = _qualityChecksForPaths(
         photoQualityChecksByPath,
         _uniqueNonBlankPaths(photoPaths),
       ),
       preparationDiagnosticsByOcrPath = _diagnosticsForPaths(
         preparationDiagnosticsByOcrPath,
         _uniqueNonBlankPaths(ocrSourcePhotoPaths).isEmpty &&
                 allowSavedProofOcrFallback
             ? _uniqueNonBlankPaths(photoPaths)
             : _uniqueNonBlankPaths(ocrSourcePhotoPaths),
       ),
       captureDiagnosticsByPhotoPath = _diagnosticsForPaths(
         captureDiagnosticsByPhotoPath,
         _uniqueNonBlankPaths(photoPaths),
       ),
       temporarySourcePhotoPaths = List.unmodifiable(
         _uniqueNonBlankPaths(temporarySourcePhotoPaths),
       ),
       stitchResult = _frozenStitchResult(stitchResult),
       photoPathInputWasSanitized = _pathInputWasSanitized(photoPaths),
       ocrSourcePathInputWasSanitized = _pathInputWasSanitized(
         ocrSourcePhotoPaths,
       ),
       usedSavedProofAsOcrSourceFallback =
           allowSavedProofOcrFallback &&
           _uniqueNonBlankPaths(ocrSourcePhotoPaths).isEmpty &&
           _uniqueNonBlankPaths(photoPaths).isNotEmpty;

  factory ReceiptPhotoReviewResult.keptForLater({
    required List<String> photoPaths,
    required ReceiptDataSaverLevel dataSaverLevel,
    Map<String, ReceiptPhotoQualityCheck> photoQualityChecksByPath = const {},
    Map<String, Map<String, Object?>> captureDiagnosticsByPhotoPath = const {},
  }) {
    final paths = _uniqueNonBlankPaths(photoPaths);
    return ReceiptPhotoReviewResult(
      photoPaths: paths,
      ocrSourcePhotoPaths: const [],
      dataSaverLevel: dataSaverLevel,
      stitchResult: ReceiptStitchResult(
        status: ReceiptStitchStatus.notNeeded,
        inputPaths: paths,
        ocrSourcePaths: const [],
      ),
      photoQualityChecksByPath: photoQualityChecksByPath,
      captureDiagnosticsByPhotoPath: _withReviewExitDiagnostics(
        captureDiagnosticsByPhotoPath,
        paths,
      ),
      outcome: ReceiptPhotoReviewOutcome.saveDraftAndExit,
      allowSavedProofOcrFallback: false,
    );
  }

  /// An explicit user decision to leave the review without retaining the
  /// staged capture as a resumable draft. This is intentionally distinct from
  /// a route closing unexpectedly, which remains recovery-safe.
  factory ReceiptPhotoReviewResult.discardedByUser({
    required ReceiptDataSaverLevel dataSaverLevel,
  }) {
    return ReceiptPhotoReviewResult(
      photoPaths: const [],
      ocrSourcePhotoPaths: const [],
      dataSaverLevel: dataSaverLevel,
      stitchResult: ReceiptStitchResult(
        status: ReceiptStitchStatus.notNeeded,
        inputPaths: [],
        ocrSourcePaths: [],
      ),
      outcome: ReceiptPhotoReviewOutcome.discardAndExit,
      allowSavedProofOcrFallback: false,
    );
  }

  final List<String> photoPaths;
  final List<String> ocrSourcePhotoPaths;
  final List<String> temporarySourcePhotoPaths;
  final ReceiptDataSaverLevel dataSaverLevel;
  final ReceiptStitchResult stitchResult;
  final Map<String, ReceiptPhotoQualityCheck> photoQualityChecksByPath;
  final Map<String, Map<String, Object?>> preparationDiagnosticsByOcrPath;
  final Map<String, Map<String, Object?>> captureDiagnosticsByPhotoPath;
  final bool photoPathInputWasSanitized;
  final bool ocrSourcePathInputWasSanitized;
  final bool usedSavedProofAsOcrSourceFallback;
  final ReceiptPhotoReviewOutcome outcome;

  String get reviewExitAction => switch (outcome) {
    ReceiptPhotoReviewOutcome.acceptedForReceiptDetails =>
      'accepted_for_receipt_details',
    ReceiptPhotoReviewOutcome.saveDraftAndExit => 'kept_for_later',
    ReceiptPhotoReviewOutcome.discardAndExit => 'discarded_by_user',
  };

  bool get acceptedForReceiptDetails =>
      outcome == ReceiptPhotoReviewOutcome.acceptedForReceiptDetails;

  bool get exitsReceiptFlow =>
      outcome != ReceiptPhotoReviewOutcome.acceptedForReceiptDetails;

  bool get discardedByUser =>
      outcome == ReceiptPhotoReviewOutcome.discardAndExit;
}
