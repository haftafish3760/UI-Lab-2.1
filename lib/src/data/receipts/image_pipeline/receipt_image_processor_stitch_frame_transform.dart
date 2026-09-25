part of 'receipt_image_processor.dart';

class _ReceiptStitchPreparedFrame {
  const _ReceiptStitchPreparedFrame({
    required this.image,
    required this.transform,
  });

  final img.Image image;
  final _ReceiptStitchFrameTransform transform;
}

class _ReceiptStitchFrameTransform {
  const _ReceiptStitchFrameTransform({
    required this.sourceWidth,
    required this.sourceHeight,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
  });

  factory _ReceiptStitchFrameTransform.identity({
    required int width,
    required int height,
  }) => _ReceiptStitchFrameTransform(
    sourceWidth: width,
    sourceHeight: height,
    cropX: 0,
    cropY: 0,
    cropWidth: width,
    cropHeight: height,
  );

  final int sourceWidth;
  final int sourceHeight;
  final int cropX;
  final int cropY;
  final int cropWidth;
  final int cropHeight;

  bool containsNormalizedPoint(double x, double y) {
    final sourceX = x * sourceWidth;
    final sourceY = y * sourceHeight;
    return sourceX >= cropX &&
        sourceX <= cropX + cropWidth &&
        sourceY >= cropY &&
        sourceY <= cropY + cropHeight;
  }

  double mapX(double normalized) =>
      ((normalized * sourceWidth - cropX) / cropWidth).clamp(0.0, 1.0);

  double mapY(double normalized) =>
      ((normalized * sourceHeight - cropY) / cropHeight).clamp(0.0, 1.0);
}

List<ReceiptStitchTextEvidence>? _mapReceiptStitchTextEvidenceToFrames(
  List<ReceiptStitchTextEvidence>? evidence,
  List<_ReceiptStitchFrameTransform> frames,
) {
  if (evidence == null || evidence.length != frames.length) return evidence;
  return List.unmodifiable([
    for (var index = 0; index < evidence.length; index++)
      _mapReceiptStitchTextEvidenceToFrame(evidence[index], frames[index]),
  ]);
}

ReceiptStitchTextEvidence _mapReceiptStitchTextEvidenceToFrame(
  ReceiptStitchTextEvidence evidence,
  _ReceiptStitchFrameTransform frame,
) {
  if (!evidence.hasPositionedLines) return evidence;
  // OCR can also see status bars, gallery controls, desk labels, and other
  // content outside the detected receipt paper. Once a private comparison
  // frame discards that border, those lines must be discarded as well. Merely
  // clamping them to 0/1 manufactures false edge anchors that can select the
  // wrong repeated-row overlap or an unsafe seam.
  final retained = [
    for (final line in evidence.positionedLines)
      if (frame.containsNormalizedPoint(line.centerX, line.centerY)) line,
  ];
  return ReceiptStitchTextEvidence(
    path: evidence.path,
    // Prevent normalizedLines from falling back to the original unframed
    // strings when every positioned line was outside the retained document.
    lines: [for (final line in retained) line.text],
    positionedLines: [
      for (final line in retained)
        ReceiptStitchTextLineEvidence(
          text: line.text,
          left: frame.mapX(line.left),
          top: frame.mapY(line.top),
          right: frame.mapX(line.right),
          bottom: frame.mapY(line.bottom),
          angleDegrees: line.angleDegrees,
        ),
    ],
  );
}

List<ReceiptNativeRegistrationProposal> _mapReceiptNativeProposalsToFrames(
  List<ReceiptNativeRegistrationProposal> proposals,
  List<_ReceiptStitchFrameTransform> frames,
) {
  return List.unmodifiable([
    for (final proposal in proposals)
      if (proposal.pairIndex >= 0 && proposal.pairIndex + 1 < frames.length)
        ReceiptNativeRegistrationProposal(
          pairIndex: proposal.pairIndex,
          scale:
              proposal.scale *
              frames[proposal.pairIndex + 1].cropWidth /
              frames[proposal.pairIndex].cropWidth,
          rotationDegrees: proposal.rotationDegrees,
          confidence: proposal.confidence,
          inlierCount: proposal.inlierCount,
          reprojectionError: proposal.reprojectionError,
          anchors: [
            for (final anchor in proposal.anchors)
              if (frames[proposal.pairIndex].containsNormalizedPoint(
                    anchor.previousX,
                    anchor.previousY,
                  ) &&
                  frames[proposal.pairIndex + 1].containsNormalizedPoint(
                    anchor.nextX,
                    anchor.nextY,
                  ))
                ReceiptNativeRegistrationAnchor(
                  previousX: frames[proposal.pairIndex].mapX(anchor.previousX),
                  previousY: frames[proposal.pairIndex].mapY(anchor.previousY),
                  nextX: frames[proposal.pairIndex + 1].mapX(anchor.nextX),
                  nextY: frames[proposal.pairIndex + 1].mapY(anchor.nextY),
                ),
          ],
        ),
  ]);
}
