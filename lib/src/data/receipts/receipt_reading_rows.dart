import 'receipt_photo_text.dart';

/// One reading-order row retaining every original OCR box behind its text.
class ReceiptReadingRow {
  ReceiptReadingRow(this.index, this.text, List<ReceiptTextLine> sourceLines)
    : sourceLines = List.unmodifiable(sourceLines);
  final int index;
  final String text;
  final List<ReceiptTextLine> sourceLines;
}

List<ReceiptReadingRow> receiptRowsWithEvidence(ReceiptPhotoText source) {
  final lines =
      source.lines
          .where(
            (line) =>
                line.text.trim().isNotEmpty &&
                line.left.isFinite &&
                line.top.isFinite &&
                line.right.isFinite &&
                line.bottom.isFinite &&
                line.right > line.left &&
                line.bottom > line.top,
          )
          .toList()
        ..sort((a, b) => a.top.compareTo(b.top));
  if (lines.isEmpty) {
    final textRows = source.text.split(RegExp(r'\r?\n'));
    return [
      for (var i = 0; i < textRows.length; i++)
        if (textRows[i].trim().isNotEmpty)
          ReceiptReadingRow(i, textRows[i].trim(), const []),
    ];
  }
  final groups = <List<ReceiptTextLine>>[];
  for (final line in lines) {
    List<ReceiptTextLine>? target;
    for (final group in groups.reversed) {
      final anchor = group.first;
      final height = (anchor.bottom - anchor.top) < (line.bottom - line.top)
          ? anchor.bottom - anchor.top
          : line.bottom - line.top;
      final centerDistance =
          ((anchor.top + anchor.bottom - line.top - line.bottom) / 2).abs();
      if (centerDistance <= height * .35 &&
          group.every(
            (other) => line.left >= other.right || line.right <= other.left,
          )) {
        target = group;
        break;
      }
      if (line.top - anchor.bottom > height) break;
    }
    if (target == null) {
      groups.add([line]);
    } else {
      target.add(line);
    }
  }
  return [
    for (var i = 0; i < groups.length; i++)
      ReceiptReadingRow(
        i,
        (groups[i]..sort((a, b) => a.left.compareTo(b.left)))
            .map((line) => line.text.trim())
            .join(' '),
        groups[i],
      ),
  ];
}

List<String> receiptReadingRows(ReceiptPhotoText source) =>
    receiptRowsWithEvidence(source).map((row) => row.text).toList();
