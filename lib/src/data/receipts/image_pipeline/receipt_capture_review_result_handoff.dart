part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultHandoff on ReceiptPhotoReviewResult {
  bool get usesImportedReceiptPhotoSource {
    return nativeCaptureSourcePolicyOutcome == 'existing_photo_import';
  }

  bool get ocrReadsClearSourceBeforeSavedProof {
    return hasOcrSourcePhotos && !usedSavedProofAsOcrSourceFallback;
  }

  bool get ocrUsesSavedProofOnlyAsFallback {
    return hasOcrSourcePhotos && usedSavedProofAsOcrSourceFallback;
  }

  bool get ocrSourceFallbackRequiresManualReview {
    return !hasOcrSourcePhotos || usedSavedProofAsOcrSourceFallback;
  }

  bool get ocrSourcePathsMatchStitchContract {
    if (!hasOcrSourcePhotos) return false;
    if (stitchResult.ocrSourceContractCode ==
        'fallback_unreadable_input_source') {
      return false;
    }
    final stitchedPath = stitchResult.stitchedPath;
    if (stitchResult.didStitch) {
      return stitchedPath != null &&
          ocrSourcePhotoPaths.length == 1 &&
          _sameReceiptArtifactPath(ocrSourcePhotoPaths.single, stitchedPath);
    }
    if (stitchResult.ocrSourcePaths.length != ocrSourcePhotoPaths.length) {
      return false;
    }
    for (var index = 0; index < ocrSourcePhotoPaths.length; index++) {
      if (!_sameReceiptArtifactPath(
        ocrSourcePhotoPaths[index],
        stitchResult.ocrSourcePaths[index],
      )) {
        return false;
      }
    }
    return true;
  }

  String get ocrSourceReviewRiskCode {
    if (photoPathInputWasSanitized || ocrSourcePathInputWasSanitized) {
      return 'receipt_source_path_input_sanitized_review_required';
    }
    if (!hasOcrSourcePhotos) return 'ocr_source_missing_manual_entry_required';
    if (stitchResult.requiresOcrSourceReviewBeforeAssistedRead ||
        !ocrSourcePathsMatchStitchContract) {
      return 'stitch_ocr_source_contract_review_required';
    }
    if (usedSavedProofAsOcrSourceFallback) {
      return 'saved_proof_ocr_fallback_review_required';
    }
    if (scannerNeedsOperatorReview) {
      return 'scanner_preparation_review_required';
    }
    return 'ocr_source_ready';
  }

  String get ocrSourceReviewRequirement {
    return ocrSourceFallbackRequiresManualReview ||
            photoPathInputWasSanitized ||
            ocrSourcePathInputWasSanitized ||
            scannerNeedsOperatorReview ||
            stitchResult.requiresOcrSourceReviewBeforeAssistedRead ||
            !ocrSourcePathsMatchStitchContract
        ? 'manual_review_required_before_saving_receipt'
        : 'standard_user_confirmation_required';
  }

  String get ocrSourceFirstDecisionCode {
    if (!hasOcrSourcePhotos) return 'ocr_source_missing_block_review';
    if (ocrUsesSavedProofOnlyAsFallback) {
      return 'saved_proof_fallback_review_required';
    }
    if (stitchResult.didStitch) {
      return 'combined_receipt_source_before_saved_proof';
    }
    if (usesImportedReceiptPhotoSource) {
      return 'imported_receipt_source_before_saved_proof';
    }
    if (scannerUsedEnhancedOcrSource) {
      return 'prepared_receipt_source_before_saved_proof';
    }
    if (scannerKeptTemporaryFullQualitySourceForQuality) {
      return 'temporary_full_quality_source_before_saved_proof';
    }
    if (usesSeparateOcrSourceCopies) {
      return 'separate_receipt_source_before_saved_proof';
    }
    return 'accepted_receipt_source_before_saved_proof';
  }

  String get ocrSourceProofRelationship {
    if (!hasOcrSourcePhotos) return 'missing_ocr_source';
    if (ocrUsesSavedProofOnlyAsFallback) return 'saved_proof_fallback';
    if (stitchResult.didStitch) return 'combined_clear_source';
    if (usesImportedReceiptPhotoSource) return 'imported_clear_source';
    if (scannerUsedEnhancedOcrSource) return 'prepared_clear_source';
    if (scannerKeptTemporaryFullQualitySourceForQuality) {
      return 'temporary_full_quality_source';
    }
    if (usesSeparateOcrSourceCopies) return 'separate_clear_source';
    return 'same_accepted_source';
  }

  String get ocrSourceFirstReviewCue {
    return switch (ocrSourceFirstDecisionCode) {
      'prepared_receipt_source_before_saved_proof' =>
        'The app is using the prepared clear receipt photo before the smaller saved image copy.',
      'imported_receipt_source_before_saved_proof' =>
        'The app is using the imported receipt photo before the smaller saved image copy.',
      'temporary_full_quality_source_before_saved_proof' =>
        'The app is using the full-quality receipt photo before the smaller saved image copy.',
      'separate_receipt_source_before_saved_proof' =>
        'The app is using the clearest receipt photos before the smaller saved image copies.',
      'accepted_receipt_source_before_saved_proof' =>
        'The app is using the accepted receipt photo before any storage-saving proof copy.',
      'saved_proof_fallback_review_required' =>
        'The saved image is being used because a clearer photo was not available. Review the filled receipt carefully.',
      'combined_receipt_source_before_saved_proof' =>
        'The app is using the combined receipt image before the smaller saved image copy.',
      _ => 'A clear receipt photo is not ready. Add one or continue by hand.',
    };
  }

  Map<String, Object?> get privacySafeOcrSourceFirstSummary {
    return Map.unmodifiable({
      'ocrSourceFirstPolicy': 'ocr_reads_clear_source_before_saved_proof',
      'ocrSourceFirstDecisionCode': ocrSourceFirstDecisionCode,
      'ocrSourceFirstOutcome': ocrSourceFirstOutcome,
      'ocrSourceFirstActionLabel': ocrSourceFirstActionLabel,
      'ocrSourceFirstReviewCue': ocrSourceFirstReviewCue,
      'ocrSourceProofRelationship': ocrSourceProofRelationship,
      'ocrSourceReviewRiskCode': ocrSourceReviewRiskCode,
      'ocrSourceReviewRequirement': ocrSourceReviewRequirement,
      'ocrSourceFallbackRequiresManualReview':
          ocrSourceFallbackRequiresManualReview,
      'ocrSourcePathsMatchStitchContract': ocrSourcePathsMatchStitchContract,
      'ocrReadsClearSourceBeforeSavedProof':
          ocrReadsClearSourceBeforeSavedProof,
      'ocrUsesSavedProofOnlyAsFallback': ocrUsesSavedProofOnlyAsFallback,
      'photoPathInputWasSanitized': photoPathInputWasSanitized,
      'ocrSourcePathInputWasSanitized': ocrSourcePathInputWasSanitized,
      'ocrSourceCount': ocrSourcePhotoCount,
      'savedProofCount': savedBackupPhotoCount,
      'savedProofDataSaverLevel': dataSaverLevel.name,
    });
  }

  bool get usesSeparateOcrSourceCopies {
    if (!hasReceiptReaderHandoff) return false;
    if (photoPaths.length != ocrSourcePhotoPaths.length) return true;
    for (var index = 0; index < photoPaths.length; index++) {
      if (photoPaths[index] != ocrSourcePhotoPaths[index]) return true;
    }
    return false;
  }
}
