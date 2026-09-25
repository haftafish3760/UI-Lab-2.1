part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultNextReview on ReceiptPhotoReviewResult {
  String get savedProofCountLabel {
    final count = photoPaths.length;
    return count == 1 ? '1 saved proof photo' : '$count saved proof photos';
  }

  bool get nextReviewUsesCombinedReceiptImage => stitchResult.didStitch;

  bool get nextReviewUsesOrderedSections =>
      stitchResult.usedFallback ||
      (!stitchResult.didStitch && ocrSourcePhotoPaths.length > 1);

  int get nextReviewSourceCount => ocrSourcePhotoPaths.length;

  String get nextReviewSourceLabel {
    if (nextReviewSourceCount <= 0) {
      return 'no clear receipt photo';
    }
    if (nextReviewUsesCombinedReceiptImage) {
      return 'one combined receipt image';
    }
    if (nextReviewUsesOrderedSections) {
      return '$nextReviewSourceCount ordered receipt sections';
    }
    return nextReviewSourceCount == 1
        ? 'one receipt photo'
        : '$nextReviewSourceCount receipt photos';
  }

  String get nextReviewHandoffLabel {
    if (!hasOcrSourcePhotos) {
      return 'No clear receipt photo is ready to fill the receipt details. Add a clearer photo or continue by hand.';
    }
    final safety =
        stitchResult.hasLowConfidenceAutomaticOverlap &&
            stitchResult.requiresOcrSourceReviewBeforeAssistedRead
        ? stitchResult.ocrHandoffSafetyLabel
        : stitchResult.stitchSafetyLabel;
    final normalizedSafety = safety.endsWith('.') ? safety : '$safety.';
    final reviewPair = stitchResult.reviewFocusPairLabel;
    if (needsAnotherReceiptSectionBeforeDetails) {
      if (firstPossiblePartialReceiptReasonCode ==
          'missing_bottom_edge_and_totals') {
        return '${_bottomGhostSliceHandoffInstruction(suffix: 'before receipt details unless this photo already shows the full receipt.')} $normalizedSafety';
      }
      return 'Add the next receipt section before receipt details unless this photo already shows the full receipt. $normalizedSafety';
    }
    if (nextReviewUsesCombinedReceiptImage) {
      if (stitchResult.hasLowConfidenceAutomaticOverlap &&
          reviewPair.isNotEmpty) {
        return 'Receipt details open from $nextReviewSourceLabel. $reviewPair still needs review. $normalizedSafety';
      }
      return 'Receipt details open from $nextReviewSourceLabel. $normalizedSafety';
    }
    if (nextReviewUsesOrderedSections) {
      if (stitchResult.usedFallback && reviewPair.isNotEmpty) {
        return 'Receipt details open from $nextReviewSourceLabel in top-to-bottom order. $reviewPair needs adjustment. $normalizedSafety';
      }
      return 'Receipt details open from $nextReviewSourceLabel in top-to-bottom order. $normalizedSafety';
    }
    return 'Receipt details open from $nextReviewSourceLabel. $normalizedSafety';
  }

  String get nextReviewDiagnosticLabel {
    final reason = stitchResult.diagnosticReasonLabel;
    final coverage = hasPossiblePartialReceiptPhotos
        ? 'possible_partial_receipt'
        : 'coverage_ok';
    final nextSection = needsAnotherReceiptSectionBeforeDetails
        ? 'needs_next_section'
        : 'details_ready';
    return '${stitchResult.status.name}:$reason:$coverage:$nextReviewSourceCount:$nextSection';
  }

  String get nextReviewMatchReadinessOutcome {
    if (!hasOcrSourcePhotos) return 'missing_ocr_source';
    if (needsAnotherReceiptSectionBeforeDetails) {
      return 'needs_next_receipt_section';
    }
    if (stitchResult.requiresOcrSourceReviewBeforeAssistedRead) {
      return 'ocr_source_review_required_before_assist';
    }
    if (stitchResult.didStitch) return 'combined_receipt_image_ready';
    if (stitchResult.usedFallback) return 'ordered_sections_fallback_ready';
    if (nextReviewUsesOrderedSections) return 'ordered_sections_ready';
    return 'single_receipt_source_ready';
  }

  String get nextReviewMatchReadinessLabel {
    return switch (nextReviewMatchReadinessOutcome) {
      'combined_receipt_image_ready' =>
        'Photo match ready: one combined receipt image will be read.',
      'ordered_sections_fallback_ready' =>
        reviewPair.isEmpty
            ? 'Photo match fallback: ordered receipt sections will be read top to bottom.'
            : 'Photo match fallback: ordered receipt sections will be read top to bottom, and $reviewPair needs review.',
      'ordered_sections_ready' =>
        'Ordered receipt sections will be read top to bottom.',
      'ocr_source_review_required_before_assist' =>
        reviewPair.isEmpty
            ? 'Photo match needs review before receipt details can be filled.'
            : 'Photo match needs review before receipt details can be filled, starting with $reviewPair.',
      'missing_ocr_source' =>
        'No clear receipt photo is ready to fill the receipt details.',
      'needs_next_receipt_section' =>
        firstPossiblePartialReceiptReasonCode ==
                'missing_bottom_edge_and_totals'
            ? _bottomGhostSliceHandoffInstruction(
                suffix: 'or confirm this photo already shows the full receipt.',
              )
            : 'Add the next receipt section or confirm this photo already shows the full receipt.',
      _ => 'The receipt photo is ready for review.',
    };
  }

  String get ocrSourceCountLabel {
    final count = ocrSourcePhotoPaths.length;
    if (count <= 0) return 'no clear receipt photo';
    if (stitchResult.didStitch) {
      return '1 clear combined receipt image';
    }
    if (nextReviewUsesOrderedSections) {
      return count == 1
          ? '1 clear ordered receipt section'
          : '$count clear ordered receipt sections';
    }
    return count == 1 ? '1 clear receipt photo' : '$count clear receipt photos';
  }

  String get reviewPair => stitchResult.reviewFocusPairLabel;
}
