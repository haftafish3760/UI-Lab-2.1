import 'dart:ui';

enum ReceiptGhostNeighbour { previous, next }

/// Image-space geometry shared by preview and capture adapters. Inputs describe
/// an upright image after orientation correction, never the raw EXIF dimensions.
/// The selected reference strip is fitted, not stretched or center-cropped.
class ReceiptGhostGeometry {
  const ReceiptGhostGeometry._(this.source, this.destination, this.neighbour);

  final Rect source;
  final Rect destination;
  final ReceiptGhostNeighbour neighbour;

  static ReceiptGhostGeometry fit({
    required Size uprightImage,
    required Rect cameraContent,
    required ReceiptGhostNeighbour neighbour,
    required double sourceFraction,
    required double maximumBandFraction,
  }) {
    if (!uprightImage.width.isFinite ||
        !uprightImage.height.isFinite ||
        uprightImage.width <= 0 ||
        uprightImage.height <= 0 ||
        !cameraContent.isFinite ||
        cameraContent.isEmpty ||
        !sourceFraction.isFinite ||
        sourceFraction <= 0 ||
        sourceFraction > 1 ||
        !maximumBandFraction.isFinite ||
        maximumBandFraction <= 0 ||
        maximumBandFraction > .5) {
      throw ArgumentError('Invalid receipt reference geometry.');
    }
    final sourceHeight = uprightImage.height * sourceFraction;
    final source = Rect.fromLTWH(
      0,
      neighbour == ReceiptGhostNeighbour.previous
          ? uprightImage.height - sourceHeight
          : 0,
      uprightImage.width,
      sourceHeight,
    );
    final widthScale = cameraContent.width / source.width;
    final heightScale =
        cameraContent.height * maximumBandFraction / source.height;
    final scale = widthScale < heightScale ? widthScale : heightScale;
    final width = source.width * scale;
    final height = source.height * scale;
    final destination = Rect.fromLTWH(
      cameraContent.left + (cameraContent.width - width) / 2,
      neighbour == ReceiptGhostNeighbour.previous
          ? cameraContent.top
          : cameraContent.bottom - height,
      width,
      height,
    );
    return ReceiptGhostGeometry._(source, destination, neighbour);
  }
}
