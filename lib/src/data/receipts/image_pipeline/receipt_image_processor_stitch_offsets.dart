part of 'receipt_image_processor.dart';

List<int> _stitchHorizontalOffsets(
  int width,
  _ReceiptStitchSearchBudget searchBudget, {
  int? horizontalOffsetHint,
}) {
  final unit = math.max(12, (width * .035).round());
  final offsets = <int>[0];
  for (
    var multiple = 1;
    multiple <= searchBudget.horizontalOffsetMultiples;
    multiple++
  ) {
    final offset = unit * multiple;
    offsets.addAll([-offset, offset]);
  }
  final maxOffset = math.max(unit * 2, (width * .14).round());
  offsets.addAll([-maxOffset, maxOffset]);
  if (horizontalOffsetHint != null) {
    final hint = horizontalOffsetHint.clamp(-maxOffset, maxOffset);
    offsets.addAll([hint - 2, hint, hint + 2]);
  }
  return offsets.where((offset) => offset.abs() <= maxOffset).toSet().toList();
}

List<int> _stitchNextTopOffsets(
  int height,
  int pixels,
  _ReceiptStitchSearchBudget searchBudget,
) {
  final maxOffset = math.min(
    320,
    math.max(0, math.min((height * .26).round(), height - pixels - 24)),
  );
  if (maxOffset <= 0) return const [0];
  return searchBudget.nextTopOffsets
      .where((offset) => offset <= maxOffset)
      .toList(growable: false);
}
