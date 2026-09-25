part of 'receipt_image_processor.dart';

Future<ReceiptStitchResult> _composeReceiptStitchOutput({
  required List<String> inputPaths,
  required List<img.Image> normalized,
  required List<int> horizontalOffsets,
  required List<int> overlaps,
  required List<double> confidences,
  required List<ReceiptStitchPairResult> pairs,
  required int targetWidth,
  required int expectedHeight,
  required int maxOutputPixels,
  required int maxOutputHeight,
  required String outputPath,
}) async {
  final placementOverlaps = <int>[
    for (var index = 1; index < normalized.length; index++)
      receiptGeometryPlacementOverlapPixels(
        seamSkipPixels: pairs[index - 1].seamSkipPixels,
        overlapPixels: pairs[index - 1].overlapPixels,
        nextImageHeight: normalized[index].height,
      ),
  ];
  final compositionHeight =
      normalized.fold<int>(0, (total, image) => total + image.height) -
      placementOverlaps.fold<int>(0, (total, overlap) => total + overlap);
  final horizontalPlacements = _stitchHorizontalPlacements(horizontalOffsets);
  final minPlacementX = horizontalPlacements.reduce(math.min);
  final maxPlacementX = horizontalPlacements
      .map((x) => x + targetWidth)
      .reduce(math.max);
  final canvasWidth = maxPlacementX - minPlacementX;
  final expandedPixels = canvasWidth * compositionHeight;
  if (compositionHeight > maxOutputHeight || expandedPixels > maxOutputPixels) {
    return _oversizedStitchFallback(
      inputPaths: inputPaths,
      targetWidth: canvasWidth,
      expectedHeight: compositionHeight,
      maxOutputPixels: maxOutputPixels,
      maxOutputHeight: maxOutputHeight,
      confidences: confidences,
      pairResults: pairs,
    )!;
  }

  final placementShiftX = -minPlacementX;
  final canvas = img.Image(
    width: canvasWidth,
    height: compositionHeight,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  var y = 0;
  img.compositeImage(
    canvas,
    normalized.first,
    dstX: horizontalPlacements.first + placementShiftX,
    dstY: y,
  );
  y += normalized.first.height;
  for (var index = 1; index < normalized.length; index++) {
    y -= placementOverlaps[index - 1];
    final pair = pairs[index - 1];
    final textSeamCrop = _receiptPositionedTextSeamCrop(
      pair: pair,
      nextHeight: normalized[index].height,
    );
    final seam = textSeamCrop == null
        ? _selectReceiptStitchSeam(
            previous: normalized[index - 1],
            next: normalized[index],
            overlapPixels: pair.overlapPixels,
            nextTopOffset: pair.verticalOffsetPixels,
            horizontalOffset: pair.horizontalOffsetPixels,
          )
        : _ReceiptStitchSeamSelection(
            cropY: textSeamCrop,
            difference: 0,
            inkRatio: 0,
            isSafe: true,
          );
    pairs[index - 1] = pair.withSelectedSeamCrop(seam.cropY);
    if (!pair.usedManualAdjustment && !seam.isSafe) {
      return ReceiptStitchResult.fallback(
        inputPaths: inputPaths,
        warning:
            'The shared receipt area did not contain a safe join between printed lines.',
        fallbackReasonCode: 'seam_quality_low',
        confidence: math.min(pair.confidence, .69),
        failedPairIndex: index - 1,
        pairs: pairs,
      );
    }
    final seamCropY = seam.cropY;
    final continuation = seamCropY <= 0
        ? normalized[index]
        : img.copyCrop(
            normalized[index],
            x: 0,
            y: seamCropY,
            width: normalized[index].width,
            height: normalized[index].height - seamCropY,
          );
    img.compositeImage(
      canvas,
      continuation,
      dstX: horizontalPlacements[index] + placementShiftX,
      dstY: y + seamCropY,
    );
    y += normalized[index].height;
  }

  final path = await _writeJpgToPath(
    canvas,
    outputPath: outputPath,
    quality: 88,
  );
  final confidence = confidences.isEmpty ? 1.0 : confidences.reduce(math.min);
  return ReceiptStitchResult(
    status: ReceiptStitchStatus.stitched,
    inputPaths: inputPaths,
    stitchedPath: path,
    ocrSourcePaths: [path],
    confidence: confidence,
    overlapPixels: overlaps,
    pairs: pairs,
    stitchedWidth: canvasWidth,
    stitchedHeight: compositionHeight,
    usedManualAdjustment: pairs.any((pair) => pair.usedManualAdjustment),
  );
}

bool _receiptHasHighTrustPositionedText(ReceiptStitchPairResult pair) {
  return hasHighTrustPositionedReceiptOverlap(
    visualConfidence: pair.visualConfidence,
    textConfidence: pair.textOverlapConfidence,
    matchedTextLineCount: pair.matchedTextLineCount,
    hasTextPositionEvidence: pair.hasTextPositionEvidence,
    textPositionalConfidence: pair.textPositionalConfidence,
  );
}

int? _receiptPositionedTextSeamCrop({
  required ReceiptStitchPairResult pair,
  required int nextHeight,
}) {
  if (!pair.hasTextPositionEvidence ||
      pair.matchedTextLineCount < 2 ||
      pair.textOverlapConfidence < .66 ||
      pair.textPositionalConfidence < .72 ||
      pair.nextTextOverlapEnd <= 0) {
    return null;
  }
  final overlapStart = pair.verticalOffsetPixels.clamp(0, nextHeight - 1);
  final overlapEnd = (overlapStart + pair.overlapPixels).clamp(
    overlapStart + 1,
    nextHeight - 1,
  );
  // Keep the complete matched text from the previous photo, then start the
  // continuation immediately after the last duplicated OCR line. A generic
  // mid-overlap seam can otherwise bisect that line or erase unique rows when
  // the overlap contains only two or three printed items.
  final hasHighTrustPositionedText = _receiptHasHighTrustPositionedText(pair);
  final textAwareCrop = receiptTextAwareSeamCropPixels(
    geometricOverlapPixels: overlapEnd,
    nextImageHeight: nextHeight,
    matchedTextEnd: pair.nextTextOverlapEnd,
    continuationTextStart: pair.nextContinuationTextStart,
    continuationTextEnd: pair.nextContinuationTextEnd,
    hasHighTrustPositionedText: hasHighTrustPositionedText,
  );
  // Dense OCR anchors plus independent image support can prove that the final
  // duplicate row extends slightly beyond the geometric overlap estimate.
  // In that case, clamping back to overlapEnd visibly repeats that row.
  final maximumCrop = hasHighTrustPositionedText ? nextHeight - 1 : overlapEnd;
  return textAwareCrop.clamp(overlapStart + 1, maximumCrop);
}
