import 'dart:math' as math;

import '../device_capabilities/device_workload_service.dart';
import 'receipt_photo_text.dart';

/// Regions of ONE upright source image. This is not multi-photo stitching.
class ReceiptOcrSection {
  const ReceiptOcrSection(this.top, this.bottom, this.width, this.sampleSize);
  final int top, bottom, width, sampleSize;
  int get height => bottom - top;
  int get decodedWidth => (width / sampleSize).ceil();
  int get decodedHeight => (height / sampleSize).ceil();
}

List<ReceiptOcrSection> planReceiptOcrSections(
  int width,
  int height,
  int maxPixels,
) {
  if (width <= 0 ||
      height <= 0 ||
      width > 30000 ||
      height > 30000 ||
      width * height > 100000000 ||
      maxPixels < 100000 ||
      maxPixels > 3000000) {
    throw const DeviceWorkloadUnavailable(
      'This photo is too large to read safely. Use separate photos for each section.',
    );
  }
  var sample = 1;
  while ((width / sample).ceil() > 1600) {
    sample *= 2;
  }
  final decodedWidth = (width / sample).ceil();
  final tileHeight = math.min(
    height,
    math.min(width * 2, (maxPixels ~/ decodedWidth) * sample),
  );
  final overlap = math.min(tileHeight ~/ 4, 160 * sample);
  final result = <ReceiptOcrSection>[];
  var top = 0;
  while (true) {
    final bottom = math.min(height, top + tileHeight);
    result.add(ReceiptOcrSection(top, bottom, width, sample));
    if (result.length > 32) {
      throw const DeviceWorkloadUnavailable(
        'This receipt needs too many sections to read at once. Add shorter sections as separate photos.',
      );
    }
    if (bottom == height) break;
    top = bottom - overlap;
  }
  return List.unmodifiable(result);
}

/// Only identical text at the same position in overlapping source regions is
/// collapsed. Repeated purchases on different rows always remain separate.
ReceiptPhotoText mergeReceiptSectionText(List<ReceiptPhotoText> sections) {
  final kept = <({ReceiptTextLine line, int section})>[];
  final warnings = <String>{
    for (final section in sections) ...section.warnings,
  };
  for (var i = 0; i < sections.length; i++) {
    for (final line in sections[i].lines) {
      if (![
            line.left,
            line.top,
            line.right,
            line.bottom,
          ].every((v) => v.isFinite) ||
          line.right <= line.left ||
          line.bottom <= line.top) {
        warnings.add(
          'Some text has an uncertain position. Check the photo before using these details.',
        );
        continue;
      }
      var duplicate = false;
      for (final previous in kept.reversed) {
        if (previous.section == i) continue;
        final old = previous.line;
        final overlapWidth = math.max(
          0.0,
          math.min(old.right, line.right) - math.max(old.left, line.left),
        );
        final overlapHeight = math.max(
          0.0,
          math.min(old.bottom, line.bottom) - math.max(old.top, line.top),
        );
        final intersection = overlapWidth * overlapHeight;
        final union =
            (old.right - old.left) * (old.bottom - old.top) +
            (line.right - line.left) * (line.bottom - line.top) -
            intersection;
        if (union <= 0 || intersection / union < 0.55) continue;
        if (old.text.trim() == line.text.trim()) {
          duplicate = true;
          break;
        }
        warnings.add(
          'Overlapping sections disagree on some text. Check those lines against the photo.',
        );
      }
      if (!duplicate) kept.add((line: line, section: i));
    }
  }
  kept.sort((a, b) {
    final byTop = a.line.top.compareTo(b.line.top);
    return byTop == 0 ? a.line.left.compareTo(b.line.left) : byTop;
  });
  return ReceiptPhotoText(
    text: kept.map((entry) => entry.line.text).join('\n'),
    lines: kept.map((entry) => entry.line).toList(),
    warnings: warnings.toList(),
  );
}
