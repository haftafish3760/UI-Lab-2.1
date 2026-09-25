part of 'receipt_image_processor.dart';

_ReceiptExposureCurve _receiptExposureCurve(img.Image source) {
  final sample = _resizeToMaxSide(source, 520);
  final values = <int>[];
  final stepX = math.max(1, sample.width ~/ 140);
  final stepY = math.max(1, sample.height ~/ 180);
  for (var y = 0; y < sample.height; y += stepY) {
    for (var x = 0; x < sample.width; x += stepX) {
      values.add(_luma(sample.getPixel(x, y)).round().clamp(0, 255));
    }
  }
  if (values.isEmpty) {
    return const _ReceiptExposureCurve(
      blackPoint: 8,
      midpoint: 148,
      whitePoint: 246,
      shadowShare: 0,
      highlightShare: 0,
    );
  }
  values.sort();
  int percentile(double value) {
    final index = (values.length * value).floor().clamp(0, values.length - 1);
    return values[index];
  }

  final shadows = values.where((value) => value < 82).length / values.length;
  final highlights =
      values.where((value) => value > 226).length / values.length;
  return _ReceiptExposureCurve(
    blackPoint: percentile(.03).toDouble(),
    midpoint: percentile(.50).toDouble(),
    whitePoint: percentile(.97).toDouble(),
    shadowShare: shadows,
    highlightShare: highlights,
  );
}

img.Image _balanceReceiptRows(
  img.Image source, {
  required int targetBrightness,
}) {
  final output = img.Image.from(source);
  final sampleStep = math.max(1, output.width ~/ 54);
  for (var y = 0; y < output.height; y++) {
    var rowTotal = 0.0;
    var rowCount = 0;
    for (var x = 0; x < output.width; x += sampleStep) {
      rowTotal += _luma(output.getPixel(x, y));
      rowCount++;
    }
    if (rowCount == 0) continue;
    final rowBrightness = rowTotal / rowCount;
    final lift = (targetBrightness - rowBrightness).clamp(-38.0, 46.0);
    if (lift.abs() < 5) continue;
    for (var x = 0; x < output.width; x++) {
      final pixel = output.getPixel(x, y);
      final current = _luma(pixel);
      final preserveInk = current < 92 && lift > 0;
      final adjustedLift = preserveInk ? lift * .38 : lift;
      final value = (current + adjustedLift).round().clamp(0, 255);
      pixel
        ..r = value
        ..g = value
        ..b = value;
    }
  }
  return output;
}
