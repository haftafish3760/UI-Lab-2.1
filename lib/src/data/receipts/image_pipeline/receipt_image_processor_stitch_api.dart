part of 'receipt_image_processor.dart';

Future<ReceiptStitchResult> _stitchReceiptPhotosForOcr({
  required List<String> paths,
  List<ReceiptStitchTextEvidence>? textEvidenceByPath,
  List<bool>? manualZeroOverlapPairs,
  List<int>? manualOverlapPixels,
  List<double>? manualOverlapFractions,
  List<double>? manualScaleCorrections,
  List<double>? manualRotationCorrectionsDegrees,
  List<double>? manualHorizontalOffsetFractions,
  int maxOutputPixels = 16000000,
  int maxOutputHeight = 20000,
  int maxTargetWidth = 1400,
  int comparisonWidth = 400,
  int retryComparisonWidth = 320,
  List<ReceiptNativeRegistrationProposal> nativeRegistrationProposals =
      const <ReceiptNativeRegistrationProposal>[],
  required String outputPath,
}) async {
  final normalizedInput = _normalizeReceiptStitchInputPaths(paths);
  if (normalizedInput.failure != null) return normalizedInput.failure!;
  final inputPaths = normalizedInput.paths;
  final confidences = <double>[];
  final pairResults = <ReceiptStitchPairResult>[];
  final requestedTargetWidth = _stitchTargetWidth(
    inputPaths.length,
    maxTargetWidth: maxTargetWidth,
  );
  var activePairIndex = -1;
  try {
    final pairStopwatch = Stopwatch()..start();
    final sourcePreparation = await _prepareReceiptStitchSources(
      inputPaths: inputPaths,
      targetWidth: requestedTargetWidth,
    );
    final preparationFailure = sourcePreparation.failure;
    if (preparationFailure != null) return preparationFailure;
    final targetWidth = sourcePreparation.targetWidth;
    final mappedTextEvidence = _mapReceiptStitchTextEvidenceToFrames(
      textEvidenceByPath,
      sourcePreparation.frameTransforms,
    );
    final mappedNativeProposals = _mapReceiptNativeProposalsToFrames(
      nativeRegistrationProposals,
      sourcePreparation.frameTransforms,
    );
    final prepared = sourcePreparation.prepared;
    final comparisonPrepared = sourcePreparation.comparisonPrepared;
    final comparisonHasReadableDetail =
        sourcePreparation.comparisonHasReadableDetail;
    final comparisonLooksLikeReceiptPhoto =
        sourcePreparation.comparisonLooksLikeReceiptPhoto;
    if (manualOverlapPixels == null && manualOverlapFractions == null) {
      final minimumAutoHeight = _minimumAutoStitchHeight(prepared);
      final minimumAutoPixels = targetWidth * minimumAutoHeight;
      if (minimumAutoHeight > maxOutputHeight ||
          minimumAutoPixels > maxOutputPixels) {
        return _oversizedStitchFallback(
          inputPaths: inputPaths,
          targetWidth: targetWidth,
          expectedHeight: minimumAutoHeight,
          maxOutputPixels: maxOutputPixels,
          maxOutputHeight: maxOutputHeight,
          confidences: const [],
          pairResults: const [],
        )!;
      }
    }
    final normalized = <img.Image>[prepared.first];
    final normalizedForComparison = <img.Image>[comparisonPrepared.first];
    var expectedHeight = normalized.first.height;
    final overlaps = <int>[];
    final horizontalOffsets = <int>[];
    ReceiptStitchResult? oversizedFallback() => _oversizedStitchFallback(
      inputPaths: inputPaths,
      targetWidth: targetWidth,
      expectedHeight: expectedHeight,
      maxOutputPixels: maxOutputPixels,
      maxOutputHeight: maxOutputHeight,
      confidences: confidences,
      pairResults: pairResults,
    );
    final initialOversizedFallback = oversizedFallback();
    if (initialOversizedFallback != null) return initialOversizedFallback;

    for (var index = 1; index < prepared.length; index++) {
      final pairIndex = index - 1;
      activePairIndex = pairIndex;
      final previous = normalized[pairIndex];
      final manualPair = _prepareReceiptManualStitchPair(
        previous: previous,
        next: prepared[index],
        targetWidth: targetWidth,
        pairIndex: pairIndex,
        manualOverlapPixels: manualOverlapPixels,
        manualOverlapFractions: manualOverlapFractions,
        manualScaleCorrections: manualScaleCorrections,
        manualRotationCorrectionsDegrees: manualRotationCorrectionsDegrees,
        manualHorizontalOffsetFractions: manualHorizontalOffsetFractions,
      );
      final manualScale = manualPair.scale;
      final manualRotation = manualPair.rotationDegrees;
      final manualHorizontalFraction = manualPair.horizontalOffsetFraction;
      final manualNext = manualPair.next;
      final manualOverlap = manualPair.overlap;
      final manualZeroOverlap = _receiptManualZeroOverlapFor(
        manualZeroOverlapPairs,
        pairIndex,
      );
      if (manualZeroOverlap) {
        final manualHorizontalOffset = (targetWidth * manualHorizontalFraction)
            .round();
        overlaps.add(0);
        horizontalOffsets.add(manualHorizontalOffset);
        confidences.add(.30);
        pairResults.add(
          ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: 0,
            confidence: .30,
            seamSkipPixels: 0,
            usedManualAdjustment: true,
            usedZeroOverlapJoin: true,
            scaleCorrection: manualScale,
            rotationCorrectionDegrees: manualRotation,
            horizontalOffsetPixels: manualHorizontalOffset,
          ),
        );
        normalized.add(manualNext);
        normalizedForComparison.add(
          _transformForStitchComparison(
            comparisonPrepared[index],
            targetWidth: targetWidth,
            scale: manualScale,
            rotationDegrees: manualRotation,
          ),
        );
        expectedHeight += manualNext.height;
        final fallback = oversizedFallback();
        if (fallback != null) return fallback;
        continue;
      }
      if (manualOverlap != null) {
        final maxManualOverlap =
            math.min(previous.height, manualNext.height) - 24;
        if (manualOverlap < 24 || manualOverlap > maxManualOverlap) {
          return ReceiptStitchResult.fallback(
            inputPaths: inputPaths,
            warning: 'Manual receipt overlap was outside the safe range.',
            fallbackReasonCode: 'manual_overlap_unsafe',
            failedPairIndex: pairIndex,
            pairs: pairResults,
          );
        }
        overlaps.add(manualOverlap);
        final manualHorizontalOffset = (targetWidth * manualHorizontalFraction)
            .round();
        horizontalOffsets.add(manualHorizontalOffset);
        confidences.add(1);
        pairResults.add(
          ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: manualOverlap,
            confidence: 1,
            seamSkipPixels: manualOverlap,
            usedManualAdjustment: true,
            scaleCorrection: manualScale,
            rotationCorrectionDegrees: manualRotation,
            horizontalOffsetPixels: manualHorizontalOffset,
          ),
        );
        normalized.add(manualNext);
        normalizedForComparison.add(
          _transformForStitchComparison(
            comparisonPrepared[index],
            targetWidth: targetWidth,
            scale: manualScale,
            rotationDegrees: manualRotation,
          ),
        );
        expectedHeight += manualNext.height - manualOverlap;
        final fallback = oversizedFallback();
        if (fallback != null) return fallback;
      } else {
        // Do not let a blank, dark, or nearly uniform photo win a visual
        // overlap score merely because it has no competing detail. It stays
        // in the ordered fallback set so the person can retake only that
        // section; it must never become part of a misleading combined proof.
        if (!comparisonHasReadableDetail[pairIndex] ||
            !comparisonHasReadableDetail[index] ||
            !comparisonLooksLikeReceiptPhoto[pairIndex] ||
            !comparisonLooksLikeReceiptPhoto[index]) {
          final failedPair = ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: 0,
            confidence: 0,
          );
          return ReceiptStitchResult.fallback(
            inputPaths: inputPaths,
            warning:
                'One receipt photo does not show enough readable detail to combine safely.',
            fallbackReasonCode: 'unreadable_section_image',
            confidence: 0,
            failedPairIndex: pairIndex,
            pairs: List.unmodifiable([...pairResults, failedPair]),
          );
        }
        final textPlan = _receiptStitchTextPlanForPair(
          inputPaths: inputPaths,
          textEvidenceByPath: mappedTextEvidence,
          pairIndex: pairIndex,
        );
        final textEvidence = textPlan.evidence;
        _traceReceiptStitchPairDecision(
          'text_plan',
          pairIndex: pairIndex,
          stopwatch: pairStopwatch,
          textAccelerated: textPlan.safelyAcceleratesGeometry,
          matchedTextLines: textEvidence.matchedLineCount,
          textConfidence: textEvidence.confidence,
          positionalConfidence: textEvidence.positionalConfidence,
        );
        final documentHorizontalOffsetHint =
            sourcePreparation.documentCenterX.length == prepared.length
            ? ((sourcePreparation.documentCenterX[index] -
                          sourcePreparation.documentCenterX[pairIndex]) *
                      targetWidth)
                  .round()
            : null;
        // OCR is a valuable document signal, but it is not universally
        // available and imperfect receipts can lose exactly the overlap text.
        // Always evaluate bounded registration, then require multiple
        // independent signals before any repeated rows are removed.
        // One subsystem owns physical placement. OCR and native features are
        // evidence about a geometry candidate; they must not independently
        // replace that candidate and then be replaced again by another
        // heuristic. The former chain made the final seam depend on which
        // helper happened to run last.
        _traceReceiptStitchPairDecision(
          'bounded_search_started',
          pairIndex: pairIndex,
          stopwatch: pairStopwatch,
        );
        final match = _bestScaleTolerantVerticalOverlap(
          previous: normalizedForComparison[pairIndex],
          next: comparisonPrepared[index],
          targetWidth: targetWidth,
          comparisonWidth: comparisonWidth,
          retryComparisonWidth: retryComparisonWidth,
          // This only chooses a bounded candidate. The fused acceptance gate
          // still requires two-dimensional geometry when OCR is unavailable.
          allowUprightFastPath: true,
          horizontalOffsetHint: documentHorizontalOffsetHint,
        );
        _traceReceiptStitchPairDecision(
          'candidate_ready',
          pairIndex: pairIndex,
          stopwatch: pairStopwatch,
          visualConfidence: match.confidence,
        );
        final continuity = _receiptOverlapContinuityEvidence(
          previous: normalizedForComparison[pairIndex],
          match: match,
        );
        final geometry = _receiptOverlapGeometryEvidence(
          previous: normalizedForComparison[pairIndex],
          match: match,
        );
        final evidenceDecision = evaluateReceiptStitchEvidence(
          ambiguousPlacement: _receiptPlacementIsAmbiguous(
            previous: normalizedForComparison[pairIndex],
            match: match,
          ),
          visualConfidence: match.confidence,
          continuityCorrelation: continuity.correlation,
          continuityDetailedBands: continuity.detailedBands,
          continuityMatchingBands: continuity.matchingBands,
          continuityProven: continuity.isProven,
          geometryCorrelation: geometry.correlation,
          geometryDetailedCells: geometry.detailedCells,
          geometryMatchingCells: geometry.matchingCells,
          geometryProven: geometry.isProven,
          textConfidence: textEvidence.confidence,
          matchedTextLineCount: textEvidence.matchedLineCount,
          textStrong: textEvidence.isStrong,
          hasTextPositionEvidence: textEvidence.hasPositionalEvidence,
          textPositionalConfidence: textEvidence.positionalConfidence,
        );
        // Geometry can safely produce a reviewable composite without OCR,
        // but it must not silently auto-clear the person's combined-image
        // review. Strong receipt-text overlap is required only for that higher
        // trust tier, not for attempting the stitch itself.
        final effectiveConfidence = textEvidence.isStrong
            ? evidenceDecision.confidence
            : math.min(evidenceDecision.confidence, .69);
        final hasExceptionalContinuity = hasExceptionalReceiptStitchContinuity(
          correlation: continuity.correlation,
          detailedBands: continuity.detailedBands,
          matchingBands: continuity.matchingBands,
        );
        final hasHighTrustPositionedText = hasHighTrustPositionedReceiptOverlap(
          visualConfidence: match.confidence,
          textConfidence: textEvidence.confidence,
          matchedTextLineCount: textEvidence.matchedLineCount,
          hasTextPositionEvidence: textEvidence.hasPositionalEvidence,
          textPositionalConfidence: textEvidence.positionalConfidence,
        );
        final overlapReferenceHeight = math.max(
          1,
          math.min(
            normalizedForComparison[pairIndex].height,
            match.nextImage.height - match.nextTopOffsetPixels,
          ),
        );
        final largeOverlapTransformIsAmbiguous =
            !hasHighTrustPositionedText &&
            isLargeReceiptOverlapTransformAmbiguous(
              overlapPixels: match.pixels,
              overlapReferenceHeight: overlapReferenceHeight,
              scaleCorrection: match.scaleCorrection,
              rotationCorrectionDegrees: match.rotationCorrectionDegrees,
              perspectiveCorrection: match.perspectiveCorrection,
              continuityCorrelation: continuity.correlation,
              continuityDetailedBands: continuity.detailedBands,
              continuityMatchingBands: continuity.matchingBands,
            );
        // A combined receipt is a user-facing proof image. Do not turn a
        // merely plausible overlap into a green "combined" result: preserve
        // the original ordered photos and target the failed pair for review.
        final lowConfidenceTransformIsAggressive =
            effectiveConfidence < .70 &&
            !hasHighTrustPositionedText &&
            !hasExceptionalContinuity &&
            !geometry.isProven &&
            ((match.scaleCorrection - 1).abs() >= .15 ||
                match.rotationCorrectionDegrees.abs() >= 3.5 ||
                match.perspectiveCorrection.abs() >= .085);
        final delayedOverlapIsStructurallyAmbiguous =
            (match.nextTopOffsetPixels > match.pixels ||
                match.nextTopOffsetPixels / overlapReferenceHeight > .18) &&
            !textEvidence.isStrong &&
            !geometry.isProven &&
            !hasExceptionalContinuity;
        _traceReceiptStitchPairDecision(
          'final_gate',
          pairIndex: pairIndex,
          stopwatch: pairStopwatch,
          accepted:
              evidenceDecision.accepted &&
              !delayedOverlapIsStructurallyAmbiguous &&
              !largeOverlapTransformIsAmbiguous &&
              !lowConfidenceTransformIsAggressive,
          matchedTextLines: textEvidence.matchedLineCount,
          textConfidence: textEvidence.confidence,
          positionalConfidence: textEvidence.positionalConfidence,
          visualConfidence: match.confidence,
          continuityConfidence: continuity.correlation,
          geometryConfidence: geometry.correlation,
          scale: match.scaleCorrection,
          overlapPixels: match.pixels,
          reason: !evidenceDecision.accepted
              ? evidenceDecision.reasonCode
              : delayedOverlapIsStructurallyAmbiguous
              ? 'delayed_overlap_ambiguous'
              : largeOverlapTransformIsAmbiguous
              ? 'large_transform_ambiguous'
              : lowConfidenceTransformIsAggressive
              ? 'low_confidence_transform_aggressive'
              : 'accepted',
        );
        // A reviewable low-confidence join may still be geometrically stable.
        // But a weak match that also needs a large scale, rotation, or offset
        // correction can erase real receipt rows when the next opaque image is
        // composited. Preserve the ordered clear sections for retake/manual
        // alignment instead of producing that destructive combined image.
        if (!evidenceDecision.accepted ||
            delayedOverlapIsStructurallyAmbiguous ||
            largeOverlapTransformIsAmbiguous ||
            lowConfidenceTransformIsAggressive) {
          final reportedConfidence = math.min(effectiveConfidence, .69);
          final failedPair = ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: match.pixels,
            confidence: reportedConfidence,
            seamSkipPixels: match.nextSkipPixels,
            scaleCorrection: match.scaleCorrection,
            rotationCorrectionDegrees: match.rotationCorrectionDegrees,
            perspectiveCorrection: match.perspectiveCorrection,
            horizontalOffsetPixels: match.nextXOffsetPixels,
            verticalOffsetPixels: match.nextTopOffsetPixels,
            textOverlapConfidence: textEvidence.confidence,
            matchedTextLineCount: textEvidence.matchedLineCount,
            textPositionalConfidence: textEvidence.positionalConfidence,
            hasTextPositionEvidence: textEvidence.hasPositionalEvidence,
            previousTextOverlapStart: textEvidence.previousOverlapStart,
            nextTextOverlapEnd: textEvidence.nextOverlapEnd,
            nextContinuationTextStart: textEvidence.nextContinuationStart,
            nextContinuationTextEnd: textEvidence.nextContinuationEnd,
            continuityCorrelation: continuity.correlation,
            continuityDetailedBands: continuity.detailedBands,
            continuityMatchingBands: continuity.matchingBands,
            geometryCorrelation: geometry.correlation,
            geometryDetailedCells: geometry.detailedCells,
            geometryMatchingCells: geometry.matchingCells,
            visualConfidence: match.confidence,
            usedNativeRegistration: false,
          );
          return ReceiptStitchResult.fallback(
            inputPaths: inputPaths,
            warning:
                'Receipt photos did not match clearly enough to stitch safely.',
            fallbackReasonCode: 'overlap_confidence_low',
            confidence: reportedConfidence,
            failedPairIndex: pairIndex,
            pairs: List.unmodifiable([...pairResults, failedPair]),
          );
        }
        overlaps.add(match.nextSkipPixels);
        horizontalOffsets.add(match.nextXOffsetPixels);
        confidences.add(effectiveConfidence);
        final nextImage = _materializeRawStitchImage(
          prepared[index],
          match: match,
          targetWidth: targetWidth,
        );
        normalized.add(nextImage);
        // Match every adjacent pair from its independently normalized source.
        // Reusing a transformed prior match compounds zoom/rotation across a
        // three-or-more-photo receipt and makes later pairs drift away from
        // their real neighboring pixels.
        normalizedForComparison.add(comparisonPrepared[index]);
        pairResults.add(
          ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: match.pixels,
            confidence: effectiveConfidence,
            seamSkipPixels: match.nextSkipPixels,
            scaleCorrection: match.scaleCorrection,
            rotationCorrectionDegrees: match.rotationCorrectionDegrees,
            perspectiveCorrection: match.perspectiveCorrection,
            horizontalOffsetPixels: match.nextXOffsetPixels,
            verticalOffsetPixels: match.nextTopOffsetPixels,
            textOverlapConfidence: textEvidence.confidence,
            matchedTextLineCount: textEvidence.matchedLineCount,
            textPositionalConfidence: textEvidence.positionalConfidence,
            hasTextPositionEvidence: textEvidence.hasPositionalEvidence,
            previousTextOverlapStart: textEvidence.previousOverlapStart,
            nextTextOverlapEnd: textEvidence.nextOverlapEnd,
            nextContinuationTextStart: textEvidence.nextContinuationStart,
            nextContinuationTextEnd: textEvidence.nextContinuationEnd,
            continuityCorrelation: continuity.correlation,
            continuityDetailedBands: continuity.detailedBands,
            continuityMatchingBands: continuity.matchingBands,
            geometryCorrelation: geometry.correlation,
            geometryDetailedCells: geometry.detailedCells,
            geometryMatchingCells: geometry.matchingCells,
            visualConfidence: match.confidence,
            usedNativeRegistration: false,
          ),
        );
        expectedHeight += nextImage.height - match.nextSkipPixels;
        final fallback = oversizedFallback();
        if (fallback != null) return fallback;
      }
    }

    activePairIndex = -1;
    return await _composeReceiptStitchOutput(
      inputPaths: inputPaths,
      normalized: normalized,
      horizontalOffsets: horizontalOffsets,
      overlaps: overlaps,
      confidences: confidences,
      pairs: pairResults,
      targetWidth: targetWidth,
      expectedHeight: expectedHeight,
      maxOutputPixels: maxOutputPixels,
      maxOutputHeight: maxOutputHeight,
      outputPath: outputPath,
    );
  } catch (_) {
    return _receiptStitchExceptionFallback(
      inputPaths: inputPaths,
      confidences: confidences,
      activePairIndex: activePairIndex,
      pairs: pairResults,
    );
  }
}
