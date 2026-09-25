part of 'receipt_capture_models.dart';

extension ReceiptPhotoCoverageDecisionLabels on ReceiptPhotoCoverageDecision {
  bool get isMissingBottomEdgeAndTotals =>
      reasonCode == 'missing_bottom_edge_and_totals';

  String get continuationCaptureContractCode => isMissingBottomEdgeAndTotals
      ? 'bottom_edge_totals_missing_use_ghost_overlap'
      : 'standard_receipt_section_review';

  String get ghostGuidePolicyCode => isMissingBottomEdgeAndTotals
      ? 'bottom_overlap_ghost_at_top_repeat_3_to_5_lines'
      : 'section_overlap_ghost_at_top_repeat_3_to_5_lines';

  String get ghostGuidePlacementCode =>
      shouldPromptForMorePhotos ? 'top_ghost_slice' : 'not_requested';

  String get ghostGuideRepeatLineTargetCode => shouldPromptForMorePhotos
      ? 'repeat_3_to_5_readable_lines'
      : 'not_requested';

  String get ghostGuideMatchTargetCode {
    if (!shouldPromptForMorePhotos) return 'not_requested';
    if (isMissingBottomEdgeAndTotals) return 'subtotal_total_and_final_lines';
    return 'repeated_receipt_lines';
  }

  String get continuationCaptureContractLabel => isMissingBottomEdgeAndTotals
      ? 'Bottom edge and totals missing: reopen the camera with the top reference strip and repeat 3-5 readable lines so subtotal, total, and final lines can be matched.'
      : 'Ask whether the receipt continues before moving to receipt details.';

  String get evidenceContractCode => isMissingBottomEdgeAndTotals
      ? 'bottom_edge_missing_plus_totals_words_and_amount_missing'
      : 'single_signal_or_manual_coverage_review';

  String get evidenceContractLabel => isMissingBottomEdgeAndTotals
      ? 'Bottom edge, subtotal/total words, and total amount evidence are missing.'
      : 'Receipt coverage decision is based on one signal family or manual review.';

  String get evidenceRationaleCode => isMissingBottomEdgeAndTotals
      ? 'edge_missing_and_totals_words_amount_missing'
      : 'single_signal_or_user_visual_review';

  String get evidenceRationaleLabel => isMissingBottomEdgeAndTotals
      ? 'The app uses receipt-edge evidence, subtotal/total word evidence, and total amount evidence before recommending another section.'
      : 'The app is asking the user to visually confirm receipt coverage.';

  String get completionEvidenceSummaryLabel {
    if (isMissingBottomEdgeAndTotals) {
      return 'Bottom edge missing plus subtotal/total words and total amount missing. Add the bottom section with the top reference strip, or continue only if this photo already shows the full receipt.';
    }
    if (shouldPromptForMorePhotos) {
      return 'Receipt may continue. Add another section if anything is missing, or continue if this photo shows the full receipt.';
    }
    return 'Receipt coverage looks complete enough for receipt details.';
  }

  Map<String, Object> get privacySafeEvidenceContract {
    return Map.unmodifiable({
      'schema': 'receipt_photo_coverage_decision_v1',
      'status': status.name,
      'reasonCode': reasonCode,
      'shouldPromptForMorePhotos': shouldPromptForMorePhotos,
      'shouldEmphasizeAddPhoto': shouldEmphasizeAddPhoto,
      'continuationCaptureContractCode': continuationCaptureContractCode,
      'continuationCaptureContractLabel': continuationCaptureContractLabel,
      'ghostGuidePolicyCode': ghostGuidePolicyCode,
      'ghostGuidePlacementCode': ghostGuidePlacementCode,
      'ghostGuideRepeatLineTargetCode': ghostGuideRepeatLineTargetCode,
      'ghostGuideMatchTargetCode': ghostGuideMatchTargetCode,
      'evidenceContractCode': evidenceContractCode,
      'evidenceRationaleCode': evidenceRationaleCode,
      'completionEvidenceSummaryLabel': completionEvidenceSummaryLabel,
      'bottomEdgeAndTotalsMissingTogether': isMissingBottomEdgeAndTotals,
    });
  }

  String get completionDialogTitle => isMissingBottomEdgeAndTotals
      ? 'Add the bottom of this receipt?'
      : 'Need another receipt section?';

  String get completionDialogMessage {
    if (isMissingBottomEdgeAndTotals) {
      return '$guidance If this photo already includes the whole receipt, you can continue, but the subtotal/total may need manual review.';
    }
    return '$guidance If the receipt continues below this photo, add another photo now. If this photo has the full receipt, use this photo.';
  }

  String get addSectionButtonLabel =>
      isMissingBottomEdgeAndTotals ? 'Add Bottom Section' : 'Add Another Photo';

  String get continueAnywayButtonLabel => 'Continue';

  bool get shouldPromptForMorePhotos =>
      status == ReceiptPhotoCoverageStatus.likelyCutOff ||
      status == ReceiptPhotoCoverageStatus.maybeContinues;

  bool get shouldEmphasizeAddPhoto =>
      status == ReceiptPhotoCoverageStatus.likelyCutOff;

  bool get isLikelyComplete =>
      status == ReceiptPhotoCoverageStatus.likelyComplete;
}
