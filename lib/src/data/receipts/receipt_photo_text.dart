/// Observations from one source image, never confirmed expense or stock data.
class ReceiptPhotoText {
  ReceiptPhotoText({
    required this.text,
    required List<ReceiptTextLine> lines,
    List<String> warnings = const [],
  }) : lines = List.unmodifiable(lines),
       warnings = List.unmodifiable(warnings);

  final String text;
  final List<ReceiptTextLine> lines;
  final List<String> warnings;
}

class ReceiptTextLine {
  const ReceiptTextLine(
    this.text,
    this.left,
    this.top,
    this.right,
    this.bottom,
  );
  final String text;
  final double left, top, right, bottom;
}
