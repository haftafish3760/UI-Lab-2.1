part of 'receipt_image_processor.dart';

class ReceiptPreparedImage {
  const ReceiptPreparedImage({
    required this.ocrSourcePath,
    required this.backupPath,
    required this.dataSaverLevel,
    required this.quality,
    required this.preparation,
  });

  final String ocrSourcePath;
  final String backupPath;
  final ReceiptDataSaverLevel dataSaverLevel;
  final ReceiptPhotoQualityCheck quality;
  final ReceiptImagePreparationReport preparation;

  bool get usesSeparateBackupCopy => backupPath != ocrSourcePath;

  String get ocrStoragePolicyCode => usesSeparateBackupCopy
      ? 'ocr_clear_source_before_saved_proof_copy'
      : 'ocr_saved_proof_fallback_review_required';

  String get ocrStoragePolicyLabel => usesSeparateBackupCopy
      ? 'Receipt details use the prepared clear photo before the smaller saved proof copy is kept.'
      : 'Receipt details are using the saved proof copy; review readability before trusting automatic fill.';

  Map<String, Object?> toStorageContractDiagnostics() {
    return {
      'ocrStoragePolicyCode': ocrStoragePolicyCode,
      'ocrUsesPreparedSourceBeforeSavedProof': usesSeparateBackupCopy,
      'ocrUsesSavedProofFallback': !usesSeparateBackupCopy,
      'dataSaverLevel': dataSaverLevel.name,
      'usesSeparateBackupCopy': usesSeparateBackupCopy,
      'savedProofReviewScoreNoHigherThanOcrSource':
          quality.reviewScore <= preparation.ocrQuality.reviewScore,
      'ocrReviewScore': preparation.ocrQuality.reviewScore,
      'savedProofReviewScore': quality.reviewScore,
      'usedEnhancedOcrSource': preparation.usedEnhancedOcrSource,
      'receiptImageProcessingVersion': preparation.processingVersion,
      'scannerDecisionCodes': preparation.scannerDecisionCodes,
    };
  }
}

class ReceiptImagePreparationReport {
  static const currentProcessingVersion = 'receipt_image_preparation_v1';

  const ReceiptImagePreparationReport({
    required this.sourcePath,
    required this.ocrSourcePath,
    required this.originalQuality,
    required this.ocrQuality,
    required this.cleanupActions,
    required this.usedEnhancedOcrSource,
    this.scannerDecisionCodes = const [],
  });

  final String sourcePath;
  final String ocrSourcePath;
  final ReceiptPhotoQualityCheck originalQuality;
  final ReceiptPhotoQualityCheck ocrQuality;
  final List<String> cleanupActions;
  final bool usedEnhancedOcrSource;
  final List<String> scannerDecisionCodes;

  String get processingVersion => currentProcessingVersion;

  bool get improvedReviewScore =>
      ocrQuality.reviewScore >= originalQuality.reviewScore;

  bool get improvedTextBands =>
      ocrQuality.textBandScore >= originalQuality.textBandScore;

  String get ocrSourceLabel {
    if (usedEnhancedOcrSource) {
      return 'Prepared clear receipt photo: ${cleanupActions.join(', ')}';
    }
    return 'Original-quality receipt photo';
  }

  Map<String, Object?> toDiagnostics() {
    return {
      'usedEnhancedOcrSource': usedEnhancedOcrSource,
      'receiptImageProcessingVersion': processingVersion,
      'cleanupActions': cleanupActions,
      'originalReviewScore': originalQuality.reviewScore,
      'ocrReviewScore': ocrQuality.reviewScore,
      'originalTextBandScore': originalQuality.textBandScore,
      'ocrTextBandScore': ocrQuality.textBandScore,
      'originalBrightness': originalQuality.brightness,
      'ocrBrightness': ocrQuality.brightness,
      'originalContrast': originalQuality.contrast,
      'ocrContrast': ocrQuality.contrast,
      'scannerDecisionCodes': scannerDecisionCodes,
    };
  }
}

class ReceiptImageCleanupSettings {
  const ReceiptImageCleanupSettings({
    this.autoCrop = true,
    this.autoStraighten = false,
    this.grayscale = true,
    this.contrastBoost = true,
    this.sharpening = true,
    this.shadowReduction = true,
    this.adaptiveExposure = true,
    this.orientationCorrection = true,
  });

  factory ReceiptImageCleanupSettings.fromDiagnostics(
    Map<String, Object?>? diagnostics,
  ) {
    if (diagnostics == null || diagnostics.isEmpty) {
      return const ReceiptImageCleanupSettings();
    }
    return ReceiptImageCleanupSettings(
      autoCrop: _boolDiagnostic(
        diagnostics,
        'autoCropSuggestionEnabled',
        fallback: true,
      ),
      autoStraighten: _boolDiagnostic(
        diagnostics,
        'perspectiveCorrectionEnabled',
        fallback: false,
      ),
      grayscale: _boolDiagnostic(
        diagnostics,
        'grayscalePreviewEnabled',
        fallback: true,
      ),
      contrastBoost: _boolDiagnostic(
        diagnostics,
        'contrastBoostEnabled',
        fallback: true,
      ),
      sharpening: _boolDiagnostic(
        diagnostics,
        'sharpeningEnabled',
        fallback: true,
      ),
      shadowReduction: _boolDiagnostic(
        diagnostics,
        'shadowReductionEnabled',
        fallback: true,
      ),
      adaptiveExposure: _boolDiagnostic(
        diagnostics,
        'adaptiveThresholdEnabled',
        fallback: true,
      ),
      orientationCorrection: _boolDiagnostic(
        diagnostics,
        'orientationCorrectionEnabled',
        fallback: true,
      ),
    );
  }

  final bool autoCrop;
  final bool autoStraighten;
  final bool grayscale;
  final bool contrastBoost;
  final bool sharpening;
  final bool shadowReduction;
  final bool adaptiveExposure;
  final bool orientationCorrection;

  bool get usesScannerCleanup =>
      grayscale ||
      contrastBoost ||
      sharpening ||
      shadowReduction ||
      adaptiveExposure;

  List<String> get enabledDiagnosticLabels => [
    if (autoCrop) 'auto_crop_enabled',
    if (autoStraighten) 'auto_straighten_enabled',
    if (grayscale) 'grayscale_enabled',
    if (contrastBoost) 'contrast_boost_enabled',
    if (sharpening) 'sharpening_enabled',
    if (shadowReduction) 'shadow_cleanup_enabled',
    if (adaptiveExposure) 'adaptive_exposure_enabled',
    if (orientationCorrection) 'orientation_cleanup_enabled',
  ];

  static bool _boolDiagnostic(
    Map<String, Object?> diagnostics,
    String key, {
    required bool fallback,
  }) {
    final value = diagnostics[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }
}
