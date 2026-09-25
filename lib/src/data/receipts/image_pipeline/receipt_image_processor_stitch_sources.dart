part of 'receipt_image_processor.dart';

class _ReceiptStitchSourcePreparation {
  const _ReceiptStitchSourcePreparation({
    required this.targetWidth,
    required this.prepared,
    required this.comparisonPrepared,
    required this.comparisonHasReadableDetail,
    required this.comparisonLooksLikeReceiptPhoto,
    required this.frameTransforms,
    required this.documentCenterX,
  }) : failure = null;

  const _ReceiptStitchSourcePreparation.failed(this.failure)
    : targetWidth = 0,
      prepared = const [],
      comparisonPrepared = const [],
      comparisonHasReadableDetail = const [],
      comparisonLooksLikeReceiptPhoto = const [],
      frameTransforms = const [],
      documentCenterX = const [];

  /// Effective proof width after honoring the capability ceiling without
  /// enlarging any source. Upscaling adds no receipt evidence and multiplies
  /// registration cost on screenshots and lower-resolution camera imports.
  final int targetWidth;
  final List<img.Image> prepared;
  final List<img.Image> comparisonPrepared;
  final List<bool> comparisonHasReadableDetail;
  final List<bool> comparisonLooksLikeReceiptPhoto;
  final List<_ReceiptStitchFrameTransform> frameTransforms;
  final List<double> documentCenterX;
  final ReceiptStitchResult? failure;
}

Future<_ReceiptStitchSourcePreparation> _prepareReceiptStitchSources({
  required List<String> inputPaths,
  required int targetWidth,
}) async {
  final workingSources = <img.Image>[];
  final sourceHashes = <String>[];
  final comparisonSources = <img.Image>[];
  final decoded = <img.Image>[];
  final detailFlags = <bool>[];
  final receiptFlags = <bool>[];
  final workingWidth = _stitchWorkingWidth(targetWidth);

  for (var sourceIndex = 0; sourceIndex < inputPaths.length; sourceIndex++) {
    final sourcePath = inputPaths[sourceIndex];
    final bytes = await ReceiptImageProcessor._readFileBytes(sourcePath);
    final sourceHash = bytes == null ? null : sha256.convert(bytes).toString();
    if (sourceHash != null &&
        _findDuplicateReceiptSourceHashIndex(sourceHashes, sourceHash) >= 0) {
      return _ReceiptStitchSourcePreparation.failed(
        _duplicateReceiptSectionFallback(inputPaths, sourceIndex - 1),
      );
    }
    final decodedImage = bytes == null
        ? null
        : ReceiptImageProcessor._decodeImage(bytes);
    if (decodedImage == null) {
      return _ReceiptStitchSourcePreparation.failed(
        ReceiptStitchResult.fallback(
          inputPaths: inputPaths,
          warning: 'One receipt photo could not be read.',
          fallbackReasonCode: 'decode_failed',
        ),
      );
    }
    // EXIF orientation is baked only into private working copies. User source
    // photos remain unchanged and available to OCR/fallback review.
    final upright = img.bakeOrientation(decodedImage);
    final working = _resizeForStitchWorkingWidth(upright, workingWidth);
    sourceHashes.add(sourceHash!);
    workingSources.add(working);
  }

  // Detect the receipt frame independently, then apply one shared normalized
  // crop to the whole sequence. Cropping every photo to its own paper bounds
  // and stretching each crop to targetWidth erases real camera movement and
  // puts pair offsets in incompatible coordinate spaces.
  final isolatedFrames = workingSources
      .map(_isolateStitchDocumentFrame)
      .toList(growable: false);
  final sharedFrames = _sharedStitchDocumentFrames(
    sources: workingSources,
    detectedFrames: isolatedFrames,
  );
  final frameTransforms = <_ReceiptStitchFrameTransform>[];
  final documentCenterX = <double>[];
  for (var index = 0; index < sharedFrames.length; index++) {
    final isolatedFrame = sharedFrames[index];
    final stitchProof = isolatedFrame.image;
    // Similar-looking sections can contain distinct repeated purchases. A
    // thumbnail similarity score cannot prove they are the same photograph.
    // Exact byte duplicates were handled above; all other sections proceed to
    // registration and seam validation, or the user's explicit manual join.
    final comparisonBase = _resizeToMaxSide(stitchProof, 720);

    decoded.add(stitchProof);
    frameTransforms.add(isolatedFrame.transform);
    final detectedTransform = isolatedFrames[index].transform;
    final detectedCenter =
        (detectedTransform.cropX + detectedTransform.cropWidth / 2) /
        detectedTransform.sourceWidth;
    documentCenterX.add(isolatedFrame.transform.mapX(detectedCenter));
    detailFlags.add(_receiptImageHasReadableDetail(comparisonBase));
    receiptFlags.add(_receiptImageLooksLikeReceiptPhoto(comparisonBase));
    comparisonSources.add(
      img.contrast(
        img.normalize(img.grayscale(comparisonBase), min: 12, max: 244),
        contrast: 100,
      ),
    );
  }

  final effectiveTargetWidth = decoded
      .map((image) => image.width)
      .fold(targetWidth, math.min)
      .clamp(1, targetWidth);
  return _ReceiptStitchSourcePreparation(
    targetWidth: effectiveTargetWidth,
    prepared: decoded
        .map((image) => _resizeToWidth(image, effectiveTargetWidth))
        .toList(growable: false),
    comparisonPrepared: comparisonSources
        .map((image) => _resizeToWidth(image, effectiveTargetWidth))
        .toList(growable: false),
    comparisonHasReadableDetail: List.unmodifiable(detailFlags),
    comparisonLooksLikeReceiptPhoto: List.unmodifiable(receiptFlags),
    frameTransforms: List.unmodifiable(frameTransforms),
    documentCenterX: List.unmodifiable(documentCenterX),
  );
}

List<_ReceiptStitchPreparedFrame> _sharedStitchDocumentFrames({
  required List<img.Image> sources,
  required List<_ReceiptStitchPreparedFrame> detectedFrames,
}) {
  if (sources.length != detectedFrames.length || sources.isEmpty) {
    return detectedFrames;
  }
  var left = 1.0;
  var top = 1.0;
  var right = 0.0;
  var bottom = 0.0;
  for (final frame in detectedFrames) {
    final transform = frame.transform;
    left = math.min(left, transform.cropX / transform.sourceWidth);
    top = math.min(top, transform.cropY / transform.sourceHeight);
    right = math.max(
      right,
      (transform.cropX + transform.cropWidth) / transform.sourceWidth,
    );
    bottom = math.max(
      bottom,
      (transform.cropY + transform.cropHeight) / transform.sourceHeight,
    );
  }
  if (right <= left || bottom <= top) return detectedFrames;
  return List.generate(sources.length, (index) {
    final source = sources[index];
    final cropX = (left * source.width).floor().clamp(0, source.width - 1);
    final cropY = (top * source.height).floor().clamp(0, source.height - 1);
    final cropRight = (right * source.width).ceil().clamp(
      cropX + 1,
      source.width,
    );
    final cropBottom = (bottom * source.height).ceil().clamp(
      cropY + 1,
      source.height,
    );
    final cropWidth = cropRight - cropX;
    final cropHeight = cropBottom - cropY;
    if (cropWidth == source.width && cropHeight == source.height) {
      return _ReceiptStitchPreparedFrame(
        image: source,
        transform: _ReceiptStitchFrameTransform.identity(
          width: source.width,
          height: source.height,
        ),
      );
    }
    return _ReceiptStitchPreparedFrame(
      image: img.copyCrop(
        source,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      ),
      transform: _ReceiptStitchFrameTransform(
        sourceWidth: source.width,
        sourceHeight: source.height,
        cropX: cropX,
        cropY: cropY,
        cropWidth: cropWidth,
        cropHeight: cropHeight,
      ),
    );
  }, growable: false);
}

_ReceiptStitchPreparedFrame _isolateStitchDocumentFrame(img.Image source) {
  _ReceiptStitchPreparedFrame unchanged() => _ReceiptStitchPreparedFrame(
    image: source,
    transform: _ReceiptStitchFrameTransform.identity(
      width: source.width,
      height: source.height,
    ),
  );
  if (source.width < 480 || source.height < 480) return unchanged();
  final sample = _resizeToMaxSide(source, 420);
  final paperBounds = _scanReceiptBounds(sample, paperOnly: true);
  final paperConsumesFrame =
      paperBounds != null &&
      paperBounds.width / sample.width > .94 &&
      paperBounds.height / sample.height > .94;
  final inkBounds = paperConsumesFrame
      ? _scanReceiptBounds(sample, paperOnly: false)
      : null;
  final bounds = inkBounds?.hitCount != null && inkBounds!.hitCount >= 120
      ? inkBounds
      : paperBounds;
  if (bounds == null || bounds.hitCount < 120 || bounds.width <= 0) {
    return unchanged();
  }
  final widthRatio = bounds.width / sample.width;
  final heightRatio = bounds.height / sample.height;
  if (widthRatio < .42 || heightRatio < .42) {
    return unchanged();
  }
  final centerX = (bounds.left + bounds.right) / 2;
  if (((centerX / sample.width) - .5).abs() > .22) return unchanged();
  final usedInkFallback = identical(bounds, inkBounds);
  final padX = (bounds.width * (usedInkFallback ? .12 : .025)).clamp(
    4,
    sample.width * .12,
  );
  final padY = usedInkFallback
      ? (bounds.height * .09).clamp(4, sample.height * .09)
      : 1.0;
  final left = (bounds.left - padX).clamp(0, sample.width - 1);
  final right = (bounds.right + padX).clamp(left + 1, sample.width);
  final top = (bounds.top - padY).clamp(0, sample.height - 1);
  final bottom = (bounds.bottom + padY).clamp(top + 1, sample.height);
  final scaleX = source.width / sample.width;
  final scaleY = source.height / sample.height;
  final cropX = (left * scaleX).round().clamp(0, source.width - 1);
  final cropRight = (right * scaleX).round().clamp(cropX + 1, source.width);
  final cropY = (top * scaleY).round().clamp(0, source.height - 1);
  final cropBottom = (bottom * scaleY).round().clamp(cropY + 1, source.height);
  final keepsHorizontalFrame = (cropRight - cropX) / source.width <= .94;
  final keepsVerticalFrame = (cropBottom - cropY) / source.height <= .94;
  if (!keepsHorizontalFrame && !keepsVerticalFrame) return unchanged();
  // This is a private stitch-working copy. The original source remains
  // untouched for fallback and OCR review. Cropping matching and composition
  // from the same rectangle preserves their coordinate system while keeping
  // phone chrome and background out of the merged receipt artifact.
  return _ReceiptStitchPreparedFrame(
    image: img.copyCrop(
      source,
      x: cropX,
      y: cropY,
      width: cropRight - cropX,
      height: cropBottom - cropY,
    ),
    transform: _ReceiptStitchFrameTransform(
      sourceWidth: source.width,
      sourceHeight: source.height,
      cropX: cropX,
      cropY: cropY,
      cropWidth: cropRight - cropX,
      cropHeight: cropBottom - cropY,
    ),
  );
}

ReceiptStitchResult _duplicateReceiptSectionFallback(
  List<String> inputPaths,
  int pairIndex,
) {
  return ReceiptStitchResult.fallback(
    inputPaths: inputPaths,
    warning:
        'Two receipt photos appear to show the same section. Receipt details will use the photos separately.',
    fallbackReasonCode: 'duplicate_section_image',
    failedPairIndex: pairIndex,
    pairs: [
      ReceiptStitchPairResult(
        pairIndex: pairIndex,
        overlapPixels: 0,
        confidence: 1,
      ),
    ],
  );
}
