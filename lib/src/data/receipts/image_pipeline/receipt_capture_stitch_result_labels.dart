part of 'receipt_capture_models.dart';

extension ReceiptStitchResultLabels on ReceiptStitchResult {
  Map<String, Object?> get privacySafeOcrHandoffSafety {
    return Map.unmodifiable({
      'stitchOcrHandoffSafetyCode': ocrHandoffSafetyCode,
      'stitchOcrHandoffSafetyLabel': ocrHandoffSafetyLabel,
      'stitchOcrHandoffUsesCombinedImage': didStitch,
      'stitchOcrHandoffUsesOrderedSections':
          usedFallback ||
          status == ReceiptStitchStatus.notNeeded ||
          status == ReceiptStitchStatus.stacked,
      'stitchOcrHandoffSourceCount': ocrSourcePaths.length,
      'stitchOcrSourceContractCode': ocrSourceContractCode,
      'stitchOcrSourceContractReady': hasValidOcrSourceContract,
      'stitchAssistedReadinessCode': assistedReadinessCode,
      'stitchRequiresOcrSourceReviewBeforeAssistedRead':
          requiresOcrSourceReviewBeforeAssistedRead,
      'stitchOcrHandoffChecklistLabel': ocrHandoffChecklistLabel,
      if (reviewFocusPairLabel.isNotEmpty)
        'stitchReviewFocusPairLabel': reviewFocusPairLabel,
    });
  }

  String get overlapExpectationLabel {
    if (inputPaths.length <= 1) return 'Full receipt in one photo';
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        'Repeat 3-5 readable lines between sections',
      ReceiptStitchStatus.stitched =>
        usedManualAdjustment
            ? 'Manual overlap accepted'
            : 'Repeated lines matched',
      ReceiptStitchStatus.stacked =>
        'Photos kept together without removing rows',
      ReceiptStitchStatus.fallback =>
        'Stitch skipped; order still controls OCR review',
    };
  }

  String get overlapCoverageLabel {
    if (pairCount == 0) return 'No overlap needed for a single receipt photo.';
    if (usedFallback) {
      final failed = failedPairLabel.isEmpty
          ? 'one photo pair'
          : failedPairLabel;
      return '$failed did not have trusted overlap; OCR keeps sections ordered.';
    }
    if (allPairsHaveOverlapEvidence) {
      return 'Every adjacent receipt section has overlap evidence.';
    }
    return 'One or more receipt section overlaps still need review.';
  }

  String get nextStepLabel {
    if (inputPaths.isEmpty) return 'Add a receipt photo before continuing.';
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'Receipt details open from this receipt photo.'
            : 'Receipt details open from these receipt sections in order.',
      ReceiptStitchStatus.stitched =>
        'Receipt details open from one combined receipt image.',
      ReceiptStitchStatus.stacked =>
        'Receipt details open from these receipt sections in order.',
      ReceiptStitchStatus.fallback =>
        'Receipt details open from each section, top to bottom.',
    };
  }

  String get stitchSafetyLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded => 'No stitch needed',
      ReceiptStitchStatus.stitched =>
        usedManualAdjustment
            ? 'Manual match accepted'
            : 'Automatic match accepted',
      ReceiptStitchStatus.stacked => 'Full receipt view ready',
      ReceiptStitchStatus.fallback => 'Stitch not trusted',
    };
  }

  String get summaryLabel {
    if (inputPaths.isEmpty) return 'No receipt photo ready for review.';
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'Single receipt photo ready for review.'
            : 'Receipt sections ready for review.',
      ReceiptStitchStatus.stitched =>
        'Receipt sections combined for app-assisted review.',
      ReceiptStitchStatus.stacked =>
        'Full receipt view ready; original photos stay in order for reading.',
      ReceiptStitchStatus.fallback =>
        'Receipt sections will be reviewed separately.',
    };
  }

  String get detailLabel {
    if (inputPaths.isEmpty) {
      return warning.trim().isEmpty
          ? 'No receipt photos were available.'
          : warning;
    }
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'One photo was prepared for receipt details.'
            : '${inputPaths.length} receipt sections were prepared for receipt details.',
      ReceiptStitchStatus.stitched =>
        '${inputPaths.length} receipt sections became 1 receipt image'
            '${stitchedSizeLabel.isEmpty ? '' : ' ($stitchedSizeLabel)'}. '
            '${usedManualAdjustment ? 'Manual match was used.' : 'Photo match confidence ${(_safeStitchUnitInterval(confidence) * 100).round()}%.'}'
            '${pairDiagnosticsLabel.isEmpty ? '' : ' $pairDiagnosticsLabel'}',
      ReceiptStitchStatus.stacked =>
        warning.trim().isEmpty
            ? '${inputPaths.length} receipt sections are shown together without removing any rows.'
            : warning,
      ReceiptStitchStatus.fallback =>
        warning.trim().isEmpty
            ? '${inputPaths.length} receipt sections stayed separate because stitching confidence was too low.'
            : failedPairLabel.isEmpty
            ? warning
            : '$failedPairLabel: $warning',
    };
  }
}
