part of 'receipt_capture_models.dart';

/// A long receipt can have a safe visual stack even when its overlapping
/// pixels are not trustworthy enough to remove duplicate rows.  That is a
/// successful review aid, not a failed receipt.
enum ReceiptStitchStatus { notNeeded, stitched, stacked, fallback }

class ReceiptStitchResult {
  ReceiptStitchResult({
    required this.status,
    required List<String> inputPaths,
    required List<String> ocrSourcePaths,
    this.stitchedPath,
    this.confidence = 0,
    List<int> overlapPixels = const [],
    List<ReceiptStitchPairResult> pairs = const [],
    this.failedPairIndex,
    this.stitchedWidth = 0,
    this.stitchedHeight = 0,
    this.warning = '',
    this.usedManualAdjustment = false,
    this.fallbackReasonCode = '',
  }) : _inputPaths = List<String>.unmodifiable(inputPaths),
       _ocrSourcePaths = List<String>.unmodifiable(ocrSourcePaths),
       _overlapPixels = List<int>.unmodifiable(overlapPixels),
       _pairs = List<ReceiptStitchPairResult>.unmodifiable(pairs);

  ReceiptStitchResult.notNeeded(List<String> paths)
    : this(
        status: ReceiptStitchStatus.notNeeded,
        inputPaths: paths,
        ocrSourcePaths: paths,
      );

  ReceiptStitchResult.fallback({
    required List<String> inputPaths,
    required String warning,
    String fallbackReasonCode = 'unknown',
    double confidence = 0,
    int? failedPairIndex,
    List<ReceiptStitchPairResult> pairs = const [],
    int stitchedWidth = 0,
    int stitchedHeight = 0,
  }) : this(
         status: ReceiptStitchStatus.fallback,
         inputPaths: inputPaths,
         ocrSourcePaths: inputPaths,
         warning: warning,
         confidence: confidence,
         failedPairIndex: failedPairIndex,
         pairs: pairs,
         stitchedWidth: stitchedWidth,
         stitchedHeight: stitchedHeight,
         fallbackReasonCode: fallbackReasonCode,
       );

  /// Builds one scrollable receipt view without deleting or guessing at any
  /// shared rows. The ordered originals remain the reading and saved sources.
  ReceiptStitchResult.stacked({
    required List<String> inputPaths,
    required List<String> ocrSourcePaths,
    required String stackedPath,
    required int stackedWidth,
    required int stackedHeight,
    List<ReceiptStitchPairResult> pairs = const [],
    String warning = '',
  }) : this(
         status: ReceiptStitchStatus.stacked,
         inputPaths: inputPaths,
         ocrSourcePaths: ocrSourcePaths,
         stitchedPath: stackedPath,
         stitchedWidth: stackedWidth,
         stitchedHeight: stackedHeight,
         pairs: pairs,
         warning: warning,
       );

  final ReceiptStitchStatus status;
  final List<String> _inputPaths;
  final List<String> _ocrSourcePaths;
  final String? stitchedPath;
  final double confidence;
  final List<int> _overlapPixels;
  final List<ReceiptStitchPairResult> _pairs;
  final int? failedPairIndex;
  final int stitchedWidth;
  final int stitchedHeight;
  final String warning;
  final bool usedManualAdjustment;
  final String fallbackReasonCode;

  List<String> get inputPaths => List<String>.unmodifiable(_inputPaths);
  List<String> get ocrSourcePaths => List<String>.unmodifiable(_ocrSourcePaths);
  List<int> get overlapPixels => List<int>.unmodifiable(_overlapPixels);
  List<ReceiptStitchPairResult> get pairs =>
      List<ReceiptStitchPairResult>.unmodifiable(_pairs);
  bool get didStitch => status == ReceiptStitchStatus.stitched;
  bool get hasCombinedPreview =>
      (status == ReceiptStitchStatus.stitched ||
          status == ReceiptStitchStatus.stacked) &&
      stitchedPath != null;
  bool get isSafelyStackedPreview => status == ReceiptStitchStatus.stacked;
  bool get usedFallback => status == ReceiptStitchStatus.fallback;
  bool get hasNoInputPaths => inputPaths.isEmpty;
  bool get hasMultipleSections => inputPaths.length > 1;
  int get pairCount => inputPaths.length <= 1 ? 0 : inputPaths.length - 1;
  int get matchedPairCount =>
      pairs.where((pair) => pair.hasTrustedOverlapEvidence).length;
  int get missingPairCount =>
      (pairCount - matchedPairCount).clamp(0, pairCount);
  bool get allPairsHaveOverlapEvidence =>
      pairCount == 0 || matchedPairCount >= pairCount;
  bool get hasLowConfidenceAutomaticOverlap => pairs.any(
    (pair) =>
        !pair.usedManualAdjustment &&
        pair.overlapPixels > 0 &&
        pair.confidence.isFinite &&
        pair.confidence < .70,
  );
  bool get hasManualZeroOverlapJoin =>
      pairs.any((pair) => pair.usedZeroOverlapJoin);
  bool get preservesOriginalSectionSources =>
      usedFallback ||
      status == ReceiptStitchStatus.notNeeded ||
      status == ReceiptStitchStatus.stacked;
  bool get usesDerivedCombinedOcrArtifact => didStitch && stitchedPath != null;
  int get stitchedPixelCount => stitchedWidth * stitchedHeight;
  int get overlapPixelTotal {
    var total = 0;
    for (final pixels in overlapPixels) {
      if (pixels > 0) total += pixels;
    }
    return total;
  }

  String get stitchedSizeLabel => stitchedWidth > 0 && stitchedHeight > 0
      ? '$stitchedWidth x $stitchedHeight'
      : '';

  String get overlapCoverageCode {
    if (pairCount == 0) return 'single_section_no_overlap_needed';
    if (usedFallback) {
      final failed = failedPairIndex;
      if (failed != null) return 'fallback_pair_${failed + 1}_to_${failed + 2}';
      return 'fallback_overlap_not_trusted';
    }
    if (allPairsHaveOverlapEvidence) return 'all_pairs_have_overlap_evidence';
    return 'missing_overlap_evidence';
  }

  String get sourcePreservationCode {
    if (usesDerivedCombinedOcrArtifact) {
      return 'original_sections_preserved_derived_stitched_ocr_artifact';
    }
    if (preservesOriginalSectionSources) {
      return 'original_sections_preserved_ordered_ocr_sources';
    }
    return 'original_section_source_policy_unknown';
  }

  String get ocrSourceContractCode {
    if (inputPaths.isEmpty) {
      return usedFallback ? 'fallback_no_ocr_sources' : 'no_ocr_sources';
    }
    if (_hasInvalidReceiptArtifactPaths(inputPaths)) {
      return _invalidInputSourceContractCode(usedFallback);
    }
    if (_hasInvalidReceiptArtifactPaths(ocrSourcePaths)) {
      return _invalidOcrSourceContractCode(usedFallback);
    }
    if (_hasDuplicateReceiptArtifactPaths(inputPaths)) {
      return usedFallback
          ? 'fallback_duplicate_input_sources'
          : 'duplicate_input_sources';
    }
    if (_hasDuplicateReceiptArtifactPaths(ocrSourcePaths)) {
      return usedFallback
          ? 'fallback_duplicate_ocr_sources'
          : 'duplicate_ocr_sources';
    }
    if (usedFallback && diagnosticReasonLabel == 'decode_failed') {
      return 'fallback_unreadable_input_source';
    }
    if (usedFallback && diagnosticReasonLabel == 'unreadable_section_image') {
      return 'fallback_unreadable_section_image';
    }
    if (usedFallback && diagnosticReasonLabel == 'duplicate_section_image') {
      // Reading both originals would count the same physical receipt section
      // twice. Preserve both files for review, but do not call that OCR-ready
      // until the person removes or replaces the duplicate.
      return 'fallback_duplicate_section_image';
    }
    // These outcomes reject a derived combined image, not the original
    // photos.  Their ordered sources remain valid for reading and editable
    // review; duplicate or overlap uncertainty is surfaced as a warning,
    // never as a reason to strand the user outside the receipt form.
    if (didStitch) {
      if (stitchedPath == null || ocrSourcePaths.length != 1) {
        return 'stitched_ocr_source_missing';
      }
      if (_receiptArtifactPathSetContains(inputPaths, stitchedPath!)) {
        return 'stitched_ocr_source_reuses_input_section';
      }
      return _sameReceiptArtifactPath(ocrSourcePaths.single, stitchedPath!)
          ? 'stitched_ocr_source_ready'
          : 'stitched_ocr_source_path_mismatch';
    }
    if (status == ReceiptStitchStatus.stacked) {
      if (stitchedPath == null) return 'stacked_preview_missing';
      if (inputPaths.length != ocrSourcePaths.length) {
        return 'stacked_preview_ordered_source_count_mismatch';
      }
      for (var index = 0; index < inputPaths.length; index++) {
        if (!_sameReceiptArtifactPath(
          inputPaths[index],
          ocrSourcePaths[index],
        )) {
          return 'stacked_preview_ordered_source_path_mismatch';
        }
      }
      return 'stacked_preview_ordered_sources_ready';
    }
    if (inputPaths.length != ocrSourcePaths.length) {
      return usedFallback
          ? 'fallback_ordered_source_count_mismatch'
          : 'ordered_source_count_mismatch';
    }
    for (var index = 0; index < inputPaths.length; index++) {
      if (!_sameReceiptArtifactPath(inputPaths[index], ocrSourcePaths[index])) {
        return usedFallback
            ? 'fallback_ordered_source_path_mismatch'
            : 'ordered_source_path_mismatch';
      }
    }
    if (usedFallback) return 'fallback_ordered_sources_ready';
    return 'ordered_sources_ready';
  }

  bool get hasValidOcrSourceContract {
    return ocrSourceContractCode == 'stitched_ocr_source_ready' ||
        ocrSourceContractCode == 'stacked_preview_ordered_sources_ready' ||
        ocrSourceContractCode == 'fallback_ordered_sources_ready' ||
        ocrSourceContractCode == 'ordered_sources_ready';
  }

  bool get requiresOcrSourceReviewBeforeAssistedRead {
    return !hasValidOcrSourceContract ||
        (didStitch && hasManualZeroOverlapJoin) ||
        (didStitch && hasMultipleSections && hasLowConfidenceAutomaticOverlap);
  }

  String get assistedReadinessCode {
    if (!hasValidOcrSourceContract) return 'stitch_contract_review_required';
    if (didStitch && hasManualZeroOverlapJoin) {
      return 'stitched_zero_overlap_review_required';
    }
    if (didStitch && hasLowConfidenceAutomaticOverlap) {
      return 'stitched_overlap_review_required';
    }
    if (didStitch && allPairsHaveOverlapEvidence) {
      return 'stitched_overlap_verified_ready';
    }
    if (didStitch) return 'stitched_overlap_review_required';
    if (status == ReceiptStitchStatus.stacked) return 'ordered_sections_ready';
    if (usedFallback && hasMultipleSections) return 'ordered_sections_ready';
    if (inputPaths.length <= 1) return 'single_section_ready';
    return 'ordered_sections_ready';
  }

  String get failedPairLabel {
    final index = failedPairIndex;
    if (index == null) return '';
    return 'Photo ${index + 1} to ${index + 2}';
  }

  String get reviewFocusPairLabel {
    final failed = failedPairLabel;
    if (failed.isNotEmpty) return failed;
    if (!didStitch || !hasLowConfidenceAutomaticOverlap) return '';
    ReceiptStitchPairResult? lowestConfidencePair;
    for (final pair in pairs) {
      if (pair.usedManualAdjustment ||
          pair.overlapPixels <= 0 ||
          !pair.confidence.isFinite ||
          pair.confidence >= .70) {
        continue;
      }
      if (lowestConfidencePair == null ||
          pair.confidence < lowestConfidencePair.confidence) {
        lowestConfidencePair = pair;
      }
    }
    if (lowestConfidencePair == null) return '';
    final pairIndex = lowestConfidencePair.pairIndex;
    return 'Photo ${pairIndex + 1} to ${pairIndex + 2}';
  }

  String get diagnosticReasonLabel {
    if (!usedFallback) return status.name;
    return _safeStitchFallbackReasonCode(fallbackReasonCode);
  }

  String get userFallbackReasonLabel {
    if (!usedFallback) return '';
    return switch (diagnosticReasonLabel) {
      'decode_failed' => 'One photo could not be read',
      'manual_overlap_unsafe' => 'Manual overlap was outside the safe range',
      'invalid_input_paths' => 'Receipt section path was not trusted',
      'duplicate_input_paths' => 'Duplicate receipt section photo',
      'duplicate_section_image' => 'Duplicate receipt section photo',
      'no_input_paths' => 'No receipt photos available',
      'manual_order_review' => 'Receipt section order needs review',
      'overlap_confidence_low' => 'Overlap was not clear enough',
      'output_too_large' => 'Receipt is too long for this device',
      'stitch_exception' => 'Stitching hit a safe fallback',
      'stitch_timeout' => 'Putting photos together took too long',
      'user_rejected_stitch' => 'Combined image rejected during review',
      'unreadable_section_image' => 'One photo is not readable as a receipt',
      _ => 'Stitching was not trusted',
    };
  }

  String get matchConfidenceLabel {
    if (!hasMultipleSections || status == ReceiptStitchStatus.notNeeded) {
      return 'Match not needed';
    }
    if (usedManualAdjustment) return 'Manual match';
    return '${(_safeStitchUnitInterval(confidence) * 100).round()}% match';
  }

  String get pairDiagnosticsLabel {
    if (pairs.isEmpty) return '';
    return pairs.map((pair) => pair.userCheckLabel).join(' ');
  }

  String get diagnosticCodeLabel {
    if (usedFallback) return diagnosticReasonLabel;
    if (pairs.isEmpty) return status.name;
    return pairs.map((pair) => pair.diagnosticCode).join(',');
  }

  String get reviewPathLabel {
    if (inputPaths.isEmpty) return 'No receipt photos to review';
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? '1 photo to review'
            : '${inputPaths.length} receipt sections to review',
      ReceiptStitchStatus.stitched => '1 combined receipt image',
      ReceiptStitchStatus.stacked => '1 full receipt view',
      ReceiptStitchStatus.fallback =>
        '${inputPaths.length} receipt sections top to bottom',
    };
  }

  String get reviewDecisionLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded => reviewPathLabel,
      ReceiptStitchStatus.stitched => '$reviewPathLabel, $matchConfidenceLabel',
      ReceiptStitchStatus.stacked => reviewPathLabel,
      ReceiptStitchStatus.fallback => '$reviewPathLabel, $matchConfidenceLabel',
    };
  }

  String get ocrHandoffChecklistLabel {
    if (inputPaths.isEmpty) {
      return 'Before use: add at least one readable receipt photo.';
    }
    if (inputPaths.length <= 1) {
      return 'Before use: confirm the full receipt is visible and readable.';
    }
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        'Before use: keep receipt sections top to bottom and make sure no middle section is missing.',
      ReceiptStitchStatus.stitched =>
        'Before use: check repeated lines joined correctly and no receipt section is missing.',
      ReceiptStitchStatus.stacked =>
        'Before use: check each receipt section is visible from top to bottom.',
      ReceiptStitchStatus.fallback =>
        'Before use: photos stay separate, so verify top-to-bottom order and any missing middle section.',
    };
  }

  String get ocrHandoffSafetyCode {
    if (inputPaths.isEmpty) return 'no_receipt_photo_available';
    if (inputPaths.length <= 1) return 'single_section_review_ready';
    return switch (status) {
      ReceiptStitchStatus.notNeeded => 'ordered_sections_review_ready',
      ReceiptStitchStatus.stitched =>
        allPairsHaveOverlapEvidence && !hasLowConfidenceAutomaticOverlap
            ? 'stitched_overlap_verified'
            : 'stitched_overlap_needs_review',
      ReceiptStitchStatus.stacked => 'ordered_sections_review_ready',
      ReceiptStitchStatus.fallback =>
        'ordered_sections_after_${diagnosticReasonLabel}_fallback',
    };
  }

  String get ocrHandoffSafetyLabel {
    return switch (ocrHandoffSafetyCode) {
      'single_section_review_ready' =>
        'OCR will read one receipt photo after review.',
      'no_receipt_photo_available' =>
        'OCR needs at least one receipt photo before app-assisted review.',
      'ordered_sections_review_ready' =>
        'OCR will read ordered receipt sections from top to bottom.',
      'stitched_overlap_verified' =>
        'OCR will read one stitched receipt image with verified overlap.',
      'stitched_overlap_needs_review' =>
        'OCR will read one stitched image, but overlap evidence still needs review.',
      _ when usedFallback =>
        'OCR will read ordered sections because stitching was not trusted.',
      _ => 'OCR handoff needs receipt-photo review.',
    };
  }

  ReceiptStitchResult copyForFinalOcr({
    required List<String> inputPaths,
    required List<String> ocrSourcePaths,
    String? stitchedPath,
  }) {
    final providedFinalStitchPath = stitchedPath?.trim().isNotEmpty == true
        ? stitchedPath
        : null;
    final finalStitchedPath =
        providedFinalStitchPath ??
        (status == ReceiptStitchStatus.stitched && ocrSourcePaths.length == 1
            ? ocrSourcePaths.single
            : this.stitchedPath);
    final finalOcrSourcePaths =
        status == ReceiptStitchStatus.stitched &&
            finalStitchedPath != null &&
            finalStitchedPath.trim().isNotEmpty
        ? [finalStitchedPath]
        : ocrSourcePaths;
    return ReceiptStitchResult(
      status: status,
      inputPaths: inputPaths,
      ocrSourcePaths: finalOcrSourcePaths,
      stitchedPath: finalStitchedPath,
      confidence: confidence,
      overlapPixels: overlapPixels,
      pairs: pairs,
      failedPairIndex: failedPairIndex,
      stitchedWidth: stitchedWidth,
      stitchedHeight: stitchedHeight,
      warning: warning,
      usedManualAdjustment: usedManualAdjustment,
      fallbackReasonCode: fallbackReasonCode,
    );
  }
}
