part of 'receipt_capture_models.dart';

class ReceiptStitchPairResult {
  const ReceiptStitchPairResult({
    required this.pairIndex,
    required this.overlapPixels,
    required this.confidence,
    this.seamSkipPixels = 0,
    this.selectedSeamCropPixels = 0,
    this.usedManualAdjustment = false,
    this.scaleCorrection = 1,
    this.rotationCorrectionDegrees = 0,
    this.perspectiveCorrection = 0,
    this.horizontalOffsetPixels = 0,
    this.verticalOffsetPixels = 0,
    this.textOverlapConfidence = 0,
    this.matchedTextLineCount = 0,
    this.textPositionalConfidence = 0,
    this.hasTextPositionEvidence = false,
    this.previousTextOverlapStart = 0,
    this.nextTextOverlapEnd = 0,
    this.nextContinuationTextStart = 0,
    this.nextContinuationTextEnd = 0,
    this.usedZeroOverlapJoin = false,
    this.continuityCorrelation = 0,
    this.continuityDetailedBands = 0,
    this.continuityMatchingBands = 0,
    this.geometryCorrelation = 0,
    this.geometryDetailedCells = 0,
    this.geometryMatchingCells = 0,
    this.visualConfidence = 0,
    this.usedNativeRegistration = false,
  });

  final int pairIndex;
  final int overlapPixels;
  final double confidence;

  /// Rows used to place the continuation in the shared proof coordinate space.
  /// Delayed overlap includes leading continuation rows in this value.
  final int seamSkipPixels;

  /// Actual continuation rows removed at the selected low-ink seam.
  final int selectedSeamCropPixels;
  final bool usedManualAdjustment;
  final double scaleCorrection;
  final double rotationCorrectionDegrees;
  final double perspectiveCorrection;
  final int horizontalOffsetPixels;
  final int verticalOffsetPixels;
  final double textOverlapConfidence;
  final int matchedTextLineCount;
  final double textPositionalConfidence;
  final bool hasTextPositionEvidence;
  final double previousTextOverlapStart;
  final double nextTextOverlapEnd;
  final double nextContinuationTextStart;
  final double nextContinuationTextEnd;
  final bool usedZeroOverlapJoin;
  final double continuityCorrelation;
  final int continuityDetailedBands;
  final int continuityMatchingBands;
  final double geometryCorrelation;
  final int geometryDetailedCells;
  final int geometryMatchingCells;
  final double visualConfidence;
  final bool usedNativeRegistration;

  ReceiptStitchPairResult withSelectedSeamCrop(int value) {
    return ReceiptStitchPairResult(
      pairIndex: pairIndex,
      overlapPixels: overlapPixels,
      confidence: confidence,
      seamSkipPixels: seamSkipPixels,
      selectedSeamCropPixels: value,
      usedManualAdjustment: usedManualAdjustment,
      scaleCorrection: scaleCorrection,
      rotationCorrectionDegrees: rotationCorrectionDegrees,
      perspectiveCorrection: perspectiveCorrection,
      horizontalOffsetPixels: horizontalOffsetPixels,
      verticalOffsetPixels: verticalOffsetPixels,
      textOverlapConfidence: textOverlapConfidence,
      matchedTextLineCount: matchedTextLineCount,
      textPositionalConfidence: textPositionalConfidence,
      hasTextPositionEvidence: hasTextPositionEvidence,
      previousTextOverlapStart: previousTextOverlapStart,
      nextTextOverlapEnd: nextTextOverlapEnd,
      nextContinuationTextStart: nextContinuationTextStart,
      nextContinuationTextEnd: nextContinuationTextEnd,
      usedZeroOverlapJoin: usedZeroOverlapJoin,
      continuityCorrelation: continuityCorrelation,
      continuityDetailedBands: continuityDetailedBands,
      continuityMatchingBands: continuityMatchingBands,
      geometryCorrelation: geometryCorrelation,
      geometryDetailedCells: geometryDetailedCells,
      geometryMatchingCells: geometryMatchingCells,
      visualConfidence: visualConfidence,
      usedNativeRegistration: usedNativeRegistration,
    );
  }

  String get pairLabel => 'Photo ${pairIndex + 1} to ${pairIndex + 2}';
  double get _safeConfidence => _safeStitchUnitInterval(confidence);
  double get _safeScaleCorrection =>
      scaleCorrection.isFinite ? scaleCorrection : 1;
  double get _safeRotationCorrectionDegrees =>
      rotationCorrectionDegrees.isFinite ? rotationCorrectionDegrees : 0;
  double get _safePerspectiveCorrection =>
      perspectiveCorrection.isFinite ? perspectiveCorrection : 0;
  int get _safeHorizontalOffsetPixels => horizontalOffsetPixels;
  int get _safeVerticalOffsetPixels => verticalOffsetPixels;
  int get _confidencePercent => (_safeConfidence * 100).round();
  double get _safeTextOverlapConfidence =>
      _safeStitchUnitInterval(textOverlapConfidence);
  bool get hasTextOverlapEvidence =>
      matchedTextLineCount > 0 && _safeTextOverlapConfidence >= .66;
  bool get hasTrustedOverlapEvidence =>
      usedManualAdjustment || (overlapPixels > 0 && _safeConfidence >= .50);

  String get summaryLabel {
    if (usedZeroOverlapJoin) {
      return '$pairLabel: placed in order with no shared lines';
    }
    final match = overlapPixels <= 0
        ? 'no safe overlap'
        : hasTextOverlapEvidence
        ? '$matchedTextLineCount repeated text ${matchedTextLineCount == 1 ? 'line' : 'lines'}'
        : 'matching image area';
    if (usedManualAdjustment) return '$pairLabel: manual match, $match';
    final rotationText = _safeRotationCorrectionDegrees.abs() >= .5
        ? ', straighten ${_safeRotationCorrectionDegrees.toStringAsFixed(1)} deg'
        : '';
    final driftText = _safeHorizontalOffsetPixels.abs() >= 24
        ? ', shifted ${_safeHorizontalOffsetPixels.abs()} px'
        : '';
    final delayedText = _safeVerticalOffsetPixels >= 24
        ? ', delayed ${_safeVerticalOffsetPixels}px'
        : '';
    final perspectiveText = _safePerspectiveCorrection.abs() >= .03
        ? ', angle corrected'
        : '';
    if ((_safeScaleCorrection - 1).abs() >= .03) {
      return '$pairLabel: $_confidencePercent% match, $match, zoom adjusted$rotationText$perspectiveText$driftText$delayedText';
    }
    return '$pairLabel: $_confidencePercent% match, $match$rotationText$perspectiveText$driftText$delayedText';
  }

  String get matchEvidenceLabel {
    if (usedZeroOverlapJoin) return 'no-overlap placement';
    if (usedManualAdjustment) return 'manual overlap';
    if (overlapPixels <= 0) return '$_confidencePercent% no overlap';
    if ((_safeScaleCorrection - 1).abs() >= .03) {
      return '$_confidencePercent% with zoom fix';
    }
    if (_safeRotationCorrectionDegrees.abs() >= .5) {
      return '$_confidencePercent% with straightening';
    }
    if (_safePerspectiveCorrection.abs() >= .03) {
      return '$_confidencePercent% with angle correction';
    }
    if (_safeHorizontalOffsetPixels.abs() >= 24) {
      return '$_confidencePercent% with drift fix';
    }
    if (_safeVerticalOffsetPixels >= 24) {
      return '$_confidencePercent% with delayed overlap';
    }
    return '$_confidencePercent% overlap';
  }

  String get diagnosticCode {
    if (usedZeroOverlapJoin) return 'manual_zero_overlap_join';
    if (usedManualAdjustment) return 'manual_overlap';
    if (overlapPixels <= 0) return 'no_safe_overlap';
    if (hasTextOverlapEvidence) return 'ocr_text_and_image_overlap_matched';
    if ((_safeScaleCorrection - 1).abs() >= .03 &&
        _safeRotationCorrectionDegrees.abs() >= .5) {
      return 'zoom_and_straighten_adjusted';
    }
    if ((_safeScaleCorrection - 1).abs() >= .03) return 'zoom_adjusted';
    if (_safeRotationCorrectionDegrees.abs() >= .5) {
      return 'straighten_adjusted';
    }
    if (_safePerspectiveCorrection.abs() >= .03) {
      return 'perspective_adjusted';
    }
    if (_safeHorizontalOffsetPixels.abs() >= 24) return 'drift_adjusted';
    if (_safeVerticalOffsetPixels >= 24) return 'delayed_overlap_adjusted';
    return 'overlap_matched';
  }

  String get userCheckLabel {
    if (usedZeroOverlapJoin) {
      return '$pairLabel was placed directly after the previous section. Check that no receipt lines are missing.';
    }
    if (usedManualAdjustment) {
      return '$pairLabel used your manual overlap. Check repeated lines once.';
    }
    if (overlapPixels <= 0) {
      return '$pairLabel did not show a safe shared receipt area.';
    }
    final adjustments = <String>[];
    if ((_safeScaleCorrection - 1).abs() >= .03) {
      adjustments.add('zoom difference');
    }
    if (_safeRotationCorrectionDegrees.abs() >= .5) {
      adjustments.add('slight tilt');
    }
    if (_safePerspectiveCorrection.abs() >= .03) {
      adjustments.add('camera angle');
    }
    if (_safeHorizontalOffsetPixels.abs() >= 24) {
      adjustments.add('sideways drift');
    }
    if (_safeVerticalOffsetPixels >= 24) {
      adjustments.add('delayed overlap');
    }
    if (adjustments.isEmpty) {
      return hasTextOverlapEvidence
          ? '$pairLabel matched $matchedTextLineCount repeated text ${matchedTextLineCount == 1 ? 'line' : 'lines'} and the receipt image.'
          : '$pairLabel matched the shared receipt image area.';
    }
    final evidence = hasTextOverlapEvidence
        ? 'repeated text and image detail'
        : 'shared image detail';
    return '$pairLabel matched $evidence after fixing ${adjustments.join(' and ')}.';
  }
}
