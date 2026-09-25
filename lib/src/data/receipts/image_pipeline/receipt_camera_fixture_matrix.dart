part of 'receipt_capture_models.dart';

enum ReceiptCameraFixtureScenario {
  cleanSingleReceipt,
  blurryReceipt,
  glareReceipt,
  lowLightReceipt,
  croppedEdges,
  missingBottomTotals,
  longReceiptStrongOverlap,
  longReceiptWeakOverlap,
  duplicateSection,
  oversizedStitch,
  barcodeQrPresent,
  corruptedImageFile,
  wrongFileType,
  emptyImage,
}

class ReceiptCameraFixtureExpectation {
  const ReceiptCameraFixtureExpectation({
    required this.scenario,
    required this.description,
    required this.expectedQualityWarnings,
    required this.expectedCoverageStatus,
    required this.expectedStitchSafetyCode,
    required this.requiresMorePhotos,
    required this.requiresManualReview,
    required this.shouldUseOrderedFallback,
    required this.shouldUseOcrSourceFirst,
    required this.privacySafeRegressionBucket,
  });

  final ReceiptCameraFixtureScenario scenario;
  final String description;
  final List<String> expectedQualityWarnings;
  final ReceiptPhotoCoverageStatus expectedCoverageStatus;
  final String expectedStitchSafetyCode;
  final bool requiresMorePhotos;
  final bool requiresManualReview;
  final bool shouldUseOrderedFallback;
  final bool shouldUseOcrSourceFirst;
  final String privacySafeRegressionBucket;

  bool get expectsStitchedImage =>
      expectedStitchSafetyCode == 'stitched_overlap_verified';

  bool get expectsBarcodeHandoff =>
      expectedStitchSafetyCode == 'receipt_barcode_camera_handoff_v1';

  Map<String, Object?> get privacySafeMetadata => {
    'scenario': scenario.name,
    'qualityWarningCount': expectedQualityWarnings.length,
    'coverageStatus': expectedCoverageStatus.name,
    'stitchSafetyCode': expectedStitchSafetyCode,
    'requiresMorePhotos': requiresMorePhotos,
    'requiresManualReview': requiresManualReview,
    'usesOrderedFallback': shouldUseOrderedFallback,
    'usesOcrSourceFirst': shouldUseOcrSourceFirst,
    'regressionBucket': privacySafeRegressionBucket,
  };
}

const receiptCameraReleaseOneFixtureExpectations = [
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.cleanSingleReceipt,
    description: 'Readable single receipt with edges and totals visible.',
    expectedQualityWarnings: [],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.likelyComplete,
    expectedStitchSafetyCode: 'single_image_no_stitch_required',
    requiresMorePhotos: false,
    requiresManualReview: false,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_clean_single_receipt',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.blurryReceipt,
    description: 'Soft receipt photo that should warn before OCR handoff.',
    expectedQualityWarnings: ['blur'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.unknown,
    expectedStitchSafetyCode: 'single_image_quality_review_required',
    requiresMorePhotos: false,
    requiresManualReview: true,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_blur_quality_warning',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.glareReceipt,
    description: 'Bright glare across text that should recommend retake.',
    expectedQualityWarnings: ['glare'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.unknown,
    expectedStitchSafetyCode: 'single_image_quality_review_required',
    requiresMorePhotos: false,
    requiresManualReview: true,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_glare_quality_warning',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.lowLightReceipt,
    description: 'Dim receipt photo that should ask for light or torch.',
    expectedQualityWarnings: ['low_light'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.unknown,
    expectedStitchSafetyCode: 'single_image_quality_review_required',
    requiresMorePhotos: false,
    requiresManualReview: true,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_low_light_quality_warning',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.croppedEdges,
    description: 'Receipt edges or text bands are likely cut off.',
    expectedQualityWarnings: ['cropped_edge'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.likelyCutOff,
    expectedStitchSafetyCode: 'single_image_coverage_review_required',
    requiresMorePhotos: true,
    requiresManualReview: true,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_cropped_edge_coverage',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.missingBottomTotals,
    description: 'Bottom edge or totals are missing on a partial receipt.',
    expectedQualityWarnings: ['missing_bottom', 'missing_total'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.maybeContinues,
    expectedStitchSafetyCode: 'single_image_needs_more_receipt_sections',
    requiresMorePhotos: true,
    requiresManualReview: true,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_missing_bottom_totals',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.longReceiptStrongOverlap,
    description: 'Ordered long receipt sections have verified overlap.',
    expectedQualityWarnings: [],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.likelyComplete,
    expectedStitchSafetyCode: 'stitched_overlap_verified',
    requiresMorePhotos: false,
    requiresManualReview: false,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_long_receipt_verified_stitch',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.longReceiptWeakOverlap,
    description:
        'Ordered long receipt sections fall back when overlap is weak.',
    expectedQualityWarnings: ['weak_overlap'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.likelyComplete,
    expectedStitchSafetyCode:
        'ordered_sections_after_overlap_confidence_low_fallback',
    requiresMorePhotos: false,
    requiresManualReview: true,
    shouldUseOrderedFallback: true,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_long_receipt_ordered_fallback',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.duplicateSection,
    description: 'Repeated long receipt section should not duplicate OCR rows.',
    expectedQualityWarnings: ['duplicate_overlap'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.likelyComplete,
    expectedStitchSafetyCode: 'ordered_sections_duplicate_section_review',
    requiresMorePhotos: false,
    requiresManualReview: true,
    shouldUseOrderedFallback: true,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_long_receipt_duplicate_section',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.oversizedStitch,
    description: 'Large receipt inputs must use memory-safe processing.',
    expectedQualityWarnings: ['large_image_memory_guard'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.likelyComplete,
    expectedStitchSafetyCode: 'memory_safe_stitch_or_ordered_fallback',
    requiresMorePhotos: false,
    requiresManualReview: true,
    shouldUseOrderedFallback: true,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_large_receipt_memory_guard',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.barcodeQrPresent,
    description: 'Barcode or QR evidence attaches to camera handoff only.',
    expectedQualityWarnings: [],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.likelyComplete,
    expectedStitchSafetyCode: 'receipt_barcode_camera_handoff_v1',
    requiresMorePhotos: false,
    requiresManualReview: false,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_barcode_qr_handoff',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.corruptedImageFile,
    description: 'Unreadable image file must fail recoverably.',
    expectedQualityWarnings: ['corrupted_image'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.unknown,
    expectedStitchSafetyCode: 'image_decode_failed_recoverable',
    requiresMorePhotos: false,
    requiresManualReview: true,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_corrupted_image_recovery',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.wrongFileType,
    description: 'Wrong file type must be rejected before OCR handoff.',
    expectedQualityWarnings: ['wrong_file_type'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.unknown,
    expectedStitchSafetyCode: 'image_type_rejected_recoverable',
    requiresMorePhotos: false,
    requiresManualReview: true,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_wrong_file_type_recovery',
  ),
  ReceiptCameraFixtureExpectation(
    scenario: ReceiptCameraFixtureScenario.emptyImage,
    description: 'Empty image must never reach OCR as a valid receipt.',
    expectedQualityWarnings: ['empty_image'],
    expectedCoverageStatus: ReceiptPhotoCoverageStatus.unknown,
    expectedStitchSafetyCode: 'empty_image_rejected_recoverable',
    requiresMorePhotos: false,
    requiresManualReview: true,
    shouldUseOrderedFallback: false,
    shouldUseOcrSourceFirst: true,
    privacySafeRegressionBucket: 'camera_empty_image_recovery',
  ),
];

Map<ReceiptCameraFixtureScenario, ReceiptCameraFixtureExpectation>
get receiptCameraReleaseOneFixtureExpectationByScenario => {
  for (final expectation in receiptCameraReleaseOneFixtureExpectations)
    expectation.scenario: expectation,
};
