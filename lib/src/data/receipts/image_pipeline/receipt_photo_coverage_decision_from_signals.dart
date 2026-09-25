part of 'receipt_capture_models.dart';

ReceiptPhotoCoverageDecision _receiptPhotoCoverageDecisionFromSignals({
  ReceiptPhotoQualityCheck? quality,
  Map<String, Object?>? diagnostics,
}) {
  final framingSignal =
      diagnostics?[ReceiptCaptureDiagnosticKeys.latestFramingSignal]
          ?.toString()
          .trim();
  final perspectiveReadiness =
      diagnostics?[ReceiptCaptureDiagnosticKeys.latestPerspectiveReadiness]
          ?.toString()
          .trim();
  final edgeCoverage = _doubleValue(
    diagnostics?[ReceiptCaptureDiagnosticKeys.latestEdgeCoverage],
  );
  final bottomEdgeScore = _doubleValue(
    diagnostics?[ReceiptCaptureDiagnosticKeys.latestCapturedBottomEdgeScore],
  );
  final framingWidthRatio = _doubleValue(
    diagnostics?[ReceiptCaptureDiagnosticKeys.latestFramingWidthRatio],
  );
  final framingHeightRatio = _doubleValue(
    diagnostics?[ReceiptCaptureDiagnosticKeys.latestFramingHeightRatio],
  );
  final textLikelyTooSmall =
      framingWidthRatio != null &&
      framingHeightRatio != null &&
      framingWidthRatio > 0 &&
      framingHeightRatio > 0 &&
      (framingWidthRatio < .42 || framingHeightRatio < .36);
  final nativeCutOffRisk =
      framingSignal == ReceiptNativeCoverageSignalValues.possiblyCutOff ||
      perspectiveReadiness ==
          ReceiptNativeCoverageSignalValues.perspectiveSkippedCutOffRisk;
  final bottomEdgeMissing = _bottomEdgeMissing(
    diagnostics,
    nativeCutOffRisk: nativeCutOffRisk,
    edgeCoverage: edgeCoverage,
    bottomEdgeScore: bottomEdgeScore,
    framingHeightRatio: framingHeightRatio,
  );
  final totalsEvidenceMissing = _totalsEvidenceMissing(diagnostics);
  if (bottomEdgeMissing && totalsEvidenceMissing) {
    return const ReceiptPhotoCoverageDecision(
      status: ReceiptPhotoCoverageStatus.likelyCutOff,
      reasonCode: 'missing_bottom_edge_and_totals',
      title: 'Add The Next Receipt Section',
      guidance:
          'Two checks agree that the receipt may continue: the bottom edge '
          'was not detected, and subtotal/total words plus the total amount '
          'were not confirmed. Add the bottom receipt photo with the top '
          'reference strip and repeat 3-5 readable lines so subtotal, '
          'total, and final lines can be matched.',
    );
  }
  if (nativeCutOffRisk &&
      quality?.isLikelyReadable == true &&
      (edgeCoverage == null || edgeCoverage >= .70)) {
    return const ReceiptPhotoCoverageDecision(
      status: ReceiptPhotoCoverageStatus.likelyComplete,
      reasonCode: 'native_cut_off_readable_check',
      title: 'Check Receipt Edges',
      guidance:
          'The receipt looks readable. Check that the top and bottom are included, then use this photo if nothing is missing.',
    );
  }
  if (nativeCutOffRisk) {
    return const ReceiptPhotoCoverageDecision(
      status: ReceiptPhotoCoverageStatus.likelyCutOff,
      reasonCode: 'native_cut_off_risk',
      title: 'Receipt May Be Cut Off',
      guidance:
          'Leave a little paper edge visible, crop if needed, or use Add Another Photo only if the receipt continues.',
    );
  }
  if (quality?.isPoorlyFramed == true) {
    return const ReceiptPhotoCoverageDecision(
      status: ReceiptPhotoCoverageStatus.likelyCutOff,
      reasonCode: 'quality_poor_framing',
      title: 'Check Receipt Edges',
      guidance:
          'Part of the receipt may be outside the photo. Crop, retake, or add another photo before using this photo.',
    );
  }
  if (framingSignal == ReceiptNativeCoverageSignalValues.moveCloser ||
      textLikelyTooSmall ||
      quality?.isLowResolution == true) {
    return const ReceiptPhotoCoverageDecision(
      status: ReceiptPhotoCoverageStatus.maybeContinues,
      reasonCode: 'text_may_be_too_small',
      title: 'Make Sure The Whole Receipt Is Readable',
      guidance:
          'If this is a long receipt, add closer photos from top to bottom instead of squeezing tiny text into one shot.',
    );
  }
  if (quality?.isMissingTextBands == true) {
    return const ReceiptPhotoCoverageDecision(
      status: ReceiptPhotoCoverageStatus.maybeContinues,
      reasonCode: 'weak_receipt_lines',
      title: 'Check For Missing Lines',
      guidance:
          'Some printed lines look weak. Use Add Another Photo if the bottom or middle of the receipt is missing.',
    );
  }
  if (framingSignal == ReceiptNativeCoverageSignalValues.framingOk &&
      (edgeCoverage == null || edgeCoverage >= .45) &&
      quality?.isLikelyReadable == true) {
    return const ReceiptPhotoCoverageDecision(
      status: ReceiptPhotoCoverageStatus.likelyComplete,
      reasonCode: 'framing_ok_readable',
      title: 'Receipt Looks Complete',
      guidance:
          'Use this photo if the store, date, total, and item prices are readable.',
    );
  }
  if (quality?.isLikelyReadable == true && quality!.cropScore >= .50) {
    return const ReceiptPhotoCoverageDecision(
      status: ReceiptPhotoCoverageStatus.likelyComplete,
      reasonCode: 'readable_framed_photo',
      title: 'Receipt Looks Complete',
      guidance:
          'Use this photo if the receipt does not continue below this photo.',
    );
  }
  if (framingSignal == ReceiptNativeCoverageSignalValues.receiptNotFound) {
    return const ReceiptPhotoCoverageDecision(
      status: ReceiptPhotoCoverageStatus.unknown,
      reasonCode: 'receipt_not_found',
      title: 'Check Receipt Photo',
      guidance:
          'The app could not clearly find the receipt edges. Crop, retake, or continue if the text is readable.',
    );
  }
  return const ReceiptPhotoCoverageDecision(
    status: ReceiptPhotoCoverageStatus.unknown,
    reasonCode: 'coverage_unknown',
    title: 'Check Receipt Coverage',
    guidance:
        'Make sure this photo includes the part of the receipt you intended before using it.',
  );
}
