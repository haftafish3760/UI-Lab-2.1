part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultHandoffStorage on ReceiptPhotoReviewResult {
  Map<String, int> get receiptDetailsHandoffCounts =>
      receiptReaderHandoffCounts;

  String get receiptReaderHandoffIntegrityLabel {
    final storage = !hasOcrSourcePhotos
        ? 'ocr_source_missing'
        : usesSeparateOcrSourceCopies
        ? 'ocr_source_separate_from_backup'
        : usedSavedProofAsOcrSourceFallback
        ? 'ocr_source_fallback_saved_proof'
        : 'ocr_source_matches_saved_backup';
    final stitch = stitchResult.status.name;
    final coverage = hasPossiblePartialReceiptPhotos
        ? 'possible_partial_receipt'
        : 'coverage_ok';
    final warnings = hasSavedPhotoQualityWarning
        ? 'saved_photo_warning'
        : 'saved_photo_ok';
    return [
      'saved=$savedBackupPhotoCount',
      'ocr=$ocrSourcePhotoCount',
      'storage=$storage',
      'stitch=$stitch',
      'coverage=$coverage',
      'warnings=$warnings',
    ].join(';');
  }

  String get receiptDetailsHandoffIntegrityLabel =>
      receiptReaderHandoffIntegrityLabel;

  List<String> get scannerDecisionCodes {
    final codes = <String>[];
    for (final diagnostics in preparationDiagnosticsByOcrPath.values) {
      final rawCodes = diagnostics['scannerDecisionCodes'];
      if (rawCodes is Iterable) {
        for (final rawCode in rawCodes) {
          final code = rawCode.toString().trim();
          if (code.isNotEmpty) codes.add(code);
        }
      }
    }
    return List.unmodifiable(codes);
  }

  Map<String, int> get scannerDecisionCounts {
    final counts = <String, int>{};
    for (final code in scannerDecisionCodes) {
      counts[code] = (counts[code] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  bool get scannerKeptTemporaryFullQualitySourceForQuality =>
      scannerDecisionCounts.containsKey(
        'ocr_source_full_quality_selected_quality_guard',
      );

  bool get scannerUsedEnhancedOcrSource =>
      scannerDecisionCounts.containsKey('ocr_source_enhanced_selected');

  bool get scannerNeedsOperatorReview {
    return scannerDecisionCodes.any(
      (code) =>
          code.endsWith('_quality_guard') ||
          code == 'decode_failed' ||
          (code.startsWith('crop_skipped_') &&
              code != 'crop_skipped_setting_off') ||
          (code.startsWith('perspective_skipped_') &&
              code != 'perspective_skipped_setting_off'),
    );
  }

  Map<String, int> get ocrStoragePolicyCounts {
    return _preparationDiagnosticValueCounts(this, 'ocrStoragePolicyCode');
  }

  Map<String, int> get ocrUsesPreparedSourceBeforeSavedProofCounts {
    return _preparationDiagnosticBoolCounts(
      this,
      'ocrUsesPreparedSourceBeforeSavedProof',
    );
  }

  Map<String, int> get ocrUsesSavedProofFallbackCounts {
    return _preparationDiagnosticBoolCounts(this, 'ocrUsesSavedProofFallback');
  }

  String get ocrStoragePolicyOutcome {
    if (ocrStoragePolicyCounts.containsKey(
      'ocr_clear_source_before_saved_proof_copy',
    )) {
      return 'ocr_clear_source_before_saved_proof_copy';
    }
    if (ocrStoragePolicyCounts.containsKey(
      'ocr_saved_proof_fallback_review_required',
    )) {
      return 'ocr_saved_proof_fallback_review_required';
    }
    if (ocrReadsClearSourceBeforeSavedProof) {
      return 'ocr_clear_source_before_saved_proof_copy';
    }
    if (ocrUsesSavedProofOnlyAsFallback) {
      return 'ocr_saved_proof_fallback_review_required';
    }
    return 'ocr_storage_policy_unknown';
  }

  Map<String, int> get receiptProofStoragePolicyCounts {
    final counts = <String, int>{};
    if (photoPaths.isNotEmpty) {
      counts['saved_proof_kept_for_receipt_record'] = photoPaths.length;
    }
    if (hasOcrSourcePhotos) {
      counts['ocr_source_used_for_reading_before_saved_proof'] =
          ocrSourcePhotoPaths.length;
    }
    if (usesSeparateOcrSourceCopies) {
      counts['temporary_ocr_source_separate_from_saved_proof'] =
          ocrSourcePhotoPaths.length;
    }
    if (usedSavedProofAsOcrSourceFallback) {
      counts['saved_proof_used_as_ocr_fallback'] = ocrSourcePhotoPaths.length;
    }
    if (ocrReadsClearSourceBeforeSavedProof) {
      counts['clear_ocr_source_read_before_saved_proof_copy'] =
          ocrSourcePhotoPaths.length;
    }
    if (scannerKeptTemporaryFullQualitySourceForQuality) {
      counts['temporary_full_quality_source_guard_for_ocr'] =
          ocrSourcePhotoPaths.length;
    }
    if (dataSaverLevel != ReceiptDataSaverLevel.original) {
      counts['normal_record_uses_data_saver_proof'] = photoPaths.length;
    } else {
      counts['normal_record_keeps_original_quality_proof'] = photoPaths.length;
    }
    if (keptForLater) {
      counts['review_kept_for_later_no_cleanup_yet'] = photoPaths.length;
    } else if (usesSeparateOcrSourceCopies ||
        scannerKeptTemporaryFullQualitySourceForQuality) {
      counts['accepted_review_allows_temporary_ocr_cleanup'] =
          ocrSourcePhotoPaths.length;
    }
    return Map.unmodifiable(counts);
  }

  String get receiptProofStoragePolicyOutcome {
    final counts = receiptProofStoragePolicyCounts;
    if (counts.isEmpty) return 'receipt_proof_storage_unknown';
    if ((counts['saved_proof_used_as_ocr_fallback'] ?? 0) > 0) {
      return 'saved_proof_ocr_fallback_review';
    }
    if ((counts['temporary_full_quality_source_guard_for_ocr'] ?? 0) > 0) {
      return 'temporary_full_quality_source_guard_review';
    }
    if ((counts['temporary_ocr_source_separate_from_saved_proof'] ?? 0) > 0 &&
        (counts['normal_record_uses_data_saver_proof'] ?? 0) > 0) {
      return 'temporary_ocr_source_saved_data_saver_proof';
    }
    if ((counts['temporary_ocr_source_separate_from_saved_proof'] ?? 0) > 0 &&
        (counts['normal_record_keeps_original_quality_proof'] ?? 0) > 0) {
      return 'temporary_ocr_source_original_quality_proof';
    }
    if ((counts['normal_record_keeps_original_quality_proof'] ?? 0) > 0) {
      return 'original_quality_proof_kept';
    }
    return 'saved_proof_storage_ready';
  }

  ReceiptProofTargetSizePolicy get receiptProofTargetSizePolicy {
    return dataSaverLevel.proofTargetSizePolicy;
  }
}
