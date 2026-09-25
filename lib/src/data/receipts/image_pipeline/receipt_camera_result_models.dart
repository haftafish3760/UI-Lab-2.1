part of 'receipt_capture_models.dart';

enum ReceiptCameraCaptureMode { singleImage, bestShotCandidates }

class ReceiptCameraResult {
  ReceiptCameraResult({
    required List<String> photoPaths,
    required this.mode,
    List<ReceiptPhotoQualityCheck> qualityChecks = const [],
    this.captureEvidence,
  }) : photoPaths = List<String>.unmodifiable(photoPaths),
       qualityChecks = List<ReceiptPhotoQualityCheck>.unmodifiable(
         qualityChecks,
       );

  ReceiptCameraResult.single(
    List<String> photoPaths, {
    List<ReceiptPhotoQualityCheck> qualityChecks = const [],
    ReceiptCameraCaptureEvidence? captureEvidence,
  }) : this(
         photoPaths: photoPaths,
         mode: ReceiptCameraCaptureMode.singleImage,
         qualityChecks: qualityChecks,
         captureEvidence: captureEvidence,
       );

  ReceiptCameraResult.bestShotCandidates(
    List<String> photoPaths, {
    List<ReceiptPhotoQualityCheck> qualityChecks = const [],
    ReceiptCameraCaptureEvidence? captureEvidence,
  }) : this(
         photoPaths: photoPaths,
         mode: ReceiptCameraCaptureMode.bestShotCandidates,
         qualityChecks: qualityChecks,
         captureEvidence: captureEvidence,
       );

  final List<String> photoPaths;
  final ReceiptCameraCaptureMode mode;
  final List<ReceiptPhotoQualityCheck> qualityChecks;
  final ReceiptCameraCaptureEvidence? captureEvidence;

  bool get isBestShotCandidateSet =>
      mode == ReceiptCameraCaptureMode.bestShotCandidates;

  ReceiptPhotoQualityCheck? get bestQualityCheck {
    if (qualityChecks.isEmpty) return null;
    return qualityChecks.reduce(
      (best, next) => next.reviewScore > best.reviewScore ? next : best,
    );
  }

  Map<String, Map<String, Object?>> captureDiagnosticsByPhotoPath(
    List<String> paths,
  ) {
    final evidence = captureEvidence;
    if (evidence == null) return const {};
    if (!_receiptCameraPathsAreUnique(photoPaths) ||
        !_receiptCameraPathsAreUnique(paths)) {
      return const {};
    }
    final diagnostics = <String, Map<String, Object?>>{};
    for (var fallbackIndex = 0; fallbackIndex < paths.length; fallbackIndex++) {
      final path = paths[fallbackIndex];
      final index = photoPaths.indexOf(path);
      if (index < 0) return const {};
      final photoIndex = index;
      diagnostics[path] = Map<String, Object?>.unmodifiable(
        evidence.toCaptureDiagnostics(
          quality: qualityForIndex(photoIndex),
          photoIndex: photoIndex,
        ),
      );
    }
    return Map<String, Map<String, Object?>>.unmodifiable(diagnostics);
  }

  bool get hasQuestionablePhoto =>
      qualityChecks.any((quality) => quality.needsReview);

  String get qualitySummaryLabel {
    final best = bestQualityCheck;
    if (best == null) return 'Photo quality not checked';
    final count = qualityChecks.length;
    final prefix = count <= 1 ? 'Photo' : 'Best of $count photos';
    return '$prefix ${best.reviewScoreLabel}: ${best.primaryIssueLabel}';
  }

  ReceiptPhotoQualityCheck? qualityForIndex(int index) {
    if (index < 0 || index >= qualityChecks.length) return null;
    return qualityChecks[index];
  }
}

bool _receiptCameraPathsAreUnique(List<String> paths) {
  return receiptPhotoPathsAreUniqueAndNormalized(paths);
}

class ReceiptCameraCaptureEvidence {
  ReceiptCameraCaptureEvidence({
    required this.captureSurface,
    required this.captureFlow,
    required this.resolutionTier,
    required this.resolutionPreset,
    required this.flashMode,
    required this.exposureMode,
    required this.focusMode,
    required this.exposurePointSupported,
    required this.focusPointSupported,
    required this.exposureOffset,
    required this.minExposureOffset,
    required this.maxExposureOffset,
    required this.zoomLevel,
    required this.minZoomLevel,
    required this.maxZoomLevel,
    required this.previewWidth,
    required this.previewHeight,
    required this.liveBrightness,
    required this.liveContrast,
    required this.liveFocusScore,
    required this.liveReadiness,
    required this.imageStreamActiveAtCapture,
    this.selectedExposureOffset,
    List<double?> candidateExposureOffsets = const [],
  }) : candidateExposureOffsets = List<double?>.unmodifiable(
         candidateExposureOffsets,
       );

  final String captureSurface;
  final String captureFlow;
  final String resolutionTier;
  final String resolutionPreset;
  final String flashMode;
  final String exposureMode;
  final String focusMode;
  final bool exposurePointSupported;
  final bool focusPointSupported;
  final double? exposureOffset;
  final double? minExposureOffset;
  final double? maxExposureOffset;
  final double zoomLevel;
  final double minZoomLevel;
  final double maxZoomLevel;
  final int previewWidth;
  final int previewHeight;
  final double? liveBrightness;
  final double? liveContrast;
  final double? liveFocusScore;
  final String liveReadiness;
  final bool imageStreamActiveAtCapture;
  final double? selectedExposureOffset;
  final List<double?> candidateExposureOffsets;

  bool get usesNativeAutoExposure => exposureMode == 'auto';
  bool get exposureAtNativeBaseline {
    final offset =
        _finiteDouble(selectedExposureOffset) ?? _finiteDouble(exposureOffset);
    if (offset == null) return true;
    return offset.abs() <= .05;
  }

  double? get _safeLiveBrightness => _finiteDouble(liveBrightness);

  bool get hasDarkLiveFrame => (_safeLiveBrightness ?? 128) < 72;
  bool get hasUnderexposedLiveFrame => (_safeLiveBrightness ?? 128) < 92;
  bool get hasBrightLiveFrame => (_safeLiveBrightness ?? 128) > 222;

  String get brightnessSummaryLabel {
    if (_safeLiveBrightness == null) return 'Live brightness not measured';
    if (hasDarkLiveFrame) return 'Live preview was dark';
    if (hasUnderexposedLiveFrame) return 'Live preview was darker than ideal';
    if (hasBrightLiveFrame) return 'Live preview had glare';
    return 'Live preview brightness was normal';
  }

  String get exposureSummaryLabel {
    if (selectedExposureOffset == null && exposureOffset == null) {
      return 'Exposure offset not measured';
    }
    if (exposureAtNativeBaseline) return 'Native auto exposure baseline';
    final selected =
        _finiteDouble(selectedExposureOffset) ??
        _finiteDouble(exposureOffset) ??
        0;
    final direction = selected > 0 ? 'brighter' : 'darker';
    return 'Bracketed $direction exposure candidate';
  }

  static double? _finiteDouble(double? value) {
    if (value == null || !value.isFinite) return null;
    return value;
  }
}
