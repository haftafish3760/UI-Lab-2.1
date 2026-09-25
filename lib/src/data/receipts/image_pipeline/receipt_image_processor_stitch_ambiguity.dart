part of 'receipt_image_processor.dart';

/// A good match is insufficient when another row displacement fits equally
/// well. Check distinct vertical placements in the already transformed frame.
/// This veto preserves the originals for review instead of guessing row count.
bool _receiptPlacementIsAmbiguous({
  required img.Image previous,
  required _ReceiptOverlapMatch match,
}) {
  final next = match.nextImage;
  final maximum = math.min(
    previous.height,
    next.height - match.nextTopOffsetPixels,
  );
  final step = math.max(1, maximum ~/ 500);
  final separation = math.max(16, (previous.width * .035).round());
  double residual(int overlap) {
    var error = 0.0;
    var inkSamples = 0;
    final stepX = math.max(2, previous.width ~/ 96);
    final stepY = math.max(1, overlap ~/ 80);
    for (var y = 0; y < overlap; y += stepY) {
      for (
        var x = previous.width ~/ 20;
        x < previous.width * 19 ~/ 20;
        x += stepX
      ) {
        final nextX = x + match.nextXOffsetPixels;
        if (nextX < 0 || nextX >= next.width) continue;
        final a = _luma(previous.getPixel(x, previous.height - overlap + y));
        final b = _luma(next.getPixel(nextX, match.nextTopOffsetPixels + y));
        if (a < 180 || b < 180) {
          error += (a - b).abs();
          inkSamples++;
        }
      }
    }
    return inkSamples < 80 ? double.infinity : error / inkSamples;
  }

  final selected = residual(match.pixels);
  if (!selected.isFinite) return false;
  for (var overlap = 72; overlap <= (maximum * .68).floor(); overlap += step) {
    if ((overlap - match.pixels).abs() < separation) continue;
    final alternative = residual(overlap);
    if (alternative <= 3 && alternative <= selected + 1) return true;
  }
  return false;
}
