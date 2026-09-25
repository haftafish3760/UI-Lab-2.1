part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultHandoffCounts on ReceiptPhotoReviewResult {
  Map<String, int> get receiptReaderHandoffCounts {
    final counts = <String, int>{
      if (hasSavedBackupPhotos) 'saved_backup_present': savedBackupPhotoCount,
      if (!hasSavedBackupPhotos) 'saved_backup_missing': 1,
      if (hasOcrSourcePhotos) 'ocr_source_present': ocrSourcePhotoCount,
      if (!hasOcrSourcePhotos) 'ocr_source_missing': 1,
      if (keptForLater) 'receipt_review_kept_for_later': 1,
      if (keptForLater) 'receipt_review_ocr_deferred': 1,
      if (keptForLater) 'receipt_review_receipt_details_not_accepted': 1,
      if (usesSeparateOcrSourceCopies) 'ocr_source_separate_from_backup': 1,
      if (!usesSeparateOcrSourceCopies && hasReceiptReaderHandoff)
        'ocr_source_matches_saved_backup': 1,
      if (usedSavedProofAsOcrSourceFallback)
        'ocr_source_fallback_saved_proof': 1,
      'ocr_source_review_risk_$ocrSourceReviewRiskCode': 1,
      'ocr_source_review_requirement_$ocrSourceReviewRequirement': 1,
    };
    if (stitchResult.didStitch) {
      counts['ocr_source_combined_stitch'] = 1;
    } else if (stitchResult.usedFallback) {
      counts['ocr_source_ordered_sections_stitch_fallback'] = 1;
      final fallbackReason = stitchResult.diagnosticReasonLabel;
      if (fallbackReason.isNotEmpty) {
        counts['stitch_fallback_$fallbackReason'] = 1;
      }
    } else if (ocrSourcePhotoCount > 1) {
      counts['ocr_source_ordered_sections'] = ocrSourcePhotoCount;
    }
    counts['stitch_ocr_source_contract_${stitchResult.ocrSourceContractCode}'] =
        1;
    counts['stitch_assisted_readiness_${stitchResult.assistedReadinessCode}'] =
        1;
    if (stitchResult.requiresOcrSourceReviewBeforeAssistedRead) {
      counts['stitch_requires_ocr_source_review_before_assist'] = 1;
    } else {
      counts['stitch_ready_for_assisted_read_without_extra_review'] = 1;
    }
    counts['match_readiness_$nextReviewMatchReadinessOutcome'] = 1;
    if (hasPossiblePartialReceiptPhotos) {
      counts['possible_partial_receipt'] =
          (counts['possible_partial_receipt'] ?? 0) + 1;
      counts['needs_next_receipt_section_review'] = 1;
      counts['user_can_continue_if_full_receipt_readable'] = 1;
    }
    for (final entry in savedPhotoParserRiskCounts.entries) {
      counts['parser_risk_${entry.key}'] =
          (counts['parser_risk_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in savedPhotoWarningActionCounts.entries) {
      counts['saved_photo_action_${entry.key}'] =
          (counts['saved_photo_action_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in nativeCameraUiHealthCounts.entries) {
      counts['native_camera_ui_${entry.key}'] =
          (counts['native_camera_ui_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in receiptSectionOrderCounts.entries) {
      counts['receipt_section_order_${entry.key}'] =
          (counts['receipt_section_order_${entry.key}'] ?? 0) + entry.value;
    }
    counts['receipt_section_order_action_$receiptSectionOrderReviewActionCode'] =
        1;
    if (receiptSectionOrderNeedsReview) {
      counts['receipt_section_order_review_required'] = 1;
    }
    counts.addBrainInstallAndFootprintCounts(this);
    for (final entry in ocrStoragePolicyCounts.entries) {
      counts['ocr_storage_policy_${entry.key}'] =
          (counts['ocr_storage_policy_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in receiptProofStoragePolicyCounts.entries) {
      counts['receipt_proof_storage_policy_${entry.key}'] =
          (counts['receipt_proof_storage_policy_${entry.key}'] ?? 0) +
          entry.value;
    }
    final proofTarget = receiptProofTargetSizePolicy;
    counts['receipt_proof_target_${proofTarget.policyCode}'] =
        (counts['receipt_proof_target_${proofTarget.policyCode}'] ?? 0) + 1;
    counts['receipt_proof_target_level_${dataSaverLevel.name}'] =
        (counts['receipt_proof_target_level_${dataSaverLevel.name}'] ?? 0) + 1;
    counts['receipt_proof_target_cloud_backup_${proofTarget.cloudBackupDefaultAllowed}'] =
        (counts['receipt_proof_target_cloud_backup_${proofTarget.cloudBackupDefaultAllowed}'] ??
            0) +
        1;
    counts['receipt_proof_target_review_required_${proofTarget.requiresReadabilityReview}'] =
        (counts['receipt_proof_target_review_required_${proofTarget.requiresReadabilityReview}'] ??
            0) +
        1;
    for (final entry in ocrUsesPreparedSourceBeforeSavedProofCounts.entries) {
      counts['ocr_prepared_source_before_saved_proof_${entry.key}'] =
          (counts['ocr_prepared_source_before_saved_proof_${entry.key}'] ?? 0) +
          entry.value;
    }
    for (final entry in ocrUsesSavedProofFallbackCounts.entries) {
      counts['ocr_saved_proof_fallback_${entry.key}'] =
          (counts['ocr_saved_proof_fallback_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in nativeCloseCapturedPhotoOutcomeCounts.entries) {
      counts['native_close_captured_photo_${entry.key}'] =
          (counts['native_close_captured_photo_${entry.key}'] ?? 0) +
          entry.value;
    }
    for (final entry in nativeRecoveryFreshnessCounts.entries) {
      counts['native_recovery_freshness_${entry.key}'] =
          (counts['native_recovery_freshness_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in nativeRecoveryStorageStatusCounts.entries) {
      counts['native_recovery_storage_${entry.key}'] =
          (counts['native_recovery_storage_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in nativeCaptureSourcePolicyCounts.entries) {
      counts['native_capture_source_${entry.key}'] =
          (counts['native_capture_source_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in nativeReceiptCameraSurfaceActualCounts.entries) {
      counts['native_capture_surface_${entry.key}'] =
          (counts['native_capture_surface_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in nativeReceiptCameraSurfaceVerificationCounts.entries) {
      counts['native_capture_surface_verified_${entry.key}'] =
          (counts['native_capture_surface_verified_${entry.key}'] ?? 0) +
          entry.value;
    }
    for (final entry in nativeCameraIdentityCounts.entries) {
      counts['native_capture_identity_${entry.key}'] =
          (counts['native_capture_identity_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in editedPhotoActionCounts.entries) {
      counts['review_photo_edit_${entry.key}'] =
          (counts['review_photo_edit_${entry.key}'] ?? 0) + entry.value;
    }
    for (final entry in editedPhotoSourceSelectionCounts.entries) {
      counts['review_photo_edit_source_selected_${entry.key}'] =
          (counts['review_photo_edit_source_selected_${entry.key}'] ?? 0) +
          entry.value;
    }
    for (final entry in editedPhotoReplacedOriginalCounts.entries) {
      counts['review_photo_edit_replaced_original_${entry.key}'] =
          (counts['review_photo_edit_replaced_original_${entry.key}'] ?? 0) +
          entry.value;
    }
    if (scannerNeedsOperatorReview) {
      counts['scanner_operator_review_needed'] = 1;
    }
    if (scannerUsedEnhancedOcrSource) {
      counts['scanner_enhanced_ocr_source_used'] = 1;
    }
    if (scannerKeptTemporaryFullQualitySourceForQuality) {
      counts['scanner_temporary_full_quality_source_guarded'] = 1;
    }
    return Map.unmodifiable(counts);
  }
}
