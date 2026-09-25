part of 'receipt_image_processor.dart';

_ScannerImageDecision _autoCorrectPerspectiveWithDecision(img.Image source) {
  final readiness = _perspectiveReadinessCode(source);
  if (readiness != 'perspective_ready_safe_bounds') {
    return _ScannerImageDecision(source, readiness);
  }
  final bounds = _findReceiptContentBounds(source);
  if (bounds == null) {
    return _ScannerImageDecision(
      source,
      'perspective_skipped_no_receipt_bounds',
    );
  }
  final quad = _detectReceiptQuadrilateral(source, bounds);
  if (quad == null) {
    return _ScannerImageDecision(source, 'perspective_skipped_weak_corners');
  }
  final topWidth = quad.topRight.x - quad.topLeft.x;
  final bottomWidth = quad.bottomRight.x - quad.bottomLeft.x;
  final leftHeight = quad.bottomLeft.y - quad.topLeft.y;
  final rightHeight = quad.bottomRight.y - quad.topRight.y;
  final meanWidth = (topWidth + bottomWidth) / 2;
  final meanHeight = (leftHeight + rightHeight) / 2;
  if (meanWidth < 280 || meanHeight < 420) {
    return _ScannerImageDecision(source, 'perspective_skipped_quad_too_small');
  }
  final widthSkew = (topWidth - bottomWidth).abs() / meanWidth;
  final sideSkew = (leftHeight - rightHeight).abs() / meanHeight;
  final centerSkew =
      (((quad.topLeft.x + quad.topRight.x) -
                  (quad.bottomLeft.x + quad.bottomRight.x)) /
              2)
          .abs() /
      meanWidth;
  final correction = math.max(widthSkew, math.max(sideSkew, centerSkew));
  if (correction < .025) {
    return _ScannerImageDecision(
      source,
      'perspective_skipped_already_rectangular',
    );
  }
  if (correction > .30 ||
      topWidth / bottomWidth < .68 ||
      topWidth / bottomWidth > 1.47) {
    return _ScannerImageDecision(
      source,
      'perspective_skipped_unsafe_distortion',
    );
  }
  final minimumReadableWidth = math.min(900, source.width);
  final outputWidth = meanWidth.round().clamp(
    minimumReadableWidth,
    source.width,
  );
  final aspectHeight = (outputWidth * meanHeight / meanWidth).round();
  final minimumReadableHeight = math.min(900, source.height);
  final outputHeight = aspectHeight.clamp(minimumReadableHeight, source.height);
  final rectified = img.copyRectify(
    source,
    topLeft: quad.topLeft,
    topRight: quad.topRight,
    bottomLeft: quad.bottomLeft,
    bottomRight: quad.bottomRight,
    interpolation: img.Interpolation.linear,
    toImage: img.Image(width: outputWidth, height: outputHeight),
  );
  final before = _qualityCheck(source);
  final after = _qualityCheck(rectified);
  final preservesReading =
      after.reviewScore + 2 >= before.reviewScore * .78 &&
      after.textBandScore >= before.textBandScore * .78 &&
      after.contrast >= 16;
  if (!preservesReading) {
    return _ScannerImageDecision(source, 'perspective_skipped_quality_guard');
  }
  return _ScannerImageDecision(rectified, 'perspective_applied_safe_quad');
}

_ReceiptQuadrilateral? _detectReceiptQuadrilateral(
  img.Image source,
  _ReceiptImageBounds bounds,
) {
  final startX = bounds.left.floor().clamp(0, source.width - 1);
  final endX = bounds.right.ceil().clamp(startX + 1, source.width);
  final startY = bounds.top.floor().clamp(0, source.height - 1);
  final endY = bounds.bottom.ceil().clamp(startY + 1, source.height);
  final step = math.max(1, math.max(bounds.width, bounds.height) ~/ 900);
  img.Point? topLeft;
  img.Point? topRight;
  img.Point? bottomLeft;
  img.Point? bottomRight;
  var topLeftScore = double.infinity;
  var topRightScore = -double.infinity;
  var bottomLeftScore = double.infinity;
  var bottomRightScore = -double.infinity;
  var lightPixels = 0;
  for (var y = startY; y < endY; y += step) {
    for (var x = startX; x < endX; x += step) {
      if (_luma(source.getPixel(x, y)) < 178) continue;
      lightPixels++;
      final sum = x + y.toDouble();
      final difference = x - y.toDouble();
      if (sum < topLeftScore) {
        topLeftScore = sum;
        topLeft = img.Point(x, y);
      }
      if (difference > topRightScore) {
        topRightScore = difference;
        topRight = img.Point(x, y);
      }
      if (difference < bottomLeftScore) {
        bottomLeftScore = difference;
        bottomLeft = img.Point(x, y);
      }
      if (sum > bottomRightScore) {
        bottomRightScore = sum;
        bottomRight = img.Point(x, y);
      }
    }
  }
  if (lightPixels < 180 ||
      topLeft == null ||
      topRight == null ||
      bottomLeft == null ||
      bottomRight == null) {
    return null;
  }
  return _ReceiptQuadrilateral(
    topLeft: topLeft,
    topRight: topRight,
    bottomLeft: bottomLeft,
    bottomRight: bottomRight,
  );
}

class _ReceiptQuadrilateral {
  const _ReceiptQuadrilateral({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final img.Point topLeft;
  final img.Point topRight;
  final img.Point bottomLeft;
  final img.Point bottomRight;
}
